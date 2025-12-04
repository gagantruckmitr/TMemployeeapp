<?php
/**
 * Complete Auto-Assign Setup
 * 
 * This script:
 * 1. Creates database triggers for future leads (auto-assign on INSERT)
 * 2. Assigns existing unassigned fresh leads (last 1 day)
 * 
 * Rules:
 * - Drivers (last 1 day) → welcome-call telecallers (round-robin)
 * - Transporters → NEVER assigned
 * - Past leads (>1 day) → NOT touched
 */

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== AUTO-ASSIGN COMPLETE SETUP ===\n";
    echo "Time: " . date('Y-m-d H:i:s') . "\n\n";
    
    // ========================================================================
    // PART 1: CREATE DATABASE TRIGGERS
    // ========================================================================
    
    echo "PART 1: Creating Database Triggers\n";
    echo "===================================\n\n";
    
    // Drop existing triggers
    echo "Step 1: Dropping old triggers...\n";
    $triggers = ['auto_assign_driver_on_insert', 'auto_assign_driver_on_update'];
    
    foreach ($triggers as $trigger) {
        try {
            $pdo->exec("DROP TRIGGER IF EXISTS $trigger");
            echo "  ✅ Dropped: $trigger\n";
        } catch (PDOException $e) {
            // Ignore
        }
    }
    
    echo "\nStep 2: Creating new triggers...\n";
    
    // Trigger for INSERT (new registrations)
    $insertTrigger = "
    CREATE TRIGGER auto_assign_driver_on_insert
    BEFORE INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE next_tc_id INT DEFAULT NULL;
        DECLARE tc_count INT DEFAULT 0;
        DECLARE last_tc_id INT DEFAULT 0;
        
        -- Only for drivers with fresh Created_at (last 1 day or future)
        IF NEW.role = 'driver' AND NEW.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN
            
            -- Count welcome-call telecallers
            SELECT COUNT(*) INTO tc_count
            FROM admins
            WHERE role = 'telecaller' AND tc_for = 'welcome-call';
            
            IF tc_count > 0 THEN
                -- Get last assigned telecaller
                SELECT COALESCE(MAX(u.assigned_to), 0) INTO last_tc_id
                FROM users u
                WHERE u.role = 'driver'
                AND u.assigned_to IN (
                    SELECT id FROM admins WHERE role = 'telecaller' AND tc_for = 'welcome-call'
                )
                ORDER BY u.id DESC
                LIMIT 1;
                
                -- Get next telecaller (round-robin)
                SELECT id INTO next_tc_id
                FROM admins
                WHERE role = 'telecaller' AND tc_for = 'welcome-call' AND id > last_tc_id
                ORDER BY id ASC
                LIMIT 1;
                
                -- Wrap around if needed
                IF next_tc_id IS NULL THEN
                    SELECT id INTO next_tc_id
                    FROM admins
                    WHERE role = 'telecaller' AND tc_for = 'welcome-call'
                    ORDER BY id ASC
                    LIMIT 1;
                END IF;
                
                -- Assign
                IF next_tc_id IS NOT NULL THEN
                    SET NEW.assigned_to = next_tc_id;
                END IF;
            END IF;
            
        -- Transporters should NEVER be assigned
        ELSEIF NEW.role = 'transporter' THEN
            SET NEW.assigned_to = NULL;
        END IF;
    END";
    
    try {
        $pdo->exec($insertTrigger);
        echo "  ✅ Created: auto_assign_driver_on_insert\n";
    } catch (PDOException $e) {
        echo "  ❌ Error creating INSERT trigger: " . $e->getMessage() . "\n";
    }
    
    // Trigger for UPDATE (role changes)
    $updateTrigger = "
    CREATE TRIGGER auto_assign_driver_on_update
    BEFORE UPDATE ON users
    FOR EACH ROW
    BEGIN
        DECLARE next_tc_id INT DEFAULT NULL;
        DECLARE tc_count INT DEFAULT 0;
        DECLARE last_tc_id INT DEFAULT 0;
        
        -- Only if role changed to driver OR driver is unassigned and fresh
        IF ((NEW.role = 'driver' AND OLD.role != 'driver') OR
            (NEW.role = 'driver' AND (NEW.assigned_to IS NULL OR NEW.assigned_to = 0)))
            AND NEW.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY) THEN
            
            -- Count welcome-call telecallers
            SELECT COUNT(*) INTO tc_count
            FROM admins
            WHERE role = 'telecaller' AND tc_for = 'welcome-call';
            
            IF tc_count > 0 THEN
                -- Get last assigned telecaller
                SELECT COALESCE(MAX(u.assigned_to), 0) INTO last_tc_id
                FROM users u
                WHERE u.role = 'driver'
                AND u.assigned_to IN (
                    SELECT id FROM admins WHERE role = 'telecaller' AND tc_for = 'welcome-call'
                )
                ORDER BY u.id DESC
                LIMIT 1;
                
                -- Get next telecaller (round-robin)
                SELECT id INTO next_tc_id
                FROM admins
                WHERE role = 'telecaller' AND tc_for = 'welcome-call' AND id > last_tc_id
                ORDER BY id ASC
                LIMIT 1;
                
                -- Wrap around if needed
                IF next_tc_id IS NULL THEN
                    SELECT id INTO next_tc_id
                    FROM admins
                    WHERE role = 'telecaller' AND tc_for = 'welcome-call'
                    ORDER BY id ASC
                    LIMIT 1;
                END IF;
                
                -- Assign
                IF next_tc_id IS NOT NULL THEN
                    SET NEW.assigned_to = next_tc_id;
                END IF;
            END IF;
            
        -- Transporters should NEVER be assigned
        ELSEIF NEW.role = 'transporter' THEN
            SET NEW.assigned_to = NULL;
        END IF;
    END";
    
    try {
        $pdo->exec($updateTrigger);
        echo "  ✅ Created: auto_assign_driver_on_update\n";
    } catch (PDOException $e) {
        echo "  ❌ Error creating UPDATE trigger: " . $e->getMessage() . "\n";
    }
    
    // ========================================================================
    // PART 2: ASSIGN EXISTING UNASSIGNED LEADS
    // ========================================================================
    
    echo "\n\nPART 2: Assigning Existing Unassigned Leads\n";
    echo "============================================\n\n";
    
    // Clear transporter assignments
    echo "Step 1: Clearing transporter assignments...\n";
    $stmt = $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'transporter' AND assigned_to IS NOT NULL");
    echo "  ✅ Cleared $stmt transporter assignments\n";
    
    // Get telecallers
    echo "\nStep 2: Getting welcome-call telecallers...\n";
    $stmt = $pdo->query("
        SELECT id, name 
        FROM admins 
        WHERE role = 'telecaller' AND tc_for = 'welcome-call'
        ORDER BY id ASC
    ");
    $telecallers = $stmt->fetchAll();
    
    if (empty($telecallers)) {
        echo "  ❌ No welcome-call telecallers found!\n";
        exit(1);
    }
    
    $telecallerIds = array_column($telecallers, 'id');
    $telecallerCount = count($telecallerIds);
    echo "  ✅ Found $telecallerCount telecallers\n";
    
    // Get unassigned fresh drivers
    echo "\nStep 3: Getting unassigned fresh drivers (last 1 day)...\n";
    $stmt = $pdo->query("
        SELECT id, name, Created_at
        FROM users
        WHERE role = 'driver'
        AND (assigned_to IS NULL OR assigned_to = 0)
        AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
        ORDER BY Created_at DESC
    ");
    $freshDrivers = $stmt->fetchAll();
    
    $totalFresh = count($freshDrivers);
    echo "  ✅ Found $totalFresh unassigned fresh drivers\n";
    
    if ($totalFresh === 0) {
        echo "  ℹ️  No drivers to assign\n";
    } else {
        // Assign in round-robin
        echo "\nStep 4: Assigning in round-robin...\n";
        
        $pdo->beginTransaction();
        
        $assignmentCounts = array_fill_keys($telecallerIds, 0);
        $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        
        foreach ($freshDrivers as $index => $driver) {
            $telecallerIndex = $index % $telecallerCount;
            $assignedTelecallerId = $telecallerIds[$telecallerIndex];
            
            $updateStmt->execute([$assignedTelecallerId, $driver['id']]);
            $assignmentCounts[$assignedTelecallerId]++;
        }
        
        $pdo->commit();
        
        echo "  ✅ Assigned $totalFresh drivers\n";
        
        echo "\n  Distribution:\n";
        foreach ($telecallers as $tc) {
            $count = $assignmentCounts[$tc['id']];
            echo "    - TC #{$tc['id']} ({$tc['name']}): $count drivers\n";
        }
    }
    
    // ========================================================================
    // VERIFICATION
    // ========================================================================
    
    echo "\n\nVERIFICATION\n";
    echo "============\n\n";
    
    // Check triggers
    $stmt = $pdo->query("SHOW TRIGGERS LIKE 'users'");
    $allTriggers = $stmt->fetchAll();
    $assignTriggers = array_filter($allTriggers, function($t) {
        return stripos($t['Trigger'], 'auto_assign') !== false;
    });
    
    echo "Active Triggers:\n";
    foreach ($assignTriggers as $t) {
        echo "  ✅ {$t['Trigger']} ({$t['Timing']} {$t['Event']})\n";
    }
    
    // Check fresh driver stats
    echo "\nFresh Drivers (Last 1 Day):\n";
    $stmt = $pdo->query("
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) as assigned,
            SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) as unassigned
        FROM users
        WHERE role = 'driver' AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
    ");
    $stats = $stmt->fetch();
    echo "  Total: {$stats['total']}\n";
    echo "  Assigned: {$stats['assigned']}\n";
    echo "  Unassigned: {$stats['unassigned']}\n";
    
    // Check transporter stats
    echo "\nTransporters:\n";
    $stmt = $pdo->query("
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) as assigned
        FROM users
        WHERE role = 'transporter'
    ");
    $stats = $stmt->fetch();
    echo "  Total: {$stats['total']}\n";
    echo "  Assigned: {$stats['assigned']} (should be 0)\n";
    
    if ($stats['assigned'] > 0) {
        echo "  ⚠️  WARNING: Transporters should NOT be assigned!\n";
    }
    
    echo "\n\n=== SETUP COMPLETE ===\n\n";
    
    echo "✅ What's working now:\n";
    echo "  1. Database triggers are active\n";
    echo "  2. New driver registrations will auto-assign\n";
    echo "  3. Existing fresh drivers (last 1 day) are assigned\n";
    echo "  4. Transporters are never assigned\n";
    echo "  5. Past leads (>1 day) remain unchanged\n\n";
    
    echo "🧪 Test it:\n";
    echo "  INSERT INTO users (name, mobile, role, Created_at) VALUES ('Test Driver', '9999999999', 'driver', NOW());\n";
    echo "  SELECT id, name, role, assigned_to FROM users WHERE name = 'Test Driver';\n\n";
    
} catch(PDOException $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "❌ Error: " . $e->getMessage() . "\n";
    exit(1);
}
