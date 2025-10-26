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
    
    // Get comprehensive telecaller data
    $query = "SELECT 
        a.id,
        a.name,
        a.email,
        a.mobile as phone,
        a.created_at,
        a.role,
        
        -- Total calls
        COUNT(DISTINCT cl.id) as total_calls,
        
        -- Connected calls
        SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
        
        -- Not answered calls (using not_reachable as equivalent)
        SUM(CASE WHEN cl.call_status IN ('not_reachable', 'failed', 'cancelled') THEN 1 ELSE 0 END) as not_answered_calls,
        
        -- Pending calls
        SUM(CASE WHEN cl.call_status = 'pending' THEN 1 ELSE 0 END) as pending_calls,
        
        -- Callback calls
        SUM(CASE WHEN cl.call_status IN ('callback', 'callback_later') THEN 1 ELSE 0 END) as callback_calls,
        
        -- Not interested calls
        SUM(CASE WHEN cl.call_status = 'not_interested' THEN 1 ELSE 0 END) as not_interested_calls,
        
        -- Calls today
        SUM(CASE WHEN DATE(cl.call_time) = CURDATE() THEN 1 ELSE 0 END) as calls_today,
        
        -- Calls this week
        SUM(CASE WHEN YEARWEEK(cl.call_time, 1) = YEARWEEK(CURDATE(), 1) THEN 1 ELSE 0 END) as calls_this_week,
        
        -- Calls this month
        SUM(CASE WHEN YEAR(cl.call_time) = YEAR(CURDATE()) AND MONTH(cl.call_time) = MONTH(CURDATE()) THEN 1 ELSE 0 END) as calls_this_month,
        
        -- Total unique drivers contacted
        COUNT(DISTINCT cl.driver_id) as total_assigned_leads,
        
        -- Contacted leads (drivers with at least one call)
        COUNT(DISTINCT CASE WHEN cl.driver_id IS NOT NULL THEN cl.driver_id END) as contacted_leads,
        
        -- Average call duration (if available)
        AVG(CASE WHEN cl.call_duration > 0 THEN cl.call_duration ELSE NULL END) as avg_call_duration,
        
        -- Total call duration
        SUM(CASE WHEN cl.call_duration > 0 THEN cl.call_duration ELSE 0 END) as total_call_duration,
        
        -- Last call time
        MAX(cl.call_time) as last_call_time,
        
        -- Conversion rate
        ROUND(
            SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) * 100.0 / 
            NULLIF(COUNT(DISTINCT cl.id), 0), 
            1
        ) as conversion_rate,
        
        -- Contact rate (unique drivers contacted)
        ROUND(
            COUNT(DISTINCT CASE WHEN cl.driver_id IS NOT NULL THEN cl.driver_id END) * 100.0 / 
            NULLIF(COUNT(DISTINCT cl.driver_id), 0), 
            1
        ) as contact_rate
        
    FROM admins a
    LEFT JOIN call_logs cl ON a.id = cl.caller_id
    WHERE a.role = 'telecaller'
    GROUP BY a.id, a.name, a.email, a.mobile, a.created_at, a.role
    ORDER BY total_calls DESC";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $telecallers = [];
    
    while ($row = $result->fetch_assoc()) {
        // Calculate additional metrics
        $totalCalls = (int)$row['total_calls'];
        $connectedCalls = (int)$row['connected_calls'];
        $assignedLeads = (int)$row['total_assigned_leads'];
        $contactedLeads = (int)$row['contacted_leads'];
        
        // Format last call time
        $lastCallTime = $row['last_call_time'];
        if ($lastCallTime) {
            $timeAgo = time() - strtotime($lastCallTime);
            if ($timeAgo < 60) {
                $lastCallFormatted = 'Just now';
            } elseif ($timeAgo < 3600) {
                $lastCallFormatted = floor($timeAgo / 60) . ' min ago';
            } elseif ($timeAgo < 86400) {
                $lastCallFormatted = floor($timeAgo / 3600) . ' hours ago';
            } else {
                $lastCallFormatted = floor($timeAgo / 86400) . ' days ago';
            }
        } else {
            $lastCallFormatted = 'Never';
        }
        
        // Format average call duration
        $avgDuration = $row['avg_call_duration'];
        if ($avgDuration) {
            $avgDurationFormatted = gmdate("i:s", (int)$avgDuration);
        } else {
            $avgDurationFormatted = '00:00';
        }
        
        // Format total call duration
        $totalDuration = (int)$row['total_call_duration'];
        $hours = floor($totalDuration / 3600);
        $minutes = floor(($totalDuration % 3600) / 60);
        $totalDurationFormatted = sprintf("%02d:%02d", $hours, $minutes);
        
        // Determine status based on activity
        $status = 'inactive';
        if ($lastCallTime) {
            $hoursSinceLastCall = (time() - strtotime($lastCallTime)) / 3600;
            if ($hoursSinceLastCall < 1) {
                $status = 'active';
            } elseif ($hoursSinceLastCall < 24) {
                $status = 'idle';
            }
        }
        
        // Get last 7 days call trend
        $trendQuery = "SELECT 
            DATE(call_time) as date,
            COUNT(*) as calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected
        FROM call_logs
        WHERE caller_id = {$row['id']}
        AND call_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        GROUP BY DATE(call_time)
        ORDER BY date ASC";
        
        $trendResult = $conn->query($trendQuery);
        $callTrend = [];
        
        if ($trendResult) {
            while ($trendRow = $trendResult->fetch_assoc()) {
                $callTrend[] = [
                    'date' => date('M d', strtotime($trendRow['date'])),
                    'calls' => (int)$trendRow['calls'],
                    'connected' => (int)$trendRow['connected']
                ];
            }
        }
        
        $telecallers[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'created_at' => $row['created_at'],
            'status' => $status,
            
            // Call metrics
            'total_calls' => $totalCalls,
            'connected_calls' => $connectedCalls,
            'not_answered_calls' => (int)$row['not_answered_calls'],
            'pending_calls' => (int)$row['pending_calls'],
            'callback_calls' => (int)$row['callback_calls'],
            'not_interested_calls' => (int)$row['not_interested_calls'],
            'calls_today' => (int)$row['calls_today'],
            'calls_this_week' => (int)$row['calls_this_week'],
            'calls_this_month' => (int)$row['calls_this_month'],
            
            // Lead metrics
            'total_assigned_leads' => $assignedLeads,
            'contacted_leads' => $contactedLeads,
            'uncontacted_leads' => max(0, $assignedLeads - $contactedLeads),
            
            // Duration metrics
            'avg_call_duration' => $avgDurationFormatted,
            'total_call_duration' => $totalDurationFormatted,
            'total_call_duration_seconds' => $totalDuration,
            
            // Rates
            'conversion_rate' => (float)($row['conversion_rate'] ?: 0),
            'contact_rate' => (float)($row['contact_rate'] ?: 100),
            
            // Activity
            'last_call_time' => $lastCallTime,
            'last_call_formatted' => $lastCallFormatted,
            
            // Trend data
            'call_trend' => $callTrend
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $telecallers,
        'total' => count($telecallers)
    ]);
    
    $conn->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
