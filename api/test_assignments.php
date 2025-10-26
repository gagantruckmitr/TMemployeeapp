<?php
// Test script to check assignments data
header('Content-Type: application/json');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $telecallerId = $_GET['telecaller_id'] ?? 6; // Default to telecaller ID 6 (Numan)
    
    echo "Testing assignments for telecaller ID: $telecallerId\n\n";
    
    // Check if telecaller exists
    $stmt = $pdo->prepare("SELECT id, name, mobile FROM admins WHERE id = ? AND role = 'telecaller'");
    $stmt->execute([$telecallerId]);
    $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$telecaller) {
        echo "❌ Telecaller not found!\n";
        exit;
    }
    
    echo "✅ Telecaller found: {$telecaller['name']} ({$telecaller['mobile']})\n\n";
    
    // Check total drivers in database
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users WHERE role = 'driver'");
    $totalDrivers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    echo "📊 Total drivers in database: $totalDrivers\n\n";
    
    // Check drivers with assigned_to field
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users WHERE role = 'driver' AND assigned_to IS NOT NULL");
    $assignedDrivers = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    echo "📊 Drivers with assigned_to set: $assignedDrivers\n\n";
    
    // Check drivers assigned to this telecaller
    $stmt = $pdo->prepare("
        SELECT 
            u.id,
            u.name,
            u.mobile,
            u.assigned_to,
            u.created_at
        FROM users u
        WHERE u.assigned_to = ? AND u.role = 'driver'
        LIMIT 10
    ");
    $stmt->execute([$telecallerId]);
    $assignments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "📋 Drivers assigned to telecaller $telecallerId: " . count($assignments) . "\n\n";
    
    if (count($assignments) > 0) {
        echo "Sample assignments:\n";
        foreach ($assignments as $i => $driver) {
            echo ($i + 1) . ". {$driver['name']} - {$driver['mobile']} (ID: {$driver['id']})\n";
        }
    } else {
        echo "❌ No drivers assigned to this telecaller!\n\n";
        
        // Show sample of drivers to see their assigned_to values
        $stmt = $pdo->query("
            SELECT id, name, mobile, assigned_to 
            FROM users 
            WHERE role = 'driver' 
            LIMIT 5
        ");
        $sampleDrivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "Sample drivers (first 5):\n";
        foreach ($sampleDrivers as $driver) {
            $assignedTo = $driver['assigned_to'] ?? 'NULL';
            echo "- {$driver['name']} (ID: {$driver['id']}) - assigned_to: $assignedTo\n";
        }
    }
    
} catch(PDOException $e) {
    echo "❌ Database error: " . $e->getMessage();
}
