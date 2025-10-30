<?php
require_once 'config.php';

header('Content-Type: text/plain');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== STEP 1: Adding New Telecallers ===\n\n";
    
    // Telecallers to add
    $telecallers = [
        [
            'name' => 'Sonam',
            'mobile' => '7678361265',
            'email' => 'sonam@gmail.com',
            'password' => 'sonam@1234#'
        ],
        [
            'name' => 'Raksha',
            'mobile' => '9254972809',
            'email' => 'raksha@gmail.com',
            'password' => 'raksha@1234#'
        ],
        [
            'name' => 'Ankit Singh',
            'mobile' => '9254972815',
            'email' => 'ankitsingh@gmail.com',
            'password' => 'ankitsingh@1234#'
        ]
    ];
    
    $newTelecallerIds = [];
    
    foreach ($telecallers as $telecaller) {
        // Check if telecaller already exists
        $checkStmt = $pdo->prepare("SELECT id FROM admins WHERE mobile = ? OR email = ?");
        $checkStmt->execute([$telecaller['mobile'], $telecaller['email']]);
        $existing = $checkStmt->fetch();
        
        if ($existing) {
            echo "✓ {$telecaller['name']} already exists (ID: {$existing['id']})\n";
            $newTelecallerIds[] = $existing['id'];
            continue;
        }
        
        // Insert telecaller
        $stmt = $pdo->prepare("
            INSERT INTO admins (name, mobile, email, password, role, email_verified_at, created_at, updated_at) 
            VALUES (?, ?, ?, ?, 'telecaller', NOW(), NOW(), NOW())
        ");
        
        $hashedPassword = password_hash($telecaller['password'], PASSWORD_DEFAULT);
        $stmt->execute([
            $telecaller['name'],
            $telecaller['mobile'],
            $telecaller['email'],
            $hashedPassword
        ]);
        
        $telecallerId = $pdo->lastInsertId();
        $newTelecallerIds[] = $telecallerId;
        
        // Initialize telecaller status
        $statusStmt = $pdo->prepare("
            INSERT INTO telecaller_status (telecaller_id, status, last_activity, created_at, updated_at)
            VALUES (?, 'offline', NOW(), NOW(), NOW())
            ON DUPLICATE KEY UPDATE updated_at = NOW()
        ");
        $statusStmt->execute([$telecallerId]);
        
        echo "✓ Added {$telecaller['name']} (ID: $telecallerId)\n";
    }
    
    echo "\n=== STEP 2: Clearing Old Assignments (except 6 & 7) ===\n\n";
    
    // Clear assignments for telecallers other than 6 and 7 in users table
    $clearStmt = $pdo->prepare("
        UPDATE users 
        SET assigned_to = NULL 
        WHERE role = 'driver' 
        AND assigned_to IS NOT NULL 
        AND assigned_to != 0
        AND assigned_to NOT IN (6, 7)
    ");
    $clearStmt->execute();
    $clearedCount = $clearStmt->rowCount();
    echo "✓ Cleared $clearedCount lead assignments\n";
    
    echo "\n=== STEP 3: Assigning Top 50 Leads to Each Telecaller ===\n\n";
    
    // Active telecallers for round-robin
    $activeTelecallers = [3, 4, 8, 9, 10];
    $leadsPerTelecaller = 50;
    
    // Get top 250 unassigned leads (50 for each of 5 telecallers), ordered by date
    // Note: assigned_to might be NULL, 0, or not in (6,7)
    $getLeadsStmt = $pdo->query("
        SELECT id 
        FROM users 
        WHERE role = 'driver'
        AND (assigned_to IS NULL OR assigned_to = 0 OR assigned_to NOT IN (6, 7))
        ORDER BY Created_at ASC
        LIMIT " . ($leadsPerTelecaller * count($activeTelecallers))
    );
    
    $availableLeads = $getLeadsStmt->fetchAll(PDO::FETCH_COLUMN);
    $totalAvailable = count($availableLeads);
    
    echo "Found $totalAvailable leads to distribute\n\n";
    
    $distribution = [];
    $index = 0;
    
    foreach ($availableLeads as $leadId) {
        $telecallerId = $activeTelecallers[$index % count($activeTelecallers)];
        
        // Assign lead
        $assignStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $assignStmt->execute([$telecallerId, $leadId]);
        
        if (!isset($distribution[$telecallerId])) {
            $distribution[$telecallerId] = 0;
        }
        $distribution[$telecallerId]++;
        
        $index++;
    }
    
    echo "Distribution completed:\n";
    foreach ($activeTelecallers as $tid) {
        $count = isset($distribution[$tid]) ? $distribution[$tid] : 0;
        echo "  Telecaller $tid: $count leads\n";
    }
    
    // Get counts for telecallers 6 and 7
    $stmt6 = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to = 6");
    $count6 = $stmt6->fetch(PDO::FETCH_ASSOC)['count'];
    
    $stmt7 = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver' AND assigned_to = 7");
    $count7 = $stmt7->fetch(PDO::FETCH_ASSOC)['count'];
    
    echo "\nUnchanged assignments:\n";
    echo "  Telecaller 6: $count6 leads\n";
    echo "  Telecaller 7: $count7 leads\n";
    
    echo "\n=== STEP 4: Updating Auto-Assignment Trigger ===\n\n";
    
    // Drop existing triggers (check both tables)
    try {
        $pdo->exec("DROP TRIGGER IF EXISTS auto_assign_driver");
        echo "✓ Dropped old trigger from users table\n";
    } catch (Exception $e) {
        echo "Note: No existing trigger on users table\n";
    }
    
    try {
        $pdo->exec("DROP TRIGGER IF EXISTS drivers.auto_assign_driver");
        echo "✓ Dropped old trigger from drivers table\n";
    } catch (Exception $e) {
        echo "Note: No existing trigger on drivers table\n";
    }
    
    // Create new trigger for round-robin among 3, 4, 8, 9, 10
    $triggerSQL = "
    CREATE TRIGGER auto_assign_driver
    AFTER INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE next_telecaller INT;
        DECLARE last_assigned INT;
        
        -- Only process if the new user is a driver
        IF NEW.role = 'driver' THEN
            -- Get the last assigned telecaller from the round-robin pool
            SELECT assigned_to INTO last_assigned
            FROM users
            WHERE role = 'driver'
            AND assigned_to IN (3, 4, 8, 9, 10)
            AND id < NEW.id
            ORDER BY id DESC
            LIMIT 1;
            
            -- Determine next telecaller in round-robin: 3 → 4 → 8 → 9 → 10 → 3
            IF last_assigned IS NULL OR last_assigned = 10 THEN
                SET next_telecaller = 3;
            ELSEIF last_assigned = 3 THEN
                SET next_telecaller = 4;
            ELSEIF last_assigned = 4 THEN
                SET next_telecaller = 8;
            ELSEIF last_assigned = 8 THEN
                SET next_telecaller = 9;
            ELSEIF last_assigned = 9 THEN
                SET next_telecaller = 10;
            ELSE
                SET next_telecaller = 3;
            END IF;
            
            -- Assign the driver to the next telecaller
            UPDATE users 
            SET assigned_to = next_telecaller 
            WHERE id = NEW.id;
        END IF;
    END;
    ";
    
    $pdo->exec($triggerSQL);
    echo "✓ Created new trigger with pattern: 3 → 4 → 8 → 9 → 10 → 3\n";
    
    echo "\n=== SETUP COMPLETE ===\n\n";
    echo "Summary:\n";
    echo "- Active telecallers: 3, 4, 8, 9, 10 (round-robin)\n";
    echo "- Unchanged: 6, 7\n";
    echo "- Each active telecaller has up to 50 leads\n";
    echo "- Future leads will auto-assign in round-robin pattern\n";
    
} catch (Exception $e) {
    echo "\n❌ ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
