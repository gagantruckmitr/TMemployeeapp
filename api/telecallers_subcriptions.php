<?php
/**
 * Telecaller Subscriptions API
 * Shows subscriptions for the logged-in telecaller
 */

require_once 'config.php';

// Get telecaller ID from request (should come from authentication)
$telecaller_id = isset($_GET['telecaller_id']) ? intval($_GET['telecaller_id']) : null;
$start_date = isset($_GET['start_date']) ? $_GET['start_date'] : null;
$end_date = isset($_GET['end_date']) ? $_GET['end_date'] : null;
$payment_status = isset($_GET['payment_status']) ? $_GET['payment_status'] : 'captured';

// Validate telecaller_id is provided
if (!$telecaller_id) {
    sendError('Telecaller ID is required', 400);
}

try {
    // Get telecaller subscriptions
    $query = "
        SELECT 
            u.id as driver_id,
            u.name as driver_name,
            u.mobile as driver_phone,
            cl.call_time,
            COALESCE(FROM_UNIXTIME(p.start_at), p.created_at) AS payment_time,
            TIMESTAMPDIFF(MINUTE, cl.call_time, COALESCE(FROM_UNIXTIME(p.start_at), p.created_at)) as minutes_after_call,
            p.amount,
            p.payment_id,
            p.payment_status,
            p.payment_type,
            DATEDIFF(FROM_UNIXTIME(p.end_at), FROM_UNIXTIME(p.start_at)) as subscription_days
        FROM users u
        JOIN payments p ON u.id = p.user_id
        LEFT JOIN (
            SELECT user_id, MIN(call_time) as call_time
            FROM call_logs
            WHERE call_time IS NOT NULL
            GROUP BY user_id
        ) cl ON u.id = cl.user_id
        WHERE u.assigned_to = " . intval($telecaller_id) . "
        AND (
            (p.start_at IS NOT NULL AND cl.call_time < FROM_UNIXTIME(p.start_at))
            OR
            (p.start_at IS NULL AND cl.call_time < p.created_at)
        )
    ";
    
    // Add filters
    if ($payment_status) {
        $query .= " AND p.payment_status = '" . $conn->real_escape_string($payment_status) . "'";
    }
    
    if ($start_date) {
        $query .= " AND DATE(cl.call_time) >= '" . $conn->real_escape_string($start_date) . "'";
    }
    
    if ($end_date) {
        $query .= " AND DATE(cl.call_time) <= '" . $conn->real_escape_string($end_date) . "'";
    }
    
    $query .= " ORDER BY cl.call_time DESC";
    
    // Execute query
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $subscriptions = [];
    while ($row = $result->fetch_assoc()) {
        $subscriptions[] = $row;
    }
    
    // Get summary statistics for this telecaller
    $summary_query = "
        SELECT 
            COUNT(DISTINCT p.id) as total_subscriptions,
            SUM(p.amount) as total_revenue,
            AVG(p.amount) as avg_subscription_value
        FROM users u
        JOIN payments p ON u.id = p.user_id
        LEFT JOIN (
            SELECT user_id, MIN(call_time) as call_time
            FROM call_logs
            WHERE call_time IS NOT NULL
            GROUP BY user_id
        ) cl ON u.id = cl.user_id
        WHERE u.assigned_to = " . intval($telecaller_id) . "
        AND (
            (p.start_at IS NOT NULL AND cl.call_time < FROM_UNIXTIME(p.start_at))
            OR
            (p.start_at IS NULL AND cl.call_time < p.created_at)
        )
    ";
    
    if ($payment_status) {
        $summary_query .= " AND p.payment_status = '" . $conn->real_escape_string($payment_status) . "'";
    }
    
    if ($start_date) {
        $summary_query .= " AND DATE(cl.call_time) >= '" . $conn->real_escape_string($start_date) . "'";
    }
    
    if ($end_date) {
        $summary_query .= " AND DATE(cl.call_time) <= '" . $conn->real_escape_string($end_date) . "'";
    }
    
    $summary_result = $conn->query($summary_query);
    
    if (!$summary_result) {
        throw new Exception("Summary query failed: " . $conn->error);
    }
    
    $summary = $summary_result->fetch_assoc();
    
    // Get monthly breakdown
    $monthly_query = "
        SELECT 
            DATE_FORMAT(cl.call_time, '%Y-%m') as month,
            COUNT(DISTINCT p.id) as subscriptions_count,
            SUM(p.amount) as revenue
        FROM users u
        JOIN payments p ON u.id = p.user_id
        LEFT JOIN (
            SELECT user_id, MIN(call_time) as call_time
            FROM call_logs
            WHERE call_time IS NOT NULL
            GROUP BY user_id
        ) cl ON u.id = cl.user_id
        WHERE u.assigned_to = " . intval($telecaller_id) . "
        AND (
            (p.start_at IS NOT NULL AND cl.call_time < FROM_UNIXTIME(p.start_at))
            OR
            (p.start_at IS NULL AND cl.call_time < p.created_at)
        )
    ";
    
    if ($payment_status) {
        $monthly_query .= " AND p.payment_status = '" . $conn->real_escape_string($payment_status) . "'";
    }
    
    if ($start_date) {
        $monthly_query .= " AND DATE(cl.call_time) >= '" . $conn->real_escape_string($start_date) . "'";
    }
    
    if ($end_date) {
        $monthly_query .= " AND DATE(cl.call_time) <= '" . $conn->real_escape_string($end_date) . "'";
    }
    
    $monthly_query .= " GROUP BY DATE_FORMAT(cl.call_time, '%Y-%m') ORDER BY month DESC LIMIT 12";
    
    $monthly_result = $conn->query($monthly_query);
    
    $monthly_breakdown = [];
    if ($monthly_result) {
        while ($row = $monthly_result->fetch_assoc()) {
            $monthly_breakdown[] = $row;
        }
    }
    
    sendSuccess([
        'subscriptions' => $subscriptions,
        'summary' => [
            'total_subscriptions' => $summary['total_subscriptions'] ?? 0,
            'total_revenue' => $summary['total_revenue'] ?? 0,
            'avg_subscription_value' => $summary['avg_subscription_value'] ?? 0
        ],
        'monthly_breakdown' => $monthly_breakdown
    ]);
    
} catch (Exception $e) {
    error_log('Telecaller Subscriptions API Error: ' . $e->getMessage());
    sendError('Failed to fetch subscriptions: ' . $e->getMessage(), 500);
}
