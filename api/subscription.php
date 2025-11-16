<?php
/**
 * Admin Subscriptions API
 * Track subscriptions based on call_logs.user_id matching with payments.user_id
 * Credits telecaller who made the call that led to subscription
 */

require_once 'config.php';

// Get filter parameters
$telecaller_id = isset($_GET['telecaller_id']) ? intval($_GET['telecaller_id']) : null;
$start_date = isset($_GET['start_date']) ? $_GET['start_date'] : null;
$end_date = isset($_GET['end_date']) ? $_GET['end_date'] : null;
$payment_status = isset($_GET['payment_status']) ? $_GET['payment_status'] : 'captured';

try {
    // Main query: Get subscriptions from call_logs table
    // Match call_logs.user_id with payments.user_id where payment_status = 'captured'
    // and payment created_at is after call_time
    $query = "
        SELECT 
            cl.id as call_log_id,
            cl.user_id as driver_id,
            COALESCE(cl.driver_name, u.name) as driver_name,
            COALESCE(cl.user_number, u.mobile) as driver_phone,
            cl.caller_id as telecaller_id,
            a.name as telecaller_name,
            cl.call_time,
            cl.call_status,
            cl.call_duration,
            p.created_at as payment_created_at,
            FROM_UNIXTIME(p.start_at) AS payment_start_time,
            TIMESTAMPDIFF(MINUTE, cl.call_time, p.created_at) as minutes_after_call,
            p.amount,
            p.payment_id,
            p.payment_status,
            p.payment_type,
            DATEDIFF(FROM_UNIXTIME(p.end_at), FROM_UNIXTIME(p.start_at)) as subscription_days
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        LEFT JOIN users u ON cl.user_id = u.id
        LEFT JOIN admins a ON cl.caller_id = a.id
        WHERE p.payment_status = 'captured'
        AND p.created_at > cl.call_time
    ";
    
    // Add filters
    if ($telecaller_id) {
        $query .= " AND cl.caller_id = " . intval($telecaller_id);
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
    
    // Get summary statistics
    $summary_query = "
        SELECT 
            COUNT(DISTINCT p.id) as total_subscriptions,
            COUNT(DISTINCT cl.caller_id) as total_telecallers,
            SUM(p.amount) as total_revenue,
            AVG(p.amount) as avg_subscription_value
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        WHERE p.payment_status = 'captured'
        AND p.created_at > cl.call_time
    ";
    
    if ($telecaller_id) {
        $summary_query .= " AND cl.caller_id = " . intval($telecaller_id);
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
    
    // Get telecaller performance
    $performance_query = "
        SELECT 
            cl.caller_id as telecaller_id,
            a.name as telecaller_name,
            COUNT(DISTINCT p.id) as subscriptions_count,
            SUM(p.amount) as total_revenue,
            AVG(p.amount) as avg_subscription_value
        FROM call_logs cl
        JOIN payments p ON cl.user_id = p.user_id
        LEFT JOIN admins a ON cl.caller_id = a.id
        WHERE p.payment_status = 'captured'
        AND p.created_at > cl.call_time
    ";
    
    if ($start_date) {
        $performance_query .= " AND DATE(cl.call_time) >= '" . $conn->real_escape_string($start_date) . "'";
    }
    
    if ($end_date) {
        $performance_query .= " AND DATE(cl.call_time) <= '" . $conn->real_escape_string($end_date) . "'";
    }
    
    $performance_query .= " GROUP BY cl.caller_id, a.name ORDER BY subscriptions_count DESC";
    
    $performance_result = $conn->query($performance_query);
    
    if (!$performance_result) {
        throw new Exception("Performance query failed: " . $conn->error);
    }
    
    $performance = [];
    while ($row = $performance_result->fetch_assoc()) {
        $performance[] = $row;
    }
    
    sendSuccess([
        'subscriptions' => $subscriptions,
        'summary' => $summary,
        'telecaller_performance' => $performance
    ]);
    
} catch (Exception $e) {
    error_log('Subscriptions API Error: ' . $e->getMessage());
    sendError('Failed to fetch subscriptions: ' . $e->getMessage(), 500);
}

