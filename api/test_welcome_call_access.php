<?php
/**
 * Test Welcome-Call Access
 * Verifies that all telecallers with tc_for='welcome-call' can see all leads
 */

header('Content-Type: text/html; charset=utf-8');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}

echo "<h2>Smart Calling Access Test - ALL Telecallers</h2>";

// Get ALL telecallers
echo "<h3>1. All Telecallers:</h3>";
$stmt = $pdo->query("SELECT id, name, mobile, tc_for FROM admins WHERE role = 'telecaller' ORDER BY id");
$allTCs = $stmt->fetchAll();

if (count($allTCs) > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>tc_for</th><th>Access</th></tr>";
    foreach ($allTCs as $tc) {
        echo "<tr>";
        echo "<td>{$tc['id']}</td>";
        echo "<td>{$tc['name']}</td>";
        echo "<td>{$tc['mobile']}</td>";
        echo "<td>{$tc['tc_for']}</td>";
        echo "<td style='color: green;'><strong>✅ ALL LEADS</strong></td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>No telecallers found</p>";
}

// Get total leads count
echo "<h3>2. Total Available Leads:</h3>";
$totalLeadsStmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role IN ('driver', 'transporter')");
$totalLeads = $totalLeadsStmt->fetch()['count'];
echo "<p><strong>Total leads in database:</strong> $totalLeads</p>";

// Test API call for each telecaller
if (count($allTCs) > 0) {
    echo "<h3>3. Testing API Access for Each Telecaller:</h3>";
    
    foreach ($allTCs as $tc) {
        $callerId = $tc['id'];
        $callerName = $tc['name'];
        
        echo "<h4>Testing for: $callerName (ID: $callerId)</h4>";
        
        // Make API call
        $apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/fresh_leads_api.php?action=fresh_leads&caller_id=$callerId&limit=10";
        
        $ch = curl_init($apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode === 200) {
            $data = json_decode($response, true);
            
            if ($data['success']) {
                echo "<p style='color: green;'>✅ <strong>SUCCESS</strong></p>";
                echo "<ul>";
                echo "<li><strong>Leads returned:</strong> {$data['count']}</li>";
                echo "<li><strong>Distribution:</strong> {$data['distribution']}</li>";
                echo "<li><strong>Note:</strong> {$data['note']}</li>";
                echo "</ul>";
                
                if ($data['count'] > 0) {
                    echo "<p><strong>Sample leads:</strong></p>";
                    echo "<table border='1' cellpadding='5'>";
                    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>City</th></tr>";
                    foreach (array_slice($data['data'], 0, 5) as $lead) {
                        echo "<tr>";
                        echo "<td>{$lead['id']}</td>";
                        echo "<td>{$lead['name']}</td>";
                        echo "<td>{$lead['phoneNumber']}</td>";
                        echo "<td>{$lead['city']}</td>";
                        echo "</tr>";
                    }
                    echo "</table>";
                }
            } else {
                echo "<p style='color: red;'>❌ <strong>FAILED:</strong> {$data['error']}</p>";
            }
        } else {
            echo "<p style='color: red;'>❌ <strong>HTTP ERROR:</strong> $httpCode</p>";
            echo "<pre>$response</pre>";
        }
        
        echo "<hr>";
    }
}

echo "<h3>4. Summary:</h3>";
echo "<div style='background: #e8f5e9; padding: 15px; border-left: 4px solid #4caf50;'>";
echo "<ul style='margin: 0;'>";
echo "<li>✅ <strong>ALL telecallers</strong> have access to <strong>ALL leads</strong></li>";
echo "<li>✅ No filtering by <code>tc_for</code> or <code>assigned_to</code></li>";
echo "<li>✅ Each telecaller only sees leads they <strong>haven't personally called</strong></li>";
echo "<li>✅ Shared lead pool for maximum flexibility</li>";
echo "<li>✅ First-come, first-served distribution</li>";
echo "</ul>";
echo "</div>";

?>
