<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
set_time_limit(60);

require_once 'config.php';

echo "SIMPLE TRIGGER SETUP\n";
echo "====================\n\n";

try {
    // Step 1: List existing triggers
    echo "Step 1: Checking existing triggers...\n";
    $existingTriggers = $conn->query("SHOW TRIGGERS WHERE `Table` = 'drivers'")->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($existingTriggers) > 0) {
        echo "Found " . count($existingTriggers) . " triggers:\n";
        foreach ($existingTriggers as $t) {
            echo "  - {$t['Trigger']}\n";
            // Drop each one
            try {
                $conn->exec("DROP TRIGGER IF EXISTS `{$t['Trigger']}`");
                echo "    ✓ Dropped\n";
            } catch (Exception $e) {
                echo "    ✗ Error: " . $e->getMessage() . "\n";
            }
        }
    } else {
        echo "  No existing triggers found\n";
    }
    
    // Step 2: Create new trigger
    echo "\nStep 2: Creating new trigger...\n";
    
    $conn->exec("
        CREATE TRIGGER auto_assign_new_leads
        AFTER INSERT ON drivers
        FOR EACH ROW
        BEGIN
            DECLARE next_tc INT;
            
            IF NEW.assigned_to IS NULL THEN
                SELECT u.id INTO next_tc
                FROM users u
                LEFT JOIN (
                    SELECT assigned_to, COUNT(*) as cnt
                    FROM drivers
                    WHERE assigned_to IS NOT NULL
                    GROUP BY assigned_to
                ) d ON u.id = d.assigned_to
                WHERE u.role = NEW.role
                ORDER BY COALESCE(d.cnt, 0) ASC, u.id ASC
                LIMIT 1;
                
                IF next_tc IS NOT NULL THEN
                    UPDATE drivers SET assigned_to = next_tc WHERE id = NEW.id;
                END IF;
            END IF;
        END;
    ");
    
    echo "  ✓ Trigger created!\n";
    
    // Step 3: Verify
    echo "\nStep 3: Verification...\n";
    $newTriggers = $conn->query("SHOW TRIGGERS WHERE `Table` = 'drivers'")->fetchAll(PDO::FETCH_ASSOC);
    echo "  Active triggers: " . count($newTriggers) . "\n";
    foreach ($newTriggers as $t) {
        echo "    - {$t['Trigger']} ({$t['Event']} {$t['Timing']})\n";
    }
    
    // Show telecallers
    echo "\nTelecallers:\n";
    $tcs = $conn->query("SELECT id, name, role FROM users WHERE role IN ('driver', 'transporter') ORDER BY id")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($tcs as $tc) {
        echo "  ID {$tc['id']}: {$tc['name']} ({$tc['role']})\n";
    }
    
    echo "\n✓ DONE!\n";
    
} catch (Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
    echo "Code: " . $e->getCode() . "\n";
}
