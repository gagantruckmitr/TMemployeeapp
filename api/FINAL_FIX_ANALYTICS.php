<?php
$file = 'telecaller_analytics_api.php';
$content = file_get_contents($file);

// Backup
file_put_contents($file . '.bak2', $content);

// Fix all instances
$content = str_replace('(telecaller_id = ? OR caller_id = ?)', 'caller_id = ?', $content);
$content = str_replace('(cl.telecaller_id = ? OR cl.caller_id = ?)', 'cl.caller_id = ?', $content);
$content = str_replace('->execute([$callerId, $callerId])', '->execute([$callerId])', $content);

file_put_contents($file, $content);

// Clear cache
if (function_exists('opcache_reset')) {
    opcache_reset();
}

echo "✅ Fixed and cache cleared!\n";
echo "Test: https://truckmitr.com/truckmitr-app/api/telecaller_analytics_api.php?caller_id=3&period=week\n";
?>
