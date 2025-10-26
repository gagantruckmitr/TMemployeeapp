<?php
// Assign 50 DIFFERENT latest leads to EACH telecaller
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Step 1: Get all active telecallers
    $telecallersStmt = $pdo->query("SELECT id, name FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($telecallers) == 0) {
        echo json_encode(['error' => 'No telecallers found']);
        exit;
    }
    
    $telecallerCount = count($telecallers);
    $leadsPerTelecaller = 50;
    $totalLeadsNeeded = $telecallerCount * $leadsPerTelecaller;
    
    // Step 2: Clear ALL old assignments
    $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'driver'");
    
    // Step 3: Get the latest drivers (top 100 for 2 telecallers, top 150 for 3, etc.)
    $stmt = $pdo->prepare("
        SELECT id, name, mobile, Created_at 
        FROM users 
        WHERE role = 'driver' 
        ORDER BY Created_at DESC 
        LIMIT :total_needed
    ");
    $stmt->bindValue(':total_needed', $totalLeadsNeeded, PDO::PARAM_INT);
    $stmt->execute();
    $latestDrivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Step 4: Distribute in round-robin fashion
    $assignments = [];
    foreach ($telecallers as $index => $telecaller) {
        $assignments[$telecaller['id']] = [
            'name' => $telecaller['name'],
            'leads' => []
        ];
    }
    
    // Assign leads in round-robin
    foreach ($latestDrivers as $index => $driver) {
        $telecallerIndex = $index % $telecallerCount;
        $telecallerId = $telecallers[$telecallerIndex]['id'];
        
        // Update database
        $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $updateStmt->execute([$telecallerId, $driver['id']]);
        
        // Track for response
        $assignments[$telecallerId]['leads'][] = [
            'id' => $driver['id'],
            'name' => $driver['name'],
            'mobile' => $driver['mobile'],
            'created_at' => $driver['Created_at']
        ];
    }
    
    // Step 5: Prepare response
    $result = [
        'success' => true,
        'message' => "Assigned $leadsPerTelecaller different leads to each telecaller",
        'total_leads_assigned' => count($latestDrivers),
        'telecallers' => []
    ];
    
    foreach ($assignments as $telecallerId => $data) {
        $result['telecallers'][] = [
            'id' => $telecallerId,
            'name' => $data['name'],
            'assigned_count' => count($data['leads']),
            'sample_leads' => array_slice($data['leads'], 0, 5) // Show first 5 as sample
        ];
    }
    
    echo json_encode($result, JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?>
