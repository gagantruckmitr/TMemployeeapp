<?php
/**
 * Auto-assign Telecallers to Existing Users
 * This script assigns telecallers to all existing users using round-robin
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'operation' => 'Auto-assign telecallers to users'
];

try {
    // Step 1: Check if assigned_to column exists in users table
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'assigned_to'");
    $columnExists = $stmt->rowCount() > 0;
    
    if (!$columnExists) {
        // Add assigned_to column
        $pdo->exec("ALTER TABLE users ADD COLUMN assigned_to INT(11) DEFAULT NULL AFTER id");
        $pdo->exec("ALTER TABLE users ADD INDEX idx_assigned_to (assigned_to)");
        $response['column_added'] = true;
    } else {
        $response['column_exists'] = true;
    }
    
    // Step 2: Get all active telecallers
    $stmt = $pdo->query("SELECT id, name FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($telecallers)) {
        $response['success'] = false;
        $response['error'] = 'No telecallers found in admins table';
        echo json_encode($response, JSON_PRETTY_PRINT);
        exit;
    }
    
    $telecallerCount = count($telecallers);
    $telecallerIds = array_column($telecallers, 'id');
    
    // Step 3: Get all users without assigned telecaller
    $stmt = $pdo->query("
        SELECT id 
        FROM users 
        WHERE role = 'driver' 
        AND (assigned_to IS NULL OR assigned_to = 0)
        ORDER BY id ASC
    ");
    $unassignedUsers = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Step 4: Assign telecallers using round-robin
    $assignedCount = 0;
    $assignments = [];
    
    foreach ($unassignedUsers as $index => $userId) {
        $telecallerIndex = $index % $telecallerCount;
        $telecallerId = $telecallerIds[$telecallerIndex];
        
        // Update user with assigned telecaller
        $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $updateStmt->execute([$telecallerId, $userId]);
        
        if (!isset($assignments[$telecallerId])) {
            $assignments[$telecallerId] = [
                'telecaller_id' => $telecallerId,
                'telecaller_name' => $telecallers[$telecallerIndex]['name'],
                'assigned_count' => 0
            ];
        }
        $assignments[$telecallerId]['assigned_count']++;
        $assignedCount++;
    }
    
    // Step 5: Get summary
    $stmt = $pdo->query("
        SELECT 
            a.id as telecaller_id,
            a.name as telecaller_name,
            COUNT(u.id) as total_assigned
        FROM admins a
        LEFT JOIN users u ON a.id = u.assigned_to AND u.role = 'driver'
        WHERE a.role = 'telecaller'
        GROUP BY a.id, a.name
        ORDER BY a.id
    ");
    $summary = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $response['success'] = true;
    $response['message'] = 'Telecallers assigned successfully';
    $response['telecaller_count'] = $telecallerCount;
    $response['users_assigned'] = $assignedCount;
    $response['assignments'] = array_values($assignments);
    $response['summary'] = $summary;
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['error'] = $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
