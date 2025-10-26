<?php
/**
 * Complete TruckMitr Setup & Test Script
 * Tests all components after database recreation
 */

echo "╔══════════════════════════════════════════════════════════════╗\n";
echo "║         TruckMitr Complete Setup & Test Script              ║\n";
echo "╚══════════════════════════════════════════════════════════════╝\n\n";

// Database credentials from .env
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

// Test 1: Database Connection
echo "Test 1: Database Connection\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✅ Database connection successful\n";
    echo "   Host: $host\n";
    echo "   Database: $dbname\n";
    echo "   User: $username\n\n";
} catch(PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "\n\n";
    echo "Please check:\n";
    echo "1. MySQL is running\n";
    echo "2. Database 'truckmitr' exists\n";
    echo "3. User 'truckmitr' has access\n";
    echo "4. Password is correct: 825Redp&4\n\n";
    exit;
}

// Test 2: Check Required Tables
echo "Test 2: Required Tables\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
$requiredTables = ['users', 'call_logs', 'payments', 'telecaller_status'];
$missingTables = [];

foreach ($requiredTables as $table) {
    try {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($stmt->rowCount() > 0) {
            $countStmt = $pdo->query("SELECT COUNT(*) as count FROM $table");
            $count = $countStmt->fetch(PDO::FETCH_ASSOC)['count'];
            echo "✅ $table (Records: $count)\n";
        } else {
            echo "❌ $table - NOT FOUND\n";
            $missingTables[] = $table;
        }
    } catch(Exception $e) {
        echo "❌ $table - ERROR: " . $e->getMessage() . "\n";
        $missingTables[] = $table;
    }
}

if (!empty($missingTables)) {
    echo "\n⚠️  Missing tables detected!\n";
    echo "Run: mysql -u $username -p$password $dbname < setup_complete_database.sql\n\n";
} else {
    echo "\n";
}

