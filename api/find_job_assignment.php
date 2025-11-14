<?php
/**
 * Find which telecaller has jobs for TM2510HRTR11180
 */

require_once 'config.php';

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

$targetTmid = 'TM2510HRTR11180';

echo "<h2>Finding Job Assignment for $targetTmid</h2>";

// Find jobs and their assignments
$query = "SELECT 
            j.job_id,
            j.job_title,
            j.assigned_to,
            j.status,
            j.Created_at,
            u.unique_id as transporter_tmid,
            u.name as transporter_name,
            a.name as assigned_to_name,
            a.email as assigned_to_email
          FROM jobs j
          LEFT JOIN users u ON j.transporter_id = u.id
          LEFT JOIN admins a ON j.assigned_to = a.id
          WHERE u.unique_id = '$targetTmid'
          ORDER BY j.Created_at DESC";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<h3>✓ Found " . $result->num_rows . " job(s) for $targetTmid</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Job ID</th><th>Job Title</th><th>Assigned To (ID)</th><th>Assigned To (Name)</th><th>Status</th><th>Posted Date</th></tr>";
    
    $assignedToIds = [];
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td><strong>" . $row['job_id'] . "</strong></td>";
        echo "<td>" . substr($row['job_title'], 0, 50) . "...</td>";
        echo "<td><strong style='color: blue;'>" . ($row['assigned_to'] ?? 'NULL') . "</strong></td>";
        echo "<td>" . ($row['assigned_to_name'] ?? 'Not Assigned') . "</td>";
        echo "<td>" . ($row['status'] == '1' ? 'Active' : 'Inactive') . "</td>";
        echo "<td>" . $row['Created_at'] . "</td>";
        echo "</tr>";
        
        if ($row['assigned_to']) {
            $assignedToIds[$row['assigned_to']] = $row['assigned_to_name'];
        }
    }
    echo "</table>";
    
    if (!empty($assignedToIds)) {
        echo "<br><h3>Test with these User IDs:</h3>";
        foreach ($assignedToIds as $id => $name) {
            $testUrl = "test_actual_api_call.php?user_id=$id";
            echo "<p>👤 <strong>$name</strong> (ID: $id)<br>";
            echo "<a href='$testUrl' target='_blank' style='background: #007bff; color: white; padding: 8px 15px; text-decoration: none; border-radius: 5px;'>Test API with user_id=$id</a></p>";
        }
    } else {
        echo "<br><p style='color: orange;'>⚠️ These jobs are NOT assigned to any telecaller!</p>";
        echo "<p>This is why they don't appear in the API response.</p>";
    }
} else {
    echo "<p style='color: red;'>❌ No jobs found for $targetTmid</p>";
}

// Also check what the app is using
echo "<br><h3>Current App Session Info:</h3>";
echo "<p>To find your actual user_id in the app:</p>";
echo "<ol>";
echo "<li>Check the app's login response</li>";
echo "<li>Or check the admins table for your telecaller account</li>";
echo "</ol>";

// Show all telecallers
echo "<h3>All Telecallers:</h3>";
$query = "SELECT id, name, email, mobile FROM admins WHERE role = 'telecaller' ORDER BY id";
$result = $conn->query($query);
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Mobile</th><th>Test API</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $testUrl = "test_actual_api_call.php?user_id=" . $row['id'];
        echo "<tr>";
        echo "<td><strong>" . $row['id'] . "</strong></td>";
        echo "<td>" . $row['name'] . "</td>";
        echo "<td>" . $row['email'] . "</td>";
        echo "<td>" . $row['mobile'] . "</td>";
        echo "<td><a href='$testUrl' target='_blank'>Test</a></td>";
        echo "</tr>";
    }
    echo "</table>";
}

$conn->close();
?>
