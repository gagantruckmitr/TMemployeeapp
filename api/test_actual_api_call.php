<?php
/**
 * Test actual API call for TM2510HRTR11180
 */

// Get user_id from query parameter
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 1;
$targetTmid = 'TM2510HRTR11180';

echo "<h2>Testing Actual API Call for $targetTmid</h2>";
echo "<p>User ID: $userId</p>";

// Build API URL
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$path = dirname($_SERVER['PHP_SELF']);
$apiUrl = "$protocol://$host$path/phase2_jobs_api.php?user_id=$userId&filter=all";

echo "<h3>API Endpoint:</h3>";
echo "<a href='$apiUrl' target='_blank'>$apiUrl</a><br><br>";

// Make the API call
echo "<h3>Making API Call...</h3>";
$response = @file_get_contents($apiUrl);

if ($response === false) {
    echo "<p style='color: red;'>❌ Failed to call API</p>";
    exit;
}

$data = json_decode($response, true);

if (!$data || !isset($data['success'])) {
    echo "<p style='color: red;'>❌ Invalid API response</p>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    exit;
}

echo "<p style='color: green;'>✓ API call successful</p>";
echo "Total jobs returned: " . count($data['data']) . "<br><br>";

// Find the job for this TMID
$foundJob = null;
foreach ($data['data'] as $job) {
    if ($job['transporterTmid'] === $targetTmid) {
        $foundJob = $job;
        break;
    }
}

if ($foundJob) {
    echo "<h3>✓ Found Job for $targetTmid</h3>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f0f0f0;'><th>Field</th><th>Value</th></tr>";
    
    $importantFields = [
        'jobId' => 'Job ID',
        'transporterName' => 'Transporter Name',
        'transporterTmid' => 'Transporter TMID',
        'transporterCreatedAt' => 'Subscription Date (transporterCreatedAt)',
        'transporterProfileCompletion' => 'Profile Completion',
        'isAssignedToMe' => 'Is Assigned To Me'
    ];
    
    foreach ($importantFields as $key => $label) {
        $value = $foundJob[$key] ?? 'NOT SET';
        $highlight = ($key === 'transporterCreatedAt') ? 'background: yellow; font-weight: bold;' : '';
        echo "<tr>";
        echo "<td><strong>$label</strong></td>";
        echo "<td style='$highlight'>" . htmlspecialchars($value) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    echo "<br><h3>Analysis:</h3>";
    $subscriptionDate = $foundJob['transporterCreatedAt'] ?? '';
    
    if (empty($subscriptionDate)) {
        echo "<div style='background: #f8d7da; padding: 15px; border: 2px solid #dc3545; border-radius: 5px;'>";
        echo "<h4 style='margin: 0; color: #721c24;'>❌ PROBLEM FOUND!</h4>";
        echo "<p style='margin: 10px 0 0 0;'>The API is returning an EMPTY transporterCreatedAt value.</p>";
        echo "<p>This is why the app shows 'N/A'.</p>";
        echo "</div>";
    } else {
        echo "<div style='background: #d4edda; padding: 15px; border: 2px solid #28a745; border-radius: 5px;'>";
        echo "<h4 style='margin: 0; color: #155724;'>✓ API is returning correct data!</h4>";
        echo "<p style='margin: 10px 0 0 0;'>transporterCreatedAt: <strong>$subscriptionDate</strong></p>";
        
        // Calculate duration
        try {
            $createdDate = new DateTime($subscriptionDate);
            $now = new DateTime();
            $diff = $now->diff($createdDate);
            
            if ($diff->y > 0) {
                $duration = $diff->y . " year" . ($diff->y > 1 ? "s" : "");
            } elseif ($diff->m > 0) {
                $duration = $diff->m . " month" . ($diff->m > 1 ? "s" : "");
            } elseif ($diff->d > 0) {
                $duration = $diff->d . " day" . ($diff->d > 1 ? "s" : "");
            } else {
                $duration = "Today";
            }
            
            echo "<p>Should display: <strong style='font-size: 18px;'>Subscribed: $duration</strong></p>";
        } catch (Exception $e) {
            echo "<p>Could not calculate duration</p>";
        }
        
        echo "<p style='color: #856404; background: #fff3cd; padding: 10px; margin-top: 10px;'>";
        echo "⚠️ If your app still shows N/A, try:<br>";
        echo "1. Pull to refresh the job list<br>";
        echo "2. Close and reopen the app<br>";
        echo "3. Clear app cache/data";
        echo "</p>";
        echo "</div>";
    }
    
    echo "<br><h3>Full Job Data (JSON):</h3>";
    echo "<pre style='background: #f4f4f4; padding: 15px; overflow: auto;'>";
    echo json_encode($foundJob, JSON_PRETTY_PRINT);
    echo "</pre>";
    
} else {
    echo "<h3>❌ Job NOT found for $targetTmid</h3>";
    echo "<p>This job might not be assigned to user_id=$userId</p>";
    echo "<p>Available TMIDs in response:</p>";
    echo "<ul>";
    foreach ($data['data'] as $job) {
        echo "<li>" . $job['transporterTmid'] . " - " . $job['transporterName'] . " (Job: " . $job['jobId'] . ")</li>";
    }
    echo "</ul>";
}
?>
