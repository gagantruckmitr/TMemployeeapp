<?php
/**
 * View feedback error logs
 */

$logFile = __DIR__ . '/feedback_errors.log';

header('Content-Type: text/html; charset=utf-8');

echo "<h2>Phase 2 Feedback Error Log</h2>";
echo "<p><a href='?clear=1'>Clear Log</a> | <a href='?refresh=1'>Refresh</a></p>";

if (isset($_GET['clear'])) {
    file_put_contents($logFile, '');
    echo "<p style='color:green'>Log cleared!</p>";
}

if (file_exists($logFile)) {
    $content = file_get_contents($logFile);
    if (empty($content)) {
        echo "<p>Log is empty. No errors yet.</p>";
    } else {
        echo "<pre style='background:#f5f5f5; padding:15px; border:1px solid #ddd; max-height:600px; overflow:auto;'>";
        echo htmlspecialchars($content);
        echo "</pre>";
    }
    
    echo "<p><strong>Last modified:</strong> " . date('Y-m-d H:i:s', filemtime($logFile)) . "</p>";
} else {
    echo "<p>Log file doesn't exist yet. It will be created when the first error occurs.</p>";
}

echo "<hr>";
echo "<p><small>Log file: $logFile</small></p>";
?>
