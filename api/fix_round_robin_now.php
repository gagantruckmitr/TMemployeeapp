<?php
// Fix round-robin assignments: Alternating distribution
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Step 1: Get telecallers
    $telecallersStmt = $pdo->query("SELECT id, name FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($telecallers) == 0) {
        echo json_encode(['error' => 'No telecallers found']);
        exit;
    }
    
    $telecallerCount = count($telecallers);
    $leadsPerTelecaller = 50;
    $totalLeadsNeeded = $telecallerCount * $leadsPerTelecaller;
    
    // Step 2: Clear ALL assignments first
    $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'driver'");
    
    // Step 3: Get latest drivers (100 for 2 telecallers)
    $stmt = $pdo->prepare("
        SELECT id, name, mobile, Created_at 
        FROM users 
        WHERE role = 'driver' 
        ORDER BY Created_at DESC 
        LIMIT ?
    ");
    $stmt->execute([$totalLeadsNeeded]);
    $latestDrivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Step 4: Assign in ALTERNATING fashion (round-robin)
    // Driver 0 → Telecaller 0 (Pooja)
    // Driver 1 → Telecaller 1 (Tanisha)
    // Driver 2 → Telecaller 0 (Pooja)
    // Driver 3 → Telecaller 1 (Tanisha)
    // And so on...
    
    $assignments = [];
    foreach ($telecallers as $tc) {
        $assignments[$tc['id']] = [
            'name' => $tc['name'],
            'count' => 0,
            'sample_leads' => []
        ];
    }
    
    $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
    
    foreach ($latestDrivers as $index => $driver) {
        // Calculate which telecaller gets this lead
        $telecallerIndex = $index % $telecallerCount;
        $telecallerId = $telecallers[$telecallerIndex]['id'];
        
        // Update database
        $updateStmt->execute([$telecallerId, $driver['id']]);
        
        // Track for response
        $assignments[$telecallerId]['count']++;
        if ($assignments[$telecallerId]['count'] <= 5) {
            $assignments[$telecallerId]['sample_leads'][] = [
                'id' => $driver['id'],
                'name' => $driver['name'],
                'mobile' => $driver['mobile'],
                'created_at' => $driver['Created_at'],
                'position' => $index
            ];
        }
    }
    
    // Step 5: Prepare response
    $result = [
        'success' => true,
        'message' => 'Round-robin assignments completed',
        'total_assigned' => count($latestDrivers),
        'distribution' => 'alternating',
        'telecallers' => []
    ];
    
    foreach ($assignments as $telecallerId => $data) {
        $result['telecallers'][] = [
            'id' => $telecallerId,
            'name' => $data['name'],
            'assigned_count' => $data['count'],
            'sample_leads' => $data['sample_leads']
        ];
    }
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
