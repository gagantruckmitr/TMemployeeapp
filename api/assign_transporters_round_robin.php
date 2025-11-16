<?php
// Script to assign all unassigned transporters to telecallers in round-robin
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== ASSIGNING TRANSPORTERS TO TELECALLERS (ROUND ROBIN) ===\n\n";
    
    // Get all telecallers from admins table where tc_for = 'welcome-call' ONLY
    $stmt = $pdo->query("
        SELECT DISTINCT id, name, tc_for 
        FROM admins 
        WHERE role = 'telecaller' 
        AND tc_for = 'welcome-call'
        ORDER BY id ASC
    ");
    $telecallers = $stmt->fetchAll();
    
    if (empty($telecallers)) {
        echo "❌ No telecallers found with tc_for = 'welcome-call'!\n";
        echo "Please ensure telecallers have tc_for set to exactly 'welcome-call' in admins table.\n";
        exit;
    }
    
    $telecallerIds = array_column($telecallers, 'id');
    $telecallerCount = count($telecallerIds);
    
    echo "1. Found $telecallerCount telecallers with tc_for = 'welcome-call':\n";
    foreach ($telecallers as $tc) {
        echo "   - ID: {$tc['id']}, Name: {$tc['name']}, tc_for: {$tc['tc_for']}\n";
    }
    echo "\n";
    
    // Get all transporters who:
    // - Have role = 'transporter'
    // - Have NOT posted jobs (not in jobs.transporter_id)
    // - Have NOT been called (not in call_logs.user_id)
    // - Are NOT already assigned (assigned_to IS NULL or 0)
    // - Ordered by Created_at DESC (newest first - fresh leads on top)
    $stmt = $pdo->query("
        SELECT u.id, u.unique_id, u.name, u.transport_name, u.Created_at
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
        AND (u.assigned_to IS NULL OR u.assigned_to = 0)
        ORDER BY u.Created_at DESC
    ");
    
    $transporters = $stmt->fetchAll();
    $totalTransporters = count($transporters);
    
    echo "2. Found $totalTransporters unassigned transporters (who haven't posted jobs)\n";
    if ($totalTransporters > 0) {
        echo "   - Newest: {$transporters[0]['name']} (Created: {$transporters[0]['Created_at']})\n";
        if ($totalTransporters > 1) {
            $lastIndex = $totalTransporters - 1;
            echo "   - Oldest: {$transporters[$lastIndex]['name']} (Created: {$transporters[$lastIndex]['Created_at']})\n";
        }
    }
    echo "\n";
    
    if ($totalTransporters == 0) {
        echo "✅ No transporters to assign. All done!\n";
        exit;
    }
    
    echo "3. Assigning transporters in round-robin...\n";
    
    $pdo->beginTransaction();
    
    $assignmentCounts = array_fill_keys($telecallerIds, 0);
    $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
    
    foreach ($transporters as $index => $transporter) {
        // Round-robin: assign to telecaller at position (index % telecaller_count)
        $telecallerIndex = $index % $telecallerCount;
        $assignedTelecallerId = $telecallerIds[$telecallerIndex];
        
        // Update the transporter's assigned_to field
        $updateStmt->execute([$assignedTelecallerId, $transporter['id']]);
        
        $assignmentCounts[$assignedTelecallerId]++;
        
        // Show progress every 100 transporters
        if (($index + 1) % 100 == 0) {
            echo "   - Assigned " . ($index + 1) . " / $totalTransporters transporters...\n";
        }
    }
    
    $pdo->commit();
    
    echo "\n4. Assignment complete! Summary:\n";
    foreach ($telecallers as $tc) {
        $count = $assignmentCounts[$tc['id']];
        echo "   - Telecaller {$tc['id']} ({$tc['name']}): $count transporters\n";
    }
    
    echo "\n✅ Successfully assigned $totalTransporters transporters to $telecallerCount telecallers!\n";
    echo "\n📝 NOTE: Future transporters will be automatically assigned via the API.\n";
    echo "   - New transporters who don't post jobs will appear in round-robin distribution\n";
    echo "   - Fresh leads (newest Created_at) will always appear on top\n";
    echo "   - Only telecallers with tc_for = 'welcome-call' will see these leads\n";
    echo "\n=== ASSIGNMENT COMPLETE ===\n";
    
} catch(PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "❌ Error: " . $e->getMessage() . "\n";
}
