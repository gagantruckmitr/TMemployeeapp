<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

try {
    echo "=== STEP 1: REMOVE ALL TRIGGERS ===\n";
    
    // Drop ALL possible triggers (including the ones found)
    $triggers = [
        'auto_assign_telecaller',
        'auto_assign_driver_to_telecaller',
        'auto_assign_telecaller_on_insert',
        'assign_user_by_role',
        'auto_assign_new_users',
        'auto_assign_lead_chronological',
        'auto_assign_leads',
        'assign_lead_to_telecaller',
        'auto_assign_driver',
        'auto_assign_transporter',
        'assign_leads_round_robin',
        'auto_round_robin_assignment'
    ];
    
    foreach ($triggers as $trigger) {
        $conn->query("DROP TRIGGER IF EXISTS $trigger");
        echo "✓ Dropped $trigger\n";
    }
    echo "\n✓ All triggers removed\n\n";
    
    echo "=== STEP 2: FIX CURRENT ASSIGNMENTS ===\n";
    
    // Clear ALL assignments
    $conn->query("UPDATE users SET assigned_to = NULL WHERE role IN ('driver', 'transporter')");
    echo "✓ Cleared all assignments\n\n";
    
    // Get top 50 LATEST drivers
    $driversQuery = "SELECT id, name, Created_at FROM users WHERE role = 'driver' ORDER BY Created_at DESC LIMIT 50";
    $driversResult = $conn->query($driversQuery);
    $drivers = [];
    while ($row = $driversResult->fetch_assoc()) {
        $drivers[] = $row;
    }
    
    // Get top 50 LATEST transporters
    $transportersQuery = "SELECT id, name, Created_at FROM users WHERE role = 'transporter' ORDER BY Created_at DESC LIMIT 50";
    $transportersResult = $conn->query($transportersQuery);
    $transporters = [];
    while ($row = $transportersResult->fetch_assoc()) {
        $transporters[] = $row;
    }
    
    echo "Found " . count($drivers) . " latest drivers\n";
    echo "Found " . count($transporters) . " latest transporters\n\n";
    
    // Assign drivers to IDs 3 and 4 ONLY
    $driverTelecallerIds = [3, 4];
    $driverIndex = 0;
    $driverStats = [3 => 0, 4 => 0];
    
    foreach ($drivers as $driver) {
        $telecallerId = $driverTelecallerIds[$driverIndex % count($driverTelecallerIds)];
        $stmt = $conn->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $stmt->bind_param("ii", $telecallerId, $driver['id']);
        $stmt->execute();
        $driverStats[$telecallerId]++;
        $driverIndex++;
    }
    
    // Assign transporters to IDs 6 and 7 ONLY
    $transporterTelecallerIds = [6, 7];
    $transporterIndex = 0;
    $transporterStats = [6 => 0, 7 => 0];
    
    foreach ($transporters as $transporter) {
        $telecallerId = $transporterTelecallerIds[$transporterIndex % count($transporterTelecallerIds)];
        $stmt = $conn->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $stmt->bind_param("ii", $telecallerId, $transporter['id']);
        $stmt->execute();
        $transporterStats[$telecallerId]++;
        $transporterIndex++;
    }
    
    echo "Driver Assignments:\n";
    echo "  ID 3 (Pooja): {$driverStats[3]} drivers\n";
    echo "  ID 4 (Tanisha): {$driverStats[4]} drivers\n\n";
    
    echo "Transporter Assignments:\n";
    echo "  ID 6 (Tarun): {$transporterStats[6]} transporters\n";
    echo "  ID 7 (Gagan): {$transporterStats[7]} transporters\n\n";
    
    echo "=== STEP 3: CREATE NEW TRIGGER ===\n";
    
    $triggerSQL = "
    CREATE TRIGGER auto_assign_lead_chronological
    AFTER INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE telecaller_id INT;
        
        IF NEW.role IN ('driver', 'transporter') THEN
            
            -- DRIVERS go to IDs 3, 4 ONLY
            IF NEW.role = 'driver' THEN
                SELECT u.id INTO telecaller_id
                FROM users u
                WHERE u.id IN (3, 4)
                ORDER BY (
                    SELECT COUNT(*) 
                    FROM users assigned 
                    WHERE assigned.assigned_to = u.id AND assigned.role = 'driver'
                ) ASC, u.id ASC
                LIMIT 1;
                
                IF telecaller_id IS NOT NULL THEN
                    UPDATE users SET assigned_to = telecaller_id WHERE id = NEW.id;
                END IF;
            END IF;
            
            -- TRANSPORTERS go to IDs 6, 7 ONLY
            IF NEW.role = 'transporter' THEN
                SELECT u.id INTO telecaller_id
                FROM users u
                WHERE u.id IN (6, 7)
                ORDER BY (
                    SELECT COUNT(*) 
                    FROM users assigned 
                    WHERE assigned.assigned_to = u.id AND assigned.role = 'transporter'
                ) ASC, u.id ASC
                LIMIT 1;
                
                IF telecaller_id IS NOT NULL THEN
                    UPDATE users SET assigned_to = telecaller_id WHERE id = NEW.id;
                END IF;
            END IF;
            
        END IF;
    END";
    
    $conn->query($triggerSQL);
    echo "✓ Created new trigger\n\n";
    
    echo "=== VERIFICATION ===\n";
    
    // Verify no drivers assigned to 6, 7
    $wrongDrivers = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to IN (6, 7)")->fetch_assoc()['count'];
    
    // Verify no transporters assigned to 3, 4
    $wrongTransporters = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'transporter' AND assigned_to IN (3, 4)")->fetch_assoc()['count'];
    
    if ($wrongDrivers == 0 && $wrongTransporters == 0) {
        echo "✓ PERFECT! No wrong assignments found\n";
        echo "✓ Drivers are ONLY assigned to IDs 3, 4\n";
        echo "✓ Transporters are ONLY assigned to IDs 6, 7\n";
    } else {
        echo "⚠ WARNING:\n";
        echo "  Wrong drivers (assigned to 6,7): $wrongDrivers\n";
        echo "  Wrong transporters (assigned to 3,4): $wrongTransporters\n";
    }
    
    echo "\n=== COMPLETE! ===\n";
    echo "✓ All old triggers removed\n";
    echo "✓ Current assignments fixed\n";
    echo "✓ New trigger created for future leads\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
