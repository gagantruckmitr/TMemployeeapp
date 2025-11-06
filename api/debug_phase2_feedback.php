<?php
/**
 * Debug script for Phase 2 call feedback submission
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h2>Debug Phase 2 Call Feedback Submission</h2>";

// Get the raw POST data
$rawData = file_get_contents('php://input');

echo "<h3>1. Raw POST Data</h3>";
echo "<pre>" . htmlspecialchars($rawData) . "</pre>";

// Decode JSON
$data = json_decode($rawData, true);

echo "<h3>2. Decoded JSON Data</h3>";
echo "<pre>" . print_r($data, true) . "</pre>";

// Check database connection
echo "<h3>3. Database Connection</h3>";
if ($conn) {
    echo "<p style='color:green'>✓ Connected to database</p>";
    echo "<p>Database: " . $conn->get_server_info() . "</p>";
} else {
    echo "<p style='color:red'>✗ Database connection failed</p>";
    die();
}

// Check table exists
echo "<h3>4. Table Structure</h3>";
$query = "DESCRIBE call_logs_match_making";
$result = $conn->query($query);

if ($result) {
    echo "<table border='1' style='border-collapse:collapse'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['Field']}</td>";
        echo "<td>{$row['Type']}</td>";
        echo "<td>{$row['Null']}</td>";
        echo "<td>{$row['Key']}</td>";
        echo "<td>" . ($row['Default'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color:red'>✗ Table not found: " . $conn->error . "</p>";
}

// Process the data if it exists
if ($data) {
    echo "<h3>5. Processing Data</h3>";
    
    $callerId = isset($data['callerId']) ? (int)$data['callerId'] : 0;
    $uniqueIdTransporter = isset($data['uniqueIdTransporter']) && !empty($data['uniqueIdTransporter']) ? $conn->real_escape_string($data['uniqueIdTransporter']) : null;
    $uniqueIdDriver = isset($data['uniqueIdDriver']) && !empty($data['uniqueIdDriver']) ? $conn->real_escape_string($data['uniqueIdDriver']) : null;
    $driverName = isset($data['driverName']) && !empty($data['driverName']) ? $conn->real_escape_string($data['driverName']) : null;
    $transporterName = isset($data['transporterName']) && !empty($data['transporterName']) ? $conn->real_escape_string($data['transporterName']) : null;
    $feedback = isset($data['feedback']) && !empty($data['feedback']) ? $conn->real_escape_string($data['feedback']) : null;
    $matchStatus = isset($data['matchStatus']) && !empty($data['matchStatus']) ? $conn->real_escape_string($data['matchStatus']) : null;
    $transporterJobRemark = isset($data['transporterJobRemark']) ? $conn->real_escape_string($data['transporterJobRemark']) : '';
    $additionalNotes = isset($data['additionalNotes']) ? $conn->real_escape_string($data['additionalNotes']) : '';
    $jobId = isset($data['jobId']) && !empty($data['jobId']) ? $conn->real_escape_string($data['jobId']) : null;
    
    echo "<table border='1' style='border-collapse:collapse'>";
    echo "<tr><th>Field</th><th>Value</th><th>Type</th></tr>";
    echo "<tr><td>callerId</td><td>$callerId</td><td>" . gettype($callerId) . "</td></tr>";
    echo "<tr><td>uniqueIdTransporter</td><td>" . ($uniqueIdTransporter ?? 'NULL') . "</td><td>" . gettype($uniqueIdTransporter) . "</td></tr>";
    echo "<tr><td>uniqueIdDriver</td><td>" . ($uniqueIdDriver ?? 'NULL') . "</td><td>" . gettype($uniqueIdDriver) . "</td></tr>";
    echo "<tr><td>driverName</td><td>" . ($driverName ?? 'NULL') . "</td><td>" . gettype($driverName) . "</td></tr>";
    echo "<tr><td>transporterName</td><td>" . ($transporterName ?? 'NULL') . "</td><td>" . gettype($transporterName) . "</td></tr>";
    echo "<tr><td>feedback</td><td>" . ($feedback ?? 'NULL') . "</td><td>" . gettype($feedback) . "</td></tr>";
    echo "<tr><td>matchStatus</td><td>" . ($matchStatus ?? 'NULL') . "</td><td>" . gettype($matchStatus) . "</td></tr>";
    echo "<tr><td>jobId</td><td>" . ($jobId ?? 'NULL') . "</td><td>" . gettype($jobId) . "</td></tr>";
    echo "</table>";
    
    // Validation
    echo "<h3>6. Validation</h3>";
    $errors = [];
    
    if ($callerId === 0) {
        $errors[] = "Caller ID is required";
    }
    
    if (!$uniqueIdTransporter && !$uniqueIdDriver) {
        $errors[] = "Either transporter or driver ID is required";
    }
    
    if (!$feedback) {
        $errors[] = "Feedback is required";
    }
    
    if (!empty($errors)) {
        echo "<p style='color:red'>✗ Validation failed:</p>";
        echo "<ul>";
        foreach ($errors as $error) {
            echo "<li>$error</li>";
        }
        echo "</ul>";
    } else {
        echo "<p style='color:green'>✓ All validations passed</p>";
        
        // Build remark
        $remarkText = '';
        if (!empty($transporterJobRemark)) {
            $remarkText = $transporterJobRemark;
        }
        if (!empty($additionalNotes)) {
            $remarkText .= (!empty($remarkText) ? ' | ' : '') . $additionalNotes;
        }
        
        // Build INSERT query - use empty string for NOT NULL columns
        echo "<h3>7. SQL Query</h3>";
        $query = "INSERT INTO call_logs_match_making 
                  (caller_id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, feedback, match_status, remark, job_id, created_at, updated_at) 
                  VALUES 
                  ($callerId, " . 
                  ($uniqueIdTransporter ? "'$uniqueIdTransporter'" : "''") . ", " .
                  ($uniqueIdDriver ? "'$uniqueIdDriver'" : "''") . ", " .
                  ($driverName ? "'$driverName'" : "NULL") . ", " .
                  ($transporterName ? "'$transporterName'" : "NULL") . ", " .
                  "'$feedback', " . 
                  ($matchStatus ? "'$matchStatus'" : "NULL") . ", " .
                  (!empty($remarkText) ? "'$remarkText'" : "NULL") . ", " .
                  ($jobId ? "'$jobId'" : "NULL") . ", NOW(), NOW())";
        
        echo "<pre>" . htmlspecialchars($query) . "</pre>";
        
        // Execute query
        echo "<h3>8. Query Execution</h3>";
        if ($conn->query($query)) {
            echo "<p style='color:green'>✓ Successfully inserted feedback (ID: " . $conn->insert_id . ")</p>";
        } else {
            echo "<p style='color:red'>✗ Failed to insert: " . $conn->error . "</p>";
        }
    }
} else {
    echo "<h3>5. No POST Data</h3>";
    echo "<p>Send a POST request with JSON data to test the insertion.</p>";
    
    echo "<h3>Sample cURL Command:</h3>";
    echo "<pre>";
    echo "curl -X POST https://truckmitr.com/truckmitr-app/api/debug_phase2_feedback.php \\\n";
    echo "  -H 'Content-Type: application/json' \\\n";
    echo "  -d '{\n";
    echo "    \"callerId\": 1,\n";
    echo "    \"uniqueIdDriver\": \"TMDR00419\",\n";
    echo "    \"driverName\": \"Test Driver\",\n";
    echo "    \"feedback\": \"Interview Done\",\n";
    echo "    \"matchStatus\": \"Selected\",\n";
    echo "    \"additionalNotes\": \"Test feedback\",\n";
    echo "    \"jobId\": \"TMJB00418\"\n";
    echo "  }'";
    echo "</pre>";
}

echo "<hr><p><strong>Debug completed at " . date('Y-m-d H:i:s') . "</strong></p>";
?>
