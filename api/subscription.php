<?php
/**
 * Telecaller Subscriptions API
 * Simple logic: Count subscriptions where user is assigned to telecaller 
 * and has a payment with status = 'captured'
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
    $period = $_GET['period'] ?? 'all'; // 'today', 'yesterday', 'week', 'all'
    
    if (!$telecaller_id) {
        throw new Exception('User ID is required');
    }
    
    // Build date filter based on period (filter by payment date)
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
        case 'all':
        default:
            $dateFilter = '';
            break;
    }
    
    // Main query: Get subscriptions where user is assigned to telecaller
    // and has a captured payment
    $query = "
        SELECT 
            p.id as payment_id,
            p.user_id as driver_id,
            u.name as driver_name,
            u.mobile as driver_mobile,
            u.unique_id as driver_tmid,
            u.assigned_telecaller as telecaller_id,
            a.name as telecaller_name,
            p.created_at as payment_created_at,
            FROM_UNIXTIME(p.start_at) as payment_start_time,
            FROM_UNIXTIME(p.end_at) as payment_end_time,
            p.amount,
            p.payment_id as razorpay_payment_id,
            p.payment_status,
            p.payment_type,
            DATEDIFF(FROM_UNIXTIME(p.end_at), FROM_UNIXTIME(p.start_at)) as subscription_days
        FROM users u
        JOIN payments p ON u.id = p.user_id
        LEFT JOIN admins a ON u.assigned_telecaller = a.id
        WHERE u.assigned_telecaller = " . intval($telecaller_id) . "
        AND p.payment_status = 'captured'
        $dateFilter
        ORDER BY p.created_at DESC
    ";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $subscriptions = [];
    while ($row = $result->fetch_assoc()) {
        $subscriptions[] = $row;
    }
    
    // Get summary statistics
    $summary_query = "
        SELECT 
            COUNT(DISTINCT p.id) as total_subscriptions,
            SUM(p.amount) as total_revenue,
            AVG(p.amount) as avg_subscription_value,
            COUNT(DISTINCT u.id) as unique_subscribers,
            MIN(p.created_at) as first_subscription_date,
            MAX(p.created_at) as latest_subscription_date
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_telecaller = " . intval($telecaller_id) . "
        AND p.payment_status = 'captured'
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
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_telecaller = " . intval($telecaller_id) . "
        AND p.payment_status = 'captured'
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
            'unique_subscribers' => (int)($summary['unique_subscribers'] ?? 0),
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