// Test 3: Check call_logs Structure
echo "Test 3: Call Logs Table Structure\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
try {
    $stmt = $pdo->query("DESCRIBE call_logs");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    $requiredColumns = ['id', 'caller_id', 'user_id', 'reference_id', 'api_response', 'call_duration', 'call_status'];
    $missingColumns = array_diff($requiredColumns, $columns);
    
    if (empty($missingColumns)) {
        echo "✅ All required columns exist\n";
        echo "   Columns: " . implode(', ', $columns) . "\n\n";
    } else {
        echo "❌ Missing columns: " . implode(', ', $missingColumns) . "\n";
        echo "Run: ALTER TABLE call_logs ADD COLUMN call_duration INT DEFAULT 0;\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error checking table: " . $e->getMessage() . "\n\n";
}

// Test 4: Check Users
echo "Test 4: Users by Role\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
try {
    $stmt = $pdo->query("
        SELECT role, status, COUNT(*) as count 
        FROM users 
        GROUP BY role, status 
        ORDER BY role, status
    ");
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($results) > 0) {
        foreach ($results as $row) {
            $icon = $row['status'] === 'active' ? '✅' : '⚠️ ';
            echo "$icon {$row['role']} ({$row['status']}): {$row['count']}\n";
        }
        echo "\n";
    } else {
        echo "⚠️  No users found. Run setup_complete_database.sql to add sample users.\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 5: Check Active Telecallers
echo "Test 5: Active Telecallers\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
try {
    $stmt = $pdo->query("
        SELECT id, unique_id, name, mobile 
        FROM users 
        WHERE role = 'telecaller' AND status = 'active'
        ORDER BY id
    ");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($telecallers) > 0) {
        echo "✅ Found " . count($telecallers) . " active telecaller(s)\n";
        foreach ($telecallers as $tc) {
            echo "   TC{$tc['id']}: {$tc['name']} ({$tc['unique_id']}) - {$tc['mobile']}\n";
        }
        echo "\n";
    } else {
        echo "⚠️  No active telecallers found\n";
        echo "Run setup_complete_database.sql to add sample telecallers\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 6: Check Drivers
echo "Test 6: Available Drivers\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
try {
    $stmt = $pdo->query("
        SELECT status, COUNT(*) as count 
        FROM users 
        WHERE role = 'driver' 
        GROUP BY status
    ");
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $totalDrivers = 0;
    foreach ($results as $row) {
        $totalDrivers += $row['count'];
        echo "   {$row['status']}: {$row['count']}\n";
    }
    echo "✅ Total drivers: $totalDrivers\n\n";
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 7: Round-Robin Distribution
echo "Test 7: Round-Robin Lead Distribution\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
try {
    $stmt = $pdo->query("SELECT id, name FROM users WHERE role = 'telecaller' AND status = 'active' ORDER BY id");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $telecallerCount = count($telecallers);
    
    if ($telecallerCount > 0) {
        echo "Testing distribution for $telecallerCount telecaller(s):\n";
        
        foreach ($telecallers as $index => $tc) {
            $stmt = $pdo->prepare("
                SELECT COUNT(*) as count 
                FROM users 
                WHERE role = 'driver' 
                AND MOD(id, ?) = ?
                AND id NOT IN (SELECT DISTINCT user_id FROM call_logs)
            ");
            $stmt->execute([$telecallerCount, $index]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            echo "   TC{$tc['id']} ({$tc['name']}): {$result['count']} fresh leads\n";
        }
        echo "✅ Round-robin distribution working\n\n";
    } else {
        echo "⚠️  Cannot test - no telecallers found\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 8: API Files
echo "Test 8: API Files\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
$apiFiles = [
    'api/config.php' => 'Core config',
    'api/auth_api.php' => 'Authentication',
    'api/fresh_leads_api.php' => 'Fresh leads (Round-robin)',
    'api/ivr_call_api.php' => 'IVR calling',
    'api/dashboard_stats_api.php' => 'Dashboard stats',
    'api/manager_dashboard_api.php' => 'Manager dashboard',
    'api/telecaller_analytics_api.php' => 'Analytics',
];

foreach ($apiFiles as $file => $description) {
    if (file_exists($file)) {
        echo "✅ $description - $file\n";
    } else {
        echo "❌ $description - $file NOT FOUND\n";
    }
}
echo "\n";

// Test 9: Database Credentials in API Files
echo "Test 9: Database Credentials in API Files\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
$filesToCheck = [
    'api/config.php',
    'api/fresh_leads_api.php',
    'api/ivr_call_api.php',
    'api/auth_api.php',
];

$allCorrect = true;
foreach ($filesToCheck as $file) {
    if (file_exists($file)) {
        $content = file_get_contents($file);
        $hasCorrectCreds = (
            strpos($content, "truckmitr") !== false &&
            strpos($content, "825Redp&4") !== false
        );
        
        if ($hasCorrectCreds) {
            echo "✅ $file - Credentials updated\n";
        } else {
            echo "❌ $file - Needs credential update\n";
            $allCorrect = false;
        }
    }
}

if ($allCorrect) {
    echo "✅ All API files have correct credentials\n\n";
} else {
    echo "⚠️  Some files need credential updates\n\n";
}

// Test 10: MyOperator Configuration
echo "Test 10: MyOperator Configuration\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
if (file_exists('api/ivr_call_api.php')) {
    $content = file_get_contents('api/ivr_call_api.php');
    
    $checks = [
        'MYOPERATOR_COMPANY_ID' => strpos($content, "define('MYOPERATOR_COMPANY_ID'") !== false,
        'MYOPERATOR_SECRET_TOKEN' => strpos($content, "define('MYOPERATOR_SECRET_TOKEN'") !== false,
        'MYOPERATOR_IVR_ID' => strpos($content, "define('MYOPERATOR_IVR_ID'") !== false,
        'MYOPERATOR_API_KEY' => strpos($content, "define('MYOPERATOR_API_KEY'") !== false,
    ];
    
    $configured = true;
    foreach ($checks as $key => $exists) {
        if ($exists) {
            if (strpos($content, "'your_") !== false) {
                echo "⚠️  $key - Needs configuration\n";
                $configured = false;
            } else {
                echo "✅ $key - Configured\n";
            }
        } else {
            echo "❌ $key - Not found\n";
            $configured = false;
        }
    }
    
    if (!$configured) {
        echo "\n⚠️  Add MyOperator credentials to .env file:\n";
        echo "MYOPERATOR_COMPANY_ID=your_company_id\n";
        echo "MYOPERATOR_SECRET_TOKEN=your_secret_token\n";
        echo "MYOPERATOR_IVR_ID=your_ivr_id\n";
        echo "MYOPERATOR_API_KEY=your_api_key\n";
        echo "MYOPERATOR_CALLER_ID=+91XXXXXXXXXX\n";
    }
} else {
    echo "❌ ivr_call_api.php not found\n";
}
echo "\n";

// Summary
echo "╔══════════════════════════════════════════════════════════════╗\n";
echo "║                      SETUP SUMMARY                           ║\n";
echo "╚══════════════════════════════════════════════════════════════╝\n\n";

echo "Legend:\n";
echo "✅ = Working correctly\n";
echo "⚠️  = Needs attention\n";
echo "❌ = Error/Missing\n\n";

echo "Next Steps:\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "1. If tables missing:\n";
echo "   mysql -u $username -p$password $dbname < setup_complete_database.sql\n\n";
echo "2. Add MyOperator credentials to .env file\n\n";
echo "3. Test API endpoints:\n";
echo "   http://192.168.29.149/api/auth_api.php\n";
echo "   http://192.168.29.149/api/fresh_leads_api.php?action=fresh_leads&caller_id=1\n\n";
echo "4. Rebuild Flutter app:\n";
echo "   flutter clean && flutter pub get && flutter run\n\n";

echo "For detailed documentation, see:\n";
echo "- QUICK_START_IVR.md\n";
echo "- MYOPERATOR_SETUP_GUIDE.md\n";
echo "- 🎯_IMPLEMENTATION_COMPLETE.md\n\n";

echo "╔══════════════════════════════════════════════════════════════╗\n";
echo "║                    TEST COMPLETE!                            ║\n";
echo "╚══════════════════════════════════════════════════════════════╝\n";
?>
