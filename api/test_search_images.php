<?php
// Test script to check if images are being returned correctly
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get a few users with their images
    $stmt = $pdo->prepare("
        SELECT 
            id,
            unique_id,
            name,
            mobile,
            role,
            images
        FROM users 
        WHERE role IN ('driver', 'transporter')
        LIMIT 10
    ");
    
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $results = [];
    foreach ($users as $user) {
        $profilePicture = null;
        
        if (!empty($user['images'])) {
            $images = json_decode($user['images'], true);
            if (is_array($images) && count($images) > 0) {
                $imagePath = $images[0];
                $profilePicture = 'https://truckmitr.com/public/' . $imagePath;
            } elseif (!is_array($images) && is_string($user['images'])) {
                $profilePicture = 'https://truckmitr.com/public/' . $user['images'];
            }
        }
        
        $results[] = [
            'id' => $user['id'],
            'name' => $user['name'],
            'mobile' => $user['mobile'],
            'role' => $user['role'],
            'images_raw' => $user['images'],
            'images_decoded' => json_decode($user['images'], true),
            'profilePicture' => $profilePicture
        ];
    }
    
    echo json_encode([
        'success' => true,
        'count' => count($results),
        'users' => $results
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
