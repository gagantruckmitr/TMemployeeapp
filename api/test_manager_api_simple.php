<?php
// Simple Manager API Test
header('Content-Type: application/json');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Test overview query
    $stmt = $pdo->query("
        SELECT 
            COUNT(DISTINCT CASE WHEN a.role = 'telecaller' THEN a.id END) as total_telecallers,
            COUNT(DISTINCT cl.id) as total_calls_today
        FROM admins a
        LEFT JOIN call_logs cl ON a.id = cl.caller_id 
            AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
        WHERE a.role = 'telecaller'
    ");
    $overview = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'message' => 'API is working',
        'overview' => $overview,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
