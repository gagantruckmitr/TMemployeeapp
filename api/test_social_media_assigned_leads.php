<?php
/**
 * Test Social Media Assigned Leads API
 * Tests that telecallers only see leads assigned to them
 */

echo "=== Testing Social Media Assigned Leads API ===\n\n";

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Database connection failed: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
    echo "✅ Database connected successfully\n\n";
    
    // Test 1: Check social media telecallers
    echo "--- Test 1: Social Media Telecallers ---\n";
    $sql = "SELECT id, name, mobile, tc_for FROM admins WHERE tc_for = 'social-media' LIMIT 5";
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        echo "Found " . $result->num_rows . " social media telecaller(s):\n";
        $telecallers = [];
        while ($row = $result->fetch_assoc()) {
            $telecallers[] = $row;
            echo "  - ID: {$row['id']}, Name: {$row['name']}, Mobile: {$row['mobile']}\n";
        }
        echo "\n";
        
        // Test 2: Check leads assigned to each telecaller
        echo "--- Test 2: Leads Assigned to Each Telecaller ---\n";
        foreach ($telecallers as $tc) {
            $adminId = $tc['id'];
            $sql = "SELECT COUNT(*) as total FROM social_media_leads WHERE assigned_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('i', $adminId);
            $stmt->execute();
            $result = $stmt->get_result();
            $row = $result->fetch_assoc();
            echo "  - {$tc['name']} (ID: {$adminId}): {$row['total']} leads assigned\n";
            $stmt->close();
        }
        echo "\n";
        
        // Test 3: Check leads without call logs for first telecaller
        if (count($telecallers) > 0) {
            $firstTc = $telecallers[0];
            $adminId = $firstTc['id'];
            
            echo "--- Test 3: Available Leads for {$firstTc['name']} (ID: {$adminId}) ---\n";
            $sql = "SELECT sml.id, sml.name, sml.mobile, sml.source, sml.assigned_id
                    FROM social_media_leads sml
                    LEFT JOIN call_logs cl ON sml.mobile COLLATE utf8mb4_unicode_ci = cl.user_number COLLATE utf8mb4_unicode_ci
                        AND cl.tc_for = 'social-media'
                    WHERE cl.id IS NULL
                        AND sml.assigned_id = ?
                    ORDER BY sml.created_at DESC 
                    LIMIT 5";
            
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('i', $adminId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                echo "Found " . $result->num_rows . " available lead(s):\n";
                while ($row = $result->fetch_assoc()) {
                    echo "  - Lead ID: {$row['id']}, Name: {$row['name']}, Mobile: {$row['mobile']}, Source: {$row['source']}, Assigned To: {$row['assigned_id']}\n";
                }
            } else {
                echo "No available leads (all have been called or none assigned)\n";
            }
            $stmt->close();
            echo "\n";
        }
        
        // Test 4: Simulate API call
        if (count($telecallers) > 0) {
            $testTc = $telecallers[0];
            echo "--- Test 4: Simulating API Call for {$testTc['name']} ---\n";
            
            // Get user ID from users table by mobile
            $sql = "SELECT id FROM users WHERE mobile = ? LIMIT 1";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param('s', $testTc['mobile']);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $userRow = $result->fetch_assoc();
                $userId = $userRow['id'];
                echo "User ID from users table: {$userId}\n";
                echo "Testing API endpoint: /api/social-media-leads.php?action=get_social_media_leads&user_id={$userId}\n";
                echo "Expected: Should return only leads assigned to admin ID {$testTc['id']}\n";
            } else {
                echo "⚠️  No matching user found in users table for mobile: {$testTc['mobile']}\n";
                echo "Testing with admin ID directly: {$testTc['id']}\n";
            }
            $stmt->close();
        }
        
    } else {
        echo "⚠️  No social media telecallers found in admins table\n";
        echo "Please ensure there are users with tc_for = 'social-media'\n";
    }
    
    $conn->close();
    echo "\n✅ Test completed successfully\n";
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>
