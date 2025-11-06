<?php
/**
 * Test dashboard stats API with user_id parameter
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

header('Content-Type: application/json');

// Test with user ID 3
$testUserId = 3;

echo "<h2>Testing Dashboard Stats API with user_id = $testUserId</h2>";

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    echo "<h3>1. Testing Individual Queries</h3>";
    
    $userFilter = "assigned_to = $testUserId";
    
    // Test 1: Total jobs
    echo "<p><strong>Total Jobs Query:</strong></p>";
    $query1 = "SELECT COUNT(*) as count FROM jobs WHERE $userFilter";
    echo "<pre>$query1</pre>";
    $result1 = $conn->query($query1);
    if ($result1) {
        $count1 = $result1->fetch_assoc()['count'];
        echo "<p>✅ Result: $count1 jobs</p>";
    } else {
        echo "<p>❌ Error: " . $conn->error . "</p>";
    }
    
    // Test 2: Approved jobs
    echo "<p><strong>Approved Jobs Query:</strong></p>";
    $query2 = "SELECT COUNT(*) as count FROM jobs WHERE $userFilter AND status = '1'";
    echo "<pre>$query2</pre>";
    $result2 = $conn->query($query2);
    if ($result2) {
        $count2 = $result2->fetch_assoc()['count'];
        echo "<p>✅ Result: $count2 approved jobs</p>";
    } else {
        echo "<p>❌ Error: " . $conn->error . "</p>";
    }
    
    // Test 3: Active transporters
    echo "<p><strong>Active Transporters Query:</strong></p>";
    $query3 = "SELECT COUNT(DISTINCT transporter_id) as count 
               FROM jobs 
               WHERE $userFilter
               AND status = '1' AND active_inactive = 1 
               AND transporter_id IS NOT NULL";
    echo "<pre>$query3</pre>";
    $result3 = $conn->query($query3);
    if ($result3) {
        $count3 = $result3->fetch_assoc()['count'];
        echo "<p>✅ Result: $count3 active transporters</p>";
    } else {
        echo "<p>❌ Error: " . $conn->error . "</p>";
    }
    
    // Test 4: Check if applyjobs table exists
    echo "<p><strong>Check applyjobs table:</strong></p>";
    $tableCheck = $conn->query("SHOW TABLES LIKE 'applyjobs'");
    if ($tableCheck && $tableCheck->num_rows > 0) {
        echo "<p>✅ applyjobs table exists</p>";
        
        // Test driver applications query
        echo "<p><strong>Driver Applications Query:</strong></p>";
        $query4 = "SELECT COUNT(DISTINCT a.driver_id) as count 
                   FROM applyjobs a
                   INNER JOIN jobs j ON j.id = a.job_id 
                   AND j.transporter_id = a.contractor_id
                   WHERE j.assigned_to = $testUserId";
        echo "<pre>$query4</pre>";
        $result4 = $conn->query($query4);
        if ($result4) {
            $count4 = $result4->fetch_assoc()['count'];
            echo "<p>✅ Result: $count4 driver applications</p>";
        } else {
            echo "<p>❌ Error: " . $conn->error . "</p>";
        }
    } else {
        echo "<p>⚠️ applyjobs table does not exist</p>";
    }
    
    // Test 5: Now test the actual API endpoint
    echo "<h3>2. Testing Actual API Endpoint</h3>";
    $apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/phase2_dashboard_stats_api.php?user_id=$testUserId";
    echo "<p><strong>API URL:</strong> <a href='$apiUrl' target='_blank'>$apiUrl</a></p>";
    
    $ch = curl_init($apiUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p><strong>HTTP Status:</strong> $httpCode</p>";
    echo "<p><strong>Response:</strong></p>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    
    if ($httpCode == 200) {
        $data = json_decode($response, true);
        if ($data && isset($data['success']) && $data['success']) {
            echo "<p>✅ API call successful!</p>";
            echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
        } else {
            echo "<p>❌ API returned error</p>";
        }
    } else {
        echo "<p>❌ API returned HTTP $httpCode</p>";
    }
    
} catch (Exception $e) {
    echo "<p>❌ Exception: " . $e->getMessage() . "</p>";
}

if ($conn) {
    $conn->close();
}
?>
