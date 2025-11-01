<?php
// Fix call_logs table - Add missing remarks column
header('Content-Type: text/html; charset=utf-8');

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>Fixing call_logs table - Adding remarks column</h2>";
    
    // Check if remarks column exists
    $checkSql = "SHOW COLUMNS FROM call_logs LIKE 'remarks'";
    $stmt = $pdo->query($checkSql);
    $remarksExists = $stmt->rowCount() > 0;
    
    if ($remarksExists) {
        echo "<p style='color: green;'>remarks column already exists</p>";
    } else {
        echo "<p style='color: orange;'>remarks column missing, adding it now...</p>";
        
        // Add remarks column after feedback
        $alterSql = "ALTER TABLE call_logs 
                     ADD COLUMN remarks TEXT DEFAULT NULL 
                     AFTER feedback";
        
        $pdo->exec($alterSql);
        echo "<p style='color: green;'>remarks column added successfully</p>";
    }
    
    echo "<h3 style='color: green;'>All fixes applied successfully!</h3>";
    
} catch(PDOException $e) {
    echo "<h3 style='color: red;'>Error: " . htmlspecialchars($e->getMessage()) . "</h3>";
}
?>
