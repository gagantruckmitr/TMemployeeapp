<?php
/**
 * Debug subscription date for specific TMID
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

// Test with the TMID from the screenshot
$testTmid = 'TM2511MPTR16401';

echo "<h2>Debugging Subscription Date for $testTmid</h2>";

// Test 1: Check if this TMID exists in users table
echo "<h3>Test 1: User exists?</h3>";
$query = "SELECT id, unique_id, name, role, created_at FROM users WHERE unique_id = '$testTmid'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "✓ User found:<br>";
    echo "ID: " . $user['id'] . "<br>";
    echo "Name: " . $user['name'] . "<br>";
    echo "Role: " . $user['role'] . "<br>";
    echo "Created: " . $user['created_at'] . "<br>";
} else {
    echo "✗ User NOT found<br>";
}

// Test 2: Check if this TMID has any payments
echo "<h3>Test 2: Payments for this TMID</h3>";
$query = "SELECT * FROM payments WHERE unique_id = '$testTmid' ORDER BY created_at ASC";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ Found " . $result->num_rows . " payment(s):<br>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Payment Status</th><th>Payment Type</th><th>Amount</th><th>Created At</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td><strong>" . $row['payment_status'] . "</strong></td>";
        echo "<td>" . $row['payment_type'] . "</td>";
        echo "<td>" . $row['amount'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "✗ No payments found for this TMID<br>";
}

// Test 3: Check for captured payments specifically
echo "<h3>Test 3: Captured payments only</h3>";
$query = "SELECT created_at FROM payments WHERE unique_id = '$testTmid' AND payment_status = 'captured' ORDER BY created_at ASC LIMIT 1";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $payment = $result->fetch_assoc();
    echo "✓ Captured payment found:<br>";
    echo "Subscription Date: <strong>" . $payment['created_at'] . "</strong><br>";
    
    // Calculate duration
    $createdDate = new DateTime($payment['created_at']);
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
    
    echo "Duration: <strong>" . $duration . "</strong><br>";
} else {
    echo "✗ No captured payment found<br>";
}

// Test 4: Check what the jobs API would return
echo "<h3>Test 4: Jobs API simulation</h3>";
$query = "SELECT 
            j.job_id,
            u.unique_id as tmid,
            u.name,
            (SELECT p.created_at 
             FROM payments p 
             WHERE p.unique_id = u.unique_id 
             AND p.payment_status = 'captured' 
             ORDER BY p.created_at ASC 
             LIMIT 1) as subscription_date
          FROM jobs j
          LEFT JOIN users u ON j.transporter_id = u.id
          WHERE u.unique_id = '$testTmid'
          LIMIT 1";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $job = $result->fetch_assoc();
    echo "Job ID: " . $job['job_id'] . "<br>";
    echo "TMID: " . $job['tmid'] . "<br>";
    echo "Name: " . $job['name'] . "<br>";
    echo "Subscription Date from API: <strong>" . ($job['subscription_date'] ?? 'NULL') . "</strong><br>";
} else {
    echo "No jobs found for this transporter<br>";
}

// Test 5: Check the actual API response format
echo "<h3>Test 5: Actual API call test</h3>";
$userId = 1; // Default user ID for testing
$query = "SELECT j.*, u.unique_id as transporter_tmid
          FROM jobs j
          LEFT JOIN users u ON j.transporter_id = u.id
          WHERE u.unique_id = '$testTmid'
          AND j.assigned_to = $userId
          LIMIT 1";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $transporterTmid = $row['transporter_tmid'];
    
    // Simulate the API logic
    $transporterCreatedAt = '';
    if (!empty($transporterTmid)) {
        $paymentQuery = "SELECT created_at 
                        FROM payments 
                        WHERE unique_id = '" . $conn->real_escape_string($transporterTmid) . "' 
                        AND payment_status = 'captured' 
                        ORDER BY created_at ASC 
                        LIMIT 1";
        $paymentResult = $conn->query($paymentQuery);
        if ($paymentResult && $paymentResult->num_rows > 0) {
            $payment = $paymentResult->fetch_assoc();
            $transporterCreatedAt = $payment['created_at'] ?? '';
        }
    }
    
    echo "transporterCreatedAt value: <strong>" . ($transporterCreatedAt ?: 'EMPTY STRING') . "</strong><br>";
    
    if (empty($transporterCreatedAt)) {
        echo "<br><span style='color: red; font-weight: bold;'>⚠️ This is why it shows N/A - the transporterCreatedAt is empty!</span><br>";
    } else {
        echo "<br><span style='color: green; font-weight: bold;'>✓ Subscription date should display correctly</span><br>";
    }
} else {
    echo "No jobs found for this user/transporter combination<br>";
}

$conn->close();
?>
