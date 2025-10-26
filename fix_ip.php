<?php
/**
 * Change IP address from 192.168.1.9 to 192.168.29.149
 */

$oldIp = '192.168.1.9';
$newIp = '192.168.29.149';

$files = [
    'lib/core/config/api_config.dart'
];

foreach ($files as $file) {
    if (file_exists($file)) {
        $content = file_get_contents($file);
        $content = str_replace($oldIp, $newIp, $content);
        file_put_contents($file, $content);
        echo "✅ Updated: $file\n";
    } else {
        echo "❌ Not found: $file\n";
    }
}

echo "\n✅ IP address changed from $oldIp to $newIp\n";
echo "New URL: http://$newIp/admin/login.php\n";
?>
