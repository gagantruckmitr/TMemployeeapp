<?php
/**
 * Telecaller Subscriptions API
 * LOGIC:
 * - Subscription is counted from payment START time (p.start_at)
 * - Payment must be CAPTURED
 * - User must be assigned to telecaller
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
    $period = $_GET['period'] ?? 'all';

    if (!$telecaller_id) {
        throw new Exception('User ID is required');
    }

    $telecaller_id = intval($telecaller_id);

    /**
     * DATE FILTER — BASED ON SUBSCRIPTION START TIME
     */
    $dateFilter = '';
    switch ($period) {
        case 'today':
            $dateFilter = "AND DATE(FROM_UNIXTIME(p.start_at)) = CURDATE()";
            break;

        case 'yesterday':
            $dateFilter = "AND DATE(FROM_UNIXTIME(p.start_at)) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)";
            break;

        case 'week':
            $dateFilter = "AND FROM_UNIXTIME(p.start_at) >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
            break;

        case 'month':
            $dateFilter = "AND FROM_UNIXTIME(p.start_at) >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
            break;

        default:
            $dateFilter = '';
    }

    /**
     * MAIN SUBSCRIPTION LIST QUERY
     */
    $query = "
        SELECT 
            p.id AS payment_id,
            p.user_id AS driver_id,
            u.name AS driver_name,
            u.mobile AS driver_mobile,
            u.unique_id AS driver_tmid,
            u.assigned_to AS telecaller_id,
            a.name AS telecaller_name,

            p.created_at AS payment_created_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            FROM_UNIXTIME(p.end_at) AS payment_end_time,

            p.amount,
            p.payment_id AS razorpay_payment_id,
            p.payment_status,
            p.payment_type,

            DATEDIFF(
                FROM_UNIXTIME(p.end_at),
                FROM_UNIXTIME(p.start_at)
            ) AS subscription_days,

            0 AS call_log_id,
            FROM_UNIXTIME(p.start_at) AS call_time,
            'assigned' AS call_status,
            0 AS call_duration,
            0 AS minutes_after_call,
            NULL AS plan_id

        FROM users u
        JOIN payments p ON u.id = p.user_id
        LEFT JOIN admins a ON u.assigned_to = a.id

        WHERE 
            u.assigned_to = $telecaller_id
            AND p.payment_status = 'captured'
            $dateFilter

        ORDER BY p.start_at DESC
    ";

    $result = $conn->query($query);
    if (!$result) {
        throw new Exception("Main query failed: " . $conn->error);
    }

    $subscriptions = [];
    while ($row = $result->fetch_assoc()) {
        $subscriptions[] = $row;
    }

    /**
     * SUMMARY QUERY (BASED ON START TIME)
     */
    $summary_query = "
        SELECT 
            COUNT(DISTINCT p.id) AS total_subscriptions,
            SUM(p.amount) AS total_revenue,
            AVG(p.amount) AS avg_subscription_value,
            MIN(FROM_UNIXTIME(p.start_at)) AS first_subscription_date,
            MAX(FROM_UNIXTIME(p.start_at)) AS latest_subscription_date
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE 
            u.assigned_to = $telecaller_id
            AND p.payment_status = 'captured'
            $dateFilter
    ";

    $summary_result = $conn->query($summary_query);
    if (!$summary_result) {
        throw new Exception("Summary query failed: " . $conn->error);
    }

    $summary = $summary_result->fetch_assoc();

    /**
     * GROUP BY DATE QUERY (FOR CHARTS / REPORTS)
     */
    $by_date_query = "
        SELECT 
            DATE(FROM_UNIXTIME(p.start_at)) AS subscription_date,
            COUNT(DISTINCT p.id) AS count,
            SUM(p.amount) AS daily_revenue
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE 
            u.assigned_to = $telecaller_id
            AND p.payment_status = 'captured'
            $dateFilter
        GROUP BY DATE(FROM_UNIXTIME(p.start_at))
        ORDER BY subscription_date DESC
    ";

    $by_date_result = $conn->query($by_date_query);
    if (!$by_date_result) {
        throw new Exception("By-date query failed: " . $conn->error);
    }

    $subscriptions_by_date = [];
    while ($row = $by_date_result->fetch_assoc()) {
        $subscriptions_by_date[] = $row;
    }

    /**
     * DEBUG INFO
     */
    $debug_query = "
        SELECT COUNT(*) AS count 
        FROM users 
        WHERE assigned_to = $telecaller_id
    ";
    $debug_result = $conn->query($debug_query);
    $debug_row = $debug_result->fetch_assoc();

    /**
     * FINAL RESPONSE
     */
    echo json_encode([
        'success' => true,
        'data' => [
            'total_subscriptions' => (int) ($summary['total_subscriptions'] ?? 0),
            'total_revenue' => (float) ($summary['total_revenue'] ?? 0),
            'avg_subscription_value' => (float) ($summary['avg_subscription_value'] ?? 0),

            'subscriptions' => $subscriptions,
            'subscriptions_by_date' => $subscriptions_by_date,

            'period' => $period,
            'summary' => $summary,

            'logic_used' => 'subscription_start_time',

            'debug' => [
                'telecaller_id' => $telecaller_id,
                'users_assigned_count' => (int) ($debug_row['count'] ?? 0),
                'date_filter' => $dateFilter
            ]
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
