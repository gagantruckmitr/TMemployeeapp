<?php
// Admin Dashboard Stats API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

try {
    
    $response = [];
    
    // Get total telecallers
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
    $stmt->execute();
    $response['total_telecallers'] = (int)$stmt->fetchColumn();
    
    // Get total managers
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM admins WHERE role = 'manager'");
    $stmt->execute();
    $response['total_managers'] = (int)$stmt->fetchColumn();
    
    // Get total admins
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM admins WHERE role = 'admin'");
    $stmt->execute();
    $response['total_admins'] = (int)$stmt->fetchColumn();
    
    // Get total drivers - check if users table exists, fallback to drivers table
    try {
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM users WHERE role IN ('driver', 'transporter')");
        $stmt->execute();
        $response['total_drivers'] = (int)$stmt->fetchColumn();
    } catch (Exception $e) {
        // Fallback to drivers table if users table doesn't exist
        try {
            $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM drivers");
            $stmt->execute();
            $response['total_drivers'] = (int)$stmt->fetchColumn();
        } catch (Exception $e2) {
            $response['total_drivers'] = 0;
        }
    }
    
    // Get call stats
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs");
    $stmt->execute();
    $response['total_calls'] = (int)$stmt->fetchColumn();
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE call_status = 'connected'");
    $stmt->execute();
    $response['connected_calls'] = (int)$stmt->fetchColumn();
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE DATE(call_time) = CURDATE()");
    $stmt->execute();
    $response['calls_today'] = (int)$stmt->fetchColumn();
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE call_status = 'pending'");
    $stmt->execute();
    $response['active_calls'] = (int)$stmt->fetchColumn();
    
    $response['conversion_rate'] = $response['total_calls'] > 0 
        ? round(($response['connected_calls'] / $response['total_calls']) * 100, 1) 
        : 0;
    
    // Get call trends - simple version
    $response['call_trends'] = [];
    for ($i = 6; $i >= 0; $i--) {
        $date = date('Y-m-d', strtotime("-$i days"));
        
        $stmt = $pdo->prepare("SELECT COUNT(*) as calls FROM call_logs WHERE DATE(call_time) = ?");
        $stmt->execute([$date]);
        $calls = (int)$stmt->fetchColumn();
        
        $stmt = $pdo->prepare("SELECT COUNT(*) as connected FROM call_logs WHERE DATE(call_time) = ? AND call_status = 'connected'");
        $stmt->execute([$date]);
        $connected = (int)$stmt->fetchColumn();
        
        $response['call_trends'][] = [
            'date' => date('M d', strtotime($date)),
            'calls' => $calls,
            'connected' => $connected
        ];
    }
    
    // Get call distribution
    $response['call_distribution'] = [];
    $stmt = $pdo->prepare("SELECT call_status as name, COUNT(*) as value FROM call_logs GROUP BY call_status");
    $stmt->execute();
    $results = $stmt->fetchAll();
    
    foreach ($results as $row) {
        $response['call_distribution'][] = [
            'name' => ucfirst(str_replace('_', ' ', $row['name'])),
            'value' => (int)$row['value']
        ];
    }
    
    // Get top performers
    $response['top_performers'] = [];
    $stmt = $pdo->prepare("SELECT 
        a.name,
        COUNT(cl.id) as calls,
        SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected
    FROM admins a
    LEFT JOIN call_logs cl ON a.id = cl.caller_id
    WHERE a.role = 'telecaller'
    GROUP BY a.id, a.name
    ORDER BY calls DESC
    LIMIT 5");
    
    $stmt->execute();
    $results = $stmt->fetchAll();
    
    foreach ($results as $row) {
        $response['top_performers'][] = [
            'name' => $row['name'],
            'calls' => (int)$row['calls'],
            'connected' => (int)$row['connected']
        ];
    }
    
    // Get recent activity
    $response['recent_activity'] = [];
    $stmt = $pdo->prepare("SELECT 
        a.name as telecaller,
        COALESCE(cl.driver_name, cl.user_number, 'Unknown') as contact_name,
        cl.call_status,
        cl.call_time
    FROM call_logs cl
    JOIN admins a ON cl.caller_id = a.id
    ORDER BY cl.call_time DESC
    LIMIT 10");
    
    $stmt->execute();
    $results = $stmt->fetchAll();
    
    foreach ($results as $row) {
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
            'action' => 'Called ' . $row['contact_name'] . ' - ' . ucfirst(str_replace('_', ' ', $row['call_status'])),
            'time' => $timeStr
        ];
    }
    
    // Get telecallers list
    $response['telecallers_list'] = [];
    $stmt = $pdo->prepare("SELECT 
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
    
    $stmt->execute();
    $response['telecallers_list'] = $stmt->fetchAll();
    
    // Get managers list
    $response['managers_list'] = [];
    $stmt = $pdo->prepare("SELECT id, name, email, mobile, created_at FROM admins WHERE role = 'manager' ORDER BY created_at DESC");
    $stmt->execute();
    $response['managers_list'] = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'data' => $response
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'line' => $e->getLine()
    ]);
}
