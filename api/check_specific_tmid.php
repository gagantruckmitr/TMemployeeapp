<?php
/**
 * Check specific TMID: TM2510HRTR11180
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

$testTmid = 'TM2510HRTR11180';

echo "<h2>Checking TMID: $testTmid</h2>";

// Test 1: Check if user exists
echo "<h3>Test 1: User Information</h3>";
$query = "SELECT id, unique_id, name, role, created_at FROM users WHERE unique_id = '$testTmid'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Value</th></tr>";
    echo "<tr><td>User ID</td><td>" . $user['id'] . "</td></tr>";
    echo "<tr><td>TMID</td><td><strong>" . $user['unique_id'] . "</strong></td></tr>";
    echo "<tr><td>Name</td><td>" . $user['name'] . "</td></tr>";
    echo "<tr><td>Role</td><td>" . $user['role'] . "</td></tr>";
    echo "<tr><td>Registration Date</td><td>" . $user['created_at'] . "</td></tr>";
    echo "</table>";
} else {
    echo "❌ User NOT found<br>";
    exit;
}

// Test 2: Check for payments
echo "<h3>Test 2: Payment Information</h3>";
$query = "SELECT * FROM payments WHERE unique_id = '$testTmid' ORDER BY created_at ASC";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ Found " . $result->num_rows . " payment(s):<br><br>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Payment Status</th><th>Payment Type</th><th>Amount</th><th>Created At</th><th>Start</th><th>End</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $startDate = !empty($row['start_at']) ? date('Y-m-d H:i:s', $row['start_at']) : 'N/A';
        $endDate = !empty($row['end_at']) ? date('Y-m-d H:i:s', $row['end_at']) : 'N/A';
        
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td><strong style='color: " . ($row['payment_status'] == 'captured' ? 'green' : 'orange') . ";'>" . $row['payment_status'] . "</strong></td>";
        echo "<td>" . $row['payment_type'] . "</td>";
        echo "<td>₹" . $row['amount'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td>" . $startDate . "</td>";
        echo "<td>" . $endDate . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "❌ No payments found<br>";
}

// Test 3: Check for captured payments specifically
echo "<h3>Test 3: Captured Payment (Subscription Date)</h3>";
$query = "SELECT created_at FROM payments WHERE unique_id = '$testTmid' AND payment_status = 'captured' ORDER BY created_at ASC LIMIT 1";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $payment = $result->fetch_assoc();
    $subscriptionDate = $payment['created_at'];
    
    echo "✅ <strong style='color: green;'>Captured payment found!</strong><br>";
    echo "Subscription Date: <strong>" . $subscriptionDate . "</strong><br><br>";
    
    // Calculate duration
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
    
    echo "<div style='background: #d4edda; padding: 15px; border: 2px solid #28a745; border-radius: 5px;'>";
    echo "<h4 style='margin: 0; color: #155724;'>Expected Display in App:</h4>";
    echo "<p style='font-size: 18px; margin: 10px 0 0 0;'><strong>Subscribed: " . $duration . "</strong></p>";
    echo "</div>";
} else {
    echo "❌ No captured payment found<br>";
    echo "<div style='background: #fff3cd; padding: 15px; border: 2px solid #ffc107; border-radius: 5px;'>";
    echo "<h4 style='margin: 0; color: #856404;'>Expected Display in App:</h4>";
    echo "<p style='font-size: 18px; margin: 10px 0 0 0;'><strong>Subscribed: N/A</strong></p>";
    echo "</div>";
}

// Test 4: Check if this user has any jobs
echo "<h3>Test 4: Jobs Posted</h3>";
$query = "SELECT job_id, job_title, Created_at, status FROM jobs WHERE transporter_id = (SELECT id FROM users WHERE unique_id = '$testTmid') ORDER BY Created_at DESC LIMIT 5";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ Found " . $result->num_rows . " job(s):<br><br>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Job ID</th><th>Job Title</th><th>Posted Date</th><th>Status</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td><strong>" . $row['job_id'] . "</strong></td>";
        echo "<td>" . $row['job_title'] . "</td>";
        echo "<td>" . $row['Created_at'] . "</td>";
        echo "<td>" . ($row['status'] == '1' ? 'Active' : 'Inactive') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No jobs found for this transporter<br>";
}

// Test 5: Simulate API response
echo "<h3>Test 5: API Response Simulation</h3>";
$query = "SELECT 
            (SELECT p.created_at 
             FROM payments p 
             WHERE p.unique_id = '$testTmid' 
             AND p.payment_status = 'captured' 
             ORDER BY p.created_at ASC 
             LIMIT 1) as transporterCreatedAt";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    echo "API will return:<br>";
    echo "<code style='background: #f4f4f4; padding: 10px; display: block; margin: 10px 0;'>";
    echo "\"transporterCreatedAt\": \"" . ($row['transporterCreatedAt'] ?? '') . "\"";
    echo "</code>";
    
    if (empty($row['transporterCreatedAt'])) {
        echo "<p style='color: red;'>⚠️ Empty value - will show N/A in app</p>";
    } else {
        echo "<p style='color: green;'>✓ Has value - will show subscription duration in app</p>";
    }
}

$conn->close();
?>
