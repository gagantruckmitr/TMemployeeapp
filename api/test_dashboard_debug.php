<?php
/**
 * Dashboard Debug Test - Check what's happening with dashboard stats
 */
header('Content-Type: application/json');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $callerId = (int)($_GET['caller_id'] ?? 1);
    $today = date('Y-m-d');
    
    // Check if call_logs table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'call_logs'");
    $tableExists = $stmt->rowCount() > 0;
    
    $debug = [
        'table_exists' => $tableExists,
        'caller_id' => $callerId,
        'today' => $today,
    ];
    
    if ($tableExists) {
        // Get total calls
        $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM call_logs WHERE caller_id = ?");
        $stmt->execute([$callerId]);
        $debug['total_calls_all_time'] = (int)$stmt->fetchColumn();
        
        // Get today's calls
        $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM call_logs WHERE caller_id = ? AND DATE(call_time) = ?");
        $stmt->execute([$callerId, $today]);
        $debug['total_calls_today'] = (int)$stmt->fetchColumn();
        
        // Get all calls for this caller
        $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE caller_id = ? ORDER BY call_time DESC LIMIT 10");
        $stmt->execute([$callerId]);
        $debug['recent_calls'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get call status breakdown
        $stmt = $pdo->prepare("SELECT call_status, COUNT(*) as count FROM call_logs WHERE caller_id = ? GROUP BY call_status");
        $stmt->execute([$callerId]);
        $debug['status_breakdown'] = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
    }
    
    // Check users table
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
    $debug['total_drivers'] = (int)$stmt->fetchColumn();
    
    // Check admins table
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
    $debug['total_telecallers'] = (int)$stmt->fetchColumn();
    
    echo json_encode([
        'success' => true,
        'debug' => $debug
    ], JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
