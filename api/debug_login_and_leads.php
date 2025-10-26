<?php
// Debug script to see what's happening with login and leads
header('Content-Type: application/json');
require_once 'config.php';

$caller_id = $_GET['caller_id'] ?? null;

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $result = [];
    
    // Show all telecallers
    $telecallersStmt = $pdo->query("SELECT id, name, email FROM admins WHERE role = 'telecaller' ORDER BY id");
    $result['all_telecallers'] = $telecallersStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // If caller_id provided, show their leads
    if ($caller_id) {
        $result['requested_caller_id'] = $caller_id;
        
        // Get telecaller info
        $tcStmt = $pdo->prepare("SELECT id, name, email FROM admins WHERE id = ? AND role = 'telecaller'");
        $tcStmt->execute([$caller_id]);
        $result['telecaller_info'] = $tcStmt->fetch(PDO::FETCH_ASSOC);
        
        // Get their assigned leads
        $leadsStmt = $pdo->prepare("
            SELECT id, name, mobile, assigned_to, Created_at
            FROM users 
            WHERE role = 'driver' 
            AND assigned_to = ?
            ORDER BY Created_at DESC
            LIMIT 10
        ");
        $leadsStmt->execute([$caller_id]);
        $result['assigned_leads'] = $leadsStmt->fetchAll(PDO::FETCH_ASSOC);
        $result['assigned_leads_count'] = count($result['assigned_leads']);
    }
    
    // Show distribution summary
    $distStmt = $pdo->query("
        SELECT 
            assigned_to,
            COUNT(*) as count,
            GROUP_CONCAT(id ORDER BY Created_at DESC LIMIT 5) as sample_ids
        FROM users 
        WHERE role = 'driver' AND assigned_to IS NOT NULL
        GROUP BY assigned_to
    ");
    $result['distribution_summary'] = $distStmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Check what the API would return
    if ($caller_id) {
        $apiTestStmt = $pdo->prepare("
            SELECT id, name, mobile, assigned_to
            FROM users
            WHERE role = 'driver'
            AND assigned_to = :caller_id
            AND id NOT IN (
                SELECT DISTINCT user_id 
                FROM call_logs
                WHERE caller_id = :caller_id
            )
            ORDER BY Created_at DESC
            LIMIT 5
        ");
        $apiTestStmt->execute(['caller_id' => $caller_id]);
        $result['api_would_return'] = $apiTestStmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
