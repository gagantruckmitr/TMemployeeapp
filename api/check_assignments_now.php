<?php
// Check current assignment distribution
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get all telecallers
    $telecallersStmt = $pdo->query("SELECT id, name, email FROM admins WHERE role = 'telecaller' ORDER BY id");
    $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_ASSOC);
    
    $result = [
        'telecallers' => [],
        'total_drivers' => 0,
        'assigned_drivers' => 0,
        'unassigned_drivers' => 0
    ];
    
    // For each telecaller, count their assignments
    foreach ($telecallers as $tc) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count 
            FROM users 
            WHERE role = 'driver' 
            AND assigned_to = ?
        ");
        $stmt->execute([$tc['id']]);
        $count = $stmt->fetch()['count'];
        
        // Get sample user IDs
        $sampleStmt = $pdo->prepare("
            SELECT id, name, mobile, Created_at 
            FROM users 
            WHERE role = 'driver' 
            AND assigned_to = ?
            ORDER BY Created_at DESC
            LIMIT 5
        ");
        $sampleStmt->execute([$tc['id']]);
        $samples = $sampleStmt->fetchAll(PDO::FETCH_ASSOC);
        
        $result['telecallers'][] = [
            'id' => $tc['id'],
            'name' => $tc['name'],
            'email' => $tc['email'],
            'assigned_count' => (int)$count,
            'sample_leads' => $samples
        ];
    }
    
    // Total drivers
    $totalStmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
    $result['total_drivers'] = (int)$totalStmt->fetch()['count'];
    
    // Assigned drivers
    $assignedStmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to IS NOT NULL");
    $result['assigned_drivers'] = (int)$assignedStmt->fetch()['count'];
    
    // Unassigned drivers
    $result['unassigned_drivers'] = $result['total_drivers'] - $result['assigned_drivers'];
    
    // Check if assigned_to column exists
    $columnCheck = $pdo->query("SHOW COLUMNS FROM users LIKE 'assigned_to'");
    $result['assigned_to_column_exists'] = $columnCheck->rowCount() > 0;
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
