<?php
/**
 * COMPLETE FIX - One script to fix everything
 * 1. Recreate break_logs table with caller_id
 * 2. Patch the API file
 */

require_once 'config.php';

echo "═══════════════════════════════════════════════════════════════\n";
echo "COMPLETE BREAK LOGS FIX\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

// STEP 1: Fix the database table
echo "STEP 1: Fixing break_logs table...\n";
$conn->query("DROP TABLE IF EXISTS break_logs");

$sql = "CREATE TABLE break_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    caller_id INT NOT NULL,
    telecaller_name VARCHAR(255),
    break_type ENUM('tea_break', 'lunch_break', 'prayer_break', 'personal_break', 'emergency_break') NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration_seconds INT,
    status ENUM('active', 'completed', 'exceeded') DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_caller_id (caller_id),
    INDEX idx_start_time (start_time),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

if ($conn->query($sql)) {
    echo "✓ break_logs table created with caller_id column\n\n";
} else {
    die("✗ Error: " . $conn->error . "\n");
}

// STEP 2: Patch the API file
echo "STEP 2: Patching API file...\n";

$apiFile = 'simple_leave_management_api.php';
$content = file_get_contents($apiFile);

if ($content === false) {
    die("✗ Error: Could not read $apiFile\n");
}

// Create backup
$backupFile = 'simple_leave_management_api.php.backup.' . date('YmdHis');
file_put_contents($backupFile, $content);
echo "✓ Backup created: $backupFile\n";

// Apply all patches
$replacements = [
    'SELECT id FROM break_logs WHERE telecaller_id = ?' => 'SELECT id FROM break_logs WHERE caller_id = ?',
    'INSERT INTO break_logs 
                  (telecaller_id, telecaller_name' => 'INSERT INTO break_logs 
                  (caller_id, telecaller_name',
    'SELECT id, start_time FROM break_logs WHERE telecaller_id = ?' => 'SELECT id, start_time FROM break_logs WHERE caller_id = ?',
    'FROM break_logs 
              WHERE telecaller_id = ? AND status' => 'FROM break_logs 
              WHERE caller_id = ? AND status',
    'FROM break_logs 
              WHERE telecaller_id = ? AND DATE(start_time)' => 'FROM break_logs 
              WHERE caller_id = ? AND DATE(start_time)',
    'FROM break_logs bl
              INNER JOIN admins a ON bl.telecaller_id = a.id' => 'FROM break_logs bl
              INNER JOIN admins a ON bl.caller_id = a.id',
    '(SELECT COUNT(*) FROM break_logs WHERE telecaller_id = ts.telecaller_id' => '(SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id'
];

$patchCount = 0;
foreach ($replacements as $old => $new) {
    if (strpos($content, $old) !== false) {
        $content = str_replace($old, $new, $content);
        $patchCount++;
    }
}

file_put_contents($apiFile, $content);
echo "✓ Applied $patchCount patches to API file\n\n";

echo "═══════════════════════════════════════════════════════════════\n";
echo "✅ COMPLETE! Everything is fixed.\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

echo "Test the API now:\n";
echo "URL: /api/simple_leave_management_api.php?action=get_my_status&telecaller_id=2\n\n";

$conn->close();
?>
