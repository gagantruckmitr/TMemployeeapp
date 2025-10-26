<?php
/**
 * Create Admin User for Admin Panel
 * Run this file once to create the admin account
 */

require_once 'config.php';

// Admin credentials
$username = 'admin';
$password = 'admin123';
$name = 'Administrator';
$email = 'admin@truckmitr.com';
$phone = '9999999999';

// Hash password
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Check if admin already exists
$checkQuery = "SELECT id FROM users WHERE email = ? OR username = ?";
$stmt = $conn->prepare($checkQuery);
$stmt->bind_param('ss', $email, $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Admin user already exists!',
        'credentials' => [
            'username' => $username,
            'password' => 'admin123'
        ]
    ]);
    exit;
}

// Check if username column exists, if not add it
$checkColumn = "SHOW COLUMNS FROM users LIKE 'username'";
$columnResult = $conn->query($checkColumn);

if ($columnResult->num_rows == 0) {
    // Add username column
    $alterQuery = "ALTER TABLE users ADD COLUMN username VARCHAR(100) UNIQUE AFTER email";
    $conn->query($alterQuery);
}

// Insert admin user
$insertQuery = "INSERT INTO users (name, email, username, phone, password, role, status, created_at) 
                VALUES (?, ?, ?, ?, ?, 'admin', 'active', NOW())";

$stmt = $conn->prepare($insertQuery);
$stmt->bind_param('sssss', $name, $email, $username, $phone, $hashedPassword);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Admin user created successfully!',
        'credentials' => [
            'username' => $username,
            'password' => 'admin123',
            'email' => $email
        ],
        'instructions' => [
            '1. Go to http://localhost:5173',
            '2. Login with username: admin',
            '3. Password: admin123',
            '4. Change password after first login'
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create admin user: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
