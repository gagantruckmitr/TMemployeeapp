<?php
/**
 * Verify callback request submission is working correctly
 */

header('Content-Type: application/json');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die(json_encode(['success' => false, 'error' => $e->getMessage()]));
}

// Check recent callback call logs
$sql = "SELECT 
            cl.id,
            cl.user_id,
            u.unique_id as tmid,
            u.name,
            cl.tc_for,
            cl.call_source,
            cl.feedback,
            cl.remarks,
            cl.created_at
        FROM call_logs cl
        LEFT JOIN users u ON cl.user_id = u.id
        WHERE cl.call_source = 'callback_requests'
        ORDER BY cl.created_at DESC
        LIMIT 5";

$stmt = $pdo->query($sql);
$callLogs = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode([
    'success' => true,
    'message' => 'Recent callback request call logs',
    'count' => count($callLogs),
    'data' => $callLogs
], JSON_PRETTY_PRINT);
?>
