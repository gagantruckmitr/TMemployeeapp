<?php
// Test script to verify welcome-call assignment logic
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== TESTING WELCOME-CALL ASSIGNMENT ===\n\n";
    
    // 1. Check telecallers with tc_for = 'welcome-call'
    echo "1. Telecallers with tc_for = 'welcome-call':\n";
    $stmt = $pdo->query("
        SELECT id, name, tc_for 
        FROM admins 
        WHERE role = 'telecaller' 
        AND tc_for = 'welcome-call'
        ORDER BY id ASC
    ");
    $telecallers = $stmt->fetchAll();
    
    if (empty($telecallers)) {
        echo "   ❌ No telecallers found!\n\n";
    } else {
        foreach ($telecallers as $tc) {
            echo "   ✅ ID: {$tc['id']}, Name: {$tc['name']}\n";
        }
        echo "\n";
    }
    
    // 2. Check transporters who haven't posted jobs
    echo "2. Transporters who haven't posted any jobs:\n";
    $stmt = $pdo->query("
        SELECT COUNT(*) as total
        FROM users u
        WHERE u.role = 'transporter'
        AND u.id NOT IN (
            SELECT DISTINCT transporter_id 
            FROM jobs
            WHERE transporter_id IS NOT NULL
            AND transporter_id != ''
            AND transporter_id > 0
        )
    ");
    $result = $stmt->fetch();
    echo "   Total: {$result['total']} transporters\n\n";
    
    // 3. Check transporters who haven't been called
    echo "3. Transporters who haven't been called:\n";
    $stmt = $pdo->query("
        SELECT COUNT(*) as total
        FROM users u
        WHERE u.role = 'transporter'
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs
            WHERE user_id IS NOT NULL
            AND user_id != ''
            AND user_id > 0
        )
    ");
    $result = $stmt->fetch();
    echo "   Total: {$result['total']} transporters\n\n";
    
    // 4. Check eligible transporters (no jobs + not called)
    echo "4. Eligible transporters (no jobs + not called):\n";
    $stmt = $pdo->query("
        SELECT u.id, u.name, u.transport_name, u.Created_at
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
        ORDER BY u.Created_at DESC
        LIMIT 10
    ");
    $eligible = $stmt->fetchAll();
    
    echo "   Total eligible: " . count($eligible) . " (showing top 10 newest)\n";
    foreach ($eligible as $t) {
        echo "   - ID: {$t['id']}, Name: {$t['name']}, Created: {$t['Created_at']}\n";
    }
    echo "\n";
    
    // 5. Test round-robin distribution
    if (!empty($telecallers) && !empty($eligible)) {
        echo "5. Round-robin distribution preview:\n";
        $telecallerCount = count($telecallers);
        $telecallerIds = array_column($telecallers, 'id');
        
        foreach ($eligible as $index => $t) {
            $telecallerIndex = $index % $telecallerCount;
            $assignedTo = $telecallerIds[$telecallerIndex];
            echo "   - Transporter {$t['id']} → Telecaller $assignedTo\n";
        }
        echo "\n";
    }
    
    echo "=== TEST COMPLETE ===\n";
    
} catch(PDOException $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
