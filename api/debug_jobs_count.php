<?php
/**
 * Debug script to check job counts
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

// Replace with your actual user ID
$userId = 1; // Change this to the actual telecaller user ID

echo "<h2>Job Count Debug</h2>";
echo "<hr>";

// Total jobs assigned to user
$result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
$totalJobs = $result->fetch_assoc()['count'];
echo "<p><strong>Total jobs assigned to user $userId:</strong> $totalJobs</p>";

// Check if Application_Deadline column exists
$columnCheck = $conn->query("SHOW COLUMNS FROM jobs LIKE 'Application_Deadline'");
$hasDeadlineColumn = $columnCheck && $columnCheck->num_rows > 0;
echo "<p><strong>Has Application_Deadline column:</strong> " . ($hasDeadlineColumn ? 'Yes' : 'No') . "</p>";

// Check if job_brief_table exists
$jobBriefCheck = $conn->query("SHOW TABLES LIKE 'job_brief_table'");
$hasJobBriefTable = $jobBriefCheck && $jobBriefCheck->num_rows > 0;
echo "<p><strong>Has job_brief_table:</strong> " . ($hasJobBriefTable ? 'Yes' : 'No') . "</p>";

if ($hasJobBriefTable) {
    $closedResult = $conn->query("SELECT COUNT(*) as count FROM job_brief_table WHERE closed_job = 1");
    $closedCount = $closedResult->fetch_assoc()['count'];
    echo "<p><strong>Total closed jobs in job_brief_table:</strong> $closedCount</p>";
    
    // Jobs that are both assigned to user AND closed
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs j INNER JOIN job_brief_table jb ON j.job_id = jb.job_id WHERE j.assigned_to = $userId AND jb.closed_job = 1");
    $userClosedJobs = $result->fetch_assoc()['count'];
    echo "<p><strong>Closed jobs assigned to user $userId:</strong> $userClosedJobs</p>";
}

echo "<hr>";
echo "<h3>Jobs by Filter (Current API Logic)</h3>";

// Test 'all' filter
$query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId";
$result = $conn->query($query);
$allCount = $result->fetch_assoc()['count'];
echo "<p><strong>'all' filter:</strong> $allCount jobs</p>";

// Test 'approved' filter
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.status = '1' AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.status = '1'";
}
$result = $conn->query($query);
$approvedCount = $result->fetch_assoc()['count'];
echo "<p><strong>'approved' filter:</strong> $approvedCount jobs</p>";

// Test 'active' filter
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.active_inactive = 1 AND j.status = '1' AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.active_inactive = 1 AND j.status = '1'";
}
$result = $conn->query($query);
$activeCount = $result->fetch_assoc()['count'];
echo "<p><strong>'active' filter:</strong> $activeCount jobs</p>";

// Test 'pending' filter
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.status = '0' AND j.active_inactive = 1 AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.status = '0' AND j.active_inactive = 1";
}
$result = $conn->query($query);
$pendingCount = $result->fetch_assoc()['count'];
echo "<p><strong>'pending' filter:</strong> $pendingCount jobs</p>";

// Test 'inactive' filter
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.active_inactive = 0 AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.active_inactive = 0";
}
$result = $conn->query($query);
$inactiveCount = $result->fetch_assoc()['count'];
echo "<p><strong>'inactive' filter:</strong> $inactiveCount jobs</p>";

// Test 'expired' filter
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs j WHERE j.assigned_to = $userId AND j.Application_Deadline IS NOT NULL AND j.Application_Deadline != '' AND j.Application_Deadline < NOW()";
    $result = $conn->query($query);
    $expiredCount = $result->fetch_assoc()['count'];
    echo "<p><strong>'expired' filter:</strong> $expiredCount jobs</p>";
} else {
    echo "<p><strong>'expired' filter:</strong> 0 jobs (no deadline column)</p>";
}

echo "<hr>";
echo "<h3>Sample Jobs Data</h3>";
$query = "SELECT job_id, job_title, status, active_inactive, Application_Deadline, Created_at FROM jobs WHERE assigned_to = $userId ORDER BY Created_at DESC LIMIT 10";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Job ID</th><th>Title</th><th>Status</th><th>Active/Inactive</th><th>Deadline</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . htmlspecialchars($row['job_id']) . "</td>";
        echo "<td>" . htmlspecialchars($row['job_title']) . "</td>";
        echo "<td>" . ($row['status'] == '1' ? 'Approved' : 'Pending') . "</td>";
        echo "<td>" . ($row['active_inactive'] == 1 ? 'Active' : 'Inactive') . "</td>";
        echo "<td>" . htmlspecialchars($row['Application_Deadline'] ?? 'N/A') . "</td>";
        echo "<td>" . htmlspecialchars($row['Created_at']) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

$conn->close();
?>
