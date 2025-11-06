<?php
/**
 * Round Robin Job Assignment Script
 * Assigns all unassigned jobs to telecallers 3, 4, 9, 11 in rotation
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    // Telecaller IDs for round-robin assignment
    $telecallerIds = [3, 4, 9, 11];
    $telecallerCount = count($telecallerIds);
    
    // Start transaction
    $conn->begin_transaction();
    
    // Get all unassigned jobs (where assigned_to is NULL or 0)
    $getUnassignedQuery = "SELECT id, job_id 
                           FROM jobs 
                           WHERE (assigned_to IS NULL OR assigned_to = 0)
                           ORDER BY id ASC";
    
    $result = $conn->query($getUnassignedQuery);
    
    if (!$result) {
        throw new Exception('Failed to fetch unassigned jobs: ' . $conn->error);
    }
    
    $unassignedJobs = [];
    while ($row = $result->fetch_assoc()) {
        $unassignedJobs[] = $row;
    }
    
    $totalUnassigned = count($unassignedJobs);
    
    if ($totalUnassigned === 0) {
        echo json_encode([
            'success' => true,
            'message' => 'No unassigned jobs found',
            'total_unassigned' => 0,
            'assigned_count' => 0,
            'assignments' => []
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    // Assign jobs in round-robin fashion
    $assignments = [];
    $assignedCount = 0;
    
    foreach ($unassignedJobs as $index => $job) {
        // Calculate which telecaller to assign to (round-robin)
        $telecallerIndex = $index % $telecallerCount;
        $assignedTo = $telecallerIds[$telecallerIndex];
        
        // Update the job
        $updateQuery = "UPDATE jobs 
                        SET assigned_to = ? 
                        WHERE id = ?";
        
        $stmt = $conn->prepare($updateQuery);
        $stmt->bind_param('ii', $assignedTo, $job['id']);
        
        if ($stmt->execute()) {
            $assignedCount++;
            $assignments[] = [
                'job_id' => $job['job_id'],
                'db_id' => $job['id'],
                'assigned_to' => $assignedTo
            ];
        }
        
        $stmt->close();
    }
    
    // Commit transaction
    $conn->commit();
    
    // Get assignment summary
    $summaryQuery = "SELECT assigned_to, COUNT(*) as count 
                     FROM jobs 
                     WHERE assigned_to IN (3, 4, 9, 11)
                     GROUP BY assigned_to 
                     ORDER BY assigned_to";
    
    $summaryResult = $conn->query($summaryQuery);
    $summary = [];
    while ($row = $summaryResult->fetch_assoc()) {
        $summary[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Successfully assigned $assignedCount jobs in round-robin fashion",
        'total_unassigned' => $totalUnassigned,
        'assigned_count' => $assignedCount,
        'telecaller_ids' => $telecallerIds,
        'assignments' => $assignments,
        'summary' => $summary,
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
