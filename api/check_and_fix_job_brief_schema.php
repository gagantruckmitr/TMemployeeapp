<?php
require_once 'config.php';

header('Content-Type: application/json');

$response = [];

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// Function to check and add column
function checkAndAddColumn($conn, $table, $column, $definition, $after = '') {
    $checkQuery = "SHOW COLUMNS FROM $table LIKE '$column'";
    $result = $conn->query($checkQuery);
    
    if ($result->num_rows == 0) {
        $alterQuery = "ALTER TABLE $table ADD COLUMN $column $definition";
        if ($after) {
            $alterQuery .= " AFTER $after";
        }
        
        if ($conn->query($alterQuery)) {
            return "Added column $column";
        } else {
            return "Failed to add column $column: " . $conn->error;
        }
    } else {
        return "Column $column already exists";
    }
}

$table = 'job_brief_table';

// Check for 'required_drivers'
$response['required_drivers'] = checkAndAddColumn($conn, $table, 'required_drivers', 'VARCHAR(255) NULL', 'call_recording');

// Check for 'closed_job'
$response['closed_job'] = checkAndAddColumn($conn, $table, 'closed_job', 'TINYINT(1) DEFAULT 0', 'required_drivers');

// Check for 'call_recording' (just in case)
$response['call_recording'] = checkAndAddColumn($conn, $table, 'call_recording', 'VARCHAR(255) NULL', 'call_status_feedback');

echo json_encode(['success' => true, 'results' => $response]);
?>
