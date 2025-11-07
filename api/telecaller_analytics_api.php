<?php
// Telecaller Analytics API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Use config.php for database connection
require_once 'config.php';
require_once 'update_activity_middleware.php';

$callerId = (int)($_GET['caller_id'] ?? $_GET['telecaller_id'] ?? 1);
$period = $_GET['period'] ?? 'week';

try {
    $dateCondition = getDateCondition($period);
    
    $overviewStats = getOverviewStats($pdo, $callerId, $dateCondition);
    $callTrends = getCallTrends($pdo, $callerId, $period);
    $callDistribution = getCallDistribution($pdo, $callerId, $dateCondition);
    $recentCalls = getRecentCalls($pdo, $callerId, 10);
    $performanceMetrics = getPerformanceMetrics($pdo, $callerId, $dateCondition);
    $hourlyActivity = getHourlyActivity($pdo, $callerId);
    
    echo json_encode([
        'success' => true,
        'data' => [
            'overview' => $overviewStats,
            'call_trends' => $callTrends,
            'call_distribution' => $callDistribution,
            'recent_calls' => $recentCalls,
            'performance_metrics' => $performanceMetrics,
            'hourly_activity' => $hourlyActivity,
        ],
        'caller_id' => $callerId,
        'period' => $period,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Failed to fetch analytics: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}

function getDateCondition($period) {
    switch($period) {
        case 'today': return "DATE(call_time) = CURDATE()";
        case 'week': return "call_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
        case 'month': return "call_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
        case 'year': return "call_time >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
        case 'all': return "1=1"; // All time data
        default: return "call_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    }
}

function getOverviewStats($pdo, $callerId, $dateCondition) {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN call_status IN ('callback', 'callback_later') THEN 1 ELSE 0 END) as callbacks,
            SUM(CASE WHEN call_status = 'not_interested' THEN 1 ELSE 0 END) as not_interested,
            SUM(CASE WHEN feedback LIKE '%interested%' OR feedback LIKE '%agree%' THEN 1 ELSE 0 END) as interested_count,
            AVG(CASE WHEN call_status = 'connected' THEN call_duration ELSE NULL END) as avg_duration
        FROM call_logs 
        WHERE caller_id = ? AND $dateCondition
    ");
    $stmt->execute([$callerId]);
    $stats = $stmt->fetch();
    
    $totalCalls = (int)$stats['total_calls'];
    $connectedCalls = (int)$stats['connected_calls'];
    $avgDuration = (int)($stats['avg_duration'] ?? 0);
    $interestedCount = (int)$stats['interested_count'];
    
    return [
        'total_calls' => $totalCalls,
        'connected_calls' => $connectedCalls,
        'callbacks' => (int)$stats['callbacks'],
        'not_interested' => (int)$stats['not_interested'],
        'interested_count' => $interestedCount,
        'success_rate' => $totalCalls > 0 ? round(($connectedCalls / $totalCalls) * 100, 1) : 0,
        'conversion_rate' => $totalCalls > 0 ? round(($interestedCount / $totalCalls) * 100, 1) : 0,
        'avg_duration' => $avgDuration,
        'avg_duration_formatted' => formatDuration($avgDuration),
    ];
}

function getCallTrends($pdo, $callerId, $period) {
    // Use switch instead of match for PHP 7.x compatibility
    switch($period) {
        case 'today':
            $days = 1;
            break;
        case 'week':
            $days = 7;
            break;
        case 'month':
            $days = 30;
            break;
        case 'year':
            $days = 365;
            break;
        case 'all':
            $days = 3650;
            break;
        default:
            $days = 7;
    }
    
    $stmt = $pdo->prepare("
        SELECT 
            DATE(call_time) as date,
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN feedback LIKE '%interested%' OR feedback LIKE '%agree%' THEN 1 ELSE 0 END) as interested
        FROM call_logs 
        WHERE caller_id = ? AND call_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        GROUP BY DATE(call_time)
        ORDER BY date ASC
    ");
    $stmt->execute([$callerId, $days]);
    
    return $stmt->fetchAll();
}

function getCallDistribution($pdo, $callerId, $dateCondition) {
    // First get total count
    $totalStmt = $pdo->prepare("
        SELECT COUNT(*) as total
        FROM call_logs 
        WHERE caller_id = ? AND $dateCondition
    ");
    $totalStmt->execute([$callerId]);
    $total = (int)$totalStmt->fetchColumn();
    
    // Then get distribution
    $stmt = $pdo->prepare("
        SELECT 
            call_status,
            COUNT(*) as count
        FROM call_logs 
        WHERE caller_id = ? AND $dateCondition
        GROUP BY call_status
        ORDER BY count DESC
    ");
    $stmt->execute([$callerId]);
    
    $results = $stmt->fetchAll();
    
    // Calculate percentages in PHP
    foreach ($results as &$row) {
        $row['percentage'] = $total > 0 ? round(($row['count'] * 100.0 / $total), 1) : 0;
    }
    
    return $results;
}

function getRecentCalls($pdo, $callerId, $limit = 50) {
    // Get complete call history for analytics page (increased limit)
    // Note: LIMIT parameter must be an integer, not a bound parameter in some MySQL versions
    $limit = (int)$limit; // Ensure it's an integer
    $stmt = $pdo->prepare("
        SELECT 
            cl.*,
            COALESCE(cl.call_initiated_at, cl.call_time) as actual_call_time,
            TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time), NOW()) as seconds_ago
        FROM call_logs cl
        WHERE cl.caller_id = ?
        ORDER BY COALESCE(cl.call_initiated_at, cl.call_time) DESC
        LIMIT $limit
    ");
    $stmt->execute([$callerId]);
    
    $calls = $stmt->fetchAll();
    
    foreach ($calls as &$call) {
        $duration = isset($call['call_duration']) ? (int)$call['call_duration'] : 0;
        $call['duration_formatted'] = formatDuration($duration);
        
        // Use actual_call_time for accurate time display
        $callTime = $call['actual_call_time'] ?? $call['call_time'];
        $call['time_ago'] = timeAgo($callTime);
        $call['date'] = date('M d, Y', strtotime($callTime));
        $call['time'] = date('h:i A', strtotime($callTime));
        
        // Set default values for missing fields
        $call['driver_name'] = $call['driver_name'] ?? 'Unknown';
        $call['driver_mobile'] = $call['driver_mobile'] ?? $call['user_number'] ?? 'N/A';
    }
    
    return $calls;
}

function getPerformanceMetrics($pdo, $callerId, $dateCondition) {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN feedback LIKE '%interested%' OR feedback LIKE '%agree%' THEN 1 ELSE 0 END) as interested,
            SUM(CASE WHEN call_status IN ('callback', 'callback_later') THEN 1 ELSE 0 END) as callbacks,
            AVG(CASE WHEN call_status = 'connected' THEN call_duration ELSE NULL END) as avg_duration
        FROM call_logs 
        WHERE caller_id = ? AND $dateCondition
    ");
    $stmt->execute([$callerId]);
    $current = $stmt->fetch();
    
    $prevDateCondition = str_replace('CURDATE()', 'DATE_SUB(CURDATE(), INTERVAL 7 DAY)', $dateCondition);
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN feedback LIKE '%interested%' OR feedback LIKE '%agree%' THEN 1 ELSE 0 END) as interested,
            AVG(CASE WHEN call_status = 'connected' THEN call_duration ELSE NULL END) as avg_duration
        FROM call_logs 
        WHERE caller_id = ? AND $prevDateCondition
    ");
    $stmt->execute([$callerId]);
    $previous = $stmt->fetch();
    
    $totalCalls = (int)$current['total_calls'];
    $connected = (int)$current['connected'];
    $interested = (int)$current['interested'];
    
    return [
        'conversion_rate' => [
            'value' => $totalCalls > 0 ? round(($interested / $totalCalls) * 100, 1) : 0,
            'change' => calculateChange($interested, (int)$previous['interested']),
        ],
        'success_rate' => [
            'value' => $totalCalls > 0 ? round(($connected / $totalCalls) * 100, 1) : 0,
            'change' => calculateChange($connected, (int)$previous['connected']),
        ],
        'avg_call_time' => [
            'value' => (int)($current['avg_duration'] ?? 0),
            'formatted' => formatDuration((int)($current['avg_duration'] ?? 0)),
            'change' => calculateChange((int)($current['avg_duration'] ?? 0), (int)($previous['avg_duration'] ?? 0)),
        ],
        'follow_up_rate' => [
            'value' => $totalCalls > 0 ? round(((int)$current['callbacks'] / $totalCalls) * 100, 1) : 0,
            'change' => calculateChange((int)$current['callbacks'], (int)($previous['callbacks'] ?? 0)),
        ],
    ];
}

function getHourlyActivity($pdo, $callerId) {
    $stmt = $pdo->prepare("
        SELECT 
            HOUR(call_time) as hour,
            COUNT(*) as calls
        FROM call_logs 
        WHERE caller_id = ? AND DATE(call_time) = CURDATE()
        GROUP BY HOUR(call_time)
        ORDER BY hour ASC
    ");
    $stmt->execute([$callerId]);
    
    return $stmt->fetchAll();
}

function calculateChange($current, $previous) {
    if ($previous == 0) return $current > 0 ? 100 : 0;
    return round((($current - $previous) / $previous) * 100, 1);
}

function formatDuration($seconds) {
    $minutes = floor($seconds / 60);
    $secs = $seconds % 60;
    return sprintf('%d:%02d', $minutes, $secs);
}

function timeAgo($datetime) {
    $time = strtotime($datetime);
    $diff = time() - $time;
    
    if ($diff < 60) return 'Just now';
    if ($diff < 3600) return floor($diff / 60) . 'm ago';
    if ($diff < 86400) return floor($diff / 3600) . 'h ago';
    return floor($diff / 86400) . 'd ago';
}
?>
