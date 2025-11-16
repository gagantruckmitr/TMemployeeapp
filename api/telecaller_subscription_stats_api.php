<?php
/**
 * Telecaller Subscription Stats API
 * Provides summary statistics for telecaller dashboard
 * Uses call_logs table matching with payments (same logic as subscription.php)
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
    
    if (!$telecaller_id) {
        throw new Exception('User ID is required');
    }
    
    // Get subscription stats using call_logs table
    // For each payment, find the most recent call BEFORE the payment from this telecaller
    // This ensures we credit the telecaller whose call led to the subscription
    $query = "
        SELECT 
            COUNT(DISTINCT p.id) as total_subscriptions,
            SUM(p.amount) as total_revenue,
            COUNT(DISTINCT CASE WHEN DATE(p.created_at) = CURDATE() THEN p.id END) as today_subscriptions,
            SUM(CASE WHEN DATE(p.created_at) = CURDATE() THEN p.amount ELSE 0 END) as today_revenue,
            COUNT(DISTINCT CASE WHEN p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN p.id END) as week_subscriptions,
            SUM(CASE WHEN p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN p.amount ELSE 0 END) as week_revenue,
            COUNT(DISTINCT CASE WHEN p.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN p.id END) as month_subscriptions,
            SUM(CASE WHEN p.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN p.amount ELSE 0 END) as month_revenue
        FROM payments p
        WHERE p.payment_status = 'captured'
        AND EXISTS (
            SELECT 1 FROM call_logs cl
            WHERE cl.user_id = p.user_id
            AND cl.caller_id = " . intval($telecaller_id) . "
            AND cl.call_time < p.created_at
        )
    ";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Stats query failed: " . $conn->error);
    }
    
    $stats = $result->fetch_assoc();
    
    // Get recent subscriptions (last 5)
    $recent_query = "
        SELECT 
            p.id as payment_id,
            p.amount,
            FROM_UNIXTIME(p.start_at) AS payment_time,
            u.name as driver_name,
            u.unique_id as driver_tmid
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        WHERE p.payment_status = 'captured'
        AND EXISTS (
            SELECT 1 FROM call_logs cl
            WHERE cl.user_id = p.user_id
            AND cl.caller_id = " . intval($telecaller_id) . "
            AND cl.call_time < p.created_at
        )
        ORDER BY p.created_at DESC
        LIMIT 5
    ";
    
    $recent_result = $conn->query($recent_query);
    
    if (!$recent_result) {
        throw new Exception("Recent subscriptions query failed: " . $conn->error);
    }
    
    $recentSubscriptions = [];
    while ($row = $recent_result->fetch_assoc()) {
        $recentSubscriptions[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_subscriptions' => (int)($stats['total_subscriptions'] ?? 0),
            'total_revenue' => (float)($stats['total_revenue'] ?? 0),
            'today_subscriptions' => (int)($stats['today_subscriptions'] ?? 0),
            'today_revenue' => (float)($stats['today_revenue'] ?? 0),
            'week_subscriptions' => (int)($stats['week_subscriptions'] ?? 0),
            'week_revenue' => (float)($stats['week_revenue'] ?? 0),
            'month_subscriptions' => (int)($stats['month_subscriptions'] ?? 0),
            'month_revenue' => (float)($stats['month_revenue'] ?? 0),
            'recent_subscriptions' => $recentSubscriptions
        ]
    ]);
    
} catch (Exception $e) {
    error_log('Telecaller Subscription Stats API Error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
