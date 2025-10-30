<?php
/**
 * Patch script to fix simple_leave_management_api.php
 * Changes all break_logs queries from telecaller_id to caller_id
 */

$apiFile = 'simple_leave_management_api.php';
$backupFile = 'simple_leave_management_api.php.backup';

echo "Patching $apiFile...\n\n";

// Read the file
$content = file_get_contents($apiFile);

if ($content === false) {
    die("Error: Could not read $apiFile\n");
}

// Create backup
file_put_contents($backupFile, $content);
echo "✓ Backup created: $backupFile\n";

// Apply patches - only for break_logs table queries
$patches = [
    // Patch 1: Check for active break
    [
        'old' => 'SELECT id FROM break_logs WHERE telecaller_id = ? AND status',
        'new' => 'SELECT id FROM break_logs WHERE caller_id = ? AND status'
    ],
    // Patch 2: Insert break log
    [
        'old' => 'INSERT INTO break_logs 
                  (telecaller_id, telecaller_name',
        'new' => 'INSERT INTO break_logs 
                  (caller_id, telecaller_name'
    ],
    // Patch 3: Get active break for ending
    [
        'old' => 'SELECT id, start_time FROM break_logs WHERE telecaller_id = ? AND status',
        'new' => 'SELECT id, start_time FROM break_logs WHERE caller_id = ? AND status'
    ],
    // Patch 4: Get active break display
    [
        'old' => 'FROM break_logs 
              WHERE telecaller_id = ? AND status',
        'new' => 'FROM break_logs 
              WHERE caller_id = ? AND status'
    ],
    // Patch 5: Get break history
    [
        'old' => 'FROM break_logs 
              WHERE telecaller_id = ? AND DATE(start_time)',
        'new' => 'FROM break_logs 
              WHERE caller_id = ? AND DATE(start_time)'
    ],
    // Patch 6: Join in get active breaks
    [
        'old' => 'FROM break_logs bl
              INNER JOIN admins a ON bl.telecaller_id = a.id',
        'new' => 'FROM break_logs bl
              INNER JOIN admins a ON bl.caller_id = a.id'
    ],
    // Patch 7: Count breaks in status query
    [
        'old' => '(SELECT COUNT(*) FROM break_logs WHERE telecaller_id = ts.telecaller_id',
        'new' => '(SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id'
    ]
];

$patchCount = 0;
foreach ($patches as $i => $patch) {
    $oldContent = $content;
    $content = str_replace($patch['old'], $patch['new'], $content);
    if ($content !== $oldContent) {
        $patchCount++;
        echo "✓ Applied patch " . ($i + 1) . "\n";
    }
}

// Write the patched file
file_put_contents($apiFile, $content);

echo "\n✅ Patching complete! Applied $patchCount patches.\n";
echo "Original file backed up to: $backupFile\n";
echo "\nNow test the API with: ?action=get_my_status&telecaller_id=2\n";
?>
