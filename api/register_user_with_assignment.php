<?php
/**
 * User Registration with Auto Telecaller Assignment
 * This API handles new user registration and automatically assigns a telecaller
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

try {
    // Get next telecaller using round-robin
    $telecallerId = getNextTelecaller($pdo);
    
    // Your existing user registration logic here
    // Add assigned_to field to the INSERT query
    
    // Example:
    $stmt = $pdo->prepare("
        INSERT INTO users (name, mobile, email, role, assigned_to, created_at) 
        VALUES (?, ?, ?, 'driver', ?, NOW())
    ");
    
    $stmt->execute([
        $input['name'] ?? '',
        $input['mobile'] ?? '',
        $input['email'] ?? '',
        $telecallerId
    ]);
    
    $userId = $pdo->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'user_id' => $userId,
        'assigned_telecaller' => $telecallerId,
        'message' => 'User registered and assigned to telecaller'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

/**
 * Get next telecaller ID using round-robin
 */
function getNextTelecaller($pdo) {
    // Get all active telecallers
    $stmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    if (empty($telecallers)) {
        return null; // No telecallers available
    }
    
    // Get count of users assigned to each telecaller
    $stmt = $pdo->query("
        SELECT assigned_to, COUNT(*) as count 
        FROM users 
        WHERE role = 'driver' AND assigned_to IS NOT NULL
        GROUP BY assigned_to
    ");
    $assignments = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
    
    // Find telecaller with least assignments
    $minCount = PHP_INT_MAX;
    $selectedTelecaller = $telecallers[0];
    
    foreach ($telecallers as $telecallerId) {
        $count = $assignments[$telecallerId] ?? 0;
        if ($count < $minCount) {
            $minCount = $count;
            $selectedTelecaller = $telecallerId;
        }
    }
    
    return $selectedTelecaller;
}
