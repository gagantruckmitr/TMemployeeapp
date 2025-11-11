<?php
/**
 * Cleanup Script for Duplicate Job Briefs
 * This script removes duplicate entries in job_brief_table,
 * keeping only the most recent record for each unique_id + job_id combination
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode([
        'success' => false,
        'message' => 'Database connection not available'
    ]));
}

try {
    // Start transaction
    $conn->begin_transaction();
    
    // Find all duplicates
    $findDuplicatesQuery = "
        SELECT unique_id, job_id, COUNT(*) as count
        FROM job_brief_table
        GROUP BY unique_id, job_id
        HAVING COUNT(*) > 1
    ";
    
    $result = $conn->query($findDuplicatesQuery);
    
    if (!$result) {
        throw new Exception('Failed to find duplicates: ' . $conn->error);
    }
    
    $duplicates = [];
    while ($row = $result->fetch_assoc()) {
        $duplicates[] = $row;
    }
    
    $totalDuplicates = count($duplicates);
    $deletedCount = 0;
    $details = [];
    
    // For each duplicate group, keep only the most recent one
    foreach ($duplicates as $duplicate) {
        $uniqueId = $conn->real_escape_string($duplicate['unique_id']);
        $jobId = $conn->real_escape_string($duplicate['job_id']);
        
        // Get all IDs for this combination, ordered by updated_at DESC
        $getIdsQuery = "
            SELECT id, created_at, updated_at
            FROM job_brief_table
            WHERE unique_id = '$uniqueId' AND job_id = '$jobId'
            ORDER BY updated_at DESC, created_at DESC
        ";
        
        $idsResult = $conn->query($getIdsQuery);
        
        if (!$idsResult) {
            throw new Exception('Failed to get IDs: ' . $conn->error);
        }
        
        $ids = [];
        while ($row = $idsResult->fetch_assoc()) {
            $ids[] = $row;
        }
        
        // Keep the first one (most recent), delete the rest
        $keepId = $ids[0]['id'];
        $deleteIds = array_slice($ids, 1);
        
        if (!empty($deleteIds)) {
            $idsToDelete = array_map(function($item) { return $item['id']; }, $deleteIds);
            $idsString = implode(',', $idsToDelete);
            
            $deleteQuery = "DELETE FROM job_brief_table WHERE id IN ($idsString)";
            
            if (!$conn->query($deleteQuery)) {
                throw new Exception('Failed to delete duplicates: ' . $conn->error);
            }
            
            $deletedCount += count($deleteIds);
            
            $details[] = [
                'unique_id' => $uniqueId,
                'job_id' => $jobId,
                'kept_id' => $keepId,
                'deleted_ids' => $idsToDelete,
                'deleted_count' => count($deleteIds)
            ];
        }
    }
    
    // Commit transaction
    $conn->commit();
    
    echo json_encode([
        'success' => true,
        'message' => 'Cleanup completed successfully',
        'data' => [
            'duplicate_groups_found' => $totalDuplicates,
            'total_records_deleted' => $deletedCount,
            'details' => $details
        ]
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    
    echo json_encode([
        'success' => false,
        'message' => 'Error during cleanup: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
