<?php
require_once 'config.php';

// Set new password for user ID 3 (Pooja Pal)
$newPassword = 'pooja123';
$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

$query = "UPDATE admins SET password = '$hashedPassword' WHERE id = 3";

if ($conn->query($query)) {
    echo "Password updated successfully!\n\n";
    echo "Login credentials:\n";
    echo "Mobile: 7678361210\n";
    echo "Password: pooja123\n";
} else {
    echo "Error: " . $conn->error;
}
?>
