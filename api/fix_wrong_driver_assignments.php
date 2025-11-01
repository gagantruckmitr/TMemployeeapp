<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: text/html; charset=utf-8');
require_once 'config.php';

$pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

echo "<h1>Fix Wrong Driver Assignments</h1>";

$stmt = $pdo->query("SELECT id, name, mobile, assigned_to FROM users WHERE role = 'driver' AND assigned_to IN (6, 7)");
$wrongDrivers = $stmt->fetchAll(PDO::FETCH_ASSOC);

if (empty($wrongDrivers)) {
    echo "<p>All Good! No drivers found assigned to TC 6 or 7.</p>";
    exit;
}

echo "<h2>Found " . count($wrongDrivers) . " Driver(s) Wrongly Assigned</h2>";
echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Mobile</th><th>Currently At</th><th>Should Be</th></tr>";
foreach ($wrongDrivers as $driver) {
    echo "<tr><td>{$driver['id']}</td><td>{$driver['name']}</td><td>{$driver['mobile']}</td><td>TC {$driver['assigned_to']}</td><td>TC 3 or 4</td></tr>";
}
echo "</table>";

echo "<form method='post'><button type='submit' name='fix' value='1'>Fix These Assignments Now</button></form>";

if (isset($_POST['fix'])) {
    echo "<hr><h2>Fixing Assignments...</h2>";
    
    $stmt = $pdo->query("SELECT assigned_to, COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to IN (3, 4) GROUP BY assigned_to");
    $counts = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $counts[$row['assigned_to']] = $row['count'];
    }
    
    $fixed = 0;
    foreach ($wrongDrivers as $driver) {
        $tc3Count = $counts[3] ?? 0;
        $tc4Count = $counts[4] ?? 0;
        $assignTo = ($tc3Count <= $tc4Count) ? 3 : 4;
        
        $stmt = $pdo->prepare("UPDATE users SET assigned_to = ?, Updated_at = NOW() WHERE id = ?");
        $stmt->execute([$assignTo, $driver['id']]);
        
        echo "<p>Moved {$driver['name']} (ID: {$driver['id']}) from TC {$driver['assigned_to']} to TC $assignTo</p>";
        $counts[$assignTo]++;
        $fixed++;
    }
    
    echo "<p><strong>Success! Fixed $fixed driver assignment(s)</strong></p>";
    echo "<p><a href='check_specific_assignments.php'>Verify Assignments</a></p>";
}
?>
