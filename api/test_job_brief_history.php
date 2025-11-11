<?php
/**
 * Test script to debug the job brief history API
 * This will help identify the exact cause of the 500 error
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

header('Content-Type: text/plain');

echo "=== Job Brief History Debug Test ===\n\n";

if (!$conn) {
    echo "ERROR: Database connection not available\n";
    echo "Error: " . mysqli_connect_error() . "\n";
    exit;
}

echo "✓ Database connection successful\n\n";

// Get unique_id from parameter or use a test value
$uniqueId = isset($_GET['unique_id']) ? $conn->real_escape_string($_GET['unique_id']) : '';

if (empty($uniqueId)) {
    echo "Please provide unique_id parameter\n";
    echo "Example: ?unique_id=TM12345\n\n";
    
    // Show available unique_ids
    echo "Available unique_ids in database:\n";
    $sampleQuery = "SELECT DISTINCT unique_id FROM job_brief_table LIMIT 10";
    $sampleResult = $conn->query($sampleQuery);
    if ($sampleResult) {
        while ($row = $sampleResult->fetch_assoc()) {
            echo "  - " . $row['unique_id'] . "\n";
        }
    }
    exit;
}

echo "Testing with unique_id: $uniqueId\n\n";

try {
    // Step 1: Check table structure
    echo "Step 1: Checking table structure...\n";
    $structureQuery = "DESCRIBE job_brief_table";
    $structureResult = $conn->query($structureQuery);
    
    if ($structureResult) {
        echo "Table columns:\n";
        $columns = [];
        while ($col = $structureResult->fetch_assoc()) {
            $columns[] = $col['Field'];
            echo "  - {$col['Field']} ({$col['Type']})\n";
        }
        echo "\n";
        
        $hasCallRecording = in_array('call_recording', $columns);
        echo "call_recording column exists: " . ($hasCallRecording ? "YES" : "NO") . "\n\n";
    }
    
    // Step 2: Test the query
    echo "Step 2: Testing query...\n";
    $query = "SELECT * FROM job_brief_table WHERE unique_id = '$uniqueId' ORDER BY created_at DESC";
    echo "Query: $query\n\n";
    
    $result = $conn->query($query);
    
    if (!$result) {
        echo "ERROR: Query failed\n";
        echo "MySQL Error: " . $conn->error . "\n";
        echo "MySQL Error Number: " . $conn->errno . "\n";
        exit;
    }
    
    echo "✓ Query executed successfully\n";
    echo "Rows found: " . $result->num_rows . "\n\n";
    
    if ($result->num_rows == 0) {
        echo "No records found for this unique_id\n";
        exit;
    }
    
    // Step 3: Test formatting each row
    echo "Step 3: Testing row formatting...\n";
    $rowNum = 0;
    while ($row = $result->fetch_assoc()) {
        $rowNum++;
        echo "\nRow $rowNum:\n";
        echo "  ID: " . $row['id'] . "\n";
        echo "  Job ID: " . $row['job_id'] . "\n";
        echo "  Name: " . ($row['name'] ?? 'NULL') . "\n";
        echo "  Call Recording: " . (isset($row['call_recording']) ? ($row['call_recording'] ?? 'NULL') : 'COLUMN_MISSING') . "\n";
        
        // Try to format using the actual function
        try {
            // Simulate formatJobBriefRow
            $formatted = [
                'id' => (int)$row['id'],
                'uniqueId' => $row['unique_id'],
                'jobId' => $row['job_id'],
                'callerId' => $row['caller_id'] ? (int)$row['caller_id'] : null,
                'name' => $row['name'],
                'callRecording' => $row['call_recording'] ?? null,
            ];
            echo "  ✓ Formatting successful\n";
        } catch (Exception $e) {
            echo "  ✗ Formatting failed: " . $e->getMessage() . "\n";
        }
    }
    
    echo "\n=== Test Complete ===\n";
    echo "If you see this message, the API should work!\n";
    
} catch (Exception $e) {
    echo "\nEXCEPTION CAUGHT:\n";
    echo "Message: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . "\n";
    echo "Line: " . $e->getLine() . "\n";
}

$conn->close();
?>
