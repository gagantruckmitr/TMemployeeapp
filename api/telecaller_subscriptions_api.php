<?php
/**
 * Telecaller Subscriptions API
 * Track subscriptions based on call_logs.user_id matching with payments.user_id
 * Credits telecaller who made the call that led to subscription
 * Same logic as subscription.php but filtered for specific telecaller
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

try {
    $telecaller_id = $_GET['user_id'] ?? null;
    $period = $_GET['period'] ?? 'all'; // 'today', 'week', 'month', 'all'
    
    if (!$telecaller_id) {
        throw new Exception('User ID is required');
    }
    
    // Build date filter based on period (filter by payment date, not call date)
    $dateFilter = '';
    switch ($period) {
        case 'today':
            $dateFilter = 'AND DATE(p.created_at) = CURDATE()';
            break;
        case 'yesterday':
            $dateFilter = 'AND DATE(p.created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)';
            break;
        case 'week':
            $dateFilter = 'AND p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)';
            break;
        case 'month':
            $dateFilter = 'AND p.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
            break;
    }
    
    // Main query: Get subscriptions where telecaller called driver before they subscribed
    // Use a simple approach with post-processing for call details
    $query = "
        SELECT 
            p.id as payment_id,
            p.user_id as driver_id,
            u.name as driver_name,
            u.mobile as driver_mobile,
            u.unique_id as driver_tmid,
            " . intval($telecaller_id) . " as telecaller_id,
            a.name as telecaller_name,
            p.created_at as payment_created_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            FROM_UNIXTIME(p.end_at) AS payment_end_time,
            p.amount,
            p.payment_id as razorpay_payment_id,
            p.payment_status,
            p.payment_type,
            DATEDIFF(FROM_UNIXTIME(p.end_at), FROM_UNIXTIME(p.start_at)) as subscription_days
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN admins a ON a.id = " . intval($telecaller_id) . "
        WHERE p.payment_status = 'captured'
        AND EXISTS (
            SELECT 1 FROM call_logs cl
            WHERE cl.user_id = p.user_id
            AND cl.caller_id = " . intval($telecaller_id) . "
            AND cl.call_time < p.created_at
        )
        $dateFilter
        ORDER BY p.created_at DESC
    ";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $subscriptions = [];
    while ($row = $result->fetch_assoc()) {
        // Get call details for this payment
        $call_query = "
            SELECT id, call_time, call_status, call_duration,
                   TIMESTAMPDIFF(MINUTE, call_time, '" . $row['payment_created_at'] . "') as minutes_after_call
            FROM call_logs
            WHERE user_id = " . intval($row['driver_id']) . "
            AND caller_id = " . intval($telecaller_id) . "
            AND call_time < '" . $row['payment_created_at'] . "'
            ORDER BY call_time DESC
            LIMIT 1
        ";
        
        $call_result = $conn->query($call_query);
        if ($call_result && $call_result->num_rows > 0) {
            $call_data = $call_result->fetch_assoc();
            $row['call_log_id'] = $call_data['id'];
            $row['call_time'] = $call_data['call_time'];
            $row['call_status'] = $call_data['call_status'];
            $row['call_duration'] = $call_data['call_duration'];
            $row['minutes_after_call'] = $call_data['minutes_after_call'];
        } else {
            // Fallback values if no call found (shouldn't happen due to EXISTS clause)
            $row['call_log_id'] = 0;
            $row['call_time'] = $row['payment_created_at'];
            $row['call_status'] = 'unknown';
            $row['call_duration'] = 0;
            $row['minutes_after_call'] = 0;
        }
        
        // Add plan_id as null since it doesn't exist in payments table
        $row['plan_id'] = null;
        
        $subscriptions[] = $row;
    }
    
    // Get summary statistics for this telecaller
    $summary_query = "
        SELECT 
            COUNT(DISTINCT p.id) as total_subscriptions,
            SUM(p.amount) as total_revenue,
            AVG(p.amount) as avg_subscription_value,
            MIN(p.created_at) as first_subscription_date,
            MAX(p.created_at) as latest_subscription_date
        FROM payments p
        WHERE p.payment_status = 'captured'
        AND EXISTS (
            SELECT 1 FROM call_logs cl
            WHERE cl.user_id = p.user_id
            AND cl.caller_id = " . intval($telecaller_id) . "
            AND cl.call_time < p.created_at
        )
        $dateFilter
    ";
    
    $summary_result = $conn->query($summary_query);
    
    if (!$summary_result) {
        throw new Exception("Summary query failed: " . $conn->error);
    }
    
    $summary = $summary_result->fetch_assoc();
    
    // Get subscription count by date for charts
    $by_date_query = "
        SELECT 
            DATE(p.created_at) as subscription_date,
            COUNT(DISTINCT p.id) as count,
            SUM(p.amount) as daily_revenue
        FROM payments p
        WHERE p.payment_status = 'captured'
        AND EXISTS (
            SELECT 1 FROM call_logs cl
            WHERE cl.user_id = p.user_id
            AND cl.caller_id = " . intval($telecaller_id) . "
            AND cl.call_time < p.created_at
        )
        $dateFilter
        GROUP BY DATE(p.created_at)
        ORDER BY subscription_date DESC
    ";
    
    $by_date_result = $conn->query($by_date_query);
    
    if (!$by_date_result) {
        throw new Exception("By date query failed: " . $conn->error);
    }
    
    $subscriptions_by_date = [];
    while ($row = $by_date_result->fetch_assoc()) {
        $subscriptions_by_date[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_subscriptions' => (int)($summary['total_subscriptions'] ?? 0),
            'total_revenue' => (float)($summary['total_revenue'] ?? 0),
            'avg_subscription_value' => (float)($summary['avg_subscription_value'] ?? 0),
            'subscriptions' => $subscriptions,
            'subscriptions_by_date' => $subscriptions_by_date,
            'period' => $period,
            'summary' => $summary
        ]
    ]);
    
} catch (Exception $e) {
    error_log('Telecaller Subscriptions API Error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
