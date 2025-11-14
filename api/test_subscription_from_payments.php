<?php
/**
 * Test subscription date from payments table
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

echo "<h2>Testing Subscription Date from Payments Table</h2>";

// Test 1: Check payments table structure
echo "<h3>Test 1: Payments table structure</h3>";
$query = "SHOW COLUMNS FROM payments WHERE Field IN ('unique_id', 'payment_status', 'created_at')";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "✓ Required columns exist:<br>";
    while ($row = $result->fetch_assoc()) {
        echo "- " . $row['Field'] . " (" . $row['Type'] . ")<br>";
    }
} else {
    echo "✗ Required columns not found<br>";
}

// Test 2: Sample captured payments
echo "<h3>Test 2: Sample captured payments</h3>";
$query = "SELECT unique_id, payment_status, created_at 
          FROM payments 
          WHERE payment_status = 'captured' 
          ORDER BY created_at DESC 
          LIMIT 5";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>TMID</th><th>Payment Status</th><th>Subscription Date</th><th>Duration</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $createdDate = new DateTime($row['created_at']);
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
        
        echo "<tr>";
        echo "<td>" . $row['unique_id'] . "</td>";
        echo "<td>" . $row['payment_status'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td><strong>" . $duration . "</strong></td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No captured payments found<br>";
}

// Test 3: Join with jobs to see subscription dates
echo "<h3>Test 3: Jobs with subscription dates from payments</h3>";
$query = "SELECT 
            j.job_id,
            u.name as transporter_name,
            u.unique_id as tmid,
            (SELECT p.created_at 
             FROM payments p 
             WHERE p.unique_id = u.unique_id 
             AND p.payment_status = 'captured' 
             ORDER BY p.created_at ASC 
             LIMIT 1) as subscription_date
          FROM jobs j
          LEFT JOIN users u ON j.transporter_id = u.id
          WHERE u.unique_id IS NOT NULL
          LIMIT 5";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Job ID</th><th>Transporter</th><th>TMID</th><th>Subscription Date</th><th>Duration</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $duration = 'N/A';
        if (!empty($row['subscription_date'])) {
            $createdDate = new DateTime($row['subscription_date']);
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
        }
        
        echo "<tr>";
        echo "<td>" . $row['job_id'] . "</td>";
        echo "<td>" . $row['transporter_name'] . "</td>";
        echo "<td>" . $row['tmid'] . "</td>";
        echo "<td>" . ($row['subscription_date'] ?? 'NULL') . "</td>";
        echo "<td><strong>" . $duration . "</strong></td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No jobs found<br>";
}

// Test 4: Count transporters with and without captured payments
echo "<h3>Test 4: Statistics</h3>";
$query = "SELECT 
            COUNT(DISTINCT u.id) as total_transporters,
            COUNT(DISTINCT CASE WHEN p.payment_status = 'captured' THEN u.id END) as with_payment,
            COUNT(DISTINCT CASE WHEN p.payment_status IS NULL THEN u.id END) as without_payment
          FROM users u
          LEFT JOIN payments p ON u.unique_id = p.unique_id AND p.payment_status = 'captured'
          WHERE u.role = 'transporter'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $stats = $result->fetch_assoc();
    echo "Total Transporters: " . $stats['total_transporters'] . "<br>";
    echo "With Captured Payment: " . $stats['with_payment'] . "<br>";
    echo "Without Payment: " . $stats['without_payment'] . "<br>";
}

$conn->close();
?>
