<?php
/**
 * Test Welcome-Call Access - Complete Flow
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Welcome-Call Access Test</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .success { color: green; font-weight: bold; }
    .error { color: red; font-weight: bold; }
    .info { color: blue; }
    .section { background: white; padding: 15px; margin: 10px 0; border-radius: 8px; }
    table { border-collapse: collapse; width: 100%; margin: 10px 0; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #4CAF50; color: white; }
</style>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<div class='section'>";
    echo "<h2>Database Connected</h2>";
    echo "</div>";
    
    // Check all telecallers
    echo "<div class='section'>";
    echo "<h2>All Telecallers</h2>";
    $stmt = $pdo->query("SELECT id, name, mobile, role, tc_for FROM admins WHERE role = 'telecaller' ORDER BY id");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table>";
    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>tc_for</th><th>Has Welcome-Call?</th></tr>";
    
    foreach ($telecallers as $tc) {
        $tcFor = $tc['tc_for'] ?? '';
        $hasWelcomeCall = false;
        
        $tcForArray = json_decode($tcFor, true);
        if (is_array($tcForArray)) {
            $hasWelcomeCall = in_array('welcome-call', $tcForArray);
        } else {
            $hasWelcomeCall = ($tcFor === 'welcome-call');
        }
        
        $accessClass = $hasWelcomeCall ? 'success' : 'error';
        $accessText = $hasWelcomeCall ? 'YES' : 'NO';
        
        echo "<tr>";
        echo "<td>{$tc['id']}</td>";
        echo "<td>{$tc['name']}</td>";
        echo "<td>{$tc['mobile']}</td>";
        echo "<td>{$tcFor}</td>";
        echo "<td class='$accessClass'>$accessText</td>";
        echo "</tr>";
    }
    echo "</table>";
    echo "</div>";
    
    // Count total leads
    echo "<div class='section'>";
    echo "<h2>Total Leads</h2>";
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM users WHERE role IN ('driver', 'transporter')");
    $totalLeads = $stmt->fetch()['total'];
    echo "<p class='info'>Total Drivers/Transporters: <strong>$totalLeads</strong></p>";
    echo "</div>";
    
} catch (Exception $e) {
    echo "<div class='section'>";
    echo "<p class='error'>Error: " . $e->getMessage() . "</p>";
    echo "</div>";
}
?>
