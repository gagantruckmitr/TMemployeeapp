<?php
require_once 'config.php';

header('Content-Type: application/json');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Telecallers to add
    $telecallers = [
        [
            'name' => 'Sonam',
            'mobile' => '7678361265',
            'email' => 'sonam@gmail.com',
            'password' => 'sonam@1234#'
        ],
        [
            'name' => 'Raksha',
            'mobile' => '9254972809',
            'email' => 'raksha@gmail.com',
            'password' => 'raksha@1234#'
        ],
        [
            'name' => 'Ankit Singh',
            'mobile' => '9254972815',
            'email' => 'ankitsingh@gmail.com',
            'password' => 'ankitsingh@1234#'
        ]
    ];
    
    $results = [];
    
    foreach ($telecallers as $telecaller) {
        // Check if telecaller already exists
        $checkStmt = $pdo->prepare("SELECT id FROM admins WHERE mobile = ? OR email = ?");
        $checkStmt->execute([$telecaller['mobile'], $telecaller['email']]);
        
        if ($checkStmt->fetch()) {
            $results[] = [
                'name' => $telecaller['name'],
                'status' => 'skipped',
                'message' => 'Already exists'
            ];
            continue;
        }
        
        // Insert telecaller
        $stmt = $pdo->prepare("
            INSERT INTO admins (name, mobile, email, password, role, email_verified_at, created_at, updated_at) 
            VALUES (?, ?, ?, ?, 'telecaller', NOW(), NOW(), NOW())
        ");
        
        $hashedPassword = password_hash($telecaller['password'], PASSWORD_DEFAULT);
        $stmt->execute([
            $telecaller['name'],
            $telecaller['mobile'],
            $telecaller['email'],
            $hashedPassword
        ]);
        
        $telecallerId = $pdo->lastInsertId();
        
        // Initialize telecaller status
        $statusStmt = $pdo->prepare("
            INSERT INTO telecaller_status (telecaller_id, status, last_activity, created_at, updated_at)
            VALUES (?, 'offline', NOW(), NOW(), NOW())
            ON DUPLICATE KEY UPDATE updated_at = NOW()
        ");
        $statusStmt->execute([$telecallerId]);
        
        $results[] = [
            'id' => $telecallerId,
            'name' => $telecaller['name'],
            'mobile' => $telecaller['mobile'],
            'email' => $telecaller['email'],
            'status' => 'success',
            'message' => 'Added successfully'
        ];
    }
    
    echo json_encode([
        'success' => true,
        'results' => $results
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
