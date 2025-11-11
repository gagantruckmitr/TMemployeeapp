<?php
/**
 * Test script for transporter recording upload
 * This script tests the complete flow of uploading a transporter recording
 */

require_once 'config.php';

echo "<h2>Transporter Recording Upload Test</h2>";

// Step 1: Check if call_recording column exists in job_brief_table
echo "<h3>Step 1: Check Database Schema</h3>";
$checkQuery = "SHOW COLUMNS FROM job_brief_table LIKE 'call_recording'";
$result = $conn->query($checkQuery);

if ($result && $result->num_rows > 0) {
    echo "✓ Column 'call_recording' exists in job_brief_table<br>";
} else {
    echo "✗ Column 'call_recording' DOES NOT exist in job_brief_table<br>";
    echo "Run: <a href='add_call_recording_column_to_job_brief.php'>add_call_recording_column_to_job_brief.php</a><br>";
}

// Step 2: Check upload directories
echo "<h3>Step 2: Check Upload Directories</h3>";

// Check driver directory
$driverDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/driver/';
echo "<strong>Driver Directory:</strong><br>";
if (is_dir($driverDir)) {
    echo "✓ Directory exists: $driverDir<br>";
    if (is_writable($driverDir)) {
        echo "✓ Directory is writable<br>";
    } else {
        echo "✗ Directory is NOT writable<br>";
    }
} else {
    echo "✗ Directory does NOT exist<br>";
}

// Check transporter directory
$transporterDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/transporter/';
echo "<br><strong>Transporter Directory:</strong><br>";
if (is_dir($transporterDir)) {
    echo "✓ Directory exists: $transporterDir<br>";
    if (is_writable($transporterDir)) {
        echo "✓ Directory is writable<br>";
    } else {
        echo "✗ Directory is NOT writable<br>";
    }
} else {
    echo "✗ Directory does NOT exist<br>";
    echo "Creating directory...<br>";
    if (mkdir($transporterDir, 0755, true)) {
        echo "✓ Directory created successfully<br>";
    } else {
        echo "✗ Failed to create directory<br>";
    }
}

// Step 3: Test API endpoint
echo "<h3>Step 3: API Endpoint Test</h3>";
$apiUrl = "https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api.php";
echo "API URL: <a href='$apiUrl' target='_blank'>$apiUrl</a><br>";
echo "Method: POST<br>";
echo "Required fields:<br>";
echo "- job_id<br>";
echo "- caller_id<br>";
echo "- transporter_tmid (for transporter recordings)<br>";
echo "- recording (file)<br>";

// Step 4: Check recent job briefs
echo "<h3>Step 4: Recent Job Briefs</h3>";
$query = "SELECT id, unique_id, job_id, name, call_recording, created_at 
          FROM job_brief_table 
          ORDER BY created_at DESC 
          LIMIT 5";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Transporter TMID</th><th>Job ID</th><th>Name</th><th>Recording</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $hasRecording = !empty($row['call_recording']) ? '✓' : '✗';
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['unique_id']}</td>";
        echo "<td>{$row['job_id']}</td>";
        echo "<td>{$row['name']}</td>";
        echo "<td>$hasRecording " . ($row['call_recording'] ?? 'None') . "</td>";
        echo "<td>{$row['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No job briefs found<br>";
}

// Step 5: Instructions
echo "<h3>Step 5: Testing Instructions</h3>";
echo "<ol>";
echo "<li>Ensure the call_recording column exists (Step 1)</li>";
echo "<li>Ensure the upload directory is writable (Step 2)</li>";
echo "<li>Use the Flutter app to edit a transporter call record</li>";
echo "<li>Select a recording file</li>";
echo "<li>Click 'Update & Upload Recording'</li>";
echo "<li>Check the debug logs in the app console</li>";
echo "<li>Refresh this page to see if the recording was saved</li>";
echo "</ol>";

$conn->close();
?>
