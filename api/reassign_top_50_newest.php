<?php
require_once 'config.php';

header('Content-Type: text/plain');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== Reassigning Top 50 Newest Leads to Each Telecaller ===\n\n";
    
    $telecallers = [3, 4, 8, 9, 10];
    
    echo "Step 1: Clearing ALL current assignments...\n";
    $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'driver'");
    echo "✓ All assignments cleared\n\n";
    
    echo "Step 2: Getting top 250 NEWEST leads (by Created_at DESC)...\n";
    
    // Get 250 newest driver leads
    $stmt = $pdo->query("
        SELECT id, name, Created_at
        FROM users 
        WHERE role = 'driver' 
        ORDER BY Created_at DESC 
        LIMIT 250
    ");
    
    $allLeads = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $totalLeads = count($allLeads);
    
    echo "Found $totalLeads newest leads\n";
    echo "Date range: {$allLeads[count($allLeads)-1]['Created_at']} to {$allLeads[0]['Created_at']}\n\n";
    
    echo "Step 3: Assigning 50 leads to each telecaller...\n\n";
    
    $chunkSize = 50;
    
    for ($i = 0; $i < 5; $i++) {
        $telecallerId = $telecallers[$i];
        $offset = $i * $chunkSize;
        $chunk = array_slice($allLeads, $offset, $chunkSize);
        
        if (count($chunk) == 0) {
            echo "Telecaller $telecallerId: No leads available\n";
            continue;
        }
        
        $leadIds = array_column($chunk, 'id');
        $ids = implode(',', $leadIds);
        
        // Assign leads
        $pdo->exec("UPDATE users SET assigned_to = $telecallerId WHERE id IN ($ids)");
        
        $firstDate = $chunk[count($chunk)-1]['Created_at'];
        $lastDate = $chunk[0]['Created_at'];
        
        echo "Telecaller $telecallerId: Assigned " . count($chunk) . " leads\n";
        echo "  Date range: $firstDate to $lastDate\n";
        echo "  Sample: {$chunk[0]['name']} (ID: {$chunk[0]['id']})\n\n";
    }
    
    echo "=== Final Distribution ===\n\n";
    
    foreach ($telecallers as $tid) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count, 
                   MIN(Created_at) as oldest, 
                   MAX(Created_at) as newest
            FROM users 
            WHERE role = 'driver' AND assigned_to = ?
        ");
        $stmt->execute([$tid]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        echo "Telecaller $tid: {$result['count']} leads\n";
        if ($result['count'] > 0) {
            echo "  Date range: {$result['oldest']} to {$result['newest']}\n";
        }
    }
    
    // Show unassigned count
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to IS NULL");
    $unassigned = $stmt->fetch()['count'];
    echo "\nUnassigned: $unassigned leads\n";
    
    echo "\n✓ COMPLETE! Top 50 newest leads assigned to each telecaller.\n";
    
} catch (Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
}
