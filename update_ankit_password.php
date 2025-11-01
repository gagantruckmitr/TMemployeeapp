<?php
require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

try {
    // New password for Ankit Singh
    $new_password = 'ankit@1234#';
    $username = 'Ankit Singh';
    
    echo "<h2>Password Update Script</h2>";
    echo "<p>Attempting to update password for: <strong>$username</strong></p>";
    
    // Hash the password using bcrypt
    $hashed_password = password_hash($new_password, PASSWORD_BCRYPT);
    echo "<p>✓ Password hashed successfully</p>";
    
    // Update the password in database
    $sql = "UPDATE admins SET password = ? WHERE name = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Failed to prepare statement: " . $conn->error);
    }
    
    $stmt->bind_param("ss", $hashed_password, $username);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            echo "<div style='background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
            echo "<h3 style='color: #155724; margin: 0 0 10px 0;'>✓ Password Updated Successfully!</h3>";
            echo "<p><strong>User:</strong> $username</p>";
            echo "<p><strong>New Password:</strong> $new_password</p>";
            echo "<p style='font-size: 12px; color: #666;'><strong>Hashed:</strong> $hashed_password</p>";
            echo "</div>";
        } else {
            echo "<div style='background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
            echo "<h3 style='color: #856404;'>⚠ No User Found</h3>";
            echo "<p>No user found with name: <strong>$username</strong></p>";
            echo "<p>Please check the exact name in the database.</p>";
            echo "</div>";
        }
    } else {
        throw new Exception("Failed to execute update: " . $stmt->error);
    }
    
    $stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    echo "<div style='background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
    echo "<h3 style='color: #721c24;'>✗ Error</h3>";
    echo "<p>" . htmlspecialchars($e->getMessage()) . "</p>";
    echo "</div>";
}
?>
