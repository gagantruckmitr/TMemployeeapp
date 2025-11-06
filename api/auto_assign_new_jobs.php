<?php
/**
 * Auto-Assign New Jobs Script
 * This script should be called whenever a new job is created
 * It assigns the job to the next telecaller in round-robin order
 */

require_once 'config.php';

header('Content-Type: application/json');

// Get job_id from POST or GET
$jobId = isset($_POST['job_id']) ? intval($_POST['job_id']) : (isset($_GET['job_id']) ? intval($_GET['job_id']) : 0);

if ($jobId === 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'job_id parameter is required'
    ]);
    exit;
}

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    // Telecaller IDs for round-robin assignment
    $telecallerIds = [3, 4, 9, 11];
    $telecallerCount = count($telecallerIds);
    
    // Check if job exists and is unassigned
    $checkQuery = "SELECT id, job_id, assigned_to 
                   FROM jobs 
                   WHERE id = ? 
                   LIMIT 1";
    
    $stmt = $conn->prepare($checkQuery);
    $stmt->bind_param('i', $jobId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('Job not found');
    }
    
    $job = $result->fetch_assoc();
    $stmt->close();
    
    if ($job['assigned_to'] !== null && $job['assigned_to'] != 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Job already assigned',
            'job_id' => $job['job_id'],
            'assigned_to' => $job['assigned_to']
        ]);
        exit;
    }
    
    // Get the count of assigned jobs to determine next telecaller
    $countQuery = "SELECT COUNT(*) as total 
                   FROM jobs 
                   WHERE assigned_to IN (3, 4, 9, 11)";
    
    $countResult = $conn->query($countQuery);
    $totalAssigned = $countResult->fetch_assoc()['total'];
    
    // Calculate next telecaller in round-robin
    $telecallerIndex = $totalAssigned % $telecallerCount;
    $assignedTo = $telecallerIds[$telecallerIndex];
    
    // Assign the job
    $updateQuery = "UPDATE jobs 
                    SET assigned_to = ? 
                    WHERE id = ?";
    
    $stmt = $conn->prepare($updateQuery);
    $stmt->bind_param('ii', $assignedTo, $jobId);
    
    if (!$stmt->execute()) {
        throw new Exception('Failed to assign job: ' . $stmt->error);
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'message' => 'Job assigned successfully',
        'job_id' => $job['job_id'],
        'db_id' => $jobId,
        'assigned_to' => $assignedTo,
        'telecaller_index' => $telecallerIndex,
        'total_assigned_before' => $totalAssigned,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

if ($conn) {
    $conn->close();
}
?>
