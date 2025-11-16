<?php
// Debug Transporter Assignment
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die(json_encode(['error' => 'DB connection failed']));
}

$telecallers = $pdo->query("SELECT id, name FROM users WHERE role IN ('telecaller', 'admin') AND status = 'active' ORDER BY id")->fetchAll();

$transporters = $pdo->query("
    SELECT u.id, u.name, u.mobile FROM users u
    WHERE u.role = 'transporter'
    AND u.id NOT IN (SELECT DISTINCT transporter_id FROM jobs WHERE transporter_id IS NOT NULL AND transporter_id > 0)
    AND u.id NOT IN (SELECT DISTINCT user_id FROM call_logs WHERE user_id IS NOT NULL AND user_id > 0)
    ORDER BY u.id
")->fetchAll();

$assignments = [];
$count = count($telecallers);
if ($count > 0) {
    foreach ($transporters as $i => $t) {
        $tc = $telecallers[$i % $count];
        $assignments[$tc['id']]['name'] = $tc['name'];
        $assignments[$tc['id']]['transporters'][] = $t;
    }
}

echo json_encode([
    'success' => true,
    'telecallers' => count($telecallers),
    'available_transporters' => count($transporters),
    'assignments' => $assignments
], JSON_PRETTY_PRINT);
?>
