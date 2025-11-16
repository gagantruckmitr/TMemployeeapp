<?php
/**
 * Test Complete Feedback Flow
 * 1. Check if feedback exists in database
 * 2. Test API response
 * 3. Verify data structure
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h2>Testing Feedback Flow</h2>";
echo "<hr>";

// Test parameters
$jobId = 'TMJB00418'; // Change to your test job ID
$driverTmid = 'TM2511UPDR15657'; // Change to a driver who has feedback

echo "<h3>Step 1: Check Database for Feedback</h3>";
echo "<p>Job ID: <strong>$jobId</strong></p>";
echo "<p>Driver TMID: <strong>$driverTmid</strong></p>";

// Check call_logs_match_making table
$query = "SELECT * FROM call_logs_match_making 
          WHERE unique_id_driver = '$driverTmid' 
          AND job_id = '$jobId' 
          ORDER BY created_at DESC 
          LIMIT 1";

echo "<p>Query: <code>$query</code></p>";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<p style='color: green;'>✓ Feedback found in database!</p>";
    $row = $result->fetch_assoc();
    
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Field</th><th>Value</th></tr>";
    foreach ($row as $key => $value) {
        $highlight = in_array($key, ['feedback', 'match_status', 'remark']) ? 'background-color: yellow;' : '';
        echo "<tr style='$highlight'><td><strong>$key</strong></td><td>" . htmlspecialchars($value ?? 'NULL') . "</td></tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>✗ No feedback found in database</p>";
    echo "<p>SQL Error: " . $conn->error . "</p>";
}

echo "<hr>";
echo "<h3>Step 2: Test API Response</h3>";

// Call the API
$apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/phase2_job_applicants_api.php?job_id=" . urlencode($jobId);
echo "<p>API URL: <code>$apiUrl</code></p>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p>HTTP Status: <strong>$httpCode</strong></p>";

if ($response === false) {
    echo "<p style='color: red;'>✗ API request failed</p>";
    exit;
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    echo "<p style='color: red;'>✗ Invalid JSON response</p>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    exit;
}

if (!isset($data['success']) || !$data['success']) {
    echo "<p style='color: red;'>✗ API returned error</p>";
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    exit;
}

echo "<p style='color: green;'>✓ API request successful</p>";

// Find the specific driver in the response
$applicants = $data['data']['applicants'] ?? [];
$foundDriver = null;

foreach ($applicants as $applicant) {
    if ($applicant['driverTmid'] === $driverTmid) {
        $foundDriver = $applicant;
        break;
    }
}

echo "<hr>";
echo "<h3>Step 3: Verify Driver Data</h3>";

if ($foundDriver) {
    echo "<p style='color: green;'>✓ Driver found in API response</p>";
    echo "<p>Driver Name: <strong>" . htmlspecialchars($foundDriver['name']) . "</strong></p>";
    
    echo "<h4>Feedback Fields:</h4>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Field</th><th>Value</th><th>Status</th></tr>";
    
    $feedbackFields = [
        'callFeedback' => $foundDriver['callFeedback'] ?? null,
        'matchStatus' => $foundDriver['matchStatus'] ?? null,
        'feedbackNotes' => $foundDriver['feedbackNotes'] ?? null,
        'transporterTmid' => $foundDriver['transporterTmid'] ?? null,
        'transporterName' => $foundDriver['transporterName'] ?? null,
    ];
    
    $allPresent = true;
    foreach ($feedbackFields as $field => $value) {
        $status = $value !== null ? '✓ Present' : '✗ Missing';
        $color = $value !== null ? 'green' : 'red';
        $displayValue = $value !== null ? htmlspecialchars($value) : '<em>null</em>';
        echo "<tr><td><strong>$field</strong></td><td>$displayValue</td><td style='color: $color;'>$status</td></tr>";
        if ($value === null && in_array($field, ['callFeedback', 'matchStatus', 'feedbackNotes'])) {
            $allPresent = false;
        }
    }
    echo "</table>";
    
    echo "<hr>";
    if ($allPresent || $feedbackFields['callFeedback'] !== null) {
        echo "<h3 style='color: green;'>✓ SUCCESS: Feedback data is present in API response!</h3>";
    } else {
        echo "<h3 style='color: orange;'>⚠ WARNING: Feedback fields are null (no feedback submitted yet)</h3>";
    }
    
    echo "<hr>";
    echo "<h4>Complete Driver Data:</h4>";
    echo "<pre>" . json_encode($foundDriver, JSON_PRETTY_PRINT) . "</pre>";
    
} else {
    echo "<p style='color: red;'>✗ Driver not found in API response</p>";
    echo "<p>Available drivers:</p>";
    echo "<ul>";
    foreach ($applicants as $applicant) {
        echo "<li>" . htmlspecialchars($applicant['name']) . " (" . htmlspecialchars($applicant['driverTmid']) . ")</li>";
    }
    echo "</ul>";
}

echo "<hr>";
echo "<h3>Step 4: Flutter Model Compatibility Check</h3>";

if ($foundDriver) {
    $requiredFields = [
        'jobId', 'jobTitle', 'contractorId', 'transporterTmid', 'transporterName',
        'driverId', 'driverTmid', 'name', 'mobile', 'email', 'city', 'state',
        'vehicleType', 'drivingExperience', 'licenseType', 'licenseNumber',
        'preferredLocation', 'aadharNumber', 'panNumber', 'gstNumber', 'status',
        'createdAt', 'updatedAt', 'appliedAt', 'profileCompletion',
        'subscriptionAmount', 'subscriptionStartDate', 'subscriptionEndDate',
        'subscriptionStatus', 'callFeedback', 'matchStatus', 'feedbackNotes'
    ];
    
    $missingFields = [];
    foreach ($requiredFields as $field) {
        if (!array_key_exists($field, $foundDriver)) {
            $missingFields[] = $field;
        }
    }
    
    if (empty($missingFields)) {
        echo "<p style='color: green;'>✓ All required fields present for Flutter model</p>";
    } else {
        echo "<p style='color: red;'>✗ Missing fields:</p>";
        echo "<ul>";
        foreach ($missingFields as $field) {
            echo "<li style='color: red;'>$field</li>";
        }
        echo "</ul>";
    }
}

?>
