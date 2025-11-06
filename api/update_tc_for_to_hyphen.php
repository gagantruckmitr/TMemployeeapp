<?php
/**
 * Migration Script: Update tc_for from match_making to match-making
 * This script updates all telecaller records to use hyphenated format
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    // Start transaction
    $conn->begin_transaction();
    
    // Update admins table - change match_making to match-making
    $updateQuery = "UPDATE admins 
                    SET tc_for = 'match-making' 
                    WHERE tc_for = 'match_making' 
                    AND role = 'telecaller'";
    
    $result = $conn->query($updateQuery);
    
    if (!$result) {
        throw new Exception('Update failed: ' . $conn->error);
    }
    
    $affectedRows = $conn->affected_rows;
    
    // Get updated records for verification
    $verifyQuery = "SELECT id, name, mobile, tc_for 
                    FROM admins 
                    WHERE tc_for = 'match-making' 
                    AND role = 'telecaller'";
    
    $verifyResult = $conn->query($verifyQuery);
    
    $updatedRecords = [];
    while ($row = $verifyResult->fetch_assoc()) {
        $updatedRecords[] = $row;
    }
    
    // Commit transaction
    $conn->commit();
    
    echo json_encode([
        'success' => true,
        'message' => 'Successfully updated tc_for values from match_making to match-making',
        'affected_rows' => $affectedRows,
        'updated_records' => $updatedRecords,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    // Rollback on error
    if ($conn) {
        $conn->rollback();
    }
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
}

if ($conn) {
    $conn->close();
}
?>
