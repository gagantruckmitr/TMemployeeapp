<?php
/**
 * Test Job Assignments Script
 * Verifies the round-robin assignment distribution
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    $telecallerIds = [3, 4, 9, 11];
    
    // Get total jobs
    $totalQuery = "SELECT COUNT(*) as total FROM jobs";
    $totalResult = $conn->query($totalQuery);
    $totalJobs = $totalResult->fetch_assoc()['total'];
    
    // Get unassigned jobs
    $unassignedQuery = "SELECT COUNT(*) as total 
                        FROM jobs 
                        WHERE assigned_to IS NULL OR assigned_to = 0";
    $unassignedResult = $conn->query($unassignedQuery);
    $unassignedJobs = $unassignedResult->fetch_assoc()['total'];
    
    // Get assignment distribution
    $distributionQuery = "SELECT 
                            assigned_to,
                            COUNT(*) as count,
                            GROUP_CONCAT(job_id ORDER BY id LIMIT 5) as sample_jobs
                          FROM jobs 
                          WHERE assigned_to IN (3, 4, 9, 11)
                          GROUP BY assigned_to 
                          ORDER BY assigned_to";
    
    $distributionResult = $conn->query($distributionQuery);
    $distribution = [];
    while ($row = $distributionResult->fetch_assoc()) {
        $distribution[] = $row;
    }
    
    // Get telecaller names
    $namesQuery = "SELECT id, name 
                   FROM admins 
                   WHERE id IN (3, 4, 9, 11)
                   ORDER BY id";
    
    $namesResult = $conn->query($namesQuery);
    $telecallers = [];
    while ($row = $namesResult->fetch_assoc()) {
        $telecallers[] = $row;
    }
    
    // Get recent assignments
    $recentQuery = "SELECT id, job_id, assigned_to, created_at 
                    FROM jobs 
                    WHERE assigned_to IN (3, 4, 9, 11)
                    ORDER BY id DESC 
                    LIMIT 20";
    
    $recentResult = $conn->query($recentQuery);
    $recentAssignments = [];
    while ($row = $recentResult->fetch_assoc()) {
        $recentAssignments[] = $row;
    }
    
    // Calculate balance
    $assignedCounts = array_column($distribution, 'count', 'assigned_to');
    $maxAssigned = !empty($assignedCounts) ? max($assignedCounts) : 0;
    $minAssigned = !empty($assignedCounts) ? min($assignedCounts) : 0;
    $difference = $maxAssigned - $minAssigned;
    
    $isBalanced = $difference <= 1; // Balanced if difference is 0 or 1
    
    echo json_encode([
        'success' => true,
        'summary' => [
            'total_jobs' => $totalJobs,
            'unassigned_jobs' => $unassignedJobs,
            'assigned_jobs' => $totalJobs - $unassignedJobs,
            'is_balanced' => $isBalanced,
            'max_difference' => $difference
        ],
        'telecallers' => $telecallers,
        'distribution' => $distribution,
        'recent_assignments' => $recentAssignments,
        'recommendation' => $unassignedJobs > 0 
            ? "Run api/assign_jobs_round_robin.php to assign $unassignedJobs unassigned jobs"
            : "All jobs are assigned!",
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
