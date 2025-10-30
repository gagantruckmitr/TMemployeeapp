<?php
require_once 'config.php';

header('Content-Type: application/json');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Active telecallers for round-robin (excluding 6 and 7)
    $activeTelecallers = [3, 4, 8, 9, 10];
    
    echo "Starting lead redistribution...\n\n";
    
    // Get all leads currently assigned to telecallers other than 6 and 7
    $stmt = $pdo->query("
        SELECT id, assigned_to 
        FROM drivers 
        WHERE assigned_to IS NOT NULL 
        AND assigned_to NOT IN (6, 7)
        ORDER BY id ASC
    ");
    
    $leadsToReassign = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $totalLeads = count($leadsToReassign);
    
    echo "Found $totalLeads leads to redistribute (excluding telecallers 6 & 7)\n\n";
    
    // Redistribute in round-robin
    $index = 0;
    $reassignedCount = 0;
    $distribution = array_fill_keys($activeTelecallers, 0);
    
    foreach ($leadsToReassign as $lead) {
        $newTelecaller = $activeTelecallers[$index % count($activeTelecallers)];
        
        // Update assignment
        $updateStmt = $pdo->prepare("UPDATE drivers SET assigned_to = ? WHERE id = ?");
        $updateStmt->execute([$newTelecaller, $lead['id']]);
        
        $distribution[$newTelecaller]++;
        $reassignedCount++;
        $index++;
    }
    
    echo "Redistribution complete!\n\n";
    echo "Distribution summary:\n";
    foreach ($distribution as $telecallerId => $count) {
        echo "Telecaller $telecallerId: $count leads\n";
    }
    
    // Get counts for telecallers 6 and 7 (unchanged)
    $stmt6 = $pdo->query("SELECT COUNT(*) as count FROM drivers WHERE assigned_to = 6");
    $count6 = $stmt6->fetch(PDO::FETCH_ASSOC)['count'];
    
    $stmt7 = $pdo->query("SELECT COUNT(*) as count FROM drivers WHERE assigned_to = 7");
    $count7 = $stmt7->fetch(PDO::FETCH_ASSOC)['count'];
    
    echo "\nUnchanged assignments:\n";
    echo "Telecaller 6: $count6 leads (unchanged)\n";
    echo "Telecaller 7: $count7 leads (unchanged)\n";
    
    echo "\nTotal leads reassigned: $reassignedCount\n";
    
    echo json_encode([
        'success' => true,
        'total_reassigned' => $reassignedCount,
        'distribution' => $distribution,
        'unchanged' => [
            'telecaller_6' => $count6,
            'telecaller_7' => $count7
        ]
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
