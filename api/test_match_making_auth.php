<?php
/**
 * Test Script: Verify match-making authentication works with hyphenated format
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    $results = [];
    
    // Test 1: Check current tc_for values
    $checkQuery = "SELECT tc_for, COUNT(*) as count 
                   FROM admins 
                   WHERE role = 'telecaller' 
                   GROUP BY tc_for";
    
    $checkResult = $conn->query($checkQuery);
    $tcForValues = [];
    while ($row = $checkResult->fetch_assoc()) {
        $tcForValues[] = $row;
    }
    
    $results['current_tc_for_values'] = $tcForValues;
    
    // Test 2: Count match-making telecallers (with hyphen)
    $hyphenQuery = "SELECT COUNT(*) as count 
                    FROM admins 
                    WHERE role = 'telecaller' 
                    AND tc_for = 'match-making'";
    
    $hyphenResult = $conn->query($hyphenQuery);
    $hyphenCount = $hyphenResult->fetch_assoc()['count'];
    
    $results['match_making_with_hyphen'] = $hyphenCount;
    
    // Test 3: Count match_making telecallers (with underscore)
    $underscoreQuery = "SELECT COUNT(*) as count 
                        FROM admins 
                        WHERE role = 'telecaller' 
                        AND tc_for = 'match_making'";
    
    $underscoreResult = $conn->query($underscoreQuery);
    $underscoreCount = $underscoreResult->fetch_assoc()['count'];
    
    $results['match_making_with_underscore'] = $underscoreCount;
    
    // Test 4: Get sample telecaller records
    $sampleQuery = "SELECT id, name, mobile, tc_for 
                    FROM admins 
                    WHERE role = 'telecaller' 
                    AND (tc_for = 'match-making' OR tc_for = 'match_making')
                    LIMIT 5";
    
    $sampleResult = $conn->query($sampleQuery);
    $sampleRecords = [];
    while ($row = $sampleResult->fetch_assoc()) {
        $sampleRecords[] = $row;
    }
    
    $results['sample_records'] = $sampleRecords;
    
    // Test 5: Verify authentication query works
    $testMobile = '9999999999'; // Use a test mobile number
    $authQuery = "SELECT id, name, mobile, tc_for 
                  FROM admins 
                  WHERE mobile = '$testMobile' 
                  AND role = 'telecaller' 
                  AND (tc_for = 'match-making' OR tc_for = 'match_making')
                  LIMIT 1";
    
    $authResult = $conn->query($authQuery);
    $authTest = $authResult->num_rows > 0 ? $authResult->fetch_assoc() : null;
    
    $results['auth_query_test'] = [
        'test_mobile' => $testMobile,
        'found' => $authTest !== null,
        'user' => $authTest
    ];
    
    // Summary
    $results['summary'] = [
        'total_match_making_telecallers' => $hyphenCount + $underscoreCount,
        'needs_migration' => $underscoreCount > 0,
        'migration_script' => 'api/update_tc_for_to_hyphen.php',
        'recommendation' => $underscoreCount > 0 
            ? 'Run migration script to update underscore to hyphen format' 
            : 'All records already use hyphen format'
    ];
    
    echo json_encode([
        'success' => true,
        'results' => $results,
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
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
