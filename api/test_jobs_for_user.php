<?php
/**
 * Test jobs API for specific users
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

echo "<h2>Jobs Count by User</h2>";
echo "<hr>";

$users = [3, 4, 9, 14];

foreach ($users as $userId) {
    echo "<h3>User ID: $userId</h3>";
    
    // Total jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
    $total = $result->fetch_assoc()['count'];
    echo "<p><strong>Total jobs:</strong> $total</p>";
    
    // Approved & Active jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1' AND active_inactive = 1");
    $approvedActive = $result->fetch_assoc()['count'];
    echo "<p><strong>Approved & Active jobs:</strong> $approvedActive</p>";
    
    // Test the actual API call
    echo "<p><a href='phase2_jobs_api.php?user_id=$userId&filter=all' target='_blank'>Test API for user $userId (filter=all)</a></p>";
    echo "<p><a href='phase2_dashboard_stats_api.php?user_id=$userId' target='_blank'>Test Dashboard Stats for user $userId</a></p>";
    
    echo "<hr>";
}

$conn->close();
?>
