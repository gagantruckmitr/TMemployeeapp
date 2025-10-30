<?php
require_once 'config.php';

header('Content-Type: text/plain');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== Checking Leads for Pooja (ID: 3) ===\n\n";
    
    // Get Pooja's info
    $stmt = $pdo->query("SELECT id, name, mobile, role FROM admins WHERE id = 3");
    $pooja = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($pooja) {
        echo "Telecaller Info:\n";
        echo "  ID: {$pooja['id']}\n";
        echo "  Name: {$pooja['name']}\n";
        echo "  Mobile: {$pooja['mobile']}\n";
        echo "  Role: {$pooja['role']}\n\n";
    } else {
        echo "Telecaller ID 3 not found!\n";
        exit;
    }
    
    // Count leads assigned to Pooja
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to = 3");
    $count = $stmt->fetch()['count'];
    
    echo "Total Leads Assigned: $count\n\n";
    
    if ($count > 0) {
        echo "Sample Leads (first 10):\n";
        echo str_repeat("-", 80) . "\n";
        
        $stmt = $pdo->query("
            SELECT id, name, mobile, Created_at 
            FROM users 
            WHERE role = 'driver' AND assigned_to = 3 
            ORDER BY Created_at ASC 
            LIMIT 10
        ");
        
        $leads = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($leads as $lead) {
            echo "ID: {$lead['id']} | Name: {$lead['name']} | Mobile: {$lead['mobile']} | Created: {$lead['Created_at']}\n";
        }
        
        echo str_repeat("-", 80) . "\n";
    } else {
        echo "No leads currently assigned to Pooja.\n";
    }
    
    // Check all assignments
    echo "\n=== All Telecaller Assignments ===\n\n";
    $stmt = $pdo->query("
        SELECT assigned_to, COUNT(*) as count 
        FROM users 
        WHERE role = 'driver' 
        GROUP BY assigned_to 
        ORDER BY assigned_to
    ");
    
    $assignments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($assignments as $assignment) {
        $tid = $assignment['assigned_to'] ?? 'NULL';
        $count = $assignment['count'];
        echo "Telecaller $tid: $count leads\n";
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
