<?php
/**
 * Simple Database Connection Test
 * Upload this to test if your Plesk deployment can connect to the database
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Database credentials - same as config.php
$db_host = 'localhost';
$db_port = '3306';
$db_name = 'truckmitr';
$db_user = 'truckmitr';
$db_pass = '825Redp&4';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'server_info' => [
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? 'Unknown'
    ]
];

try {
    // Try to connect
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name, $db_port);
    
    if ($conn->connect_error) {
        throw new Exception('Connection failed: ' . $conn->connect_error);
    }
    
    // Connection successful
    $response['success'] = true;
    $response['message'] = 'Database connected successfully';
    $response['database'] = [
        'host' => $db_host,
        'port' => $db_port,
        'name' => $db_name,
        'user' => $db_user,
        'charset' => $conn->character_set_name()
    ];
    
    // Test query - count tables
    $result = $conn->query("SHOW TABLES");
    if ($result) {
        $response['database']['table_count'] = $result->num_rows;
        
        // List some important tables
        $tables = [];
        while ($row = $result->fetch_array()) {
            $tables[] = $row[0];
        }
        $response['database']['tables'] = $tables;
    }
    
    // Test specific tables
    $important_tables = ['users', 'drivers', 'call_logs', 'telecaller_status'];
    $table_status = [];
    
    foreach ($important_tables as $table) {
        $result = $conn->query("SELECT COUNT(*) as count FROM `$table`");
        if ($result) {
            $row = $result->fetch_assoc();
            $table_status[$table] = [
                'exists' => true,
                'row_count' => $row['count']
            ];
        } else {
            $table_status[$table] = [
                'exists' => false,
                'error' => $conn->error
            ];
        }
    }
    
    $response['database']['table_status'] = $table_status;
    
    $conn->close();
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Database connection failed';
    $response['error'] = $e->getMessage();
    $response['troubleshooting'] = [
        'check_credentials' => 'Verify DB_HOST, DB_USER, DB_PASS, DB_NAME',
        'check_mysql' => 'Ensure MySQL service is running',
        'check_permissions' => 'Verify database user has proper permissions',
        'try_alternative' => 'Try changing DB_HOST from localhost to 127.0.0.1 or vice versa'
    ];
}

// Pretty print JSON
echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
