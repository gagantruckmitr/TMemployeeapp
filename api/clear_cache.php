<?php
/**
 * Clear PHP opcache and restart
 */

echo "Clearing PHP cache...\n\n";

// Clear opcache if available
if (function_exists('opcache_reset')) {
    opcache_reset();
    echo "✓ Opcache cleared\n";
} else {
    echo "⚠ Opcache not available\n";
}

// Clear realpath cache
clearstatcache(true);
echo "✓ Stat cache cleared\n";

// Force reload of enhanced_leave_management_api.php
if (file_exists('enhanced_leave_management_api.php')) {
    touch('enhanced_leave_management_api.php');
    echo "✓ Touched enhanced_leave_management_api.php\n";
}

echo "\n✅ Cache cleared! Try the break function again.\n";
?>
