<?php
/**
 * Comprehensive test for User ID 3 jobs
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

$userId = 3;

echo "<h1>User ID 3 - Job Analysis</h1>";
echo "<hr>";

// Total jobs
$result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
$totalJobs = $result->fetch_assoc()['count'];
echo "<h2>Total Jobs: $totalJobs</h2>";

// Check if Application_Deadline column exists
$columnCheck = $conn->query("SHOW COLUMNS FROM jobs LIKE 'Application_Deadline'");
$hasDeadlineColumn = $columnCheck && $columnCheck->num_rows > 0;
echo "<p><strong>Has Application_Deadline column:</strong> " . ($hasDeadlineColumn ? 'Yes' : 'No') . "</p>";

// Check if job_brief_table exists
$jobBriefCheck = $conn->query("SHOW TABLES LIKE 'job_brief_table'");
$hasJobBriefTable = $jobBriefCheck && $jobBriefCheck->num_rows > 0;
echo "<p><strong>Has job_brief_table:</strong> " . ($hasJobBriefTable ? 'Yes' : 'No') . "</p>";

if ($hasJobBriefTable) {
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs j INNER JOIN job_brief_table jb ON j.job_id = jb.job_id WHERE j.assigned_to = $userId AND jb.closed_job = 1");
    $closedJobs = $result->fetch_assoc()['count'];
    echo "<p><strong>Closed jobs:</strong> $closedJobs</p>";
}

echo "<hr>";
echo "<h2>Jobs by Filter</h2>";

// All jobs
$query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId";
$result = $conn->query($query);
$allCount = $result->fetch_assoc()['count'];
echo "<p><strong>ALL filter:</strong> $allCount jobs</p>";

// Approved jobs (status = 1, excluding expired)
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1' AND (Application_Deadline IS NULL OR Application_Deadline = '' OR Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1'";
}
$result = $conn->query($query);
$approvedCount = $result->fetch_assoc()['count'];
echo "<p><strong>APPROVED filter:</strong> $approvedCount jobs</p>";

// Active jobs (status = 1, active_inactive = 1, excluding expired)
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1' AND active_inactive = 1 AND (Application_Deadline IS NULL OR Application_Deadline = '' OR Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1' AND active_inactive = 1";
}
$result = $conn->query($query);
$activeCount = $result->fetch_assoc()['count'];
echo "<p><strong>ACTIVE filter:</strong> $activeCount jobs</p>";

// Pending jobs
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '0' AND active_inactive = 1 AND (Application_Deadline IS NULL OR Application_Deadline = '' OR Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '0' AND active_inactive = 1";
}
$result = $conn->query($query);
$pendingCount = $result->fetch_assoc()['count'];
echo "<p><strong>PENDING filter:</strong> $pendingCount jobs</p>";

// Inactive jobs
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND active_inactive = 0 AND (Application_Deadline IS NULL OR Application_Deadline = '' OR Application_Deadline >= NOW())";
} else {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND active_inactive = 0";
}
$result = $conn->query($query);
$inactiveCount = $result->fetch_assoc()['count'];
echo "<p><strong>INACTIVE filter:</strong> $inactiveCount jobs</p>";

// Expired jobs
if ($hasDeadlineColumn) {
    $query = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND Application_Deadline IS NOT NULL AND Application_Deadline != '' AND Application_Deadline < NOW()";
    $result = $conn->query($query);
    $expiredCount = $result->fetch_assoc()['count'];
    echo "<p><strong>EXPIRED filter:</strong> $expiredCount jobs</p>";
} else {
    echo "<p><strong>EXPIRED filter:</strong> 0 jobs (no deadline column)</p>";
}

echo "<hr>";
echo "<h2>API Test Links</h2>";
echo "<p><a href='phase2_dashboard_stats_api.php?user_id=$userId' target='_blank'>Dashboard Stats API</a></p>";
echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=all' target='_blank'>Jobs API - ALL filter</a></p>";
echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=approved' target='_blank'>Jobs API - APPROVED filter</a></p>";
echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=active' target='_blank'>Jobs API - ACTIVE filter</a></p>";
echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=pending' target='_blank'>Jobs API - PENDING filter</a></p>";
echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=inactive' target='_blank'>Jobs API - INACTIVE filter</a></p>";
echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=expired' target='_blank'>Jobs API - EXPIRED filter</a></p>";

echo "<hr>";
echo "<h2>Sample Jobs (First 20)</h2>";
$query = "SELECT id, job_id, job_title, status, active_inactive, Application_Deadline, Created_at FROM jobs WHERE assigned_to = $userId ORDER BY Created_at DESC LIMIT 20";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Job ID</th><th>Title</th><th>Status</th><th>Active</th><th>Deadline</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $isExpired = $hasDeadlineColumn && !empty($row['Application_Deadline']) && strtotime($row['Application_Deadline']) < time();
        $rowColor = $isExpired ? 'background-color: #ffcccc;' : '';
        
        echo "<tr style='$rowColor'>";
        echo "<td>" . htmlspecialchars($row['id']) . "</td>";
        echo "<td>" . htmlspecialchars($row['job_id']) . "</td>";
        echo "<td>" . htmlspecialchars(substr($row['job_title'], 0, 50)) . "...</td>";
        echo "<td>" . ($row['status'] == '1' ? '<span style="color: green;">Approved</span>' : '<span style="color: orange;">Pending</span>') . "</td>";
        echo "<td>" . ($row['active_inactive'] == 1 ? '<span style="color: green;">Active</span>' : '<span style="color: red;">Inactive</span>') . "</td>";
        echo "<td>" . htmlspecialchars($row['Application_Deadline'] ?? 'N/A') . ($isExpired ? ' <strong>(EXPIRED)</strong>' : '') . "</td>";
        echo "<td>" . htmlspecialchars($row['Created_at']) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<p>User ID 3 should see:</p>";
echo "<ul>";
echo "<li><strong>Dashboard Total Jobs:</strong> $totalJobs</li>";
echo "<li><strong>Job Posting 'All' section:</strong> $allCount jobs</li>";
echo "<li><strong>Job Posting 'Active' section:</strong> $activeCount jobs</li>";
echo "<li><strong>Job Posting 'Approved' section:</strong> $approvedCount jobs</li>";
echo "</ul>";

$conn->close();
?>
