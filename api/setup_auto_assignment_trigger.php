<?php
/**
 * Setup Automatic Telecaller Assignment Trigger
 * This creates a MySQL trigger for automatic assignment on new registrations
 */

header('Content-Type: text/plain; charset=utf-8');

$host = 'localhost';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=================================================\n";
    echo "   AUTO-ASSIGNMENT TRIGGER SETUP\n";
    echo "=================================================\n\n";
    
    // Step 1: Drop existing trigger
    echo "Step 1: Removing old trigger...\n";
    $pdo->exec("DROP TRIGGER IF EXISTS auto_assign_telecaller_on_insert");
    echo "✅ Done\n\n";
    
    // Step 2: Create new trigger
    echo "Step 2: Creating trigger...\n";
    
    $triggerSQL = "
    CREATE TRIGGER auto_assign_telecaller_on_insert
    BEFORE INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE telecaller_id INT;
        
        -- ONLY assign transporters (drivers are handled by existing system)
        IF NEW.assigned_to IS NULL AND NEW.role = 'transporter' THEN
            
            -- Assign to Tarun or Gagan (round-robin)
            SELECT a.id INTO telecaller_id
            FROM admins a
            LEFT JOIN users u ON a.id = u.assigned_to AND u.role = 'transporter'
            WHERE a.role = 'telecaller' 
            AND (a.name LIKE '%Tarun%' OR a.name LIKE '%Gagan%')
            GROUP BY a.id
            ORDER BY COUNT(u.id) ASC, a.id ASC
            LIMIT 1;
            
            IF telecaller_id IS NOT NULL THEN
                SET NEW.assigned_to = telecaller_id;
            END IF;
            
        END IF;
    END
    ";
    
    $pdo->exec($triggerSQL);
    echo "✅ Trigger created!\n\n";
    
    // Step 3: Verify
    echo "Step 3: Verifying...\n";
    $stmt = $pdo->query("SHOW TRIGGERS WHERE `Trigger` = 'auto_assign_telecaller_on_insert'");
    $trigger = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($trigger) {
        echo "✅ Trigger is active!\n\n";
    }
    
    echo "=================================================\n";
    echo "✅ SETUP COMPLETE!\n";
    echo "=================================================\n\n";
    
    echo "HOW IT WORKS:\n";
    echo "• When a new TRANSPORTER registers from ANY app\n";
    echo "• Trigger runs automatically before insert\n";
    echo "• Assigns to Tarun or Gagan (round-robin)\n";
    echo "• Drivers use existing assignment system\n";
    echo "• No code changes needed in your other app!\n\n";
    
} catch(PDOException $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
