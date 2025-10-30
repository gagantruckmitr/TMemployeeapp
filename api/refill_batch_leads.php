<?php
/**
 * Refill Batch Leads (Auto-assign next 50)
 * 
 * Checks each telecaller:
 * - If they have < 10 fresh leads remaining, assign next 50
 * - Maintains continuous flow of leads
 * 
 * Can be run:
 * - Manually when needed
 * - Via cron job (every hour)
 * - Called from app when telecaller finishes batch
 */

header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "🔄 Checking and refilling batch leads...\n\n";
    
    $refillThreshold = 10; // Refill when less than 10 fresh leads remain
    $batchSize = 50;
    
    $telecallers = [
        3 => 'driver',
        4 => 'driver',
        6 => 'transporter',
        7 => 'transporter'
    ];
    
    $refilled = [];
    
    foreach ($telecallers as $telecallerId => $role) {
        // Count fresh leads for this telecaller
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM users u
            WHERE u.assigned_to = ?
            AND u.id NOT IN (SELECT DISTINCT user_id FROM call_logs WHERE caller_id = ?)
        ");
        $stmt->execute([$telecallerId, $telecallerId]);
        $freshCount = $stmt->fetch()['count'];
        
        echo "Telecaller $telecallerId: $freshCount fresh leads";
        
        // If below threshold, refill
        if ($freshCount < $refillThreshold) {
            echo " (< $refillThreshold) - Refilling...\n";
            
            // Get next batch of unassigned leads
            $stmt = $pdo->prepare("
                SELECT id 
                FROM users 
                WHERE role = ?
                AND assigned_to IS NULL
                ORDER BY Created_at DESC
                LIMIT ?
            ");
            $stmt->execute([$role, $batchSize]);
            $newLeads = $stmt->fetchAll(PDO::FETCH_COLUMN);
            
            // Assign them to this telecaller
            foreach ($newLeads as $leadId) {
                $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?")
                    ->execute([$telecallerId, $leadId]);
            }
            
            $assignedCount = count($newLeads);
            echo "  ✅ Assigned $assignedCount new leads\n";
            
            $refilled[$telecallerId] = $assignedCount;
        } else {
            echo " - OK (no refill needed)\n";
            $refilled[$telecallerId] = 0;
        }
    }
    
    echo "\n✅ Refill check completed!\n\n";
    
    // Show updated counts
    echo "Updated fresh lead counts:\n";
    foreach ($telecallers as $telecallerId => $role) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM users u
            WHERE u.assigned_to = ?
            AND u.id NOT IN (SELECT DISTINCT user_id FROM call_logs WHERE caller_id = ?)
        ");
        $stmt->execute([$telecallerId, $telecallerId]);
        $freshCount = $stmt->fetch()['count'];
        echo "  Telecaller $telecallerId: $freshCount fresh leads\n";
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Batch refill completed',
        'refilled' => $refilled,
        'threshold' => $refillThreshold,
        'batch_size' => $batchSize
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
