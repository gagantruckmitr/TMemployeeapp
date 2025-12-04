<?php
// Test script to check actual feedback values in database
require_once 'config.php';

$callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 3;

echo "<h2>Checking Feedback Values in Database (Caller ID: $callerId)</h2>";

// Get sample feedback values
$stmt = $pdo->prepare("
    SELECT 
        id,
        driver_name,
        call_status,
        feedback,
        created_at
    FROM call_logs 
    WHERE caller_id = ? 
    AND (feedback IS NOT NULL AND feedback != '')
    ORDER BY created_at DESC
    LIMIT 20
");
$stmt->execute([$callerId]);
$results = $stmt->fetchAll();

echo "<h3>Sample Feedback Values (Last 20):</h3>";
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>ID</th><th>Driver</th><th>Status</th><th>Feedback</th><th>Date</th></tr>";
foreach ($results as $row) {
    echo "<tr>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['driver_name']}</td>";
    echo "<td>{$row['call_status']}</td>";
    echo "<td><strong>{$row['feedback']}</strong></td>";
    echo "<td>{$row['created_at']}</td>";
    echo "</tr>";
}
echo "</table>";

// Count by feedback patterns
echo "<h3>Feedback Pattern Counts:</h3>";
$patterns = [
    "Contains 'interested'" => "feedback LIKE '%interested%'",
    "Contains 'not interested'" => "feedback LIKE '%not interested%'",
    "Contains 'agree'" => "feedback LIKE '%agree%'",
    "Status = 'not_interested'" => "call_status = 'not_interested'",
    "Empty or NULL feedback" => "(feedback IS NULL OR feedback = '')",
];

echo "<table border='1' cellpadding='5'>";
echo "<tr><th>Pattern</th><th>Count</th></tr>";
foreach ($patterns as $label => $condition) {
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as count
        FROM call_logs 
        WHERE caller_id = ? AND $condition
    ");
    $stmt->execute([$callerId]);
    $count = $stmt->fetch()['count'];
    echo "<tr><td>$label</td><td>$count</td></tr>";
}
echo "</table>";

// Get all unique call statuses
echo "<h3>All Call Statuses:</h3>";
$stmt = $pdo->prepare("
    SELECT call_status, COUNT(*) as count
    FROM call_logs 
    WHERE caller_id = ?
    GROUP BY call_status
    ORDER BY count DESC
");
$stmt->execute([$callerId]);
$statuses = $stmt->fetchAll();

echo "<table border='1' cellpadding='5'>";
echo "<tr><th>Status</th><th>Count</th></tr>";
foreach ($statuses as $row) {
    echo "<tr><td>{$row['call_status']}</td><td>{$row['count']}</td></tr>";
}
echo "</table>";
?>
