<?php
// Authentication API for TruckMitr
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'login';

switch($action) {
    case 'login':
        handleLogin($pdo);
        break;
    case 'profile':
        getProfile($pdo);
        break;
    case 'update_profile':
        updateProfile($pdo);
        break;
    case 'logout':
        handleLogout();
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function handleLogin($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $mobile = $input['mobile'] ?? '';
    $username = $input['username'] ?? '';
    $password = $input['password'] ?? '';
    $role = $input['role'] ?? '';
    
    if ((empty($mobile) && empty($username)) || empty($password)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Username/mobile and password required'
        ]);
        return;
    }
    
    try {
        // Try users table first (for admin panel)
        if (!empty($username) || $role === 'admin') {
            $identifier = !empty($username) ? $username : $mobile;
            $stmt = $pdo->prepare("SELECT * FROM users WHERE (username = ? OR email = ? OR phone = ?) LIMIT 1");
            $stmt->execute([$identifier, $identifier, $identifier]);
            $user = $stmt->fetch();
            
            if ($user && password_verify($password, $user['password'])) {
                unset($user['password']);
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Login successful',
                    'data' => [
                        'id' => (int)$user['id'],
                        'role' => $user['role'],
                        'name' => $user['name'],
                        'email' => $user['email'],
                        'phone' => $user['phone'],
                        'username' => $user['username'] ?? $user['email']
                    ]
                ]);
                return;
            }
        }
        
        // Try admins table (for mobile app)
        if (!empty($mobile)) {
            $stmt = $pdo->prepare("SELECT * FROM admins WHERE mobile = ?");
            $stmt->execute([$mobile]);
            $user = $stmt->fetch();
            
            if ($user && password_verify($password, $user['password'])) {
                unset($user['password']);
                unset($user['remember_token']);
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Login successful',
                    'user' => [
                        'id' => (string)$user['id'],
                        'role' => $user['role'],
                        'name' => $user['name'],
                        'mobile' => $user['mobile'],
                        'email' => $user['email'],
                        'createdAt' => $user['created_at'],
                        'updatedAt' => $user['updated_at']
                    ],
                    'token' => generateToken($user['id'])
                ]);
                return;
            }
        }
        
        // If not found or password incorrect
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid credentials'
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Login failed: ' . $e->getMessage()
        ]);
    }
}

function getProfile($pdo) {
    $userId = $_GET['user_id'] ?? '';
    
    if (empty($userId)) {
        http_response_code(400);
        echo json_encode(['error' => 'User ID required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("SELECT * FROM admins WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
            return;
        }
        
        // Remove sensitive data
        unset($user['password']);
        unset($user['remember_token']);
        
        // Get user statistics
        $stats = getUserStats($pdo, $userId, $user['role']);
        
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => (string)$user['id'],
                'role' => $user['role'],
                'name' => $user['name'],
                'mobile' => $user['mobile'],
                'email' => $user['email'],
                'createdAt' => $user['created_at'],
                'updatedAt' => $user['updated_at']
            ],
            'stats' => $stats
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch profile: ' . $e->getMessage()]);
    }
}

