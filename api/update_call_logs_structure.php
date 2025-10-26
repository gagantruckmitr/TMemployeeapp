<?php
/**
 * Update call_logs table structure for telecaller app
 * Adds missing columns without deleting existing data
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'operation' => 'Update call_logs table structure'
];

try {
    $columnsAdded = [];
    $columnsExisted = [];
    
    // Add telecaller_id column (alias for caller_id for our app)
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN telecaller_id INT(11) DEFAULT NULL AFTER caller_id");
        $columnsAdded[] = 'telecaller_id';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'telecaller_id';
        }
    }
    
    // Add driver_id column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN driver_id INT(11) DEFAULT NULL AFTER user_id");
        $columnsAdded[] = 'driver_id';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'driver_id';
        }
    }
    
    // Add driver_name column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN driver_name VARCHAR(255) DEFAULT NULL AFTER driver_id");
        $columnsAdded[] = 'driver_name';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'driver_name';
        }
    }
    
    // Add driver_mobile column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN driver_mobile VARCHAR(15) DEFAULT NULL AFTER driver_name");
        $columnsAdded[] = 'driver_mobile';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'driver_mobile';
        }
    }
    
    // Add call_status column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN call_status ENUM('connected','not_connected','busy','no_answer','callback','callback_later','not_interested') DEFAULT NULL AFTER driver_mobile");
        $columnsAdded[] = 'call_status';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'call_status';
        }
    }
    
    // Add feedback column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN feedback ENUM('interested','not_interested','callback_later','profile_incomplete') DEFAULT NULL AFTER call_status");
        $columnsAdded[] = 'feedback';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'feedback';
        }
    }
    
    // Add notes column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN notes TEXT DEFAULT NULL AFTER feedback");
        $columnsAdded[] = 'notes';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'notes';
        }
    }
    
    // Add call_duration column
    try {
        $pdo->exec("ALTER TABLE call_logs ADD COLUMN call_duration INT(11) DEFAULT 0 AFTER notes");
        $columnsAdded[] = 'call_duration';
    } catch (Exception $e) {
        if (strpos($e->getMessage(), 'Duplicate column') !== false) {
            $columnsExisted[] = 'call_duration';
        }
    }
    
    // Add indexes for better performance
    try {
        $pdo->exec("ALTER TABLE call_logs ADD INDEX idx_telecaller_id (telecaller_id)");
        $columnsAdded[] = 'index: idx_telecaller_id';
    } catch (Exception $e) {
        // Index might already exist
    }
    
    try {
        $pdo->exec("ALTER TABLE call_logs ADD INDEX idx_driver_id (driver_id)");
        $columnsAdded[] = 'index: idx_driver_id';
    } catch (Exception $e) {
        // Index might already exist
    }
    
    try {
        $pdo->exec("ALTER TABLE call_logs ADD INDEX idx_call_time (call_time)");
        $columnsAdded[] = 'index: idx_call_time';
    } catch (Exception $e) {
        // Index might already exist
    }
    
    // Get updated table structure
    $stmt = $pdo->query("DESCRIBE call_logs");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $response['success'] = true;
    $response['message'] = 'call_logs table updated successfully';
    $response['columns_added'] = $columnsAdded;
    $response['columns_existed'] = $columnsExisted;
    $response['current_structure'] = $columns;
    $response['note'] = 'All existing data is safe. Only new columns were added.';
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['error'] = $e->getMessage();
    $response['file'] = $e->getFile();
    $response['line'] = $e->getLine();
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
