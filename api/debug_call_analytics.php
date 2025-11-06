<?php
/**
 * Debug Call Analytics API
 * Test the call analytics queries
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    // Test 1: Check if table exists and has data
    $tableCheck = $conn->query("SHOW TABLES LIKE 'call_logs_match_making'");
    $tableExists = $tableCheck->num_rows > 0;
    
    // Test 2: Count total records
    $totalQuery = "SELECT COUNT(*) as total FROM call_logs_match_making";
    $totalResult = $conn->query($totalQuery);
    $totalRecords = $totalResult->fetch_assoc()['total'];
    
    // Test 3: Get sample data
    $sampleQuery = "SELECT * FROM call_logs_match_making LIMIT 5";
    $sampleResult = $conn->query($sampleQuery);
    $sampleData = [];
    while ($row = $sampleResult->fetch_assoc()) {
        $sampleData[] = $row;
    }
    
    // Test 4: Check caller_id values
    $callerIdsQuery = "SELECT DISTINCT caller_id FROM call_logs_match_making";
    $callerIdsResult = $conn->query($callerIdsQuery);
    $callerIds = [];
    while ($row = $callerIdsResult->fetch_assoc()) {
        $callerIds[] = $row['caller_id'];
    }
    
    // Test 5: Test with caller_id filter
    $testCallerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    $filteredCount = 0;
    if ($testCallerId > 0) {
        $filteredQuery = "SELECT COUNT(*) as total FROM call_logs_match_making WHERE caller_id = $testCallerId";
        $filteredResult = $conn->query($filteredQuery);
        $filteredCount = $filteredResult->fetch_assoc()['total'];
    }
    
    echo json_encode([
        'success' => true,
        'debug' => [
            'tableExists' => $tableExists,
            'totalRecords' => (int)$totalRecords,
            'sampleData' => $sampleData,
            'distinctCallerIds' => $callerIds,
            'testCallerId' => $testCallerId,
            'filteredCount' => (int)$filteredCount,
        ]
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

$conn->close();
