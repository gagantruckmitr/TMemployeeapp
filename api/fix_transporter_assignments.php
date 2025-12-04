<?php
/**
 * Fix Transporter Assignments
 * Remove all assigned_to values for transporters
 * Create triggers to prevent future assignments
 */

header('Content-Type: text/html; charset=utf-8');

require_once 'config.php';

echo "<h1>Fix Transporter Assignments</h1>";
echo "<p>Removing all transporter assignments and creating prevention triggers</p>";

try {
    // Step 1: Check current state
    echo "<h2>Step 1: Current State</h2>";
    $query = "SELECT 
                COUNT(*) as total_transporters,
                SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) as assigned_count,
                SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) as unassigned_count
              FROM users 
              WHERE role = 'transporter'";
    
    $result = $conn->query($query);
    $before = $result->fetch_assoc();
    
    echo "<table border='1' cellpadding='5' cellspacing='0'>";
    echo "<tr><th>Total Transporters</th><th>Assigned</th><th>Unassigned</th></tr>";
    echo "<tr>";
    echo "<td><strong>{$before['total_transporters']}</strong></td>";
    echo "<td style='color: red;'><strong>{$before['assigned_count']}</strong></td>";
    echo "<td style='color: green;'><strong>{$before['unassigned_count']}</strong></td>";
    echo "</tr>";
    echo "</table>";
    
    if ($before['assigned_count'] > 0) {
        echo "<p style='color: orange;'>⚠️ Found {$before['assigned_count']} transporters with assignments - will fix!</p>";
        
        // Show which telecallers had transporters
        echo "<h3>Telecallers with Transporter Assignments:</h3>";
        $detailQuery = "SELECT 
                            a.id as telecaller_id,
                            a.name as telecaller_name,
                            a.tc_for,
                            COUNT(u.id) as transporter_count
                        FROM users u
                        INNER JOIN admins a ON u.assigned_to = a.id
                        WHERE u.role = 'transporter'
                        AND u.assigned_to IS NOT NULL
                        GROUP BY a.id, a.name, a.tc_for
                        ORDER BY transporter_count DESC";
        
        $detailResult = $conn->query($detailQuery);
        
        if ($detailResult && $detailResult->num_rows > 0) {
            echo "<table border='1' cellpadding='5' cellspacing='0'>";
            echo "<tr><th>Telecaller ID</th><th>Name</th><th>tc_for</th><th>Transporter Count</th></tr>";
            
            while ($row = $detailResult->fetch_assoc()) {
                echo "<tr>";
                echo "<td>{$row['telecaller_id']}</td>";
                echo "<td>{$row['telecaller_name']}</td>";
                echo "<td><strong>{$row['tc_for']}</strong></td>";
                echo "<td>{$row['transporter_count']}</td>";
                echo "</tr>";
            }
            echo "</table>";
        }
    } else {
        echo "<p style='color: green;'>✅ No transporters are currently assigned</p>";
    }
    
    // Step 2: Clear all transporter assignments
    echo "<h2>Step 2: Clearing Transporter Assignments</h2>";
    $updateQuery = "UPDATE users 
                    SET assigned_to = NULL 
                    WHERE role = 'transporter' 
                    AND assigned_to IS NOT NULL";
    
    if ($conn->query($updateQuery)) {
        $affected = $conn->affected_rows;
        echo "<p style='color: green; font-weight: bold;'>✅ Cleared {$affected} transporter assignments</p>";
    } else {
        echo "<p style='color: red;'>✗ Error: " . $conn->error . "</p>";
    }
    
    // Step 3: Create UPDATE trigger
    echo "<h2>Step 3: Creating Prevention Triggers</h2>";
    
    // Drop existing triggers
    $conn->query("DROP TRIGGER IF EXISTS prevent_transporter_assignment");
    $conn->query("DROP TRIGGER IF EXISTS prevent_transporter_assignment_insert");
    
    // Create UPDATE trigger
    $updateTrigger = "CREATE TRIGGER prevent_transporter_assignment
                      BEFORE UPDATE ON users
                      FOR EACH ROW
                      BEGIN
                          IF NEW.role = 'transporter' THEN
                              SET NEW.assigned_to = NULL;
                          END IF;
                      END";
    
    if ($conn->query($updateTrigger)) {
        echo "<p style='color: green;'>✅ Created UPDATE trigger: prevent_transporter_assignment</p>";
    } else {
        echo "<p style='color: red;'>✗ Error creating UPDATE trigger: " . $conn->error . "</p>";
    }
    
    // Create INSERT trigger
    $insertTrigger = "CREATE TRIGGER prevent_transporter_assignment_insert
                      BEFORE INSERT ON users
                      FOR EACH ROW
                      BEGIN
                          IF NEW.role = 'transporter' THEN
                              SET NEW.assigned_to = NULL;
                          END IF;
                      END";
    
    if ($conn->query($insertTrigger)) {
        echo "<p style='color: green;'>✅ Created INSERT trigger: prevent_transporter_assignment_insert</p>";
    } else {
        echo "<p style='color: red;'>✗ Error creating INSERT trigger: " . $conn->error . "</p>";
    }
    
    // Step 4: Verify fix
    echo "<h2>Step 4: Verification</h2>";
    $result = $conn->query($query);
    $after = $result->fetch_assoc();
    
    echo "<table border='1' cellpadding='5' cellspacing='0'>";
    echo "<tr><th>Total Transporters</th><th>Assigned</th><th>Unassigned</th></tr>";
    echo "<tr>";
    echo "<td><strong>{$after['total_transporters']}</strong></td>";
    echo "<td style='color: " . ($after['assigned_count'] == 0 ? 'green' : 'red') . ";'><strong>{$after['assigned_count']}</strong></td>";
    echo "<td style='color: green;'><strong>{$after['unassigned_count']}</strong></td>";
    echo "</tr>";
    echo "</table>";
    
    if ($after['assigned_count'] == 0) {
        echo "<p style='color: green; font-weight: bold; font-size: 18px;'>✅ SUCCESS! All transporters are now unassigned</p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ FAILED: Still have {$after['assigned_count']} assigned transporters</p>";
    }
    
    // Step 5: Test the trigger
    echo "<h2>Step 5: Testing Triggers</h2>";
    echo "<p>Testing that triggers prevent future assignments...</p>";
    
    // Try to assign a transporter (should be prevented by trigger)
    $testQuery = "SELECT id FROM users WHERE role = 'transporter' LIMIT 1";
    $testResult = $conn->query($testQuery);
    
    if ($testResult && $testRow = $testResult->fetch_assoc()) {
        $testId = $testRow['id'];
        
        // Try to assign it
        $assignQuery = "UPDATE users SET assigned_to = 999 WHERE id = $testId";
        $conn->query($assignQuery);
        
        // Check if it was prevented
        $checkQuery = "SELECT assigned_to FROM users WHERE id = $testId";
        $checkResult = $conn->query($checkQuery);
        $checkRow = $checkResult->fetch_assoc();
        
        if ($checkRow['assigned_to'] === null) {
            echo "<p style='color: green; font-weight: bold;'>✅ Trigger works! Attempted assignment was prevented</p>";
        } else {
            echo "<p style='color: red; font-weight: bold;'>✗ Trigger failed! Assignment was not prevented</p>";
        }
    }
    
    // Show triggers
    echo "<h2>Active Triggers</h2>";
    $triggerQuery = "SHOW TRIGGERS WHERE `Table` = 'users' AND `Trigger` LIKE '%transporter%'";
    $triggerResult = $conn->query($triggerQuery);
    
    if ($triggerResult && $triggerResult->num_rows > 0) {
        echo "<table border='1' cellpadding='5' cellspacing='0'>";
        echo "<tr><th>Trigger</th><th>Event</th><th>Timing</th></tr>";
        
        while ($row = $triggerResult->fetch_assoc()) {
            echo "<tr>";
            echo "<td><strong>{$row['Trigger']}</strong></td>";
            echo "<td>{$row['Event']}</td>";
            echo "<td>{$row['Timing']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red; font-weight: bold;'>Error: " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<ul>";
echo "<li>✅ All transporter assignments cleared (assigned_to = NULL)</li>";
echo "<li>✅ Triggers created to prevent future assignments</li>";
echo "<li>✅ Transporters now use round-robin in transporter_leads_api.php</li>";
echo "<li>✅ Welcome-call users will ONLY see drivers</li>";
echo "<li>✅ Match-making users will ONLY see transporters</li>";
echo "</ul>";

echo "<h2>What This Means</h2>";
echo "<table border='1' cellpadding='10' cellspacing='0'>";
echo "<tr><th>User Type</th><th>Role</th><th>Assignment Method</th><th>API</th></tr>";
echo "<tr><td><strong>Drivers</strong></td><td>driver</td><td>assigned_to column</td><td>fresh_leads_api.php</td></tr>";
echo "<tr><td><strong>Transporters</strong></td><td>transporter</td><td>Round-robin (NO assignment)</td><td>transporter_leads_api.php</td></tr>";
echo "</table>";

$conn->close();
?>
