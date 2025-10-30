<?php
require_once 'config.php';
require_once 'update_activity_middleware.php';

try {
    // Get total telecallers
    $telecallersQuery = "SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'";
    $result = $conn->query($telecallersQuery);
    $totalTelecallers = $result->fetch_assoc()['count'];
    
    // Get total managers
    $managersQuery = "SELECT COUNT(*) as count FROM admins WHERE role = 'manager'";
    $result = $conn->query($managersQuery);
    $totalManagers = $result->fetch_assoc()['count'];
    
    // Get total drivers/leads
    $driversQuery = "SELECT COUNT(*) as count FROM drivers";
    $result = $conn->query($driversQuery);
    $totalDrivers = $result->fetch_assoc()['count'];
    
    // Get call logs stats
    $callLogsQuery = "SELECT 
        COUNT(*) as total_calls,
        COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected_calls,
        COUNT(CASE WHEN DATE(call_time) = CURDATE() THEN 1 END) as calls_today,
        COUNT(CASE WHEN call_status IN ('in_progress', 'ringing') THEN 1 END) as active_calls
    FROM call_logs";
    $result = $conn->query($callLogsQuery);
    $callStats = $result->fetch_assoc();
    
    // Calculate conversion rate
    $conversionRate = $callStats['total_calls'] > 0 
        ? round(($callStats['connected_calls'] / $callStats['total_calls']) * 100, 1) 
        : 0;
    
    // Get call trends (last 7 days)
    $trendsQuery = "SELECT 
        DATE(call_time) as date,
        COUNT(*) as calls,
        COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected
    FROM call_logs
    WHERE call_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY DATE(call_time)
    ORDER BY date ASC";
    $result = $conn->query($trendsQuery);
    $callTrends = [];
    while ($row = $result->fetch_assoc()) {
        $callTrends[] = [
            'date' => date('M d', strtotime($row['date'])),
            'calls' => (int)$row['calls'],
            'connected' => (int)$row['connected']
        ];
    }
    
    // Get call distribution
    $distributionQuery = "SELECT 
        call_status as name,
        COUNT(*) as value
    FROM call_logs
    WHERE call_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY call_status
    LIMIT 5";
    $result = $conn->query($distributionQuery);
    $callDistribution = [];
    while ($row = $result->fetch_assoc()) {
        $callDistribution[] = [
            'name' => ucfirst(str_replace('_', ' ', $row['name'])),
            'value' => (int)$row['value']
        ];
    }
    
    // Get top performers
    $performersQuery = "SELECT 
        a.name,
        COUNT(cl.id) as calls,
        COUNT(CASE WHEN cl.call_status = 'connected' THEN 1 END) as connected
    FROM admins a
    LEFT JOIN call_logs cl ON a.id = cl.telecaller_id AND DATE(cl.call_time) = CURDATE()
    WHERE a.role = 'telecaller'
    GROUP BY a.id, a.name
    ORDER BY calls DESC
    LIMIT 5";
    $result = $conn->query($performersQuery);
    $topPerformers = [];
    while ($row = $result->fetch_assoc()) {
        $topPerformers[] = [
            'name' => $row['name'],
            'calls' => (int)$row['calls'],
            'connected' => (int)$row['connected']
        ];
    }
    
    // Get recent activity
    $activityQuery = "SELECT 
        a.name as telecaller,
        d.name as driver_name,
        cl.call_status,
        cl.call_time
    FROM call_logs cl
    JOIN admins a ON cl.caller_id = a.id
    LEFT JOIN drivers d ON cl.driver_id = d.id
    ORDER BY cl.call_time DESC
    LIMIT 10";
    $result = $conn->query($activityQuery);
    $recentActivity = [];
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
        
        $recentActivity[] = [
            'telecaller' => $row['telecaller'],
            'action' => 'Called ' . ($row['driver_name'] ?? 'Unknown') . ' - ' . ucfirst($row['call_status']),
            'time' => $timeStr
        ];
    }
    
    sendSuccess([
        'total_telecallers' => (int)$totalTelecallers,
        'total_managers' => (int)$totalManagers,
        'total_drivers' => (int)$totalDrivers,
        'active_calls' => (int)$callStats['active_calls'],
        'calls_today' => (int)$callStats['calls_today'],
        'total_calls' => (int)$callStats['total_calls'],
        'connected_calls' => (int)$callStats['connected_calls'],
        'conversion_rate' => $conversionRate,
        'call_trends' => $callTrends,
        'call_distribution' => $callDistribution,
        'top_performers' => $topPerformers,
        'recent_activity' => $recentActivity
    ]);
    
} catch (Exception $e) {
    sendError('Failed to fetch dashboard stats: ' . $e->getMessage());
}
