<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "CREATING TRIGGER (NO CHECKS)\n";
echo "=============================\n\n";

try {
    echo "Creating trigger 'auto_assign_new_leads'...\n";
    
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
    
    echo "✓ Trigger created successfully!\n\n";
    echo "The trigger will now auto-assign new leads based on role matching.\n";
    
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n\n";
    
    if (strpos($e->getMessage(), 'already exists') !== false) {
        echo "The trigger already exists. You need to drop it first.\n";
        echo "Go to phpMyAdmin > truckmitr database > Triggers tab\n";
        echo "And manually delete any existing triggers on the 'drivers' table.\n";
    }
}
