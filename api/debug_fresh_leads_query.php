<?php
/**
 * Debug Fresh Leads Query
 */

require_once 'config.php';

$callerId = $_GET['caller_id'] ?? 3;
$limit = $_GET['limit'] ?? 50;

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Debug Fresh Leads Query for Telecaller $callerId</h1>";
echo "<style>
    body { font-family: monospace; margin: 20px; }
    .success { color: green; }
    .error { color: red; }
    pre { background: #f0f0f0; padding: 10px; overflow: auto; }
</style>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Step 1: Check assigned users
    echo "<h2>Step 1: Users Assigned to Telecaller $callerId</h2>";
    $sql1 = "SELECT COUNT(*) as count FROM users WHERE assigned_to = ? AND role IN ('driver', 'transporter')";
    $stmt = $pdo->prepare($sql1);
    $stmt->execute([$callerId]);
    $assignedCount = $stmt->fetch()['count'];
    echo "<p>Assigned users: <strong>$assignedCount</strong></p>";
    
    // Step 2: Check call_logs for this telecaller
    echo "<h2>Step 2: Call Logs for Telecaller $callerId</h2>";
    $sql2 = "SELECT COUNT(*) as count, COUNT(DISTINCT user_id) as distinct_users FROM call_logs WHERE caller_id = ?";
    $stmt = $pdo->prepare($sql2);
    $stmt->execute([$callerId]);
    $callData = $stmt->fetch();
    echo "<p>Total call logs: <strong>{$callData['count']}</strong></p>";
    echo "<p>Distinct users called: <strong>{$callData['distinct_users']}</strong></p>";
    
    // Step 3: Check user_id values in call_logs
    echo "<h2>Step 3: Sample user_id values in call_logs</h2>";
    $sql3 = "SELECT user_id, COUNT(*) as count FROM call_logs WHERE caller_id = ? GROUP BY user_id LIMIT 10";
    $stmt = $pdo->prepare($sql3);
    $stmt->execute([$callerId]);
    $userIds = $stmt->fetchAll();
    echo "<pre>";
    print_r($userIds);
    echo "</pre>";
    
    // Step 4: Check if user_ids in call_logs match users table
    echo "<h2>Step 4: Matching user_ids</h2>";
    $sql4 = "
        SELECT 
            cl.user_id,
            u.id as actual_user_id,
            u.name,
            CASE WHEN u.id IS NULL THEN 'NOT FOUND' ELSE 'FOUND' END as status
        FROM call_logs cl
        LEFT JOIN users u ON cl.user_id = u.id
        WHERE cl.caller_id = ?
        LIMIT 10
    ";
    $stmt = $pdo->prepare($sql4);
    $stmt->execute([$callerId]);
    $matches = $stmt->fetchAll();
    echo "<pre>";
    print_r($matches);
    echo "</pre>";
    
    // Step 5: Run the actual query
    echo "<h2>Step 5: Actual Fresh Leads Query</h2>";
    $sql5 = "SELECT 
                u.id,
                u.unique_id,
                u.name,
                u.mobile,
                u.assigned_to
            FROM users u
            WHERE u.role IN ('driver', 'transporter')
            AND u.assigned_to = ?
            AND u.id NOT IN (
                SELECT DISTINCT user_id 
                FROM call_logs
                WHERE caller_id = ?
                AND user_id IS NOT NULL
            )
            ORDER BY u.Created_at DESC
            LIMIT ?";
    
    echo "<pre>$sql5</pre>";
    
    $stmt = $pdo->prepare($sql5);
    $stmt->execute([$callerId, $callerId, $limit]);
    $freshLeads = $stmt->fetchAll();
    
    echo "<p>Fresh leads returned: <strong>" . count($freshLeads) . "</strong></p>";
    
    if (count($freshLeads) > 0) {
        echo "<h3>Sample Fresh Leads (first 5)</h3>";
        echo "<pre>";
        print_r(array_slice($freshLeads, 0, 5));
        echo "</pre>";
    } else {
        echo "<p class='error'>⚠️ No fresh leads returned!</p>";
        
        // Debug: Check what's being excluded
        echo "<h3>Debug: What's being excluded?</h3>";
        $sql6 = "SELECT DISTINCT user_id FROM call_logs WHERE caller_id = ? AND user_id IS NOT NULL LIMIT 20";
        $stmt = $pdo->prepare($sql6);
        $stmt->execute([$callerId]);
        $excluded = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "<p>User IDs being excluded (first 20): " . implode(', ', $excluded) . "</p>";
        
        // Check if all assigned users are in the excluded list
        $sql7 = "
            SELECT u.id, u.name, u.assigned_to,
                   CASE WHEN cl.user_id IS NOT NULL THEN 'CALLED' ELSE 'NOT CALLED' END as status
            FROM users u
            LEFT JOIN (SELECT DISTINCT user_id FROM call_logs WHERE caller_id = ?) cl ON u.id = cl.user_id
            WHERE u.assigned_to = ? AND u.role IN ('driver', 'transporter')
            LIMIT 10
        ";
        $stmt = $pdo->prepare($sql7);
        $stmt->execute([$callerId, $callerId]);
        $statusCheck = $stmt->fetchAll();
        echo "<h3>Sample Assigned Users Status</h3>";
        echo "<pre>";
        print_r($statusCheck);
        echo "</pre>";
    }
    
} catch (Exception $e) {
    echo "<p class='error'>Error: " . $e->getMessage() . "</p>";
}
?>
