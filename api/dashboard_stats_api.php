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
    
    $callLogsQuery = "SELECT 
        COUNT(*) as total_calls,
        COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected_calls,
        COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as calls_today,
        0 as active_calls
    FROM call_history";
    $result = $conn->query($callLogsQuery);
    $callStats = $result->fetch_assoc();
    
    // Calculate conversion rate
    $conversionRate = $callStats['total_calls'] > 0 
        ? round(($callStats['connected_calls'] / $callStats['total_calls']) * 100, 1) 
        : 0;
    
    // Get call trends (last 7 days) - using call_history table
    $trendsQuery = "SELECT 
        DATE(created_at) as date,
        COUNT(*) as calls,
        COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected
    FROM call_history
    WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY DATE(created_at)
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
    
    // Get call distribution - using call_history table
    $distributionQuery = "SELECT 
        COALESCE(call_status, 'unknown') as name,
        COUNT(*) as value
    FROM call_history
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY call_status
    ORDER BY value DESC
    LIMIT 5";
    $result = $conn->query($distributionQuery);
    $callDistribution = [];
    while ($row = $result->fetch_assoc()) {
        // Format call_status labels properly
        $statusLabel = $row['name'];
        if ($statusLabel === 'connected') {
            $statusLabel = 'Connected';
        } elseif ($statusLabel === 'not_connected') {
            $statusLabel = 'Not Connected';
        } elseif ($statusLabel === 'callback_later') {
            $statusLabel = 'Call Back';
        } elseif ($statusLabel === 'unknown' || $statusLabel === '' || $statusLabel === null) {
            $statusLabel = 'Unknown';
        } else {
            $statusLabel = ucfirst(str_replace('_', ' ', $statusLabel));
        }
        
        $callDistribution[] = [
            'name' => $statusLabel,
            'value' => (int)$row['value']
        ];
    }
    
    // Get top performers - using call_history table with assigned_to
    $performersQuery = "SELECT 
        a.name,
        COUNT(ch.id) as calls,
        COUNT(CASE WHEN ch.call_status = 'connected' THEN 1 END) as connected
    FROM admins a
    LEFT JOIN call_history ch ON a.id = ch.assigned_to AND DATE(ch.created_at) = CURDATE()
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
    
    // Get recent activity - using call_history table with assigned_to
    $activityQuery = "SELECT 
        a.name as telecaller,
        u.name as driver_name,
        COALESCE(ch.call_status, 'unknown') as call_status,
        ch.created_at as call_time
    FROM call_history ch
    JOIN admins a ON ch.assigned_to = a.id
    LEFT JOIN users u ON ch.user_id = u.id
    ORDER BY ch.created_at DESC
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
        
        // Format call_status labels
        $statusLabel = $row['call_status'];
        if ($statusLabel === 'connected') {
            $statusLabel = 'Connected';
        } elseif ($statusLabel === 'not_connected') {
            $statusLabel = 'Not Connected';
        } elseif ($statusLabel === 'callback_later') {
            $statusLabel = 'Call Back';
        } elseif ($statusLabel === 'unknown' || $statusLabel === '' || $statusLabel === null) {
            $statusLabel = 'Unknown';
        } else {
            $statusLabel = ucfirst(str_replace('_', ' ', $statusLabel ?? ''));
        }
        
        $recentActivity[] = [
            'telecaller' => $row['telecaller'],
            'action' => 'Called ' . ($row['driver_name'] ?? 'Unknown') . ' - ' . $statusLabel,
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
