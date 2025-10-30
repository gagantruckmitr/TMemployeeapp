<?php
require_once 'config.php';

header('Content-Type: text/plain');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== Assigning 50 Leads to Each Telecaller ===\n\n";
    
    // Active telecallers for assignment
    $telecallers = [3, 4, 8, 9, 10];
    $leadsPerTelecaller = 50;
    
    // First, verify telecallers exist
    echo "Verifying telecallers exist:\n";
    foreach ($telecallers as $tid) {
        $stmt = $pdo->prepare("SELECT id, name, mobile FROM admins WHERE id = ? AND role = 'telecaller'");
        $stmt->execute([$tid]);
        $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($telecaller) {
            echo "  ✓ Telecaller $tid: {$telecaller['name']} ({$telecaller['mobile']})\n";
        } else {
            echo "  ✗ Telecaller $tid: NOT FOUND!\n";
        }
    }
    
    echo "\n=== Starting Assignment ===\n\n";
    
    // Clear all assignments except 6 and 7
    $clearStmt = $pdo->exec("
        UPDATE users 
        SET assigned_to = NULL 
        WHERE role = 'driver' 
        AND assigned_to IS NOT NULL
        AND assigned_to != 0
        AND assigned_to NOT IN (6, 7)
    ");
    echo "Cleared existing assignments (except 6 & 7): $clearStmt rows affected\n\n";
    
    // Assign 50 leads to each telecaller
    foreach ($telecallers as $telecallerId) {
        echo "Assigning to Telecaller $telecallerId...\n";
        
        // Get 50 oldest unassigned leads
        $stmt = $pdo->query("
            SELECT id 
            FROM users 
            WHERE role = 'driver' 
            AND (assigned_to IS NULL OR assigned_to = 0)
            ORDER BY Created_at ASC 
            LIMIT $leadsPerTelecaller
        ");
        
        $leads = $stmt->fetchAll(PDO::FETCH_COLUMN);
        $assignedCount = 0;
        
        foreach ($leads as $leadId) {
            $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
            $updateStmt->execute([$telecallerId, $leadId]);
            $assignedCount++;
        }
        
        echo "  ✓ Assigned $assignedCount leads to Telecaller $telecallerId\n";
    }
    
    echo "\n=== Final Distribution ===\n\n";
    
    // Show final counts
    foreach ($telecallers as $tid) {
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to = ?");
        $stmt->execute([$tid]);
        $count = $stmt->fetch()['count'];
        echo "Telecaller $tid: $count leads\n";
    }
    
    // Show telecallers 6 and 7 (unchanged)
    echo "\nUnchanged:\n";
    $stmt6 = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to = 6");
    echo "Telecaller 6: " . $stmt6->fetch()['count'] . " leads\n";
    
    $stmt7 = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to = 7");
    echo "Telecaller 7: " . $stmt7->fetch()['count'] . " leads\n";
    
    // Show unassigned
    $stmtUnassigned = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND (assigned_to IS NULL OR assigned_to = 0)");
    echo "\nUnassigned: " . $stmtUnassigned->fetch()['count'] . " leads\n";
    
    echo "\n✓ Assignment complete!\n";
    
} catch (Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
