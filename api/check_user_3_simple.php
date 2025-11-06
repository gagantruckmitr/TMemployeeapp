<?php
require_once 'config.php';
header('Content-Type: text/plain');

$result = $conn->query("SELECT * FROM admins WHERE id = 3");
if ($result) {
    $user = $result->fetch_assoc();
    print_r($user);
} else {
    echo "Error: " . $conn->error;
}
?>
