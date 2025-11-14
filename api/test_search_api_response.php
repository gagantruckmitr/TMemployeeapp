<?php
/**
 * Test Search API Response
 * Check what the search API actually returns
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h2>Test Search API Response</h2>";

// Test with user_id = 3 (Pooja Pal)
$testUserId = 3;
$testQuery = "driver";

echo "<h3>Testing with User ID: $testUserId (Pooja Pal)</h3>";
echo "<p>Search Query: '$testQuery'</p>";

$conn = getDBConnection();

if (!$conn) {
    die("Database connection failed");
}

// Simulate the exact query from the search API
$searchQuery = $conn->real_escape_string($testQuery);

$query = "SELECT  
    j.*,
    COALESCE(vt.vehicle_name, j.vehicle_type) as vehicle_type_name,
    u.name as transporter_name,
    u.unique_id as transporter_tmid,
    u.mobile as transporter_phone,
    u.city as transporter_city,
    u.states as transporter_state_id,
    a.name as assigned_to_name,
    a.id as admin_id_check
FROM jobs j
LEFT JOIN vehicle_type vt ON j.vehicle_type = vt.id
LEFT JOIN users u ON j.transporter_id = u.id
LEFT JOIN admins a ON j.assigned_to = a.id
WHERE 1=1
AND (
    j.job_id LIKE '%$searchQuery%' OR
    j.job_title LIKE '%$searchQuery%' OR
    j.job_location LIKE '%$searchQuery%' OR
    j.Job_Description LIKE '%$searchQuery%' OR
    u.name LIKE '%$searchQuery%' OR
    u.unique_id LIKE '%$searchQuery%' OR
    u.mobile LIKE '%$searchQuery%' OR
    u.city LIKE '%$searchQuery%' OR
    COALESCE(vt.vehicle_name, j.vehicle_type) LIKE '%$searchQuery%'
)
ORDER BY j.Created_at DESC 
LIMIT 10";

$result = $conn->query($query);

if (!$result) {
    die("Query failed: " . $conn->error);
}

echo "<h3>SQL Query Results:</h3>";
echo "<table border='1' cellpadding='5' style='border-collapse: collapse; font-size: 12px;'>";
echo "<tr style='background: #f0f0f0;'>";
echo "<th>Job ID</th><th>Job Title</th><th>assigned_to</th><th>assigned_to_name</th><th>admin_id_check</th><th>Match User?</th>";
echo "</tr>";

$jobs = [];
while ($row = $result->fetch_assoc()) {
    $assignedTo = !empty($row['assigned_to']) ? (int)$row['assigned_to'] : null;
    $assignedToName = $row['assigned_to_name'] ?? null;
    $isMatchingUser = ($assignedTo === $testUserId);
    
    $rowColor = $isMatchingUser ? '#e0ffe0' : '#ffe0e0';
    
    echo "<tr style='background: $rowColor;'>";
    echo "<td>" . htmlspecialchars($row['job_id']) . "</td>";
    echo "<td>" . htmlspecialchars(substr($row['job_title'], 0, 30)) . "</td>";
    echo "<td><strong>" . ($assignedTo ?? 'NULL') . "</strong></td>";
    echo "<td><strong>" . htmlspecialchars($assignedToName ?? 'NULL') . "</strong></td>";
    echo "<td>" . htmlspecialchars($row['admin_id_check'] ?? 'NULL') . "</td>";
    echo "<td>" . ($isMatchingUser ? '✓ YES' : '✗ NO') . "</td>";
    echo "</tr>";
    
    // Build the API response format
    $jobs[] = [
        'jobId' => $row['job_id'],
        'jobTitle' => $row['job_title'],
        'assignedTo' => $assignedTo,
        'assignedToName' => $assignedToName,
    ];
}

echo "</table>";

echo "<h3>API Response Format (JSON):</h3>";
echo "<pre style='background: #f5f5f5; padding: 10px; border: 1px solid #ddd;'>";
echo json_encode(['success' => true, 'data' => $jobs], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
echo "</pre>";

echo "<h3>Type Information:</h3>";
echo "<ul>";
foreach ($jobs as $job) {
    echo "<li>Job {$job['jobId']}: assignedTo type = " . gettype($job['assignedTo']) . ", value = " . var_export($job['assignedTo'], true) . "</li>";
}
echo "</ul>";

?>
