<?php
/**
 * Debug Fresh Leads API
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$callerId = $_GET['caller_id'] ?? 1;

try {
    // Check assigned_to values
    $stmt = $pdo->prepare("
        SELECT 
            id, name, mobile, assigned_to, Created_at
        FROM users 
        WHERE role = 'driver' 
        AND assigned_to = ?
        ORDER BY Created_at DESC
        LIMIT 10
    ");
    $stmt->execute([$callerId]);
    $assignedUsers = $stmt->fetchAll();
    
    // Check all assigned_to values
    $stmt = $pdo->query("
        SELECT assigned_to, COUNT(*) as count 
        FROM users 
        WHERE role = 'driver' AND assigned_to IS NOT NULL
        GROUP BY assigned_to
    ");
    $distribution = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'caller_id' => $callerId,
        'users_assigned_to_this_telecaller' => count($assignedUsers),
        'sample_users' => $assignedUsers,
        'overall_distribution' => $distribution
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