function updateProfile($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $userId = $input['user_id'] ?? '';
    $name = $input['name'] ?? '';
    $email = $input['email'] ?? '';
    $mobile = $input['mobile'] ?? '';
    
    if (empty($userId)) {
        http_response_code(400);
        echo json_encode(['error' => 'User ID required']);
        return;
    }
    
    try {
        $updates = [];
        $params = [];
        
        if (!empty($name)) {
            $updates[] = "name = ?";
            $params[] = $name;
        }
        if (!empty($email)) {
            $updates[] = "email = ?";
            $params[] = $email;
        }
        if (!empty($mobile)) {
            $updates[] = "mobile = ?";
            $params[] = $mobile;
        }
        
        if (empty($updates)) {
            echo json_encode(['error' => 'No fields to update']);
            return;
        }
        
        $params[] = $userId;
        $sql = "UPDATE admins SET " . implode(', ', $updates) . " WHERE id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        
        echo json_encode([
            'success' => true,
            'message' => 'Profile updated successfully'
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update profile: ' . $e->getMessage()]);
    }
}

function handleLogout() {
    echo json_encode([
        'success' => true,
        'message' => 'Logged out successfully'
    ]);
}

function getUserStats($pdo, $userId, $role) {
    $stats = [
        'totalCalls' => 0,
        'connectedCalls' => 0,
        'pendingCalls' => 0,
        'callbacksScheduled' => 0
    ];
    
    try {
        // Check if call_logs table exists
        $stmt = $pdo->query("SHOW TABLES LIKE 'call_logs'");
        if ($stmt->rowCount() > 0) {
            // Check which column exists (telecaller_id or caller_id)
            $stmt = $pdo->query("DESCRIBE call_logs");
            $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
            $hasTelecallerId = in_array('telecaller_id', $columns);
            $hasCallerId = in_array('caller_id', $columns);
            
            // Determine which column to use
            $idColumn = $hasTelecallerId ? 'telecaller_id' : ($hasCallerId ? 'caller_id' : null);
            
            if ($idColumn) {
                // Total calls made by this user
                $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE $idColumn = ?");
                $stmt->execute([$userId]);
                $stats['totalCalls'] = (int)$stmt->fetch()['count'];
                
                // Connected calls
                $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE $idColumn = ? AND call_status = 'connected'");
                $stmt->execute([$userId]);
                $stats['connectedCalls'] = (int)$stmt->fetch()['count'];
                
                // Pending calls = Assigned leads - Already called users
                // Get total assigned leads
                $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM users WHERE assigned_to = ? AND role IN ('driver', 'transporter')");
                $stmt->execute([$userId]);
                $totalAssigned = (int)$stmt->fetch()['count'];
                
                // Get unique users already called
                $stmt = $pdo->prepare("SELECT COUNT(DISTINCT user_id) as count FROM call_logs WHERE $idColumn = ? AND user_id IS NOT NULL");
                $stmt->execute([$userId]);
                $calledUsers = (int)$stmt->fetch()['count'];
                
                // Calculate pending
                $stats['pendingCalls'] = max(0, $totalAssigned - $calledUsers);
                
                // Callbacks scheduled
                $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE $idColumn = ? AND (call_status = 'callback' OR call_status = 'callback_later')");
                $stmt->execute([$userId]);
                $stats['callbacksScheduled'] = (int)$stmt->fetch()['count'];
            }
        }
    } catch(Exception $e) {
        // Return default stats if error
        error_log("Error getting user stats: " . $e->getMessage());
    }
    
    return $stats;
}

function generateToken($userId) {
    // Simple token generation (in production, use JWT or similar)
    return base64_encode($userId . ':' . time() . ':' . bin2hex(random_bytes(16)));
}

// Show documentation if accessed directly
if (empty($_GET['action'])) {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>TruckMitr Auth API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
            .endpoint { margin: 15px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #28a745; }
            h1 { color: #333; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🔐 TruckMitr Authentication API</h1>
            
            <div class="endpoint">
                <strong>Login:</strong><br>
                POST /auth_api.php?action=login<br>
                Body: {"mobile":"8888888888","password":"password"}
            </div>
            
            <div class="endpoint">
                <strong>Get Profile:</strong><br>
                GET /auth_api.php?action=profile&user_id=1
            </div>
            
            <div class="endpoint">
                <strong>Update Profile:</strong><br>
                POST /auth_api.php?action=update_profile<br>
                Body: {"user_id":"1","name":"New Name","email":"new@email.com"}
            </div>
            
            <h2>Test Credentials:</h2>
            <ul>
                <li>Mobile: 8888888888 (Telecaller - Puja)</li>
                <li>Mobile: 7777777777 (Telecaller - Tanisha)</li>
                <li>Mobile: 8800549949 (Admin - Deepak Arora)</li>
            </ul>
        </div>
    </body>
    </html>
    <?php
}
?>