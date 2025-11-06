<?php
/**
 * Test script to check job assignment
 */

require_once 'config.php';

$jobId = isset($_GET['job_id']) ? $_GET['job_id'] : 'TMJB00427';

echo "<h2>Job Assignment Check</h2>";
echo "Checking job: <strong>$jobId</strong><br><br>";

// Get job details
$query = "SELECT j.*, a.name as assigned_to_name, a.email as assigned_to_email
          FROM jobs j
          LEFT JOIN admins a ON j.assigned_to = a.id
          WHERE j.job_id = ?";

$stmt = $conn->prepare($query);
$stmt->bind_param("s", $jobId);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $job = $result->fetch_assoc();
    
    echo "<h3>Job Details:</h3>";
    echo "<table border='1' cellpadding='10'>";
    echo "<tr><th>Field</th><th>Value</th></tr>";
    echo "<tr><td>Job ID</td><td>" . $job['job_id'] . "</td></tr>";
    echo "<tr><td>Job Title</td><td>" . $job['job_title'] . "</td></tr>";
    echo "<tr><td>Assigned To (ID)</td><td>" . ($job['assigned_to'] ?? 'NULL') . "</td></tr>";
    echo "<tr><td>Assigned To (Name)</td><td>" . ($job['assigned_to_name'] ?? 'NULL') . "</td></tr>";
    echo "<tr><td>Assigned To (Email)</td><td>" . ($job['assigned_to_email'] ?? 'NULL') . "</td></tr>";
    echo "<tr><td>Status</td><td>" . ($job['status'] == '1' ? 'Approved' : 'Pending') . "</td></tr>";
    echo "<tr><td>Active</td><td>" . ($job['active_inactive'] == 1 ? 'Yes' : 'No') . "</td></tr>";
    echo "<tr><td>Created At</td><td>" . $job['Created_at'] . "</td></tr>";
    echo "</table>";
    
    // Get all telecallers
    echo "<br><h3>All Telecallers:</h3>";
    $tcQuery = "SELECT id, name, email FROM admins WHERE role = 'telecaller' OR role = 'Telecaller' ORDER BY name";
    $tcResult = $conn->query($tcQuery);
    
    if ($tcResult) {
        echo "<table border='1' cellpadding='10'>";
        echo "<tr><th>ID</th><th>Name</th><th>Email</th></tr>";
        while ($tc = $tcResult->fetch_assoc()) {
            $highlight = ($tc['id'] == $job['assigned_to']) ? ' style="background-color: #90EE90;"' : '';
            echo "<tr$highlight>";
            echo "<td>" . $tc['id'] . "</td>";
            echo "<td>" . $tc['name'] . "</td>";
            echo "<td>" . $tc['email'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        echo "<p><em>Green highlight = Currently assigned telecaller</em></p>";
    }
    
} else {
    echo "❌ Job not found: $jobId";
}

?>
