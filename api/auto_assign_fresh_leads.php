<?php
/**
 * Auto-Assign Fresh Leads (PHP-based, no triggers)
 * 
 * This script automatically assigns fresh leads to telecallers:
 * - Drivers (last 1 day) → welcome-call telecallers (round-robin)
 * - Transporters → NEVER assigned (use API round-robin)
 * 
 * Run this script:
 * - Manually: php api/auto_assign_fresh_leads.php
 * - Via cron: Every 5 minutes
 */

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== AUTO-ASSIGN FRESH LEADS ===\n";
    echo "Time: " . date('Y-m-d H:i:s') . "\n\n";
    
    // Step 1: Clear any transporter assignments (they should NEVER be assigned)
    $stmt = $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'transporter' AND assigned_to IS NOT NULL");
    if ($stmt > 0) {
        echo "✅ Cleared $stmt transporter assignments\n";
    }
    
    // Step 2: Get welcome-call telecallers
    $stmt = $pdo->query("
        SELECT id, name 
        FROM admins 
        WHERE role = 'telecaller' 
        AND tc_for = 'welcome-call'
        ORDER BY id ASC
    ");
    $telecallers = $stmt->fetchAll();
    
    if (empty($telecallers)) {
        echo "❌ No welcome-call telecallers found!\n";
        exit(1);
    }
    
    $telecallerIds = array_column($telecallers, 'id');
    $telecallerCount = count($telecallerIds);
    
    echo "📊 Found $telecallerCount welcome-call telecallers\n";
    
    // Step 3: Get unassigned fresh drivers (last 1 day)
    $stmt = $pdo->query("
        SELECT id, name, Created_at
        FROM users
        WHERE role = 'driver'
        AND (assigned_to IS NULL OR assigned_to = 0)
        AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
        ORDER BY Created_at DESC
    ");
    $freshDrivers = $stmt->fetchAll();
    
    $totalFresh = count($freshDrivers);
    echo "📊 Found $totalFresh unassigned fresh drivers (last 1 day)\n";
    
    if ($totalFresh === 0) {
        echo "✅ No fresh drivers to assign\n";
        exit(0);
    }
    
    // Step 4: Assign in round-robin
    echo "\n🔄 Assigning drivers in round-robin...\n";
    
    $pdo->beginTransaction();
    
    $assignmentCounts = array_fill_keys($telecallerIds, 0);
    $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
    
    foreach ($freshDrivers as $index => $driver) {
        // Round-robin: assign to telecaller at position (index % telecaller_count)
        $telecallerIndex = $index % $telecallerCount;
        $assignedTelecallerId = $telecallerIds[$telecallerIndex];
        
        // Update the driver's assigned_to field
        $updateStmt->execute([$assignedTelecallerId, $driver['id']]);
        
        $assignmentCounts[$assignedTelecallerId]++;
    }
    
    $pdo->commit();
    
    echo "\n✅ Assignment complete!\n\n";
    echo "📊 Distribution:\n";
    foreach ($telecallers as $tc) {
        $count = $assignmentCounts[$tc['id']];
        echo "   - TC #{$tc['id']} ({$tc['name']}): $count drivers\n";
    }
    
    echo "\n=== COMPLETE ===\n";
    echo "Total assigned: $totalFresh drivers\n";
    
} catch(PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "❌ Error: " . $e->getMessage() . "\n";
    exit(1);
}
