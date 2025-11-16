<?php
// Quick check for transporters
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== TRANSPORTER DIAGNOSTIC ===\n\n";
    
    // 1. Total transporters
    $total = $pdo->query("SELECT COUNT(*) FROM users WHERE role = 'transporter'")->fetchColumn();
    echo "1. Total Transporters: $total\n\n";
    
    // 2. Transporters with jobs
    $withJobs = $pdo->query("
        SELECT COUNT(DISTINCT transporter_id) 
        FROM jobs 
        WHERE transporter_id IS NOT NULL 
        AND transporter_id != '' 
        AND transporter_id > 0
    ")->fetchColumn();
    echo "2. Transporters with Jobs (EXCLUDED): $withJobs\n\n";
    
    // 3. Transporters already called
    $called = $pdo->query("
        SELECT COUNT(DISTINCT user_id) 
        FROM call_logs 
        WHERE user_id IN (SELECT id FROM users WHERE role = 'transporter')
        AND user_id IS NOT NULL 
        AND user_id > 0
    ")->fetchColumn();
    echo "3. Transporters Already Called (EXCLUDED): $called\n\n";
    
    // 4. Available transporters
    $available = $pdo->query("
        SELECT COUNT(*) 
        FROM users u
        WHERE u.role = 'transporter'
        AND u.id NOT IN (
            SELECT DISTINCT transporter_id 
            FROM jobs 
            WHERE transporter_id IS NOT NULL 
            AND transporter_id > 0
        )
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs 
            WHERE user_id IS NOT NULL 
            AND user_id > 0
        )
    ")->fetchColumn();
    echo "4. Available for Assignment: $available\n\n";
    
    // 5. Active telecallers
    $telecallers = $pdo->query("
        SELECT COUNT(*) 
        FROM users 
        WHERE role IN ('telecaller', 'admin') 
        AND status = 'active'
    ")->fetchColumn();
    echo "5. Active Telecallers: $telecallers\n\n";
    
    // 6. Sample available transporters
    echo "6. Sample Available Transporters:\n";
    $samples = $pdo->query("
        SELECT u.id, u.name, u.mobile, u.transport_name
        FROM users u
        WHERE u.role = 'transporter'
        AND u.id NOT IN (
            SELECT DISTINCT transporter_id 
            FROM jobs 
            WHERE transporter_id IS NOT NULL 
            AND transporter_id > 0
        )
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs 
            WHERE user_id IS NOT NULL 
            AND user_id > 0
        )
        LIMIT 5
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($samples as $s) {
        echo "   - ID: {$s['id']}, Name: {$s['name']}, Mobile: {$s['mobile']}\n";
    }
    
    echo "\n=== DIAGNOSIS ===\n";
    if ($available == 0) {
        echo "❌ NO TRANSPORTERS AVAILABLE\n";
        echo "Reason: All transporters either have jobs or have been called\n";
        echo "Solution: Add new transporters OR reset call_logs for testing\n";
    } else {
        echo "✅ $available transporters available for assignment\n";
        if ($telecallers == 0) {
            echo "❌ NO ACTIVE TELECALLERS\n";
            echo "Solution: Activate telecaller accounts\n";
        } else {
            echo "✅ Distribution: ~" . ceil($available / $telecallers) . " transporters per telecaller\n";
        }
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
?>
