<?php
// Test transporter assignment for specific caller_id
require_once 'config.php';

$callerId = 3; // Test for caller_id = 3

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== TRANSPORTER ASSIGNMENT TEST FOR CALLER_ID = $callerId ===\n\n";
    
    // Get all telecallers from admins table
    $stmt = $pdo->query("SELECT id, name, role FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $stmt->fetchAll();
    
    echo "1. Telecallers in admins table:\n";
    foreach ($telecallers as $tc) {
        echo "   - ID: {$tc['id']}, Name: {$tc['name']}, Role: {$tc['role']}\n";
    }
    echo "\n";
    
    $telecallerIds = array_column($telecallers, 'id');
    $telecallerCount = count($telecallerIds);
    
    // Find caller's index
    $callerIndex = array_search($callerId, $telecallerIds);
    if ($callerIndex === false) {
        echo "❌ Caller ID $callerId not found in telecallers list!\n";
        exit;
    }
    
    echo "2. Caller ID $callerId is at index: $callerIndex (out of $telecallerCount telecallers)\n\n";
    
    // Get all eligible transporters
    $stmt = $pdo->query("
        SELECT u.id, u.unique_id, u.name, u.transport_name
        FROM users u
        WHERE u.role = 'transporter'
        AND u.id NOT IN (
            SELECT DISTINCT transporter_id 
            FROM jobs
            WHERE transporter_id IS NOT NULL
            AND transporter_id != ''
            AND transporter_id > 0
        )
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs
            WHERE user_id IS NOT NULL
            AND user_id != ''
            AND user_id > 0
        )
        ORDER BY u.id ASC
    ");
    
    $allTransporters = $stmt->fetchAll();
    $totalTransporters = count($allTransporters);
    
    echo "3. Total eligible transporters: $totalTransporters\n\n";
    
    // Calculate assignment using modulo
    $assignedTransporters = [];
    foreach ($allTransporters as $index => $transporter) {
        if ($index % $telecallerCount == $callerIndex) {
            $assignedTransporters[] = $transporter;
        }
    }
    
    $assignedCount = count($assignedTransporters);
    echo "4. Transporters assigned to caller $callerId: $assignedCount\n\n";
    
    echo "5. First 10 assigned transporters:\n";
    $sample = array_slice($assignedTransporters, 0, 10);
    foreach ($sample as $t) {
        echo "   - ID: {$t['id']}, TMID: {$t['unique_id']}, Name: {$t['name']}, Transport: {$t['transport_name']}\n";
    }
    
    echo "\n6. Distribution breakdown:\n";
    foreach ($telecallerIds as $idx => $tcId) {
        $count = 0;
        foreach ($allTransporters as $index => $transporter) {
            if ($index % $telecallerCount == $idx) {
                $count++;
            }
        }
        $marker = ($tcId == $callerId) ? " <-- YOU" : "";
        echo "   - Telecaller ID $tcId (index $idx): $count transporters$marker\n";
    }
    
    echo "\n=== TEST COMPLETE ===\n";
    
} catch(PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
