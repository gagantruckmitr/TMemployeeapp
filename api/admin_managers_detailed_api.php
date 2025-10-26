<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            getManagers($conn);
            break;
        case 'POST':
            createManager($conn);
            break;
        case 'PUT':
            updateManager($conn);
            break;
        case 'DELETE':
            deleteManager($conn);
            break;
        default:
            throw new Exception('Method not allowed');
    }
    
    $conn->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

function getManagers($conn) {
    // Get comprehensive manager data
    $query = "SELECT 
        a.id,
        a.name,
        a.email,
        a.mobile as phone,
        a.created_at,
        a.role,
        
        -- Team size (telecallers under this manager)
        COUNT(DISTINCT t.id) as team_size,
        
        -- Team's total calls
        COUNT(DISTINCT cl.id) as team_total_calls,
        
        -- Team's connected calls
        SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as team_connected_calls,
        
        -- Team's calls today
        SUM(CASE WHEN DATE(cl.call_time) = CURDATE() THEN 1 ELSE 0 END) as team_calls_today,
        
        -- Team's calls this week
        SUM(CASE WHEN YEARWEEK(cl.call_time, 1) = YEARWEEK(CURDATE(), 1) THEN 1 ELSE 0 END) as team_calls_this_week,
        
        -- Team's calls this month
        SUM(CASE WHEN YEAR(cl.call_time) = YEAR(CURDATE()) AND MONTH(cl.call_time) = MONTH(CURDATE()) THEN 1 ELSE 0 END) as team_calls_this_month,
        
        -- Team conversion rate
        ROUND(
            SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) * 100.0 / 
            NULLIF(COUNT(DISTINCT cl.id), 0), 
            1
        ) as team_conversion_rate,
        
        -- Active telecallers (called in last 24 hours)
        COUNT(DISTINCT CASE 
            WHEN cl.call_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR) 
            THEN t.id 
        END) as active_telecallers,
        
        -- Last activity time
        MAX(cl.call_time) as last_activity_time
        
    FROM admins a
    LEFT JOIN admins t ON t.role = 'telecaller'
    LEFT JOIN call_logs cl ON t.id = cl.caller_id
    WHERE a.role = 'manager'
    GROUP BY a.id, a.name, a.email, a.mobile, a.created_at, a.role
    ORDER BY team_total_calls DESC";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $managers = [];
    
    while ($row = $result->fetch_assoc()) {
        $teamSize = (int)$row['team_size'];
        $teamTotalCalls = (int)$row['team_total_calls'];
        $teamConnectedCalls = (int)$row['team_connected_calls'];
        
        // Format last activity time
        $lastActivityTime = $row['last_activity_time'];
        if ($lastActivityTime) {
            $timeAgo = time() - strtotime($lastActivityTime);
            if ($timeAgo < 60) {
                $lastActivityFormatted = 'Just now';
            } elseif ($timeAgo < 3600) {
                $lastActivityFormatted = floor($timeAgo / 60) . ' min ago';
            } elseif ($timeAgo < 86400) {
                $lastActivityFormatted = floor($timeAgo / 3600) . ' hours ago';
            } else {
                $lastActivityFormatted = floor($timeAgo / 86400) . ' days ago';
            }
        } else {
            $lastActivityFormatted = 'No activity';
        }
        
        // Determine status based on activity
        $status = 'inactive';
        if ($lastActivityTime) {
            $hoursSinceLastActivity = (time() - strtotime($lastActivityTime)) / 3600;
            if ($hoursSinceLastActivity < 1) {
                $status = 'active';
            } elseif ($hoursSinceLastActivity < 24) {
                $status = 'idle';
            }
        }
        
        // Get team members list
        $teamQuery = "SELECT 
            a.id,
            a.name,
            a.email,
            a.mobile,
            COUNT(cl.id) as total_calls,
            SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls
        FROM admins a
        LEFT JOIN call_logs cl ON a.id = cl.caller_id
        WHERE a.role = 'telecaller'
        GROUP BY a.id
        ORDER BY total_calls DESC";
        
        $teamResult = $conn->query($teamQuery);
        $teamMembers = [];
        
        if ($teamResult) {
            while ($teamRow = $teamResult->fetch_assoc()) {
                $teamMembers[] = [
                    'id' => (int)$teamRow['id'],
                    'name' => $teamRow['name'],
                    'email' => $teamRow['email'],
                    'phone' => $teamRow['mobile'],
                    'total_calls' => (int)$teamRow['total_calls'],
                    'connected_calls' => (int)$teamRow['connected_calls']
                ];
            }
        }
        
        // Get 7-day team performance trend
        $trendQuery = "SELECT 
            DATE(cl.call_time) as date,
            COUNT(*) as calls,
            SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected
        FROM call_logs cl
        JOIN admins t ON cl.caller_id = t.id
        WHERE t.role = 'telecaller'
        AND cl.call_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        GROUP BY DATE(cl.call_time)
        ORDER BY date ASC";
        
        $trendResult = $conn->query($trendQuery);
        $performanceTrend = [];
        
        if ($trendResult) {
            while ($trendRow = $trendResult->fetch_assoc()) {
                $performanceTrend[] = [
                    'date' => date('M d', strtotime($trendRow['date'])),
                    'calls' => (int)$trendRow['calls'],
                    'connected' => (int)$trendRow['connected']
                ];
            }
        }
        
        $managers[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'created_at' => $row['created_at'],
            'status' => $status,
            
            // Team metrics
            'team_size' => $teamSize,
            'active_telecallers' => (int)$row['active_telecallers'],
            'team_total_calls' => $teamTotalCalls,
            'team_connected_calls' => $teamConnectedCalls,
            'team_calls_today' => (int)$row['team_calls_today'],
            'team_calls_this_week' => (int)$row['team_calls_this_week'],
            'team_calls_this_month' => (int)$row['team_calls_this_month'],
            'team_conversion_rate' => (float)($row['team_conversion_rate'] ?: 0),
            
            // Activity
            'last_activity_time' => $lastActivityTime,
            'last_activity_formatted' => $lastActivityFormatted,
            
            // Additional data
            'team_members' => $teamMembers,
            'performance_trend' => $performanceTrend
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $managers,
        'total' => count($managers)
    ]);
}

