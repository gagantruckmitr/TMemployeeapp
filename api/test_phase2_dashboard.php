<?php
/**
 * Test script for Phase 2 Dashboard Stats API
 */

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Testing Phase 2 Dashboard Stats API</h2>";

// Test 1: Check if config.php exists and loads
echo "<h3>Test 1: Config File</h3>";
if (file_exists('config.php')) {
    echo "✓ config.php exists<br>";
    require_once 'config.php';
    
    if (isset($conn)) {
        echo "✓ Database connection variable exists<br>";
        
        if ($conn && !$conn->connect_error) {
            echo "✓ Database connected successfully<br>";
            echo "Database: " . $conn->server_info . "<br>";
        } else {
            echo "✗ Database connection failed: " . ($conn ? $conn->connect_error : 'Connection object is null') . "<br>";
        }
    } else {
        echo "✗ \$conn variable not set<br>";
    }
} else {
    echo "✗ config.php not found<br>";
    exit;
}

// Test 2: Check if jobs table exists
echo "<h3>Test 2: Jobs Table</h3>";
$result = $conn->query("SHOW TABLES LIKE 'jobs'");
if ($result && $result->num_rows > 0) {
    echo "✓ jobs table exists<br>";
    
    // Get count
    $countResult = $conn->query("SELECT COUNT(*) as count FROM jobs");
    if ($countResult) {
        $count = $countResult->fetch_assoc()['count'];
        echo "✓ Total jobs: $count<br>";
    }
} else {
    echo "✗ jobs table not found<br>";
}

// Test 3: Check if users table exists
echo "<h3>Test 3: Users Table</h3>";
$result = $conn->query("SHOW TABLES LIKE 'users'");
if ($result && $result->num_rows > 0) {
    echo "✓ users table exists<br>";
    
    // Get count
    $countResult = $conn->query("SELECT COUNT(*) as count FROM users WHERE user_type = 'transporter'");
    if ($countResult) {
        $count = $countResult->fetch_assoc()['count'];
        echo "✓ Total transporters: $count<br>";
    }
} else {
    echo "✗ users table not found<br>";
}

// Test 4: Check if applyjobs table exists
echo "<h3>Test 4: Applyjobs Table</h3>";
$result = $conn->query("SHOW TABLES LIKE 'applyjobs'");
if ($result && $result->num_rows > 0) {
    echo "✓ applyjobs table exists<br>";
    
    // Get count
    $countResult = $conn->query("SELECT COUNT(*) as count FROM applyjobs");
    if ($countResult) {
        $count = $countResult->fetch_assoc()['count'];
        echo "✓ Total applications: $count<br>";
    }
} else {
    echo "⚠ applyjobs table not found (optional)<br>";
}

// Test 5: Test the actual API call
echo "<h3>Test 5: API Response</h3>";
echo "<pre>";

try {
    // Simulate the API call
    $stats = [];
    
    // Total jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs");
    $stats['totalJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    // Approved jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE status = '1'");
    $stats['approvedJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    // Pending jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE status = '0'");
    $stats['pendingJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    // Inactive jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE active_inactive = 0");
    $stats['inactiveJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    // Expired jobs
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs 
                            WHERE Application_Deadline IS NOT NULL 
                            AND Application_Deadline != '' 
                            AND STR_TO_DATE(Application_Deadline, '%Y-%m-%d') < CURDATE()");
    $stats['expiredJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    // Active transporters
    $result = $conn->query("SELECT COUNT(DISTINCT j.transporter_id) as count 
                            FROM jobs j
                            INNER JOIN users u ON j.transporter_id = u.id
                            WHERE j.status = '1' AND j.active_inactive = 1");
    $stats['activeTransporters'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    // Drivers applied
    $tableCheck = $conn->query("SHOW TABLES LIKE 'applyjobs'");
    if ($tableCheck && $tableCheck->num_rows > 0) {
        $result = $conn->query("SELECT COUNT(*) as count FROM applyjobs");
        $stats['driversApplied'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
        
        $result = $conn->query("SELECT COUNT(*) as count FROM applyjobs WHERE status = 'Interested'");
        $stats['totalMatches'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    } else {
        $stats['driversApplied'] = 0;
        $stats['totalMatches'] = 0;
    }
    
    // Total calls
    $callTableCheck = $conn->query("SHOW TABLES LIKE 'call_logs'");
    if ($callTableCheck && $callTableCheck->num_rows > 0) {
        $result = $conn->query("SELECT COUNT(*) as count FROM call_logs");
        $stats['totalCalls'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    } else {
        $stats['totalCalls'] = 0;
    }
    
    echo "✓ API data generated successfully:\n";
    echo json_encode([
        'success' => true,
        'message' => 'Dashboard stats fetched successfully',
        'data' => $stats
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage();
}

echo "</pre>";

echo "<h3>Test 6: Direct API Call</h3>";
echo "<a href='phase2_dashboard_stats_api.php' target='_blank'>Click here to test the actual API</a>";
?>
