<?php
/**
 * Manually Reassign Fresh Leads
 * 
 * This script manually reassigns fresh driver leads (last 1 day) to telecallers
 * in round-robin fashion. Use this if you need to rebalance assignments.
 * 
 * Usage:
 *   php api/reassign_fresh_leads.php
 *   php api/reassign_fresh_leads.php --days=7  (reassign last 7 days)
 *   php api/reassign_fresh_leads.php --force   (reassign even if already assigned)
 */

require_once 'config.php';

// Parse command line arguments
$days = 1; // Default: last 1 day
$force = false; // Default: only reassign unassigned

foreach ($argv as $arg) {
    if (strpos($arg, '--days=') === 0) {
        $days = (int)substr($arg, 7);
    }
    if ($arg === '--force') {
        $force = true;
    }
}

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== REASSIGN FRESH LEADS ===\n\n";
    echo "Configuration:\n";
    echo "  - Days: Last $days day(s)\n";
    echo "  - Force: " . ($force ? "Yes (reassign all)" : "No (only unassigned)") . "\n\n";
    
    // Get welcome-call telecallers
    $stmt = $pdo->query("
        SELECT id, name, tc_for 
        FROM admins 
        WHERE role = 'telecaller' 
        AND tc_for = 'welcome-call'
        ORDER BY id ASC
    ");
    $telecallers = $stmt->fetchAll();
    
    if (empty($telecallers)) {
        echo "❌ No welcome-call telecallers found!\n";
        echo "   Please ensure telecallers have tc_for = 'welcome-call' in admins table.\n";
        exit(1);
    }
    
    $telecallerIds = array_column($telecallers, 'id');
    $telecallerCount = count($telecallerIds);
    
    echo "✅ Found $telecallerCount welcome-call telecallers:\n";
    foreach ($telecallers as $tc) {
        echo "   - TC #{$tc['id']}: {$tc['name']}\n";
    }
    echo "\n";
    
    // Get drivers to reassign
    $whereClause = "role = 'driver' AND Created_at >= DATE_SUB(NOW(), INTERVAL $days DAY)";
    if (!$force) {
        $whereClause .= " AND (assigned_to IS NULL OR assigned_to = 0)";
    }
    
    $stmt = $pdo->query("
        SELECT id, name, mobile, Created_at, assigned_to
        FROM users
        WHERE $whereClause
        ORDER BY Created_at DESC
    ");
    $drivers = $stmt->fetchAll();
    
    $totalDrivers = count($drivers);
    
    echo "📊 Found $totalDrivers drivers to reassign\n";
    if ($totalDrivers === 0) {
        echo "   Nothing to do!\n";
        exit(0);
    }
    
    // Show current distribution if force mode
    if ($force) {
        echo "\n📊 Current Distribution:\n";
        $stmt = $pdo->query("
            SELECT 
                a.id,
                a.name,
                COUNT(u.id) AS count
            FROM admins a
            LEFT JOIN users u ON u.assigned_to = a.id 
                AND u.role = 'driver'
                AND u.Created_at >= DATE_SUB(NOW(), INTERVAL $days DAY)
            WHERE a.role = 'telecaller'
            AND a.tc_for = 'welcome-call'
            GROUP BY a.id, a.name
            ORDER BY a.id ASC
        ");
        $currentDist = $stmt->fetchAll();
        foreach ($currentDist as $dist) {
            echo "   - TC #{$dist['id']} ({$dist['name']}): {$dist['count']} drivers\n";
        }
    }
    
    echo "\n";
    
    // Confirm before proceeding
    if ($totalDrivers > 100) {
        echo "⚠️  WARNING: About to reassign $totalDrivers drivers!\n";
        echo "   Press Enter to continue or Ctrl+C to cancel...\n";
        if (php_sapi_name() === 'cli') {
            fgets(STDIN);
        }
    }
    
    echo "🔄 Reassigning drivers in round-robin...\n";
    
    $pdo->beginTransaction();
    
    $assignmentCounts = array_fill_keys($telecallerIds, 0);
    $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
    
    foreach ($drivers as $index => $driver) {
        // Round-robin: assign to telecaller at position (index % telecaller_count)
        $telecallerIndex = $index % $telecallerCount;
        $assignedTelecallerId = $telecallerIds[$telecallerIndex];
        
        // Update the driver's assigned_to field
        $updateStmt->execute([$assignedTelecallerId, $driver['id']]);
        
        $assignmentCounts[$assignedTelecallerId]++;
        
        // Show progress every 100 drivers
        if (($index + 1) % 100 == 0) {
            echo "   - Assigned " . ($index + 1) . " / $totalDrivers drivers...\n";
        }
    }
    
    $pdo->commit();
    
    echo "\n✅ Reassignment complete!\n\n";
    
    echo "📊 New Distribution:\n";
    foreach ($telecallers as $tc) {
        $count = $assignmentCounts[$tc['id']];
        echo "   - TC #{$tc['id']} ({$tc['name']}): $count drivers\n";
    }
    
    // Calculate balance
    $counts = array_values($assignmentCounts);
    $maxCount = max($counts);
    $minCount = min($counts);
    $diff = $maxCount - $minCount;
    
    echo "\n📈 Balance:\n";
    echo "   - Max: $maxCount drivers\n";
    echo "   - Min: $minCount drivers\n";
    echo "   - Difference: $diff\n";
    
    if ($diff <= 1) {
        echo "   ✅ Distribution is balanced!\n";
    } else {
        echo "   ⚠️  Distribution may be unbalanced\n";
    }
    
    echo "\n=== REASSIGNMENT COMPLETE ===\n\n";
    
    echo "📝 Summary:\n";
    echo "   - Total drivers reassigned: $totalDrivers\n";
    echo "   - Telecallers: $telecallerCount\n";
    echo "   - Average per telecaller: " . round($totalDrivers / $telecallerCount, 1) . "\n";
    echo "   - Time period: Last $days day(s)\n\n";
    
} catch(PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "❌ Database Error: " . $e->getMessage() . "\n";
    exit(1);
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    exit(1);
}
