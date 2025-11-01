<?php
/**
 * Verify Transporter Telecaller Setup
 */

header('Content-Type: text/html; charset=utf-8');

if (file_exists(__DIR__ . '/config.php')) {
    require_once __DIR__ . '/config.php';
} else {
    $host = '127.0.0.1';
    $dbname = 'truckmitr';
    $username = 'truckmitr';
    $password = '825Redp&4';
    
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch(PDOException $e) {
        die("Connection failed: " . $e->getMessage());
    }
}

// Get all telecallers with assignments
$stmt = $pdo->query("
    SELECT 
        a.id, a.name, a.mobile,
        COUNT(CASE WHEN u.role = 'driver' THEN 1 END) as drivers,
        COUNT(CASE WHEN u.role = 'transporter' THEN 1 END) as transporters
    FROM admins a
    LEFT JOIN users u ON a.id = u.assigned_to
    WHERE a.role = 'telecaller'
    GROUP BY a.id, a.name, a.mobile
    ORDER BY a.id
");
$telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "<h1>Transporter Telecaller Verification</h1>";
echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Drivers</th><th>Transporters</th></tr>";

foreach ($telecallers as $tc) {
    echo "<tr>";
    echo "<td>{$tc['id']}</td>";
    echo "<td><strong>{$tc['name']}</strong></td>";
    echo "<td>{$tc['mobile']}</td>";
    echo "<td>{$tc['drivers']}</td>";
    echo "<td>{$tc['transporters']}</td>";
    echo "</tr>";
}

echo "</table>";
