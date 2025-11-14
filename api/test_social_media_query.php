<?php
/**
 * Test Social Media Query
 */

header('Content-Type: application/json');

$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Connection failed: ' . $conn->connect_error);
    }
    
    // Get all social media leads
    $allLeads = $conn->query("SELECT id, name, mobile FROM social_media_leads ORDER BY created_at DESC LIMIT 10");
    $leads = [];
    while ($row = $allLeads->fetch_assoc()) {
        $leads[] = $row;
    }
    
    // Get all call logs with tc_for = social-media
    $allLogs = $conn->query("SELECT id, driver_name, user_number FROM call_logs WHERE tc_for = 'social-media' ORDER BY created_at DESC LIMIT 10");
    $logs = [];
    while ($row = $allLogs->fetch_assoc()) {
        $logs[] = $row;
    }
    
    // Test the JOIN query with collation fix
    $joinQuery = "SELECT sml.id, sml.name, sml.mobile, cl.id as call_log_id, cl.user_number
                  FROM social_media_leads sml
                  LEFT JOIN call_logs cl ON sml.mobile COLLATE utf8mb4_unicode_ci = cl.user_number COLLATE utf8mb4_unicode_ci
                      AND cl.tc_for = 'social-media'
                  ORDER BY sml.created_at DESC 
                  LIMIT 10";
    
    $joinResult = $conn->query($joinQuery);
    $joinData = [];
    while ($row = $joinResult->fetch_assoc()) {
        $joinData[] = $row;
    }
    
    // Leads that should be excluded (have call logs)
    $excludeQuery = "SELECT sml.id, sml.name, sml.mobile, cl.id as call_log_id
                     FROM social_media_leads sml
                     LEFT JOIN call_logs cl ON sml.mobile COLLATE utf8mb4_unicode_ci = cl.user_number COLLATE utf8mb4_unicode_ci
                         AND cl.tc_for = 'social-media'
                     WHERE cl.id IS NOT NULL
                     ORDER BY sml.created_at DESC";
    
    $excludeResult = $conn->query($excludeQuery);
    $shouldBeExcluded = [];
    while ($row = $excludeResult->fetch_assoc()) {
        $shouldBeExcluded[] = $row;
    }
    
    echo json_encode([
        'all_leads' => $leads,
        'all_call_logs' => $logs,
        'join_result' => $joinData,
        'should_be_excluded' => $shouldBeExcluded,
        'query' => $joinQuery
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
