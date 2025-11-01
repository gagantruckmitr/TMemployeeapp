<?php
require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

try {
    // Telecallers to add
    $telecallers = [
        [
            'name' => 'Bhauna',
            'mobile' => '7678361295',
            'password' => 'bhauna@1234#',
            'email' => 'bhauna@gmail.com'
        ],
        [
            'name' => 'Arpita',
            'mobile' => '7678361237',
            'password' => 'arpita@1234#',
            'email' => 'arpita@gmail.com'
        ]
    ];
    
    echo "<h2>Add Telecallers Script</h2>";
    echo "<p>Adding " . count($telecallers) . " telecallers...</p>";
    echo "<hr>";
    
    $sql = "INSERT INTO admins (name, role, mobile, email, password, email_verified_at, created_at, updated_at) 
            VALUES (?, 'telecaller', ?, ?, ?, NOW(), NOW(), NOW())";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Failed to prepare statement: " . $conn->error);
    }
    
    $successCount = 0;
    $errorCount = 0;
    
    foreach ($telecallers as $telecaller) {
        // Hash the password
        $hashed_password = password_hash($telecaller['password'], PASSWORD_BCRYPT);
        
        $stmt->bind_param("ssss", 
            $telecaller['name'], 
            $telecaller['mobile'], 
            $telecaller['email'], 
            $hashed_password
        );
        
        if ($stmt->execute()) {
            $successCount++;
            echo "<div style='background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
            echo "<h3 style='color: #155724; margin: 0 0 10px 0;'>✓ Added: {$telecaller['name']}</h3>";
            echo "<p><strong>Mobile:</strong> {$telecaller['mobile']}</p>";
            echo "<p><strong>Email:</strong> {$telecaller['email']}</p>";
            echo "<p><strong>Password:</strong> {$telecaller['password']}</p>";
            echo "<p><strong>Role:</strong> telecaller</p>";
            echo "</div>";
        } else {
            $errorCount++;
            echo "<div style='background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
            echo "<h3 style='color: #721c24;'>✗ Failed: {$telecaller['name']}</h3>";
            echo "<p>Error: " . htmlspecialchars($stmt->error) . "</p>";
            echo "</div>";
        }
    }
    
    $stmt->close();
    $conn->close();
    
    echo "<hr>";
    echo "<div style='background: #e7f3ff; border: 1px solid #b3d9ff; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
    echo "<h3 style='color: #004085;'>Summary</h3>";
    echo "<p><strong>Successfully Added:</strong> $successCount</p>";
    echo "<p><strong>Failed:</strong> $errorCount</p>";
    echo "</div>";
    
} catch (Exception $e) {
    echo "<div style='background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
    echo "<h3 style='color: #721c24;'>✗ Error</h3>";
    echo "<p>" . htmlspecialchars($e->getMessage()) . "</p>";
    echo "</div>";
}
?>
