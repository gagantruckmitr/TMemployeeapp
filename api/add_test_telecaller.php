<?php
/**
 * Add Test Telecaller NUMAN for IVR Testing
 */

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if telecaller already exists
    $stmt = $pdo->prepare("SELECT id FROM admins WHERE mobile = ?");
    $stmt->execute(['6394756798']);
    $existing = $stmt->fetch();
    
    if ($existing) {
        echo "✅ Telecaller NUMAN already exists (ID: {$existing['id']})\n";
        echo "Mobile: 6394756798\n";
        echo "Email: numan@truckmitr.com\n";
        echo "Password: password\n";
    } else {
        // Add telecaller NUMAN
        $hashedPassword = password_hash('password', PASSWORD_BCRYPT);
        
        $sql = "INSERT INTO admins (name, email, mobile, password, role, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, NOW(), NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            'NUMAN',
            'numan@truckmitr.com',
            '6394756798',
            $hashedPassword,
            'telecaller'
        ]);
        
        $id = $pdo->lastInsertId();
        
        echo "✅ Telecaller NUMAN added successfully!\n";
        echo "ID: $id\n";
        echo "Name: NUMAN\n";
        echo "Mobile: 6394756798\n";
        echo "Email: numan@truckmitr.com\n";
        echo "Password: password\n";
        echo "Role: telecaller\n";
    }
    
} catch(PDOException $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>
