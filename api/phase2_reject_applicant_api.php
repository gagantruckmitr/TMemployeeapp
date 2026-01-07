<?php
/**
 * Phase 2 Reject Job Applicant API
 * Rejects a driver's application for a specific job
 * Updates both applyjobs table status and call_logs_match_making with rejection
 */

require_once 'config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    sendError('Invalid JSON input', 400);
}

// Validate required fields
$callerId = isset($input['callerId']) ? intval($input['callerId']) : 0;
$driverId = isset($input['driverId']) ? intval($input['driverId']) : 0;
$jobId = isset($input['jobId']) ? intval($input['jobId']) : 0;
$driverTmid = isset($input['driverTmid']) ? $conn->real_escape_string($input['driverTmid']) : '';
$jobIdString = isset($input['jobIdString']) ? $conn->real_escape_string($input['jobIdString']) : '';
$reason = isset($input['reason']) ? $conn->real_escape_string($input['reason']) : '';

if ($callerId === 0 || $driverId === 0 || $jobId === 0) {
    sendError('Missing required fields: callerId, driverId, or jobId', 400);
}

try {
    // Start transaction
    $conn->begin_transaction();
    
    // 1. Update applyjobs table - set status to 'Rejected'
    $updateApplyJobsQuery = "UPDATE applyjobs 
                             SET status = 'Rejected', 
                                 updated_at = NOW() 
                             WHERE driver_id = $driverId 
                             AND job_id = $jobId";
    
    if (!$conn->query($updateApplyJobsQuery)) {
        throw new Exception('Failed to update applyjobs table: ' . $conn->error);
    }
    
    $applyJobsAffected = $conn->affected_rows;
    
    // 2. Insert/Update call_logs_match_making with rejection status
    // First check if there's already a record for this driver and job
    $checkLogQuery = "SELECT id FROM call_logs_match_making 
                      WHERE unique_id_driver = '$driverTmid' 
                      AND job_id = '$jobIdString' 
                      ORDER BY created_at DESC 
                      LIMIT 1";
    
    $checkResult = $conn->query($checkLogQuery);
    
    if ($checkResult && $checkResult->num_rows > 0) {
        // Update existing record
        $logRow = $checkResult->fetch_assoc();
        $logId = $logRow['id'];
        
        $remarkText = !empty($reason) 
            ? "Rejected by telecaller on " . date('Y-m-d H:i:s') . ". Reason: $reason"
            : "Rejected by telecaller on " . date('Y-m-d H:i:s');
        
        $updateLogQuery = "UPDATE call_logs_match_making 
                          SET match_status = 'Not Selected',
                              feedback = 'Not Selected',
                              remark = CONCAT(COALESCE(remark, ''), '\n$remarkText'),
                              updated_at = NOW()
                          WHERE id = $logId";
        
        if (!$conn->query($updateLogQuery)) {
            throw new Exception('Failed to update call_logs_match_making: ' . $conn->error);
        }
        
        $callLogsAffected = $conn->affected_rows;
    } else {
        // Insert new record
        // Get driver and job details
        $driverQuery = "SELECT name, unique_id FROM users WHERE id = $driverId LIMIT 1";
        $driverResult = $conn->query($driverQuery);
        
        if (!$driverResult || $driverResult->num_rows === 0) {
            throw new Exception('Driver not found');
        }
        
        $driver = $driverResult->fetch_assoc();
        $driverName = $conn->real_escape_string($driver['name']);
        $driverUnique = $conn->real_escape_string($driver['unique_id']);
        
        $remarkText = !empty($reason) 
            ? "Rejected by telecaller. Reason: $reason"
            : "Rejected by telecaller";
        
        $insertLogQuery = "INSERT INTO call_logs_match_making 
                          (caller_id, unique_id_driver, driver_name, job_id, 
                           feedback, match_status, remark, created_at, updated_at)
                          VALUES 
                          ($callerId, '$driverUnique', '$driverName', '$jobIdString',
                           'Not Selected', 'Not Selected', '$remarkText', NOW(), NOW())";
        
        if (!$conn->query($insertLogQuery)) {
            throw new Exception('Failed to insert into call_logs_match_making: ' . $conn->error);
        }
        
        $callLogsAffected = $conn->affected_rows;
    }
    
    // Commit transaction
    $conn->commit();
    
    sendSuccess([
        'applyJobsUpdated' => $applyJobsAffected,
        'callLogsUpdated' => $callLogsAffected,
        'driverId' => $driverId,
        'jobId' => $jobId,
        'jobIdString' => $jobIdString,
    ], 'Applicant rejected successfully');
    
} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    sendError('Error rejecting applicant: ' . $e->getMessage(), 500);
}
