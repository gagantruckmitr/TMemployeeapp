<?php
/**
 * Simple Plesk Database Connection Test
 * Tests if the database connection is working properly
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
    'test' => 'Plesk Database Connection'
];

try {
    // Attempt connection
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name, $db_port);
    
    // Check for connection errors
    if ($conn->connect_error) {
        throw new Exception('Connection failed: ' . $conn->connect_error);
    }
    
    // Connection successful
    $response['success'] = true;
    $response['message'] = '✓ Database connected successfully!';
    $response['connection'] = [
        'host' => $db_host,
        'port' => $db_port,
        'database' => $db_name,
        'user' => $db_user,
        'charset' => $conn->character_set_name()
    ];
    
    // Test query - count important tables
    $important_tables = ['users', 'drivers', 'call_logs', 'telecaller_status'];
    $table_data = [];
    
    foreach ($important_tables as $table) {
        $result = $conn->query("SELECT COUNT(*) as count FROM `$table`");
        if ($result) {
            $row = $result->fetch_assoc();
            $table_data[$table] = [
                'exists' => true,
                'records' => (int)$row['count']
            ];
        } else {
            $table_data[$table] = [
                'exists' => false,
                'error' => $conn->error
            ];
        }
    }
    
    $response['tables'] = $table_data;
    
    // Test a simple query on users table
    $result = $conn->query("SELECT COUNT(*) as total FROM users WHERE role = 'telecaller'");
    if ($result) {
        $row = $result->fetch_assoc();
        $response['telecaller_count'] = (int)$row['total'];
    }
    
    $conn->close();
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = '✗ Database connection failed!';
    $response['error'] = $e->getMessage();
    $response['help'] = [
        'Check database credentials in config.php',
        'Verify MySQL service is running',
        'Check database user permissions',
        'Try changing host from localhost to 127.0.0.1'
    ];
}

// Output JSON
echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
