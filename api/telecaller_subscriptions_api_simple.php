<?php
/**
 * Telecaller Subscriptions API - Simplified Version
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

try {
    $telecaller_id = intval($_GET['user_id'] ?? 0);
    $period = $_GET['period'] ?? 'all';
    
    if (!$telecaller_id) {
        throw new Exception('User ID is required');
    }
    
    // Date filter
    $dateFilter = '';
    if ($period == 'today') $dateFilter = 'AND DATE(p.created_at) = CURDATE()';
    elseif ($period == 'week') $dateFilter = 'AND p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)';
    elseif ($period == 'month') $dateFilter = 'AND p.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
    
    // Simple query - just get payments with basic info
    $query = "
        SELECT 
            p.id as payment_id,
            p.user_id as driver_id,
            COALESCE(u.name, 'Unknown') as driver_name,
            COALESCE(u.mobile, '') as driver_mobile,
            COALESCE(u.unique_id, '') as driver_tmid,
            $telecaller_id as telecaller_id,
            COALESCE(a.name, '') as telecaller_name,
            p.created_at as payment_created_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            FROM_UNIXTIME(p.end_at) AS payment_end_time,
            p.amount,
            COALESCE(p.payment_id, '') as razorpay_payment_id,
            p.payment_status,
            COALESCE(p.payment_type, '') as payment_type,
            p.plan_id,
            COALESCE(DATEDIFF(FROM_UNIXTIME(p.end_at), FROM_UNIXTIME(p.start_at)), 0) as subscription_days,
            0 as call_log_id,
            p.created_at as call_time,
            'completed' as call_status,
            0 as call_duration,
            0 as minutes_after_call
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN admins a ON a.id = $telecaller_id
        WHERE p.payment_status = 'captured'
        AND EXISTS (
            SELECT 1 FROM call_logs cl
            WHERE cl.user_id = p.user_id
            AND cl.caller_id = $telecaller_id
            AND cl.call_time < p.created_at
        )
        $dateFilter
        ORDER BY p.created_at DESC
        LIMIT 100
    ";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query error: " . $conn->error);
    }
    
    $subscriptions = [];
    while ($row = $result->fetch_assoc()) {
        $subscriptions[] = $row;
    }
    
    // Summary
    $count = count($subscriptions);
    $revenue = array_sum(array_column($subscriptions, 'amount'));
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_subscriptions' => $count,
            'total_revenue' => (float)$revenue,
            'avg_subscription_value' => $count > 0 ? $revenue / $count : 0,
            'subscriptions' => $subscriptions,
            'subscriptions_by_date' => [],
            'period' => $period,
            'summary' => [
                'total_subscriptions' => $count,
                'total_revenue' => (float)$revenue
            ]
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
