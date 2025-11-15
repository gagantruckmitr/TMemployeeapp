<?php
/**
 * Debug Click2Call API
 */

error_reporting(E_ALL);
ini_set('display_errors', '1');

header('Content-Type: application/json');

echo json_encode([
    'test' => 'Debug script working',
    'php_version' => phpversion(),
    'time' => date('Y-m-d H:i:s')
]);

// Test database
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    echo "\nDatabase: Connected";
} catch(PDOException $e) {
    echo "\nDatabase Error: " . $e->getMessage();
}

// Test telecaller query
$callerId = 3;
$stmt = $pdo->prepare("SELECT mobile, name, role FROM admins WHERE id = ? AND role = 'telecaller'");
$stmt->execute([$callerId]);
$telecaller = $stmt->fetch();

echo "\nTelecaller Query Result: " . json_encode($telecaller);

// Test driver query
$driverMobile = '8800549949';
$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ? AND role IN ('driver', 'transporter')");
$stmt->execute([$driverMobile]);
$driver = $stmt->fetch();

echo "\nDriver Query Result: " . json_encode($driver);
?>
