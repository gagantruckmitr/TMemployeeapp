<?php
// Test script to verify transporter query logic
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== TRANSPORTER QUERY TEST ===\n\n";
    
    // Test 1: Count all transporters
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users WHERE role = 'transporter'");
    $result = $stmt->fetch();
    echo "1. Total transporters in users table: " . $result['total'] . "\n\n";
    
    // Test 2: Count transporters who have posted jobs
    $stmt = $pdo->query("
        SELECT COUNT(DISTINCT transporter_id) as total 
        FROM jobs 
        WHERE transporter_id IS NOT NULL 
        AND transporter_id != '' 
        AND transporter_id > 0
    ");
    $result = $stmt->fetch();
    echo "2. Transporters who have posted jobs: " . $result['total'] . "\n\n";
    
    // Test 3: Count transporters who have been called
    $stmt = $pdo->query("
        SELECT COUNT(DISTINCT user_id) as total 
        FROM call_logs 
        WHERE user_id IS NOT NULL 
        AND user_id != '' 
        AND user_id > 0
        AND user_id IN (SELECT id FROM users WHERE role = 'transporter')
    ");
    $result = $stmt->fetch();
    echo "3. Transporters who have been called: " . $result['total'] . "\n\n";
    
    // Test 4: Count eligible transporters (never posted jobs, never called)
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
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs
            WHERE user_id IS NOT NULL
            AND user_id != ''
            AND user_id > 0
        )
    ");
    $result = $stmt->fetch();
    echo "4. Eligible transporters (never posted jobs, never called): " . $result['total'] . "\n\n";
    
    // Test 5: Show sample eligible transporters
    $stmt = $pdo->query("
        SELECT u.id, u.unique_id, u.name, u.transport_name, u.mobile
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
        LIMIT 5
    ");
    
    echo "5. Sample eligible transporters:\n";
    while ($row = $stmt->fetch()) {
        echo "   - ID: {$row['id']}, TMID: {$row['unique_id']}, Name: {$row['name']}, Transport: {$row['transport_name']}, Mobile: {$row['mobile']}\n";
    }
    
    echo "\n=== TEST COMPLETE ===\n";
    
} catch(PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
