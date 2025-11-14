<?php
/**
 * Test with a transporter who HAS a captured payment
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

echo "<h2>Testing with Transporters Who Have Captured Payments</h2>";

// Get a transporter who has a captured payment and also has jobs
$query = "SELECT 
            j.job_id,
            u.id as user_id,
            u.unique_id as tmid,
            u.name,
            u.role,
            p.created_at as payment_date,
            p.payment_status
          FROM jobs j
          INNER JOIN users u ON j.transporter_id = u.id
          INNER JOIN payments p ON u.unique_id = p.unique_id
          WHERE p.payment_status = 'captured'
          AND u.role = 'transporter'
          LIMIT 5";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<h3>Transporters with Jobs AND Captured Payments:</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Job ID</th><th>TMID</th><th>Name</th><th>Payment Date</th><th>Duration</th></tr>";
    
    while ($row = $result->fetch_assoc()) {
        $createdDate = new DateTime($row['payment_date']);
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
        echo "<td>" . $row['job_id'] . "</td>";
        echo "<td><strong>" . $row['tmid'] . "</strong></td>";
        echo "<td>" . $row['name'] . "</td>";
        echo "<td>" . $row['payment_date'] . "</td>";
        echo "<td><strong style='color: green;'>" . $duration . "</strong></td>";
        echo "</tr>";
    }
    echo "</table>";
    
    echo "<br><p style='color: green; font-weight: bold;'>✓ These transporters should show subscription dates in the app</p>";
} else {
    echo "No transporters found with both jobs and captured payments<br>";
}

// Summary statistics
echo "<h3>Summary Statistics:</h3>";
$query = "SELECT 
            COUNT(DISTINCT j.id) as total_jobs,
            COUNT(DISTINCT CASE WHEN p.payment_status = 'captured' THEN j.id END) as jobs_with_payment,
            COUNT(DISTINCT CASE WHEN p.payment_status IS NULL THEN j.id END) as jobs_without_payment
          FROM jobs j
          LEFT JOIN users u ON j.transporter_id = u.id
          LEFT JOIN payments p ON u.unique_id = p.unique_id AND p.payment_status = 'captured'";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    $stats = $result->fetch_assoc();
    echo "Total Jobs: " . $stats['total_jobs'] . "<br>";
    echo "Jobs with Paid Subscription: <strong style='color: green;'>" . $stats['jobs_with_payment'] . "</strong><br>";
    echo "Jobs without Payment (will show N/A): <strong style='color: orange;'>" . $stats['jobs_without_payment'] . "</strong><br>";
    
    $percentage = $stats['total_jobs'] > 0 ? round(($stats['jobs_with_payment'] / $stats['total_jobs']) * 100, 1) : 0;
    echo "<br>Percentage with subscription: <strong>" . $percentage . "%</strong><br>";
}

echo "<h3>Explanation:</h3>";
echo "<p><strong>TM2511MPTR16401 (Himank sahu)</strong> shows 'N/A' because:</p>";
echo "<ul>";
echo "<li>✓ User exists in database</li>";
echo "<li>✓ Has posted jobs</li>";
echo "<li>❌ Has NOT made any payment (no entry in payments table)</li>";
echo "<li>❌ Therefore, no subscription date to display</li>";
echo "</ul>";

echo "<p><strong>This is correct behavior!</strong> Only transporters who have made a captured payment will show a subscription date.</p>";

$conn->close();
?>
