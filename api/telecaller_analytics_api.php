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
    $dateConditionForPayments = getDateConditionForPayments($period);
    
    $overviewStats = getOverviewStats($pdo, $callerId, $dateCondition, $dateConditionForPayments);
    $callTrends = getCallTrends($pdo, $callerId, $period);
    $callDistribution = getCallDistribution($pdo, $callerId, $dateCondition);
    $recentCalls = getRecentCalls($pdo, $callerId, 50, $dateCondition);
    $performanceMetrics = getPerformanceMetrics($pdo, $callerId, $dateCondition);
    $hourlyActivity = getHourlyActivity($pdo, $callerId);
    $interestedCalls = getInterestedCalls($pdo, $callerId, $dateCondition);
    $notInterestedCalls = getNotInterestedCalls($pdo, $callerId, $dateCondition);
    
    echo json_encode([
        'success' => true,
        'data' => [
            'overview' => $overviewStats,
            'call_trends' => $callTrends,
            'call_distribution' => $callDistribution,
            'recent_calls' => $recentCalls,
            'performance_metrics' => $performanceMetrics,
            'hourly_activity' => $hourlyActivity,
            'interested_calls' => $interestedCalls,
            'not_interested_calls' => $notInterestedCalls,
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
        case 'today': return "DATE(created_at) = CURDATE()";
        case 'yesterday': return "DATE(created_at) = SUBDATE(CURDATE(), 1)";
        case 'this_week': return "YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1)";
        case 'this_month': return "MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE())";
        case 'week': return "created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)"; // Last 7 days
        case 'month': return "created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)"; // Last 30 days
        case 'year': return "created_at >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
        case 'all': return "1=1"; // All time data
        default: return "created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    }
}

function getDateConditionForPayments($period) {
    switch($period) {
        case 'today': return "DATE(p.created_at) = CURDATE()";
        case 'yesterday': return "DATE(p.created_at) = SUBDATE(CURDATE(), 1)";
        case 'this_week': return "YEARWEEK(p.created_at, 1) = YEARWEEK(CURDATE(), 1)";
        case 'this_month': return "MONTH(p.created_at) = MONTH(CURDATE()) AND YEAR(p.created_at) = YEAR(CURDATE())";
        case 'week': return "p.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
        case 'month': return "p.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
        case 'year': return "p.created_at >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)";
        case 'all': return "1=1"; // All time data
        default: return "p.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    }
}

function getOverviewStats($pdo, $callerId, $dateCondition, $dateConditionForPayments) {
    // Get stats from call_history table
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks_scheduled,
            SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks,
            SUM(CASE WHEN call_status = 'not_connected' THEN 1 ELSE 0 END) as not_connected_calls,
            SUM(CASE 
                WHEN call_feedback IS NOT NULL AND (
                    LOWER(call_feedback) LIKE '%not interested%' 
                    OR LOWER(call_feedback) LIKE '%not_interested%'
                    OR LOWER(call_feedback) LIKE '%notinterested%'
                )
                THEN 1 ELSE 0 
            END) as not_interested,
            SUM(CASE 
                WHEN call_feedback IS NOT NULL 
                AND call_feedback != ''
                AND (LOWER(call_feedback) LIKE '%agree%' 
                     OR LOWER(call_feedback) LIKE '%demo%' 
                     OR LOWER(call_feedback) LIKE '%subscribe%'
                     OR LOWER(call_feedback) LIKE '%interested%')
                AND LOWER(call_feedback) NOT LIKE '%not%interested%'
                THEN 1 ELSE 0 
            END) as interested_count,
            AVG(CASE WHEN call_status = 'connected' AND call_duration IS NOT NULL THEN CAST(call_duration AS UNSIGNED) ELSE NULL END) as avg_duration
        FROM call_history 
        WHERE assigned_to = ? AND $dateCondition
    ");
    $stmt->execute([$callerId]);
    $stats = $stmt->fetch();
    
    // Get stats from call_logs_match_making table with feedback mapping
    $stmt2 = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE 
                WHEN LOWER(feedback) IN ('interview done', 'interview fixed', 'ready for interview', 
                                         'will confirm later', 'match making done', 'not interested', 'not selected')
                THEN 1 ELSE 0 
            END) as connected_calls,
            SUM(CASE 
                WHEN LOWER(feedback) IN ('busy right now', 'call tomorrow morning', 
                                         'call in evening', 'call after 2 days')
                THEN 1 ELSE 0 
            END) as callbacks_scheduled,
            SUM(CASE 
                WHEN LOWER(feedback) IN ('ringing', 'call busy', 'switched off', 
                                         'not reachable', 'disconnected')
                THEN 1 ELSE 0 
            END) as not_connected_calls,
            SUM(CASE 
                WHEN LOWER(feedback) IN ('not interested', 'not selected')
                THEN 1 ELSE 0 
            END) as not_interested,
            SUM(CASE 
                WHEN feedback IS NOT NULL 
                AND feedback != ''
                AND (LOWER(feedback) LIKE '%interested%'
                     OR LOWER(feedback) LIKE '%interview%'
                     OR LOWER(feedback) LIKE '%ready%')
                AND LOWER(feedback) NOT LIKE '%not%interested%'
                AND LOWER(feedback) NOT LIKE '%not%selected%'
                THEN 1 ELSE 0 
            END) as interested_count
        FROM call_logs_match_making
        WHERE caller_id = ? AND $dateCondition
    ");
    $stmt2->execute([$callerId]);
    $matchMakingStats = $stmt2->fetch();
    
    // Combine stats from both tables
    $totalCalls = (int)$stats['total_calls'] + (int)$matchMakingStats['total_calls'];
    $connectedCalls = (int)$stats['connected_calls'] + (int)$matchMakingStats['connected_calls'];
    $notConnectedCalls = (int)$stats['not_connected_calls'] + (int)$matchMakingStats['not_connected_calls'];
    $callbacksScheduled = (int)$stats['callbacks_scheduled'] + (int)$matchMakingStats['callbacks_scheduled'];
    $callbacks = (int)$stats['callbacks'] + (int)$matchMakingStats['callbacks_scheduled'];
    $notInterested = (int)$stats['not_interested'] + (int)$matchMakingStats['not_interested'];
    $avgDuration = (int)($stats['avg_duration'] ?? 0); // Only from call_logs (match_making doesn't have duration)
    $interestedCount = (int)$stats['interested_count'] + (int)$matchMakingStats['interested_count'];
    
    // Get subscription count - same logic as subscription screen
    // Count payments where user is assigned to this telecaller and payment is captured
    $subscriptionStmt = $pdo->prepare("
        SELECT COUNT(DISTINCT p.id) as subscription_count
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_to = ?
        AND p.payment_status = 'captured'
        AND $dateConditionForPayments
    ");
    $subscriptionStmt->execute([$callerId]);
    $subscriptionData = $subscriptionStmt->fetch();
    $subscriptionCount = (int)($subscriptionData['subscription_count'] ?? 0);
    
    // Debug log
    error_log("Caller $callerId - Subscription Count: $subscriptionCount");
    
    return [
        'total_calls' => $totalCalls,
        'connected_calls' => $connectedCalls,
        'not_connected_calls' => $notConnectedCalls,
        'callbacks_scheduled' => $callbacksScheduled,
        'callbacks' => $callbacks,
        'not_interested' => $notInterested,
        'interested_count' => $interestedCount,
        'subscription_count' => $subscriptionCount,
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
    
    // Get trends from call_history table
    $stmt = $pdo->prepare("
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN (call_feedback LIKE '%interested%' OR call_feedback LIKE '%agree%') AND call_feedback NOT LIKE '%not interested%' AND call_feedback NOT LIKE '%not_interested%' THEN 1 ELSE 0 END) as interested
        FROM call_history 
        WHERE assigned_to = ? AND created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        GROUP BY DATE(created_at)
    ");
    $stmt->execute([$callerId, $days]);
    $callLogsData = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get trends from call_logs_match_making
    $stmt2 = $pdo->prepare("
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as total_calls,
            SUM(CASE 
                WHEN LOWER(feedback) IN ('interview done', 'interview fixed', 'ready for interview', 
                                         'will confirm later', 'match making done', 'not interested', 'not selected')
                THEN 1 ELSE 0 
            END) as connected,
            SUM(CASE 
                WHEN feedback IS NOT NULL 
                AND (LOWER(feedback) LIKE '%interested%' OR LOWER(feedback) LIKE '%interview%')
                AND LOWER(feedback) NOT LIKE '%not%interested%'
                AND LOWER(feedback) NOT LIKE '%not%selected%'
                THEN 1 ELSE 0 
            END) as interested
        FROM call_logs_match_making
        WHERE caller_id = ? AND created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        GROUP BY DATE(created_at)
    ");
    $stmt2->execute([$callerId, $days]);
    $matchMakingData = $stmt2->fetchAll(PDO::FETCH_ASSOC);
    
    // Combine data by date
    $combined = [];
    foreach ($callLogsData as $row) {
        $date = $row['date'];
        $combined[$date] = [
            'date' => $date,
            'total_calls' => (int)$row['total_calls'],
            'connected' => (int)$row['connected'],
            'interested' => (int)$row['interested']
        ];
    }
    
    foreach ($matchMakingData as $row) {
        $date = $row['date'];
        if (isset($combined[$date])) {
            $combined[$date]['total_calls'] += (int)$row['total_calls'];
            $combined[$date]['connected'] += (int)$row['connected'];
            $combined[$date]['interested'] += (int)$row['interested'];
        } else {
            $combined[$date] = [
                'date' => $date,
                'total_calls' => (int)$row['total_calls'],
                'connected' => (int)$row['connected'],
                'interested' => (int)$row['interested']
            ];
        }
    }
    
    // Sort by date and return as indexed array
    ksort($combined);
    return array_values($combined);
}

function getCallDistribution($pdo, $callerId, $dateCondition) {
    // Get distribution from call_history
    $stmt = $pdo->prepare("
        SELECT 
            call_status,
            COUNT(*) as count
        FROM call_history 
        WHERE assigned_to = ? AND $dateCondition
        GROUP BY call_status
    ");
    $stmt->execute([$callerId]);
    $callHistoryData = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get distribution from call_logs_match_making (map feedback to status)
    $stmt2 = $pdo->prepare("
        SELECT 
            CASE 
                WHEN LOWER(feedback) IN ('interview done', 'interview fixed', 'ready for interview', 
                                         'will confirm later', 'match making done', 'not interested', 'not selected')
                THEN 'connected'
                WHEN LOWER(feedback) IN ('busy right now', 'call tomorrow morning', 
                                         'call in evening', 'call after 2 days')
                THEN 'callback_later'
                WHEN LOWER(feedback) IN ('ringing', 'call busy', 'switched off', 
                                         'not reachable', 'disconnected')
                THEN 'not_connected'
                ELSE 'other'
            END as call_status,
            COUNT(*) as count
        FROM call_logs_match_making
        WHERE caller_id = ? AND $dateCondition
        GROUP BY call_status
    ");
    $stmt2->execute([$callerId]);
    $matchMakingData = $stmt2->fetchAll(PDO::FETCH_ASSOC);
    
    // Combine data by status
    $combined = [];
    foreach ($callHistoryData as $row) {
        $status = $row['call_status'] ?? 'unknown';
        $combined[$status] = (int)$row['count'];
    }
    
    foreach ($matchMakingData as $row) {
        $status = $row['call_status'];
        if (isset($combined[$status])) {
            $combined[$status] += (int)$row['count'];
        } else {
            $combined[$status] = (int)$row['count'];
        }
    }
    
    // Calculate total and percentages with proper labels
    $total = array_sum($combined);
    $results = [];
    foreach ($combined as $status => $count) {
        // Format status labels
        $statusLabel = $status;
        if ($status === 'connected') {
            $statusLabel = 'Connected';
        } elseif ($status === 'not_connected') {
            $statusLabel = 'Not Connected';
        } elseif ($status === 'callback_later') {
            $statusLabel = 'Call Back';
        } else {
            $statusLabel = ucfirst(str_replace('_', ' ', $status));
        }
        
        $results[] = [
            'call_status' => $statusLabel,
            'count' => $count,
            'percentage' => $total > 0 ? round(($count * 100.0 / $total), 1) : 0
        ];
    }
    
    // Sort by count descending
    usort($results, function($a, $b) {
        return $b['count'] - $a['count'];
    });
    
    return $results;
}

function getRecentCalls($pdo, $callerId, $limit = 50, $dateCondition = null) {
    // Get complete call history for analytics page
    $limit = (int)$limit;
    
    // Add date condition if provided
    $dateSql = "";
    if ($dateCondition) {
        $dateSql = " AND " . str_replace('created_at', 'ch.created_at', $dateCondition);
    }

    $stmt = $pdo->prepare("
        SELECT 
            ch.*,
            u.name as driver_name,
            u.mobile as driver_mobile,
            ch.created_at as actual_call_time,
            TIMESTAMPDIFF(SECOND, ch.created_at, NOW()) as seconds_ago,
            ch.call_feedback as feedback,
            ch.call_remarks as remarks
        FROM call_history ch
        LEFT JOIN users u ON ch.user_id = u.id
        WHERE ch.assigned_to = ? $dateSql
        ORDER BY ch.created_at DESC
        LIMIT $limit
    ");
    $stmt->execute([$callerId]);
    
    $calls = $stmt->fetchAll();
    
    foreach ($calls as &$call) {
        $duration = isset($call['call_duration']) ? (int)$call['call_duration'] : 0;
        $call['duration_formatted'] = formatDuration($duration);
        
        // Use actual_call_time for accurate time display
        $callTime = $call['actual_call_time'] ?? $call['created_at'];
        $call['time_ago'] = timeAgo($callTime);
        $call['date'] = date('M d, Y', strtotime($callTime));
        $call['time'] = date('h:i A', strtotime($callTime));
        
        // Set default values for missing fields
        $call['driver_name'] = $call['driver_name'] ?? 'Unknown';
        $call['driver_mobile'] = $call['driver_mobile'] ?? 'N/A';
    }
    
    return $calls;
}

function getPerformanceMetrics($pdo, $callerId, $dateCondition) {
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN (call_feedback LIKE '%interested%' OR call_feedback LIKE '%agree%') AND call_feedback NOT LIKE '%not interested%' AND call_feedback NOT LIKE '%not_interested%' THEN 1 ELSE 0 END) as interested,
            SUM(CASE WHEN call_status = 'callback_later' THEN 1 ELSE 0 END) as callbacks,
            AVG(CASE WHEN call_status = 'connected' AND call_duration IS NOT NULL THEN CAST(call_duration AS UNSIGNED) ELSE NULL END) as avg_duration
        FROM call_history 
        WHERE assigned_to = ? AND $dateCondition
    ");
    $stmt->execute([$callerId]);
    $current = $stmt->fetch();
    
    // For previous period, shift the date condition back by the same interval
    $prevDateCondition = str_replace('CURDATE()', 'DATE_SUB(CURDATE(), INTERVAL 7 DAY)', $dateCondition);
    $prevDateCondition = str_replace('DATE_SUB(CURDATE(), INTERVAL 7 DAY)', 'DATE_SUB(CURDATE(), INTERVAL 14 DAY)', $prevDateCondition);
    
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected,
            SUM(CASE WHEN (call_feedback LIKE '%interested%' OR call_feedback LIKE '%agree%') AND call_feedback NOT LIKE '%not interested%' AND call_feedback NOT LIKE '%not_interested%' THEN 1 ELSE 0 END) as interested,
            AVG(CASE WHEN call_status = 'connected' AND call_duration IS NOT NULL THEN CAST(call_duration AS UNSIGNED) ELSE NULL END) as avg_duration
        FROM call_history 
        WHERE assigned_to = ? AND $prevDateCondition
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
            HOUR(created_at) as hour,
            COUNT(*) as calls
        FROM call_history 
        WHERE assigned_to = ? AND DATE(created_at) = CURDATE()
        GROUP BY HOUR(created_at)
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

function getInterestedCalls($pdo, $callerId, $dateCondition) {
    // Add table alias for JOIN queries
    $dateConditionWithAlias = str_replace('created_at', 'ch.created_at', $dateCondition);
    
    $stmt = $pdo->prepare("
        SELECT 
            ch.*,
            u.name as driver_name,
            u.mobile as driver_mobile,
            ch.created_at as actual_call_time,
            ch.call_feedback as feedback,
            ch.call_remarks as remarks
        FROM call_history ch
        LEFT JOIN users u ON ch.user_id = u.id
        WHERE ch.assigned_to = ? 
        AND $dateConditionWithAlias
        AND ch.call_feedback IS NOT NULL
        AND ch.call_feedback != ''
        AND (LOWER(ch.call_feedback) LIKE '%agree%' 
             OR LOWER(ch.call_feedback) LIKE '%demo%' 
             OR LOWER(ch.call_feedback) LIKE '%subscribe%'
             OR LOWER(ch.call_feedback) LIKE '%interested%')
        AND LOWER(ch.call_feedback) NOT LIKE '%not%interested%'
        ORDER BY ch.created_at DESC
    ");
    $stmt->execute([$callerId]);
    
    $calls = $stmt->fetchAll();
    
    foreach ($calls as &$call) {
        $duration = isset($call['call_duration']) ? (int)$call['call_duration'] : 0;
        $call['duration_formatted'] = formatDuration($duration);
        
        $callTime = $call['actual_call_time'] ?? $call['created_at'];
        $call['time_ago'] = timeAgo($callTime);
        $call['date'] = date('M d, Y', strtotime($callTime));
        $call['time'] = date('h:i A', strtotime($callTime));
        
        $call['driver_name'] = $call['driver_name'] ?? 'Unknown';
        $call['driver_mobile'] = $call['driver_mobile'] ?? 'N/A';
    }
    
    return $calls;
}

function getNotInterestedCalls($pdo, $callerId, $dateCondition) {
    // Add table alias for JOIN queries
    $dateConditionWithAlias = str_replace('created_at', 'ch.created_at', $dateCondition);
    
    $stmt = $pdo->prepare("
        SELECT 
            ch.*,
            u.name as driver_name,
            u.mobile as driver_mobile,
            ch.created_at as actual_call_time,
            ch.call_feedback as feedback,
            ch.call_remarks as remarks
        FROM call_history ch
        LEFT JOIN users u ON ch.user_id = u.id
        WHERE ch.assigned_to = ? 
        AND $dateConditionWithAlias
        AND ch.call_feedback IS NOT NULL 
        AND (LOWER(ch.call_feedback) LIKE '%not interested%' 
             OR LOWER(ch.call_feedback) LIKE '%not_interested%'
             OR LOWER(ch.call_feedback) LIKE '%notinterested%')
        ORDER BY ch.created_at DESC
    ");
    $stmt->execute([$callerId]);
    
    $calls = $stmt->fetchAll();
    
    foreach ($calls as &$call) {
        $duration = isset($call['call_duration']) ? (int)$call['call_duration'] : 0;
        $call['duration_formatted'] = formatDuration($duration);
        
        $callTime = $call['actual_call_time'] ?? $call['created_at'];
        $call['time_ago'] = timeAgo($callTime);
        $call['date'] = date('M d, Y', strtotime($callTime));
        $call['time'] = date('h:i A', strtotime($callTime));
        
        $call['driver_name'] = $call['driver_name'] ?? 'Unknown';
        $call['driver_mobile'] = $call['driver_mobile'] ?? 'N/A';
    }
    
    return $calls;
}
?>
