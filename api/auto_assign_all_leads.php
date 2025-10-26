<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h1>Auto-Assign All Unassigned Leads</h1>";

// Get all telecallers
$result = $conn->query("SELECT id, name FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
$telecallers = [];
while ($row = $result->fetch_assoc()) {
    $telecallers[] = $row;
}

if (empty($telecallers)) {
    echo "<p style='color: red;'>No telecallers found!</p>";
    exit;
}

echo "<h2>Available Telecallers:</h2>";
echo "<ul>";
foreach ($telecallers as $tc) {
    echo "<li>ID: {$tc['id']} - {$tc['name']}</li>";
}
echo "</ul>";

// Get unassigned drivers
$result = $conn->query("
    SELECT COUNT(*) as count 
    FROM users 
    WHERE role = 'driver' 
    AND (assigned_to IS NULL OR assigned_to = 0 OR assigned_to = '')
");
$row = $result->fetch_assoc();
$unassignedCount = $row['count'];

echo "<h2>Unassigned Leads: $unassignedCount</h2>";

if ($unassignedCount == 0) {
    echo "<p style='color: green;'>All leads are already assigned!</p>";
    
    // Show current distribution
    echo "<h2>Current Distribution:</h2>";
    $result = $conn->query("
        SELECT 
            u.assigned_to,
            a.name as telecaller_name,
            COUNT(*) as count
        FROM users u
        LEFT JOIN admins a ON u.assigned_to = a.id
        WHERE u.role = 'driver'
        GROUP BY u.assigned_to, a.name
    ");
    echo "<table border='1'><tr><th>Telecaller ID</th><th>Name</th><th>Leads</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $tcId = $row['assigned_to'] ?: 'NULL';
        $tcName = $row['telecaller_name'] ?: 'Unassigned';
        echo "<tr><td>{$tcId}</td><td>{$tcName}</td><td>{$row['count']}</td></tr>";
    }
    echo "</table>";
    
    exit;
}

// Perform round-robin assignment (50 leads per telecaller)
echo "<h2>Assigning Leads...</h2>";

$telecallerCount = count($telecallers);
$leadsPerTelecaller = 50; // Assign only 50 leads to each telecaller
$totalToAssign = $telecallerCount * $leadsPerTelecaller;

echo "<p><strong>Strategy:</strong> Assigning top $leadsPerTelecaller most recent leads to each telecaller</p>";
echo "<p><strong>Total to assign:</strong> $totalToAssign leads ($leadsPerTelecaller × $telecallerCount telecallers)</p>";

$result = $conn->query("
    SELECT id 
    FROM users 
    WHERE role = 'driver' 
    AND (assigned_to IS NULL OR assigned_to = 0 OR assigned_to = '')
    ORDER BY Created_at DESC
    LIMIT $totalToAssign
");

$leads = [];
while ($row = $result->fetch_assoc()) {
    $leads[] = $row['id'];
}

$actualLeadsCount = count($leads);
echo "<p><strong>Found:</strong> $actualLeadsCount unassigned leads</p>";

$assignedCount = 0;
$assignmentsByTelecaller = array_fill_keys(array_column($telecallers, 'id'), 0);

// Round-robin: Lead1→TC1, Lead2→TC2, Lead3→TC3, Lead4→TC1, etc.
foreach ($leads as $index => $leadId) {
    $telecallerIndex = $index % $telecallerCount;
    $telecallerId = $telecallers[$telecallerIndex]['id'];
    
    // Only assign if this telecaller hasn't reached 50 leads yet
    if ($assignmentsByTelecaller[$telecallerId] < $leadsPerTelecaller) {
        $stmt = $conn->prepare("UPDATE users SET assigned_to = ?, Updated_at = NOW() WHERE id = ?");
        $stmt->bind_param("ii", $telecallerId, $leadId);
        
        if ($stmt->execute()) {
            $assignedCount++;
            $assignmentsByTelecaller[$telecallerId]++;
        }
    }
}

echo "<p style='color: green;'><strong>✓ Successfully assigned $assignedCount leads!</strong></p>";

echo "<h2>Assignment Distribution:</h2>";
echo "<table border='1'><tr><th>Telecaller ID</th><th>Name</th><th>Assigned Leads</th></tr>";
foreach ($telecallers as $tc) {
    $count = $assignmentsByTelecaller[$tc['id']];
    echo "<tr><td>{$tc['id']}</td><td>{$tc['name']}</td><td>$count</td></tr>";
}
echo "</table>";

// Verify final distribution
echo "<h2>Final Verification:</h2>";
$result = $conn->query("
    SELECT 
        u.assigned_to,
        a.name as telecaller_name,
        COUNT(*) as count
    FROM users u
    LEFT JOIN admins a ON u.assigned_to = a.id
    WHERE u.role = 'driver'
    GROUP BY u.assigned_to, a.name
");
echo "<table border='1'><tr><th>Telecaller ID</th><th>Name</th><th>Total Leads</th></tr>";
while ($row = $result->fetch_assoc()) {
    $tcId = $row['assigned_to'] ?: 'NULL';
    $tcName = $row['telecaller_name'] ?: 'Unassigned';
    echo "<tr><td>{$tcId}</td><td>{$tcName}</td><td>{$row['count']}</td></tr>";
}
echo "</table>";

$conn->close();

echo "<hr><p><strong>Completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><a href='test_leads_final.php'>Test Leads System</a> | <a href='../admin-panel/'>Go to Admin Panel</a></p>";
?>
