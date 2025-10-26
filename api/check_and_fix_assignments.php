<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h1>Check and Fix Lead Assignments</h1>";

// 1. Check current assignment status
echo "<h2>1. Current Assignment Status</h2>";
$result = $conn->query("
    SELECT 
        CASE 
            WHEN assigned_to IS NULL THEN 'NULL'
            WHEN assigned_to = 0 THEN '0'
            WHEN assigned_to = '' THEN 'EMPTY'
            ELSE CAST(assigned_to AS CHAR)
        END as assignment_status,
        COUNT(*) as count
    FROM users
    WHERE role = 'driver'
    GROUP BY assignment_status
");

echo "<table border='1'><tr><th>Assignment Status</th><th>Count</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['assignment_status']}</td><td>{$row['count']}</td></tr>";
}
echo "</table>";

// 2. Check telecallers
echo "<h2>2. Available Telecallers</h2>";
$result = $conn->query("SELECT id, name, email FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
$telecallers = [];
echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Email</th></tr>";
while ($row = $result->fetch_assoc()) {
    $telecallers[] = $row;
    echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['email']}</td></tr>";
}
echo "</table>";

if (empty($telecallers)) {
    echo "<p style='color: red;'><strong>ERROR: No telecallers found!</strong></p>";
    exit;
}

// 3. Check if assignments need fixing
$result = $conn->query("
    SELECT COUNT(*) as count 
    FROM users 
    WHERE role = 'driver' 
    AND (assigned_to IS NULL OR assigned_to = 0 OR assigned_to = '')
");
$row = $result->fetch_assoc();
$needsFixing = $row['count'];

echo "<h2>3. Leads Needing Assignment</h2>";
echo "<p><strong>Unassigned Leads:</strong> $needsFixing</p>";

if ($needsFixing == 0) {
    echo "<p style='color: green;'>✓ All leads are already assigned!</p>";
    
    // Show distribution
    echo "<h2>4. Current Distribution</h2>";
    $result = $conn->query("
        SELECT 
            u.assigned_to,
            a.name as telecaller_name,
            COUNT(*) as count
        FROM users u
        LEFT JOIN admins a ON u.assigned_to = a.id
        WHERE u.role = 'driver'
        AND u.assigned_to IS NOT NULL 
        AND u.assigned_to != 0 
        AND u.assigned_to != ''
        GROUP BY u.assigned_to, a.name
        ORDER BY u.assigned_to
    ");
    
    echo "<table border='1'><tr><th>Telecaller ID</th><th>Name</th><th>Assigned Leads</th></tr>";
    $totalAssigned = 0;
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['assigned_to']}</td><td>{$row['telecaller_name']}</td><td>{$row['count']}</td></tr>";
        $totalAssigned += $row['count'];
    }
    echo "</table>";
    echo "<p><strong>Total Assigned:</strong> $totalAssigned</p>";
    
} else {
    echo "<p style='color: orange;'>⚠ Need to assign $needsFixing leads</p>";
    echo "<form method='post' style='margin: 20px 0;'>";
    echo "<button type='submit' name='fix' value='1' style='padding: 10px 20px; background: #4CAF50; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 16px;'>";
    echo "🔧 Fix Assignments Now (Round-Robin)";
    echo "</button>";
    echo "</form>";
    
    // Handle fix request
    if (isset($_POST['fix'])) {
        echo "<h2>4. Fixing Assignments...</h2>";
        
        $telecallerCount = count($telecallers);
        $leadsPerTelecaller = 50; // Assign only 50 leads to each telecaller
        $totalToAssign = $telecallerCount * $leadsPerTelecaller;
        
        echo "<p><strong>Strategy:</strong> Assigning top $leadsPerTelecaller most recent leads to each telecaller (Total: $totalToAssign leads)</p>";
        
        // Get unassigned leads ordered by creation date (newest first)
        // Limit to total needed (50 per telecaller)
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
        echo "<p><strong>Found:</strong> $actualLeadsCount unassigned leads to distribute</p>";
        
        $assignedCount = 0;
        $assignmentsByTelecaller = [];
        
        foreach ($telecallers as $tc) {
            $assignmentsByTelecaller[$tc['id']] = 0;
        }
        
        // Round-robin assignment: Lead1→TC1, Lead2→TC2, Lead3→TC3, Lead4→TC1, etc.
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
        
        echo "<h3>Assignment Distribution:</h3>";
        echo "<table border='1'><tr><th>Telecaller ID</th><th>Name</th><th>Newly Assigned</th></tr>";
        foreach ($telecallers as $tc) {
            $count = $assignmentsByTelecaller[$tc['id']];
            echo "<tr><td>{$tc['id']}</td><td>{$tc['name']}</td><td>$count</td></tr>";
        }
        echo "</table>";
        
        echo "<p style='margin-top: 20px;'><a href='check_and_fix_assignments.php' style='padding: 10px 20px; background: #2196F3; color: white; text-decoration: none; border-radius: 5px;'>🔄 Refresh Page</a></p>";
    }
}

// 5. Show sample leads with assignments
echo "<h2>5. Sample Leads (First 10)</h2>";
$result = $conn->query("
    SELECT 
        u.id,
        u.name,
        u.mobile,
        u.assigned_to,
        a.name as telecaller_name,
        u.Created_at
    FROM users u
    LEFT JOIN admins a ON u.assigned_to = a.id
    WHERE u.role = 'driver'
    ORDER BY u.Created_at DESC
    LIMIT 10
");

echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Mobile</th><th>Assigned To ID</th><th>Telecaller</th><th>Registered</th></tr>";
while ($row = $result->fetch_assoc()) {
    $tcId = $row['assigned_to'] ?: '<span style="color: red;">NULL</span>';
    $tcName = $row['telecaller_name'] ?: '<span style="color: red;">Unassigned</span>';
    echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['mobile']}</td><td>$tcId</td><td>$tcName</td><td>{$row['Created_at']}</td></tr>";
}
echo "</table>";

$conn->close();

echo "<hr>";
echo "<p><strong>Completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p>";
echo "<a href='test_leads_final.php' style='padding: 8px 16px; background: #FF9800; color: white; text-decoration: none; border-radius: 5px; margin-right: 10px;'>📊 Test Leads System</a>";
echo "<a href='../admin-panel/' style='padding: 8px 16px; background: #9C27B0; color: white; text-decoration: none; border-radius: 5px;'>🎛️ Admin Panel</a>";
echo "</p>";
?>