function createManager($conn) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['name']) || !isset($data['email']) || !isset($data['phone']) || !isset($data['password'])) {
        throw new Exception('Missing required fields');
    }
    
    $name = $conn->real_escape_string($data['name']);
    $email = $conn->real_escape_string($data['email']);
    $phone = $conn->real_escape_string($data['phone']);
    $password = password_hash($data['password'], PASSWORD_DEFAULT);
    
    $query = "INSERT INTO admins (name, email, mobile, password, role, created_at) 
              VALUES ('$name', '$email', '$phone', '$password', 'manager', NOW())";
    
    if ($conn->query($query)) {
        echo json_encode([
            'success' => true,
            'message' => 'Manager created successfully',
            'id' => $conn->insert_id
        ]);
    } else {
        throw new Exception('Failed to create manager: ' . $conn->error);
    }
}

function updateManager($conn) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['id']) || !isset($data['name']) || !isset($data['email']) || !isset($data['phone'])) {
        throw new Exception('Missing required fields');
    }
    
    $id = (int)$data['id'];
    $name = $conn->real_escape_string($data['name']);
    $email = $conn->real_escape_string($data['email']);
    $phone = $conn->real_escape_string($data['phone']);
    
    $query = "UPDATE admins 
              SET name = '$name', email = '$email', mobile = '$phone', updated_at = NOW()
              WHERE id = $id AND role = 'manager'";
    
    if ($conn->query($query)) {
        echo json_encode([
            'success' => true,
            'message' => 'Manager updated successfully'
        ]);
    } else {
        throw new Exception('Failed to update manager: ' . $conn->error);
    }
}

function deleteManager($conn) {
    if (!isset($_GET['id'])) {
        throw new Exception('Manager ID is required');
    }
    
    $id = (int)$_GET['id'];
    
    $query = "DELETE FROM admins WHERE id = $id AND role = 'manager'";
    
    if ($conn->query($query)) {
        echo json_encode([
            'success' => true,
            'message' => 'Manager deleted successfully'
        ]);
    } else {
        throw new Exception('Failed to delete manager: ' . $conn->error);
    }
}
