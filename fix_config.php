<?php
/**
 * Quick fix for config.php - removes the PDO code that's outside PHP tags
 */

$configFile = 'api/config.php';
$content = file_get_contents($configFile);

// Remove the PDO code that's outside PHP tags (after ?>)
$content = preg_replace('/\?>\s*\/\/ ====.*?PDO CONNECTION.*?\}/s', '?>', $content);

// Add PDO connection before the closing ?>
$pdoCode = "
// ============================================
// PDO CONNECTION (for admin panel)
// ============================================
try {
    \$pdo = new PDO(
        \"mysql:host=\" . DB_HOST . \";port=\" . DB_PORT . \";dbname=\" . DB_NAME . \";charset=utf8mb4\",
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
} catch(PDOException \$e) {
    error_log('PDO Connection Error: ' . \$e->getMessage());
    if (DB_HOST === 'localhost') {
        die('Database connection failed: ' . \$e->getMessage());
    } else {
        die('Database connection failed. Please contact administrator.');
    }
}

?>";

$content = str_replace('?>', $pdoCode, $content);

file_put_contents($configFile, $content);

echo "✅ config.php fixed!\n";
echo "Now run: fix_ip.php to change IP address\n";
?>
