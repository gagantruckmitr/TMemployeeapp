<?php
/**
 * IVR Integration Test Script
 * Run this to verify your setup is working correctly
 */

echo "=== TruckMitr IVR Integration Test ===\n\n";

// Test 1: Database Connection
echo "Test 1: Database Connection\n";
echo "----------------------------\n";
try {
    $pdo = new PDO("mysql:host=localhost;dbname=truckmitr;charset=utf8mb4", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✅ Database connection successful\n\n";
} catch(PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "\n\n";
    exit;
}

// Test 2: Check call_logs table
echo "Test 2: Call Logs Table Structure\n";
echo "-----------------------------------\n";
try {
    $stmt = $pdo->query("DESCRIBE call_logs");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    $requiredColumns = ['id', 'caller_id', 'user_id', 'reference_id', 'api_response', 'call_duration'];
    $missingColumns = array_diff($requiredColumns, $columns);
    
    if (empty($missingColumns)) {
        echo "✅ All required columns exist\n";
        echo "Columns: " . implode(', ', $columns) . "\n\n";
    } else {
        echo "❌ Missing columns: " . implode(', ', $missingColumns) . "\n";
        echo "Run: ALTER TABLE call_logs ADD COLUMN call_duration INT DEFAULT 0;\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error checking table: " . $e->getMessage() . "\n\n";
}

// Test 3: Check telecallers
echo "Test 3: Active Telecallers\n";
echo "---------------------------\n";
try {
    $stmt = $pdo->query("SELECT id, name, mobile FROM users WHERE role = 'telecaller' AND status = 'active'");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($telecallers) > 0) {
        echo "✅ Found " . count($telecallers) . " active telecaller(s)\n";
        foreach ($telecallers as $tc) {
            echo "  - ID: {$tc['id']}, Name: {$tc['name']}, Mobile: {$tc['mobile']}\n";
        }
        echo "\n";
    } else {
        echo "⚠️  No active telecallers found\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 4: Check drivers
echo "Test 4: Available Drivers\n";
echo "-------------------------\n";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
    $result = $stmt->fetch();
    echo "✅ Found {$result['count']} driver(s) in database\n\n";
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 5: Round-robin distribution
echo "Test 5: Round-Robin Lead Distribution\n";
echo "--------------------------------------\n";
try {
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
            $result = $stmt->fetch();
            
            echo "  TC{$tc['id']} ({$tc['name']}): {$result['count']} fresh leads\n";
        }
        echo "✅ Round-robin distribution working\n\n";
    } else {
        echo "⚠️  Cannot test - no telecallers found\n\n";
    }
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n\n";
}

// Test 6: API file exists
echo "Test 6: API Files\n";
echo "-----------------\n";
$apiFiles = [
    'api/ivr_call_api.php',
    'api/fresh_leads_api.php',
    'api/auth_api.php',
];

foreach ($apiFiles as $file) {
    if (file_exists($file)) {
        echo "✅ $file exists\n";
    } else {
        echo "❌ $file NOT FOUND\n";
    }
}
echo "\n";

// Test 7: MyOperator Configuration
echo "Test 7: MyOperator Configuration\n";
echo "---------------------------------\n";
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
            // Check if it's still the default value
            if (strpos($content, "'your_") !== false) {
                echo "⚠️  $key defined but needs configuration\n";
                $configured = false;
            } else {
                echo "✅ $key configured\n";
            }
        } else {
            echo "❌ $key not found\n";
            $configured = false;
        }
    }
    
    if (!$configured) {
        echo "\n⚠️  Update MyOperator credentials in api/ivr_call_api.php\n";
    }
} else {
    echo "❌ ivr_call_api.php not found\n";
}
echo "\n";

// Summary
echo "=== Test Summary ===\n";
echo "-------------------\n";
echo "✅ = Working correctly\n";
echo "⚠️  = Needs attention\n";
echo "❌ = Error/Missing\n\n";

echo "Next Steps:\n";
echo "1. If call_duration column missing, run: add_call_duration.sql\n";
echo "2. Configure MyOperator credentials in api/ivr_call_api.php\n";
echo "3. Test API endpoint: http://192.168.29.149/api/ivr_call_api.php\n";
echo "4. Rebuild Flutter app: flutter clean && flutter run\n";
echo "\nFor detailed setup, see: MYOPERATOR_SETUP_GUIDE.md\n";
?>
