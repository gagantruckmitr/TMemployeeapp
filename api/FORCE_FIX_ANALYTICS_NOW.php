<?php
$file = 'telecaller_analytics_api.php';
$lines = file($file);
$fixed = [];

foreach ($lines as $line) {
    // Fix the WHERE clauses
    $line = preg_replace('/WHERE \(telecaller_id = \? OR caller_id = \?\)/', 'WHERE caller_id = ?', $line);
    
    // Fix the execute with 2 params to 1 param (but keep 3 params as 2)
    if (strpos($line, '->execute([$callerId, $callerId, $days])') !== false) {
        $line = str_replace('->execute([$callerId, $callerId, $days])', '->execute([$callerId, $days])', $line);
    } else if (strpos($line, '->execute([$callerId, $callerId])') !== false) {
        $line = str_replace('->execute([$callerId, $callerId])', '->execute([$callerId])', $line);
    }
    
    // Fix JOIN clauses
    $line = str_replace('cl.telecaller_id = a.id', 'cl.caller_id = a.id', $line);
    
    $fixed[] = $line;
}

file_put_contents($file, implode('', $fixed));

if (function_exists('opcache_reset')) {
    opcache_reset();
}

echo "✅ FORCED FIX COMPLETE!\n";
echo "All instances replaced using line-by-line processing.\n";
?>
