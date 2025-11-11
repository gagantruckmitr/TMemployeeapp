<?php
/**
 * Get Server Time API
 * Returns current server time for client synchronization
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Set timezone (adjust as needed)
date_default_timezone_set('Asia/Kolkata'); // Indian Standard Time

$response = [
    'success' => true,
    'data' => [
        'current_timestamp' => time(),
        'current_datetime' => date('Y-m-d H:i:s'),
        'current_date' => date('Y-m-d'),
        'current_time' => date('H:i:s'),
        'current_year' => (int)date('Y'),
        'current_month' => (int)date('m'),
        'current_day' => (int)date('d'),
        'timezone' => date_default_timezone_get(),
        'formatted_time' => date('g:i A'), // 12-hour format
        'formatted_date' => date('d/m/Y'), // DD/MM/YYYY format
    ],
    'message' => 'Server time retrieved successfully'
];

echo json_encode($response);
?>