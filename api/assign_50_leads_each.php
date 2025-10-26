<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h1>🎯 Assign 50 Leads to Each Telecaller</h1>";
echo "<p style='background: #e3f2fd; padding: 15px; border-left: 4px solid #2196F3;'>";
echo "<strong>Strategy:</strong> Round-robin assignment of the <strong>50 most recent</strong> leads to each telecaller<br>";
echo "<strong>Example:</strong> Lead1→Pooja, Lead2→Tanisha, Lead3→Numan, Lead4→Pooja, Lead5→Tanisha, etc.";
echo "</p>";

// Get telecallers
$result = $conn->query("SELECT id, name, email FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
$telecallers = [];
while ($row = $result->fetch_assoc()) {
    $telecallers[] = $row;
}

if (empty($telecallers)) {
    echo "<p style='color: red;'><strong>ERROR: No telecallers found!</strong></p>";
    exit;
}

$telecallerCount = count($telecallers);
$leadsPerTelecaller = 50;
$totalToAssign = $telecallerCount * $leadsPerTelecaller;

echo "<h2>📋 Telecallers ($telecallerCount)</h2>";
echo "<table border='1' style='border-collapse: collapse;'>";
echo "<tr style='background: #f5f5f5;'><th style='padding: 8px;'>ID</th><th style='padding: 8px;'>Name</th><th style='padding: 8px;'>Email</th><th style='padding: 8px;'>Will Get</th></tr>";
foreach ($telecallers as $tc) {
    echo "<tr><td style='padding: 8px;'>{$tc['id']}</td><td style='padding: 8px;'>{$tc['name']}</td><td style='padding: 8px;'>{$tc['email']}</td><td style='padding: 8px; text-align: center;'><strong>50 leads</strong></td></tr>";
}
echo "</table>";

// Check current status
$result = $conn->query("
    SELECT COUNT(*) as count 
    FROM users 
    WHERE role = 'driver' 
    AND (assigned_to IS NULL OR assigned_to = 0 OR assigned_to = '')
");
$row = $result->fetch_assoc();
$unassignedCount = $row['count'];

echo "<h2>📊 Current Status</h2>";
echo "<table border='1' style='border-collapse: collapse;'>";
echo "<tr style='background: #f5f5f5;'><th style='padding: 8px;'>Metric</th><th style='padding: 8px;'>Count</th></tr>";
echo "<tr><td style='padding: 8px;'>Unassigned Leads</td><td style='padding: 8px; text-align: center;'><strong>$unassignedCount</strong></td></tr>";
echo "<tr><td style='padding: 8px;'>Leads to Assign</td><td style='padding: 8px; text-align: center;'><strong>$totalToAssign</strong> (50 × $telecallerCount)</td></tr>";
echo "<tr><td style='padding: 8px;'>Will Remain Unassigned</td><td style='padding: 8px; text-align: center;'><strong>" . max(0, $unassignedCount - $totalToAssign) . "</strong></td></tr>";
echo "</table>";

if ($unassignedCount < $totalToAssign) {
    echo "<p style='background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107;'>";
    echo "⚠️ <strong>Note:</strong> Only $unassignedCount unassigned leads available. Will assign all of them.";
    echo "</p>";
}

// Show what will be assigned
echo "<h2>🔍 Preview: Top 10 Leads to be Assigned</h2>";
$result = $conn->query("
    SELECT 
        u.id,
        u.name,
        u.mobile,
        u.Created_at
    FROM users u
    WHERE u.role = 'driver'
    AND (u.assigned_to IS NULL OR u.assigned_to = 0 OR u.assigned_to = '')
    ORDER BY u.Created_at DESC
    LIMIT 10
");

echo "<table border='1' style='border-collapse: collapse;'>";
echo "<tr style='background: #f5f5f5;'><th style='padding: 8px;'>Position</th><th style='padding: 8px;'>Lead ID</th><th style='padding: 8px;'>Name</th><th style='padding: 8px;'>Mobile</th><th style='padding: 8px;'>Will Go To</th><th style='padding: 8px;'>Registered</th></tr>";

$position = 1;
while ($row = $result->fetch_assoc()) {
    $telecallerIndex = ($position - 1) % $telecallerCount;
    $assignedTo = $telecallers[$telecallerIndex]['name'];
    $bgColor = $position <= 3 ? '#e8f5e9' : '';
    
    echo "<tr style='background: $bgColor;'>";
    echo "<td style='padding: 8px; text-align: center;'>$position</td>";
    echo "<td style='padding: 8px;'>{$row['id']}</td>";
    echo "<td style='padding: 8px;'>{$row['name']}</td>";
    echo "<td style='padding: 8px;'>{$row['mobile']}</td>";
    echo "<td style='padding: 8px;'><strong>$assignedTo</strong></td>";
    echo "<td style='padding: 8px;'>{$row['Created_at']}</td>";
    echo "</tr>";
    $position++;
}
echo "</table>";

// Assignment button
if ($unassignedCount > 0) {
    echo "<form method='post' style='margin: 30px 0;'>";
    echo "<button type='submit' name='assign' value='1' style='padding: 15px 30px; background: #4CAF50; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 18px; font-weight: bold;'>";
    echo "✅ Assign 50 Leads to Each Telecaller Now";
    echo "</button>";
    echo "</form>";
    
    // Handle assignment
    if (isset($_POST['assign'])) {
        echo "<hr>";
        echo "<h2>🚀 Assignment in Progress...</h2>";
        
        // Get leads to assign
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
        
        $assignedCount = 0;
        $assignmentsByTelecaller = [];
        
        foreach ($telecallers as $tc) {
            $assignmentsByTelecaller[$tc['id']] = 0;
        }
        
        // Round-robin assignment
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
        
        echo "<p style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745; font-size: 18px;'>";
        echo "✅ <strong>Success!</strong> Assigned $assignedCount leads";
        echo "</p>";
        
        echo "<h3>📈 Assignment Results</h3>";
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr style='background: #f5f5f5;'><th style='padding: 8px;'>Telecaller ID</th><th style='padding: 8px;'>Name</th><th style='padding: 8px;'>Leads Assigned</th></tr>";
        foreach ($telecallers as $tc) {
            $count = $assignmentsByTelecaller[$tc['id']];
            echo "<tr><td style='padding: 8px;'>{$tc['id']}</td><td style='padding: 8px;'>{$tc['name']}</td><td style='padding: 8px; text-align: center;'><strong>$count</strong></td></tr>";
        }
        echo "</table>";
        
        echo "<p style='margin-top: 20px;'>";
        echo "<a href='test_leads_final.php' style='padding: 10px 20px; background: #FF9800; color: white; text-decoration: none; border-radius: 5px; margin-right: 10px;'>📊 Test System</a>";
        echo "<a href='../admin-panel/' style='padding: 10px 20px; background: #9C27B0; color: white; text-decoration: none; border-radius: 5px;'>🎛️ View in Admin Panel</a>";
        echo "</p>";
    }
} else {
    echo "<p style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745;'>";
    echo "✅ <strong>All Done!</strong> No unassigned leads found.";
    echo "</p>";
}

$conn->close();

echo "<hr>";
echo "<p><strong>Completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
