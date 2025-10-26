<?php
// Script to assign drivers to telecaller
header('Content-Type: text/plain');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $telecallerId = $_GET['telecaller_id'] ?? 6;
    $count = $_GET['count'] ?? 50;
    
    echo "Assigning $count drivers to telecaller ID: $telecallerId\n\n";
    
    // Check if telecaller exists
    $stmt = $pdo->prepare("SELECT id, name FROM admins WHERE id = ? AND role = 'telecaller'");
    $stmt->execute([$telecallerId]);
    $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$telecaller) {
        echo "❌ Telecaller not found!\n";
        exit;
    }
    
    echo "✅ Telecaller: {$telecaller['name']}\n\n";
    
    // Get drivers that are not assigned to anyone or assigned to this telecaller
    $stmt = $pdo->prepare("
        SELECT id, name, mobile 
        FROM users 
        WHERE role = 'driver' 
        AND (assigned_to IS NULL OR assigned_to = ?)
        LIMIT " . intval($count) . "
    ");
    $stmt->execute([$telecallerId]);
    $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($drivers) == 0) {
        echo "❌ No available drivers to assign!\n";
        exit;
    }
    
    echo "Found " . count($drivers) . " drivers to assign\n\n";
    
    // Assign drivers to telecaller
    $stmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
    
    $assigned = 0;
    foreach ($drivers as $driver) {
        $stmt->execute([$telecallerId, $driver['id']]);
        $assigned++;
        if ($assigned <= 10) {
            echo "$assigned. Assigned: {$driver['name']} ({$driver['mobile']})\n";
        }
    }
    
    if ($assigned > 10) {
        echo "... and " . ($assigned - 10) . " more drivers\n";
    }
    
    echo "\n✅ Successfully assigned $assigned drivers to telecaller {$telecaller['name']}\n";
    
    // Verify
    $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE assigned_to = ? AND role = 'driver'");
    $stmt->execute([$telecallerId]);
    $total = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    echo "\n📊 Total drivers now assigned to this telecaller: $total\n";
    
} catch(PDOException $e) {
    echo "❌ Database error: " . $e->getMessage();
}
