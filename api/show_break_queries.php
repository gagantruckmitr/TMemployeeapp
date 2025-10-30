<?php
/**
 * Show what queries are actually in the production file
 */

$file = 'simple_leave_management_api.php';
$content = file_get_contents($file);

echo "Searching for break_logs queries in $file...\n\n";

// Find all break_logs queries
preg_match_all('/FROM break_logs.*?WHERE.*?[\r\n]/s', $content, $matches);

if (!empty($matches[0])) {
    echo "Found " . count($matches[0]) . " break_logs queries:\n\n";
    foreach ($matches[0] as $i => $match) {
        echo "Query " . ($i + 1) . ":\n";
        echo trim($match) . "\n";
        
        if (strpos($match, 'telecaller_id') !== false) {
            echo "❌ STILL USES telecaller_id - NEEDS FIX\n";
        } else if (strpos($match, 'caller_id') !== false) {
            echo "✓ Uses caller_id - CORRECT\n";
        }
        echo "\n";
    }
} else {
    echo "No break_logs queries found\n";
}

// Also check INSERT queries
preg_match_all('/INSERT INTO break_logs.*?\)/s', $content, $inserts);
if (!empty($inserts[0])) {
    echo "\nINSERT queries:\n\n";
    foreach ($inserts[0] as $i => $match) {
        echo "Insert " . ($i + 1) . ":\n";
        echo trim($match) . "\n";
        
        if (strpos($match, 'telecaller_id') !== false) {
            echo "❌ STILL USES telecaller_id - NEEDS FIX\n";
        } else if (strpos($match, 'caller_id') !== false) {
            echo "✓ Uses caller_id - CORRECT\n";
        }
        echo "\n";
    }
}

// Check JOIN queries
preg_match_all('/FROM break_logs.*?JOIN.*?ON.*?[\r\n]/s', $content, $joins);
if (!empty($joins[0])) {
    echo "\nJOIN queries:\n\n";
    foreach ($joins[0] as $i => $match) {
        echo "Join " . ($i + 1) . ":\n";
        echo trim($match) . "\n";
        
        if (strpos($match, 'bl.telecaller_id') !== false) {
            echo "❌ STILL USES telecaller_id - NEEDS FIX\n";
        } else if (strpos($match, 'bl.caller_id') !== false) {
            echo "✓ Uses caller_id - CORRECT\n";
        }
        echo "\n";
    }
}
?>
