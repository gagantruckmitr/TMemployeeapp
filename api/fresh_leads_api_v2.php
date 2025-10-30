<?php
// Fresh Leads API V2 - Gets caller_id from auth token instead of parameter
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';
require_once 'update_activity_middleware.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'fresh_leads';

// Get caller_id from Authorization header (JWT token) or session
$callerId = getCallerIdFromAuth($pdo);

if (!$callerId) {
    // Fallback to GET parameter
    $callerId = (int)($_GET['caller_id'] ?? 0);
}

error_log("🔍 API V2: Using caller_id: $callerId");

switch($action) {
    case 'fresh_leads':
        getFreshLeads($pdo, $callerId);
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function getCallerIdFromAuth($pdo) {
    // Try to get from Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;
    
    if ($authHeader && preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = $matches[1];
        
        // Look up user by token
        $stmt = $pdo->prepare("SELECT id FROM admins WHERE auth_token = ? AND role = 'telecaller' LIMIT 1");
        $stmt->execute([$token]);
        $user = $stmt->fetch();
        
        if ($user) {
            return (int)$user['id'];
        }
    }
    
    // Try session
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    if (isset($_SESSION['user_id']) && isset($_SESSION['role']) && $_SESSION['role'] === 'telecaller') {
        return (int)$_SESSION['user_id'];
    }
    
    return null;
}

function getFreshLeads($pdo, $callerId) {
    try {
        $limit = (int)($_GET['limit'] ?? 50);
        
        if (!$callerId) {
            echo json_encode([
                'error' => 'Caller ID not found. Please login again.',
                'caller_id' => $callerId
            ]);
            return;
        }
        
        // Get telecaller info
        $tcStmt = $pdo->prepare("SELECT id, name FROM admins WHERE id = ? AND role = 'telecaller'");
        $tcStmt->execute([$callerId]);
        $telecaller = $tcStmt->fetch();
        
        if (!$telecaller) {
            echo json_encode(['error' => 'Telecaller not found']);
            return;
        }
        
        // Get assigned leads
        $sql = "SELECT 
                    u.id,
                    u.unique_id,
                    u.name,
                    u.mobile,
                    u.email,
                    u.city,
                    u.states,
                    u.status,
                    u.assigned_to,
                    u.Created_at,
                    u.Updated_at
                FROM users u
                WHERE u.role = 'driver'
                AND u.assigned_to = :caller_id
                AND u.id NOT IN (
                    SELECT DISTINCT user_id 
                    FROM call_logs
                    WHERE caller_id = :caller_id
                )
                ORDER BY u.Created_at DESC
                LIMIT :limit";
        
        $stmt = $pdo->prepare($sql);
        $stmt->bindValue(':caller_id', $callerId, PDO::PARAM_INT);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        $users = $stmt->fetchAll();
        
        // Transform to driver format
        $drivers = array_map(function($user) use ($pdo) {
            $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'Driver ' . $user['id'],
                'company' => ($user['city'] ?? 'Unknown') . ' Transport',
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? 'Unknown',
                'state' => $user['states'] ?? 'Unknown',
                'subscriptionStatus' => 'inactive',
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => 'pending',
                'lastFeedback' => null,
                'lastCallTime' => null,
                'remarks' => null,
                'paymentInfo' => null,
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'createdAt' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'updatedAt' => $user['Updated_at'] ?? date('Y-m-d H:i:s'),
                'profile_completion' => '0%'
            ];
        }, $users);
        
        echo json_encode([
            'success' => true,
            'data' => $drivers,
            'count' => count($drivers),
            'caller_id' => $callerId,
            'telecaller_name' => $telecaller['name'],
            'distribution' => 'assigned_to_column',
            'note' => 'Showing leads assigned to ' . $telecaller['name'],
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['error' => 'Failed to fetch fresh leads: ' . $e->getMessage()]);
    }
}
?>
