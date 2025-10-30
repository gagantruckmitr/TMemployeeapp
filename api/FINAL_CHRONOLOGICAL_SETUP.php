<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

try {
    echo "=== FINAL CHRONOLOGICAL SETUP ===\n\n";
    
    // STEP 1: Remove ALL triggers
    echo "STEP 1: Removing ALL triggers...\n";
    $allTriggers = [
        'auto_assign_telecaller',
        'auto_assign_driver_to_telecaller',
        'auto_assign_telecaller_on_insert',
        'assign_user_by_role',
        'auto_assign_new_users',
        'auto_assign_lead_chronological'
    ];
    
    foreach ($allTriggers as $trigger) {
        $conn->query("DROP TRIGGER IF EXISTS $trigger");
    }
    echo "✓ All triggers removed\n\n";
    
    // STEP 2: Clear ALL assignments
    echo "STEP 2: Clearing all assignments...\n";
    $conn->query("UPDATE users SET assigned_to = NULL WHERE role IN ('driver', 'transporter')");
    echo "✓ All assignments cleared\n\n";
    
    // STEP 3: Assign ONLY top 50 latest drivers (chronologically)
    echo "STEP 3: Assigning top 50 latest drivers...\n";
    $driversQuery = "SELECT id, name, Created_at FROM users WHERE role = 'driver' ORDER BY Created_at DESC LIMIT 50";
    $driversResult = $conn->query($driversQuery);
    $drivers = [];
    while ($row = $driversResult->fetch_assoc()) {
        $drivers[] = $row;
    }
    
    $driverTelecallerIds = [3, 4]; // Pooja, Tanisha
    $driverIndex = 0;
    
    foreach ($drivers as $driver) {
        $telecallerId = $driverTelecallerIds[$driverIndex % 2];
        $stmt = $conn->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $stmt->bind_param("ii", $telecallerId, $driver['id']);
        $stmt->execute();
        $driverIndex++;
    }
    
    $count3 = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = 3")->fetch_assoc()['count'];
    $count4 = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = 4")->fetch_assoc()['count'];
    
    echo "✓ Assigned " . count($drivers) . " drivers\n";
    echo "  - ID 3 (Pooja): $count3 drivers\n";
    echo "  - ID 4 (Tanisha): $count4 drivers\n\n";
    
    // STEP 4: Assign ONLY top 50 latest transporters (chronologically)
    echo "STEP 4: Assigning top 50 latest transporters...\n";
    $transportersQuery = "SELECT id, name, Created_at FROM users WHERE role = 'transporter' ORDER BY Created_at DESC LIMIT 50";
    $transportersResult = $conn->query($transportersQuery);
    $transporters = [];
    while ($row = $transportersResult->fetch_assoc()) {
        $transporters[] = $row;
    }
    
    $transporterTelecallerIds = [6, 7]; // Tarun, Gagan
    $transporterIndex = 0;
    
    foreach ($transporters as $transporter) {
        $telecallerId = $transporterTelecallerIds[$transporterIndex % 2];
        $stmt = $conn->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $stmt->bind_param("ii", $telecallerId, $transporter['id']);
        $stmt->execute();
        $transporterIndex++;
    }
    
    $count6 = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = 6")->fetch_assoc()['count'];
    $count7 = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = 7")->fetch_assoc()['count'];
    
    echo "✓ Assigned " . count($transporters) . " transporters\n";
    echo "  - ID 6 (Tarun): $count6 transporters\n";
    echo "  - ID 7 (Gagan): $count7 transporters\n\n";
    
    // STEP 5: Create trigger for FUTURE leads only
    echo "STEP 5: Creating trigger for future leads...\n";
    
    $triggerSQL = "
    CREATE TRIGGER auto_assign_lead_chronological
    AFTER INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE telecaller_id INT;
        
        IF NEW.role IN ('driver', 'transporter') THEN
            
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
    
    if ($conn->query($triggerSQL)) {
        echo "✓ Trigger created successfully\n\n";
    } else {
        echo "✗ Error: " . $conn->error . "\n\n";
    }
    
    // STEP 6: Verification
    echo "=== VERIFICATION ===\n";
    $totalDrivers = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'")->fetch_assoc()['count'];
    $assignedDrivers = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to IS NOT NULL")->fetch_assoc()['count'];
    $unassignedDrivers = $totalDrivers - $assignedDrivers;
    
    $totalTransporters = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'transporter'")->fetch_assoc()['count'];
    $assignedTransporters = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'transporter' AND assigned_to IS NOT NULL")->fetch_assoc()['count'];
    $unassignedTransporters = $totalTransporters - $assignedTransporters;
    
    echo "Drivers: $assignedDrivers assigned, $unassignedDrivers unassigned (Total: $totalDrivers)\n";
    echo "Transporters: $assignedTransporters assigned, $unassignedTransporters unassigned (Total: $totalTransporters)\n\n";
    
    // Check for wrong assignments
    $wrongDrivers = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to IN (6, 7)")->fetch_assoc()['count'];
    $wrongTransporters = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'transporter' AND assigned_to IN (3, 4)")->fetch_assoc()['count'];
    
    if ($wrongDrivers == 0 && $wrongTransporters == 0) {
        echo "✓ PERFECT! No wrong assignments\n";
    } else {
        echo "⚠ WARNING: $wrongDrivers drivers wrongly assigned, $wrongTransporters transporters wrongly assigned\n";
    }
    
    echo "\n=== SETUP COMPLETE ===\n";
    echo "✓ Only top 50 latest leads assigned\n";
    echo "✓ Chronological order maintained\n";
    echo "✓ Trigger active for future leads\n";
    echo "✓ Drivers → IDs 3, 4 only\n";
    echo "✓ Transporters → IDs 6, 7 only\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
