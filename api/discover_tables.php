<?php
/**
 * Discover All Tables in Plesk Database
 * Shows what tables actually exist in the live database
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Database credentials
$db_host = 'localhost';
$db_port = '3306';
$db_name = 'truckmitr';
$db_user = 'truckmitr';
$db_pass = '825Redp&4';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'database' => $db_name
];

try {
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name, $db_port);
    
    if ($conn->connect_error) {
        throw new Exception('Connection failed: ' . $conn->connect_error);
    }
    
    $response['success'] = true;
    $response['message'] = 'Database connected successfully';
    
    // Get all tables
    $result = $conn->query("SHOW TABLES");
    $all_tables = [];
    
    while ($row = $result->fetch_array()) {
        $table_name = $row[0];
        
        // Get row count for each table
        $count_result = $conn->query("SELECT COUNT(*) as count FROM `$table_name`");
        $count_row = $count_result->fetch_assoc();
        
        $all_tables[$table_name] = (int)$count_row['count'];
    }
    
    $response['total_tables'] = count($all_tables);
    $response['tables'] = $all_tables;
    
    // Look for tables that might be related to your app
    $app_related = [];
    $keywords = ['user', 'driver', 'call', 'telecaller', 'lead', 'payment', 'job'];
    
    foreach ($all_tables as $table => $count) {
        foreach ($keywords as $keyword) {
            if (stripos($table, $keyword) !== false) {
                $app_related[$table] = $count;
                break;
            }
        }
    }
    
    $response['app_related_tables'] = $app_related;
    
    $conn->close();
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Error: ' . $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
