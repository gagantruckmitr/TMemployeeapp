<?php
/**
 * Test Assigned Leads for Telecaller
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

$callerId = $_GET['caller_id'] ?? 3;

echo "<h1>Testing Assigned Leads for Telecaller ID: $callerId</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; margin: 20px 0; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
    .success { color: green; font-weight: bold; }
    .error { color: red; font-weight: bold; }
</style>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check telecaller info
    echo "<h2>Telecaller Info</h2>";
    $stmt = $pdo->prepare("SELECT id, name, mobile, role, tc_for FROM admins WHERE id = ?");
    $stmt->execute([$callerId]);
    $telecaller = $stmt->fetch();
    
    if ($telecaller) {
        echo "<table>";
        echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Role</th><th>tc_for</th></tr>";
        echo "<tr>";
        echo "<td>{$telecaller['id']}</td>";
        echo "<td>{$telecaller['name']}</td>";
        echo "<td>{$telecaller['mobile']}</td>";
        echo "<td>{$telecaller['role']}</td>";
        echo "<td>{$telecaller['tc_for']}</td>";
        echo "</tr>";
        echo "</table>";
    } else {
        echo "<p class='error'>Telecaller not found!</p>";
        exit;
    }
    
    // Check total users
    echo "<h2>Total Users in Database</h2>";
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users WHERE role IN ('driver', 'transporter')");
    $totalUsers = $stmt->fetch()['total'];
    echo "<p>Total Drivers/Transporters: <strong>$totalUsers</strong></p>";
    
    // Check assigned users
    echo "<h2>Users Assigned to This Telecaller</h2>";
    $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM users WHERE assigned_to = ? AND role IN ('driver', 'transporter')");
    $stmt->execute([$callerId]);
    $assignedUsers = $stmt->fetch()['total'];
    echo "<p>Assigned to Telecaller $callerId: <strong>$assignedUsers</strong></p>";
    
    if ($assignedUsers > 0) {
        echo "<h3>Sample Assigned Users (first 10)</h3>";
        $stmt = $pdo->prepare("
            SELECT id, unique_id, name, mobile, role, assigned_to, Created_at 
            FROM users 
            WHERE assigned_to = ? AND role IN ('driver', 'transporter')
            ORDER BY Created_at DESC 
            LIMIT 10
        ");
        $stmt->execute([$callerId]);
        $users = $stmt->fetchAll();
        
        echo "<table>";
        echo "<tr><th>ID</th><th>TMID</th><th>Name</th><th>Mobile</th><th>Role</th><th>Assigned To</th><th>Created</th></tr>";
        foreach ($users as $user) {
            echo "<tr>";
            echo "<td>{$user['id']}</td>";
            echo "<td>{$user['unique_id']}</td>";
            echo "<td>{$user['name']}</td>";
            echo "<td>{$user['mobile']}</td>";
            echo "<td>{$user['role']}</td>";
            echo "<td>{$user['assigned_to']}</td>";
            echo "<td>{$user['Created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // Check users already called by this telecaller
    echo "<h2>Users Already Called by This Telecaller</h2>";
    $stmt = $pdo->prepare("SELECT COUNT(DISTINCT user_id) as total FROM call_logs WHERE caller_id = ?");
    $stmt->execute([$callerId]);
    $calledUsers = $stmt->fetch()['total'];
    echo "<p>Already Called: <strong>$calledUsers</strong></p>";
    
    // Calculate pending calls
    $pendingCalls = $assignedUsers - $calledUsers;
    echo "<h2>Summary</h2>";
    echo "<table>";
    echo "<tr><th>Metric</th><th>Count</th></tr>";
    echo "<tr><td>Total Users in DB</td><td>$totalUsers</td></tr>";
    echo "<tr><td>Assigned to Telecaller</td><td>$assignedUsers</td></tr>";
    echo "<tr><td>Already Called</td><td>$calledUsers</td></tr>";
    echo "<tr><td><strong>Pending Calls (Fresh Leads)</strong></td><td class='success'><strong>$pendingCalls</strong></td></tr>";
    echo "</table>";
    
    // Check assignment distribution
    echo "<h2>Assignment Distribution</h2>";
    $stmt = $pdo->query("
        SELECT assigned_to, COUNT(*) as count 
        FROM users 
        WHERE role IN ('driver', 'transporter') 
        GROUP BY assigned_to 
        ORDER BY count DESC
    ");
    $distribution = $stmt->fetchAll();
    
    echo "<table>";
    echo "<tr><th>Assigned To (Telecaller ID)</th><th>Count</th></tr>";
    foreach ($distribution as $row) {
        $highlight = ($row['assigned_to'] == $callerId) ? 'style="background-color: #90EE90;"' : '';
        echo "<tr $highlight>";
        echo "<td>" . ($row['assigned_to'] ?? 'NULL') . "</td>";
        echo "<td>{$row['count']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Recommendation
    echo "<h2>Recommendation</h2>";
    if ($assignedUsers == 0) {
        echo "<p class='error'>⚠️ No users are assigned to this telecaller!</p>";
        echo "<p>To fix this, run one of these SQL commands:</p>";
        echo "<pre style='background: #f0f0f0; padding: 10px;'>";
        echo "-- Option 1: Assign all unassigned users to this telecaller\n";
        echo "UPDATE users SET assigned_to = $callerId WHERE assigned_to IS NULL AND role IN ('driver', 'transporter');\n\n";
        echo "-- Option 2: Distribute users evenly among telecallers\n";
        echo "-- (Run the round-robin assignment script)\n";
        echo "</pre>";
    } elseif ($pendingCalls == 0) {
        echo "<p class='error'>⚠️ All assigned users have been called!</p>";
        echo "<p>The telecaller has completed all their assigned leads.</p>";
    } else {
        echo "<p class='success'>✅ Everything looks good! Telecaller has $pendingCalls pending calls.</p>";
    }
    
} catch (Exception $e) {
    echo "<p class='error'>Error: " . $e->getMessage() . "</p>";
}
?>
