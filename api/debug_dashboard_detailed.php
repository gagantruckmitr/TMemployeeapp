<?php
/**
 * Detailed Debug for Dashboard Stats API
 * Shows exactly where the error occurs
 */

// Enable ALL error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);

header('Content-Type: text/html; charset=utf-8');

echo "<h2>Detailed Dashboard Stats Debug</h2>";

// Step 1: Check if config.php exists
echo "<h3>Step 1: Check config.php</h3>";
if (file_exists('config.php')) {
    echo "✅ config.php exists<br>";
} else {
    echo "❌ config.php NOT FOUND<br>";
    exit;
}

// Step 2: Try to include config.php
echo "<h3>Step 2: Include config.php</h3>";
try {
    require_once 'config.php';
    echo "✅ config.php included successfully<br>";
} catch (Exception $e) {
    echo "❌ Error including config.php: " . $e->getMessage() . "<br>";
    exit;
}

// Step 3: Check database connection
echo "<h3>Step 3: Check Database Connection</h3>";
if (!isset($conn)) {
    echo "❌ \$conn variable not set<br>";
    exit;
}

if (!$conn) {
    echo "❌ \$conn is false/null<br>";
    exit;
}

if ($conn->connect_error) {
    echo "❌ Connection error: " . $conn->connect_error . "<br>";
    exit;
}

echo "✅ Database connected successfully<br>";
echo "Host: " . (defined('DB_HOST') ? DB_HOST : 'not defined') . "<br>";
echo "Database: " . (defined('DB_NAME') ? DB_NAME : 'not defined') . "<br>";

// Step 4: Test a simple query
echo "<h3>Step 4: Test Simple Query</h3>";
$result = $conn->query("SELECT 1 as test");
if ($result) {
    echo "✅ Simple query works<br>";
} else {
    echo "❌ Simple query failed: " . $conn->error . "<br>";
    exit;
}

// Step 5: Test with user_id = 3
echo "<h3>Step 5: Test Dashboard Queries with user_id = 3</h3>";
$userId = 3;

try {
    $stats = [];
    
    // Total jobs
    $sql = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId";
    echo "<p><strong>Query:</strong> $sql</p>";
    $result = $conn->query($sql);
    if ($result) {
        $stats['totalJobs'] = (int)$result->fetch_assoc()['count'];
        echo "✅ Total Jobs: " . $stats['totalJobs'] . "<br>";
    } else {
        echo "❌ Error: " . $conn->error . "<br>";
    }
    
    // Approved jobs
    $sql = "SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId AND status = '1'";
    echo "<p><strong>Query:</strong> $sql</p>";
    $result = $conn->query($sql);
    if ($result) {
        $stats['approvedJobs'] = (int)$result->fetch_assoc()['count'];
        echo "✅ Approved Jobs: " . $stats['approvedJobs'] . "<br>";
    } else {
        echo "❌ Error: " . $conn->error . "<br>";
    }
    
    // Active transporters
    $sql = "SELECT COUNT(DISTINCT transporter_id) as count 
            FROM jobs 
            WHERE assigned_to = $userId
            AND status = '1' AND active_inactive = 1 
            AND transporter_id IS NOT NULL";
    echo "<p><strong>Query:</strong> $sql</p>";
    $result = $conn->query($sql);
    if ($result) {
        $stats['activeTransporters'] = (int)$result->fetch_assoc()['count'];
        echo "✅ Active Transporters: " . $stats['activeTransporters'] . "<br>";
    } else {
        echo "❌ Error: " . $conn->error . "<br>";
    }
    
    // Driver applications
    $sql = "SELECT COUNT(DISTINCT a.driver_id) as count 
            FROM applyjobs a
            INNER JOIN jobs j ON j.id = a.job_id 
            AND j.transporter_id = a.contractor_id
            WHERE j.assigned_to = $userId";
    echo "<p><strong>Query:</strong> $sql</p>";
    $result = $conn->query($sql);
    if ($result) {
        $stats['driversApplied'] = (int)$result->fetch_assoc()['count'];
        echo "✅ Drivers Applied: " . $stats['driversApplied'] . "<br>";
    } else {
        echo "❌ Error: " . $conn->error . "<br>";
    }
    
    echo "<h3>Step 6: Build JSON Response</h3>";
    $response = [
        'success' => true,
        'message' => 'Dashboard stats fetched successfully',
        'data' => $stats
    ];
    
    echo "<pre>" . json_encode($response, JSON_PRETTY_PRINT) . "</pre>";
    
    echo "<h3>Step 7: Test JSON Encoding</h3>";
    $jsonOutput = json_encode($response);
    if ($jsonOutput === false) {
        echo "❌ JSON encoding failed: " . json_last_error_msg() . "<br>";
    } else {
        echo "✅ JSON encoding successful<br>";
        echo "Length: " . strlen($jsonOutput) . " bytes<br>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>Exception:</strong> " . $e->getMessage() . "</p>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}

echo "<h3>✅ All Steps Completed</h3>";
echo "<p>If you see this message, the API should work. The 500 error might be:</p>";
echo "<ul>";
echo "<li>A header issue (headers already sent)</li>";
echo "<li>A PHP version compatibility issue</li>";
echo "<li>A server configuration issue</li>";
echo "</ul>";
?>
