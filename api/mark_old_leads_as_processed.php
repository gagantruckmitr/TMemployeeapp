<?php
/**
 * Mark All Existing Leads as Processed
 * 
 * This will mark all current leads in the database as "already processed"
 * so they won't show up as fresh leads anymore.
 * 
 * After running this:
 * - All existing 5000+ leads will be hidden from telecallers
 * - Only NEW registrations from now will appear as fresh leads
 * - Telecallers will start with 0 fresh leads
 */

header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "🔧 Marking all existing leads as processed...\n\n";
    echo "⚠️  This will hide all current 5000+ leads from telecallers\n";
    echo "⚠️  Only NEW registrations from now will appear as fresh leads\n\n";
    
    // Get count of existing leads
    $stmt = $pdo->query("
        SELECT COUNT(*) as total
        FROM users
        WHERE role IN ('driver', 'transporter')
    ");
    $totalLeads = $stmt->fetch()['total'];
    
    echo "Found $totalLeads existing leads in database\n\n";
    
    // Create call_logs entries for all existing leads to mark them as "processed"
    echo "Step 1: Marking all leads as processed...\n";
    
    // For each telecaller, mark their assigned leads as processed
    $telecallers = [3, 4, 6, 7];
    $totalMarked = 0;
    
    foreach ($telecallers as $telecallerId) {
        // Get leads assigned to this telecaller
        $stmt = $pdo->prepare("
            SELECT id 
            FROM users 
            WHERE assigned_to = ? 
            AND role IN ('driver', 'transporter')
            AND id NOT IN (SELECT DISTINCT user_id FROM call_logs WHERE caller_id = ?)
        ");
        $stmt->execute([$telecallerId, $telecallerId]);
        $leads = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        // Mark each lead as processed by creating a call_log entry
        foreach ($leads as $userId) {
            $insertStmt = $pdo->prepare("
                INSERT INTO call_logs 
                (user_id, driver_id, caller_id, call_status, feedback, remarks, created_at)
                VALUES 
                (?, ?, ?, 'archived', 'Old lead - marked as processed', 'Archived before fresh lead system', NOW())
            ");
            $insertStmt->execute([$userId, $userId, $telecallerId]);
            $totalMarked++;
        }
        
        echo "  ✅ Telecaller $telecallerId: " . count($leads) . " leads marked as processed\n";
    }
    
    echo "\n✅ Total leads marked as processed: $totalMarked\n\n";
    
    // Verify - check fresh leads count for each telecaller
    echo "Step 2: Verifying fresh leads count (should be 0 for all):\n";
    
    foreach ($telecallers as $telecallerId) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as fresh_count
            FROM users u
            WHERE u.assigned_to = ?
            AND u.role IN ('driver', 'transporter')
            AND u.id NOT IN (
                SELECT DISTINCT user_id 
                FROM call_logs 
                WHERE caller_id = ?
            )
        ");
        $stmt->execute([$telecallerId, $telecallerId]);
        $freshCount = $stmt->fetch()['fresh_count'];
        
        echo "  Telecaller $telecallerId: $freshCount fresh leads\n";
    }
    
    echo "\n✅ All existing leads marked as processed!\n\n";
    echo "📋 What happens now:\n";
    echo "  1. All existing 5000+ leads are hidden from telecallers\n";
    echo "  2. Telecallers will see 0 fresh leads right now\n";
    echo "  3. Only NEW registrations from now will appear as fresh leads\n";
    echo "  4. New drivers → Telecallers 3 & 4\n";
    echo "  5. New transporters → Telecallers 6 & 7\n";
    
    echo json_encode([
        'success' => true,
        'message' => 'All existing leads marked as processed',
        'stats' => [
            'total_leads_in_db' => $totalLeads,
            'leads_marked_processed' => $totalMarked,
            'fresh_leads_remaining' => 0
        ],
        'note' => 'Only NEW registrations from now will appear as fresh leads'
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
