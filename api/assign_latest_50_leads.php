<?php
/**
 * Assign Latest 50 Leads to Each Telecaller
 * Distributes the newest 150 users (50 per telecaller) using round-robin
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'operation' => 'Assign latest 50 leads per telecaller'
];

try {
    // Step 1: Check if assigned_to column exists
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'assigned_to'");
    if ($stmt->rowCount() == 0) {
        $pdo->exec("ALTER TABLE users ADD COLUMN assigned_to INT(11) DEFAULT NULL AFTER id");
        $pdo->exec("ALTER TABLE users ADD INDEX idx_assigned_to (assigned_to)");
    }
    
    // Step 2: Clear all previous assignments
    $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'driver'");
    
    // Step 3: Get all active telecallers
    $stmt = $pdo->query("SELECT id, name FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($telecallers)) {
        throw new Exception('No telecallers found');
    }
    
    $telecallerCount = count($telecallers);
    $leadsPerTelecaller = 50;
    $totalLeadsNeeded = $telecallerCount * $leadsPerTelecaller;
    
    // Step 4: Get latest users (newest first)
    $stmt = $pdo->prepare("
        SELECT id 
        FROM users 
        WHERE role = 'driver'
        ORDER BY Created_at DESC, id DESC
        LIMIT ?
    ");
    $stmt->execute([$totalLeadsNeeded]);
    $latestUsers = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Step 5: Assign using round-robin
    $assignments = [];
    foreach ($telecallers as $index => $telecaller) {
        $assignments[$telecaller['id']] = [
            'telecaller_id' => $telecaller['id'],
            'telecaller_name' => $telecaller['name'],
            'assigned_users' => []
        ];
    }
    
    foreach ($latestUsers as $index => $userId) {
        $telecallerIndex = $index % $telecallerCount;
        $telecaller = $telecallers[$telecallerIndex];
        $telecallerId = $telecaller['id'];
        
        // Assign user to telecaller
        $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $updateStmt->execute([$telecallerId, $userId]);
        
        $assignments[$telecallerId]['assigned_users'][] = $userId;
    }
    
    // Step 6: Get summary
    $summary = [];
    foreach ($telecallers as $telecaller) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count 
            FROM users 
            WHERE role = 'driver' AND assigned_to = ?
        ");
        $stmt->execute([$telecaller['id']]);
        $count = $stmt->fetchColumn();
        
        $summary[] = [
            'telecaller_id' => $telecaller['id'],
            'telecaller_name' => $telecaller['name'],
            'assigned_count' => $count
        ];
    }
    
    $response['success'] = true;
    $response['message'] = 'Latest leads assigned successfully';
    $response['telecaller_count'] = $telecallerCount;
    $response['leads_per_telecaller'] = $leadsPerTelecaller;
    $response['total_assigned'] = count($latestUsers);
    $response['summary'] = $summary;
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['error'] = $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
