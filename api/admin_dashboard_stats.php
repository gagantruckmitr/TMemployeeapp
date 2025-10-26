<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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
    
    $response = [];
    
    // Get total telecallers
    $result = $conn->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
    if ($result) {
        $response['total_telecallers'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['total_telecallers'] = 0;
    }
    
    // Get total managers
    $result = $conn->query("SELECT COUNT(*) as count FROM admins WHERE role = 'manager'");
    if ($result) {
        $response['total_managers'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['total_managers'] = 0;
    }
    
    // Get total admins
    $result = $conn->query("SELECT COUNT(*) as count FROM admins WHERE role = 'admin'");
    if ($result) {
        $response['total_admins'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['total_admins'] = 0;
    }
    
    // Get total drivers
    $result = $conn->query("SELECT COUNT(*) as count FROM drivers");
    if ($result) {
        $response['total_drivers'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['total_drivers'] = 0;
    }
    
    // Get call stats
    $result = $conn->query("SELECT COUNT(*) as count FROM call_logs");
    if ($result) {
        $response['total_calls'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['total_calls'] = 0;
    }
    
    $result = $conn->query("SELECT COUNT(*) as count FROM call_logs WHERE call_status = 'connected'");
    if ($result) {
        $response['connected_calls'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['connected_calls'] = 0;
    }
    
    $result = $conn->query("SELECT COUNT(*) as count FROM call_logs WHERE DATE(call_time) = CURDATE()");
    if ($result) {
        $response['calls_today'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['calls_today'] = 0;
    }
    
    $result = $conn->query("SELECT COUNT(*) as count FROM call_logs WHERE call_status = 'pending'");
    if ($result) {
        $response['active_calls'] = (int)$result->fetch_assoc()['count'];
    } else {
        $response['active_calls'] = 0;
    }
    
    $response['conversion_rate'] = $response['total_calls'] > 0 
        ? round(($response['connected_calls'] / $response['total_calls']) * 100, 1) 
        : 0;
    
    // Get call trends - simple version
    $response['call_trends'] = [];
    for ($i = 6; $i >= 0; $i--) {
        $date = date('Y-m-d', strtotime("-$i days"));
        $result = $conn->query("SELECT COUNT(*) as calls FROM call_logs WHERE DATE(call_time) = '$date'");
        $calls = 0;
        if ($result) {
            $row = $result->fetch_assoc();
            $calls = (int)$row['calls'];
        }
        
        $result = $conn->query("SELECT COUNT(*) as connected FROM call_logs WHERE DATE(call_time) = '$date' AND call_status = 'connected'");
        $connected = 0;
        if ($result) {
            $row = $result->fetch_assoc();
            $connected = (int)$row['connected'];
        }
        
        $response['call_trends'][] = [
            'date' => date('M d', strtotime($date)),
            'calls' => $calls,
            'connected' => $connected
        ];
    }
    
    // Get call distribution
    $response['call_distribution'] = [];
    $result = $conn->query("SELECT call_status as name, COUNT(*) as value FROM call_logs GROUP BY call_status");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $response['call_distribution'][] = [
                'name' => ucfirst(str_replace('_', ' ', $row['name'])),
                'value' => (int)$row['value']
            ];
        }
    }
    
    // Get top performers
    $response['top_performers'] = [];
    $result = $conn->query("SELECT 
        a.name,
        COUNT(cl.id) as calls,
        SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected
    FROM admins a
    LEFT JOIN call_logs cl ON a.id = cl.caller_id
    WHERE a.role = 'telecaller'
    GROUP BY a.id, a.name
    ORDER BY calls DESC
    LIMIT 5");
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $response['top_performers'][] = [
                'name' => $row['name'],
                'calls' => (int)$row['calls'],
                'connected' => (int)$row['connected']
            ];
        }
    }
    
    // Get recent activity
    $response['recent_activity'] = [];
    $result = $conn->query("SELECT 
        a.name as telecaller,
        cl.driver_name,
        cl.call_status,
        cl.call_time
    FROM call_logs cl
    JOIN admins a ON cl.caller_id = a.id
    ORDER BY cl.call_time DESC
    LIMIT 10");
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $timeAgo = time() - strtotime($row['call_time']);
            if ($timeAgo < 60) {
                $timeStr = 'Just now';
            } elseif ($timeAgo < 3600) {
                $timeStr = floor($timeAgo / 60) . ' min ago';
            } elseif ($timeAgo < 86400) {
                $timeStr = floor($timeAgo / 3600) . ' hours ago';
            } else {
                $timeStr = date('M d, H:i', strtotime($row['call_time']));
            }
            
            $response['recent_activity'][] = [
                'telecaller' => $row['telecaller'],
                'action' => 'Called ' . ($row['driver_name'] ?: 'Unknown') . ' - ' . ucfirst($row['call_status']),
                'time' => $timeStr
            ];
        }
    }
    
    // Get telecallers list
    $response['telecallers_list'] = [];
    $result = $conn->query("SELECT 
        a.id,
        a.name,
        a.email,
        a.mobile,
        a.created_at,
        COUNT(cl.id) as total_calls,
        SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls
    FROM admins a
    LEFT JOIN call_logs cl ON a.id = cl.caller_id
    WHERE a.role = 'telecaller'
    GROUP BY a.id
    ORDER BY total_calls DESC");
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $response['telecallers_list'][] = $row;
        }
    }
    
    // Get managers list
    $response['managers_list'] = [];
    $result = $conn->query("SELECT id, name, email, mobile, created_at FROM admins WHERE role = 'manager' ORDER BY created_at DESC");
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $response['managers_list'][] = $row;
        }
    }
    
    echo json_encode([
        'success' => true,
        'data' => $response
    ]);
    
    $conn->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'line' => $e->getLine()
    ]);
}
