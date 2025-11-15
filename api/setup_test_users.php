<?php
/**
 * Setup Test Users for Click2Call IVR Testing
 * Adds telecaller and driver to database
 */

header('Content-Type: text/plain; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║         Setup Test Users for Click2Call IVR               ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo "✅ Database connected\n\n";
} catch (PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "\n";
    exit;
}

// Test user details
$telecaller_mobile = '6394756798';
$driver_mobile = '8448079624';

echo "Test Users:\n";
echo "├─ Telecaller: $telecaller_mobile\n";
echo "└─ Driver: $driver_mobile\n\n";

echo str_repeat("─", 60) . "\n\n";

// Step 1: Check/Add Telecaller
echo "Step 1: Setup Telecaller\n";

$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM admins WHERE mobile = ?");
$stmt->execute([$telecaller_mobile]);
$telecaller = $stmt->fetch(PDO::FETCH_ASSOC);

if ($telecaller) {
    echo "✓ Telecaller exists in database\n";
    echo "  ID: {$telecaller['id']}\n";
    echo "  Name: {$telecaller['name']}\n";
    echo "  Role: {$telecaller['role']}\n";
    
    if ($telecaller['role'] !== 'telecaller') {
        echo "  ⚠️  Updating role to 'telecaller'...\n";
        $stmt = $pdo->prepare("UPDATE admins SET role = 'telecaller' WHERE id = ?");
        $stmt->execute([$telecaller['id']]);
        echo "  ✅ Role updated to 'telecaller'\n";
    }
} else {
    echo "⚠️  Telecaller not found. Adding to database...\n";
    
    $stmt = $pdo->prepare("
        INSERT INTO admins (name, mobile, email, password, role, created_at, updated_at) 
        VALUES (?, ?, ?, ?, 'telecaller', NOW(), NOW())
    ");
    
    $password = password_hash('test123', PASSWORD_DEFAULT);
    $stmt->execute([
        'Test Telecaller',
        $telecaller_mobile,
        'telecaller@test.com',
        $password
    ]);
    
    $telecaller_id = $pdo->lastInsertId();
    echo "✅ Telecaller added successfully\n";
    echo "  ID: $telecaller_id\n";
    echo "  Name: Test Telecaller\n";
    echo "  Mobile: $telecaller_mobile\n";
    echo "  Email: telecaller@test.com\n";
    echo "  Password: test123\n";
}

echo "\n" . str_repeat("─", 60) . "\n\n";

// Step 2: Check/Add Driver
echo "Step 2: Setup Driver\n";

$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ?");
$stmt->execute([$driver_mobile]);
$driver = $stmt->fetch(PDO::FETCH_ASSOC);

if ($driver) {
    echo "✓ Driver exists in database\n";
    echo "  ID: {$driver['id']}\n";
    echo "  Name: {$driver['name']}\n";
    echo "  Role: {$driver['role']}\n";
} else {
    echo "⚠️  Driver not found. Adding to database...\n";
    
    $stmt = $pdo->prepare("
        INSERT INTO users (name, mobile, email, password, role, created_at, updated_at) 
        VALUES (?, ?, ?, ?, 'driver', NOW(), NOW())
    ");
    
    $password = password_hash('test123', PASSWORD_DEFAULT);
    $stmt->execute([
        'Test Driver',
        $driver_mobile,
        'driver@test.com',
        $password
    ]);
    
    $driver_id = $pdo->lastInsertId();
    echo "✅ Driver added successfully\n";
    echo "  ID: $driver_id\n";
    echo "  Name: Test Driver\n";
    echo "  Mobile: $driver_mobile\n";
    echo "  Email: driver@test.com\n";
    echo "  Password: test123\n";
}

echo "\n" . str_repeat("─", 60) . "\n\n";

// Step 3: Verify Setup
echo "Step 3: Verify Setup\n\n";

$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM admins WHERE mobile = ? AND role = 'telecaller'");
$stmt->execute([$telecaller_mobile]);
$telecaller = $stmt->fetch(PDO::FETCH_ASSOC);

$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ?");
$stmt->execute([$driver_mobile]);
$driver = $stmt->fetch(PDO::FETCH_ASSOC);

if ($telecaller && $driver) {
    echo "╔════════════════════════════════════════════════════════════╗\n";
    echo "║              ✅ SETUP COMPLETE - READY TO TEST             ║\n";
    echo "╚════════════════════════════════════════════════════════════╝\n\n";
    
    echo "📋 Test Configuration:\n";
    echo "├─ Telecaller ID: {$telecaller['id']}\n";
    echo "├─ Telecaller Name: {$telecaller['name']}\n";
    echo "├─ Telecaller Mobile: {$telecaller['mobile']}\n";
    echo "├─ Driver ID: {$driver['id']}\n";
    echo "├─ Driver Name: {$driver['name']}\n";
    echo "└─ Driver Mobile: {$driver['mobile']}\n\n";
    
    echo "🚀 Next Steps:\n";
    echo "1. Login to the app with telecaller credentials\n";
    echo "2. Go to Smart Calling page\n";
    echo "3. Find the test driver in the list\n";
    echo "4. Click call button\n";
    echo "5. Select 'IVR Call'\n";
    echo "6. Both phones will ring!\n\n";
    
    echo "📱 Login Credentials:\n";
    echo "   Mobile: $telecaller_mobile\n";
    echo "   Password: test123 (if newly created)\n\n";
    
} else {
    echo "❌ Setup verification failed\n";
    if (!$telecaller) echo "  - Telecaller not found\n";
    if (!$driver) echo "  - Driver not found\n";
}

echo str_repeat("═", 60) . "\n";
echo "Setup completed at: " . date('Y-m-d H:i:s') . "\n";
echo str_repeat("═", 60) . "\n";
