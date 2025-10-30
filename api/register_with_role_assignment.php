<?php
/**
 * User Registration with Role-Based Telecaller Assignment
 * Drivers → Telecallers 3 & 4 (round-robin)
 * Transporters → Telecallers 5 & 6 (round-robin)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Use production config if available
if (file_exists(__DIR__ . '/config.php')) {
    require_once __DIR__ . '/config.php';
} else {
    // Fallback to local config
    $host = '127.0.0.1';
    $dbname = 'truckmitr';
    $username = 'truckmitr';
    $password = '825Redp&4';
    
    try {
        $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Database connection failed']);
        exit;
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

try {
    $role = $input['role'] ?? 'driver';
    
    // Get telecaller IDs - FIXED IDs
    if ($role === 'driver') {
        // Driver telecallers: 3 (Pooja), 4 (Tanisha)
        $telecallerId = getNextTelecallerForRole($pdo, 'driver', [3, 4]);
    } elseif ($role === 'transporter') {
        // Transporter telecallers: 6 (Tarun), 7 (Gagan)
        $telecallerId = getNextTelecallerForRole($pdo, 'transporter', [6, 7]);
    } else {
        $telecallerId = null;
    }
    
    // Register user with assigned telecaller
    $stmt = $pdo->prepare("
        INSERT INTO users (name, mobile, email, role, assigned_to, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, NOW(), NOW())
    ");
    
    $stmt->execute([
        $input['name'] ?? '',
        $input['mobile'] ?? '',
        $input['email'] ?? '',
        $role,
        $telecallerId
    ]);
    
    $userId = $pdo->lastInsertId();
    
    // Get telecaller name
    $telecallerName = null;
    if ($telecallerId) {
        $stmt = $pdo->prepare("SELECT name FROM admins WHERE id = ?");
        $stmt->execute([$telecallerId]);
        $telecallerName = $stmt->fetchColumn();
    }
    
    echo json_encode([
        'success' => true,
        'user_id' => $userId,
        'role' => $role,
        'assigned_telecaller_id' => $telecallerId,
        'assigned_telecaller_name' => $telecallerName,
        'message' => 'User registered and assigned to telecaller'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

/**
 * Get transporter telecaller IDs (Tarun & Gagan)
 */
function getTransporterTelecallers($pdo) {
    // Look for telecallers named Tarun or Gagan
    $stmt = $pdo->query("
        SELECT id 
        FROM admins 
        WHERE role = 'telecaller' 
        AND (name LIKE '%Tarun%' OR name LIKE '%Gagan%')
        ORDER BY id ASC
    ");
    $ids = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // If not found, return empty array (will need to run setup script first)
    return !empty($ids) ? $ids : [];
}

/**
 * Get next telecaller for specific role using round-robin
 */
function getNextTelecallerForRole($pdo, $role, $telecallerIds) {
    if (empty($telecallerIds)) {
        return null;
    }
    
    // Get count of users assigned to each telecaller for this role
    $placeholders = implode(',', array_fill(0, count($telecallerIds), '?'));
    
    $stmt = $pdo->prepare("
        SELECT assigned_to, COUNT(*) as count 
        FROM users 
        WHERE role = ? AND assigned_to IN ($placeholders)
        GROUP BY assigned_to
    ");
    
    $params = array_merge([$role], $telecallerIds);
    $stmt->execute($params);
    $assignments = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
    
    // Find telecaller with least assignments
    $minCount = PHP_INT_MAX;
    $selectedTelecaller = $telecallerIds[0];
    
    foreach ($telecallerIds as $telecallerId) {
        $count = $assignments[$telecallerId] ?? 0;
        if ($count < $minCount) {
            $minCount = $count;
            $selectedTelecaller = $telecallerId;
        }
    }
    
    return $selectedTelecaller;
}
