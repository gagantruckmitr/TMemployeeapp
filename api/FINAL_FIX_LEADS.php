<?php
// FINAL FIX - This will solve the duplicate leads problem once and for all
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo json_encode([
        'step' => 'Starting final fix...',
        'time' => date('H:i:s')
    ]) . "\n";
    
    // STEP 1: Get telecallers
    $telecallersStmt = $pdo->query("SELECT id, name FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($telecallers) < 2) {
        echo json_encode(['error' => 'Need at least 2 telecallers']);
        exit;
    }
    
    $tc1 = $telecallers[0]; // Pooja (ID 3)
    $tc2 = $telecallers[1]; // Tanisha (ID 4)
    
    echo json_encode([
        'step' => 'Found telecallers',
        'tc1' => $tc1['name'] . ' (ID: ' . $tc1['id'] . ')',
        'tc2' => $tc2['name'] . ' (ID: ' . $tc2['id'] . ')'
    ]) . "\n";
    
    // STEP 2: Clear ALL assignments
    $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'driver'");
    
    echo json_encode(['step' => 'Cleared all old assignments']) . "\n";
    
    // STEP 3: Get latest 100 drivers
    $driversStmt = $pdo->query("
        SELECT id, name, mobile, Created_at 
        FROM users 
        WHERE role = 'driver' 
        ORDER BY Created_at DESC 
        LIMIT 100
    ");
    $drivers = $driversStmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'step' => 'Got latest drivers',
        'count' => count($drivers)
    ]) . "\n";
    
    // STEP 4: Assign in STRICT alternating pattern
    $tc1_leads = [];
    $tc2_leads = [];
    
    foreach ($drivers as $index => $driver) {
        if ($index % 2 == 0) {
            // Even index (0, 2, 4, 6...) → Telecaller 1
            $pdo->exec("UPDATE users SET assigned_to = {$tc1['id']} WHERE id = {$driver['id']}");
            $tc1_leads[] = $driver['name'];
        } else {
            // Odd index (1, 3, 5, 7...) → Telecaller 2
            $pdo->exec("UPDATE users SET assigned_to = {$tc2['id']} WHERE id = {$driver['id']}");
            $tc2_leads[] = $driver['name'];
        }
    }
    
    echo json_encode([
        'step' => 'Assignments complete!',
        'tc1_count' => count($tc1_leads),
        'tc2_count' => count($tc2_leads),
        'tc1_sample' => array_slice($tc1_leads, 0, 5),
        'tc2_sample' => array_slice($tc2_leads, 0, 5)
    ]) . "\n";
    
    // STEP 5: Verify the assignments
    $verify1 = $pdo->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = {$tc1['id']}")->fetch();
    $verify2 = $pdo->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = {$tc2['id']}")->fetch();
    
    echo json_encode([
        'step' => 'VERIFICATION',
        'success' => true,
        'tc1' => [
            'name' => $tc1['name'],
            'id' => $tc1['id'],
            'assigned_count' => $verify1['count']
        ],
        'tc2' => [
            'name' => $tc2['name'],
            'id' => $tc2['id'],
            'assigned_count' => $verify2['count']
        ],
        'message' => 'Each telecaller now has DIFFERENT leads!',
        'next_step' => 'Refresh the app to see different leads'
    ], JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'line' => $e->getLine()
    ]);
}
?>
