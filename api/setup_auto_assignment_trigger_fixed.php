<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h1>🔧 Setup Auto-Assignment Trigger</h1>";
echo "<p style='background: #e3f2fd; padding: 15px;'>";
echo "This will create a database trigger that automatically assigns new users to telecallers in round-robin order when they register.";
echo "</p>";

// Drop old triggers
echo "<h2>Step 1: Removing Old Triggers...</h2>";
$triggers = [
    'after_driver_insert',
    'after_driver_update', 
    'assign_driver_trigger',
    'auto_assign_leads',
    'auto_assign_role_based_leads',
    'auto_assign_new_leads',
    'auto_assign_new_users'
];

foreach ($triggers as $trigger) {
    $conn->query("DROP TRIGGER IF EXISTS $trigger");
    echo "<p>✓ Dropped trigger: $trigger</p>";
}

// Create new trigger
echo "<h2>Step 2: Creating New Trigger...</h2>";

$sql = "
CREATE TRIGGER auto_assign_new_users
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    DECLARE next_tc INT;
    DECLARE lead_role VARCHAR(50);
    
    SET lead_role = NEW.role;
    
    -- Only assign if role is driver or transporter and not already assigned
    IF lead_role IN ('driver', 'transporter') AND (NEW.assigned_to IS NULL OR NEW.assigned_to = 0) THEN
        
        -- For DRIVER leads: Round-robin between telecaller IDs 3 and 4
        IF lead_role = 'driver' THEN
            SELECT a.id INTO next_tc
            FROM admins a
            LEFT JOIN (
                SELECT assigned_to, COUNT(*) as cnt
                FROM users
                WHERE assigned_to IN (3, 4)
                GROUP BY assigned_to
            ) u ON a.id = u.assigned_to
            WHERE a.id IN (3, 4)
            AND a.role = 'telecaller'
            ORDER BY COALESCE(u.cnt, 0) ASC, a.id ASC
            LIMIT 1;
        END IF;
        
        -- For TRANSPORTER leads: Round-robin between telecaller IDs 6 and 7
        IF lead_role = 'transporter' THEN
            SELECT a.id INTO next_tc
            FROM admins a
            LEFT JOIN (
                SELECT assigned_to, COUNT(*) as cnt
                FROM users
                WHERE assigned_to IN (6, 7)
                GROUP BY assigned_to
            ) u ON a.id = u.assigned_to
            WHERE a.id IN (6, 7)
            AND a.role = 'telecaller'
            ORDER BY COALESCE(u.cnt, 0) ASC, a.id ASC
            LIMIT 1;
        END IF;
        
        -- Assign the lead
        IF next_tc IS NOT NULL THEN
            UPDATE users SET assigned_to = next_tc, Updated_at = NOW() WHERE id = NEW.id;
        END IF;
    END IF;
END
";

if ($conn->query($sql)) {
    echo "<p style='background: #d4edda; padding: 15px;'>✅ <strong>Success!</strong> Trigger 'auto_assign_new_users' created</p>";
} else {
    echo "<p style='background: #f8d7da; padding: 15px;'>❌ <strong>Error:</strong> " . $conn->error . "</p>";
}

// Verify trigger exists
echo "<h2>Step 3: Verification</h2>";
$result = $conn->query("SHOW TRIGGERS LIKE 'users'");

if ($result->num_rows > 0) {
    echo "<table border='1' style='border-collapse: collapse;'>";
    echo "<tr style='background: #f5f5f5;'><th style='padding: 8px;'>Trigger</th><th style='padding: 8px;'>Event</th><th style='padding: 8px;'>Table</th><th style='padding: 8px;'>Timing</th></tr>";
    
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td style='padding: 8px;'><strong>{$row['Trigger']}</strong></td>";
        echo "<td style='padding: 8px;'>{$row['Event']}</td>";
        echo "<td style='padding: 8px;'>{$row['Table']}</td>";
        echo "<td style='padding: 8px;'>{$row['Timing']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='background: #fff3cd; padding: 15px;'>⚠️ No triggers found on 'users' table</p>";
}

// Explain how it works
echo "<hr>";
echo "<h2>📖 How It Works</h2>";
echo "<div style='background: #f5f5f5; padding: 20px; border-left: 4px solid #2196F3;'>";
echo "<h3>Automatic Assignment Logic:</h3>";
echo "<ol>";
echo "<li><strong>When a new user registers</strong> (INSERT into users table)</li>";
echo "<li><strong>If role = 'driver':</strong> Assigns to telecaller 3 or 4 (whoever has fewer leads)</li>";
echo "<li><strong>If role = 'transporter':</strong> Assigns to telecaller 6 or 7 (whoever has fewer leads)</li>";
echo "<li><strong>Round-robin:</strong> Always assigns to the telecaller with the least number of leads</li>";
echo "<li><strong>Chronological:</strong> New users get assigned immediately in the order they register</li>";
echo "</ol>";
echo "<h3>Example:</h3>";
echo "<p>• New driver registers → Checks: Pooja has 50 leads, Tanisha has 50 leads → Assigns to Pooja (ID 3, lower ID)<br>";
echo "• Another driver registers → Checks: Pooja has 51 leads, Tanisha has 50 leads → Assigns to Tanisha (ID 4)<br>";
echo "• New transporter registers → Checks: Tarun has 30 leads, Gagan has 30 leads → Assigns to Tarun (ID 6, lower ID)</p>";
echo "</div>";

echo "<hr>";
echo "<h2>✅ Setup Complete!</h2>";
echo "<p style='background: #d4edda; padding: 20px; font-size: 18px;'>";
echo "<strong>The trigger is now active!</strong><br>";
echo "All new users will be automatically assigned to telecallers in round-robin order.";
echo "</p>";

echo "<p style='margin-top: 20px;'>";
echo "<a href='fix_assign_latest_now.php' style='padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 5px; margin-right: 10px;'>🔄 Assign Existing Unassigned Leads</a>";
echo "<a href='check_latest_users.php' style='padding: 10px 20px; background: #2196F3; color: white; text-decoration: none; border-radius: 5px;'>📊 Check Latest Users</a>";
echo "</p>";

$conn->close();
?>
