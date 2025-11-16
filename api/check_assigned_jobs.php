<?php
/**
 * Check which jobs are assigned to which users
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

echo "<h2>Job Assignment Analysis</h2>";
echo "<hr>";

// Total jobs in database
$result = $conn->query("SELECT COUNT(*) as count FROM jobs");
$totalJobs = $result->fetch_assoc()['count'];
echo "<p><strong>Total jobs in database:</strong> $totalJobs</p>";

// Jobs with assigned_to = 0 or NULL
$result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to IS NULL OR assigned_to = 0");
$unassignedJobs = $result->fetch_assoc()['count'];
echo "<p><strong>Unassigned jobs (assigned_to IS NULL OR 0):</strong> $unassignedJobs</p>";

// Jobs grouped by assigned_to
echo "<hr>";
echo "<h3>Jobs by Assigned User</h3>";
$result = $conn->query("SELECT assigned_to, COUNT(*) as count FROM jobs GROUP BY assigned_to ORDER BY count DESC");

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Assigned To (User ID)</th><th>Job Count</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $userId = $row['assigned_to'] ?? 'NULL';
        $count = $row['count'];
        echo "<tr>";
        echo "<td>" . htmlspecialchars($userId) . "</td>";
        echo "<td>" . htmlspecialchars($count) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// Sample of jobs with their assigned_to values
echo "<hr>";
echo "<h3>Sample Jobs (First 20)</h3>";
$result = $conn->query("SELECT id, job_id, job_title, assigned_to, status, active_inactive, Created_at FROM jobs ORDER BY Created_at DESC LIMIT 20");

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Job ID</th><th>Title</th><th>Assigned To</th><th>Status</th><th>Active</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . htmlspecialchars($row['id']) . "</td>";
        echo "<td>" . htmlspecialchars($row['job_id']) . "</td>";
        echo "<td>" . htmlspecialchars($row['job_title']) . "</td>";
        echo "<td>" . htmlspecialchars($row['assigned_to'] ?? 'NULL') . "</td>";
        echo "<td>" . ($row['status'] == '1' ? 'Approved' : 'Pending') . "</td>";
        echo "<td>" . ($row['active_inactive'] == 1 ? 'Active' : 'Inactive') . "</td>";
        echo "<td>" . htmlspecialchars($row['Created_at']) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

$conn->close();
?>
