<?php
/**
 * Debug Environment Variables
 */

echo "<h1>Environment Variables Debug</h1>";
echo "<hr>";

// Find .env file
$possiblePaths = [
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
    dirname(dirname(__DIR__)) . '/.env',
    $_SERVER['DOCUMENT_ROOT'] . '/../.env',
];

echo "<h2>Searching for .env file:</h2>";
echo "<ul>";
foreach ($possiblePaths as $path) {
    $exists = file_exists($path);
    echo "<li>" . htmlspecialchars($path) . " - " . ($exists ? "<strong style='color:green;'>FOUND</strong>" : "not found") . "</li>";
    if ($exists) {
        $envFile = $path;
    }
}
echo "</ul>";

if (!isset($envFile)) {
    die("<p style='color:red;'>No .env file found!</p>");
}

echo "<h2>Reading .env file: " . htmlspecialchars($envFile) . "</h2>";

$lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
$telecmiVars = [];

echo "<h3>All lines in .env:</h3>";
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>#</th><th>Line Content</th><th>Parsed?</th></tr>";

$lineNum = 0;
foreach ($lines as $line) {
    $lineNum++;
    $trimmed = trim($line);
    
    // Check if it's a TELECMI line
    if (strpos($trimmed, 'TELECMI') !== false) {
        echo "<tr style='background:#ffffcc;'>";
    } else {
        echo "<tr>";
    }
    
    echo "<td>$lineNum</td>";
    echo "<td><code>" . htmlspecialchars($line) . "</code></td>";
    
    // Check if parseable
    if (strpos($trimmed, '#') === 0) {
        echo "<td>Comment</td>";
    } elseif (strpos($line, '=') === false) {
        echo "<td>No '=' found</td>";
    } else {
        list($name, $value) = explode('=', $line, 2);
        $name = trim($name);
        $value = trim($value);
        
        if (strpos($name, 'TELECMI') !== false) {
            $telecmiVars[$name] = $value;
        }
        
        echo "<td>✅ <strong>$name</strong> = " . htmlspecialchars(substr($value, 0, 30)) . (strlen($value) > 30 ? '...' : '') . "</td>";
    }
    
    echo "</tr>";
}

echo "</table>";

echo "<h2>TeleCMI Variables Found:</h2>";
if (empty($telecmiVars)) {
    echo "<p style='color:red;'>❌ No TeleCMI variables found!</p>";
} else {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>Variable</th><th>Value</th></tr>";
    foreach ($telecmiVars as $name => $value) {
        echo "<tr>";
        echo "<td><strong>$name</strong></td>";
        echo "<td><code>" . htmlspecialchars($value ?: '(empty)') . "</code></td>";
        echo "</tr>";
    }
    echo "</table>";
}

// Now test with getenv
echo "<h2>Testing with getenv():</h2>";

// Load into environment
foreach ($lines as $line) {
    if (strpos(trim($line), '#') === 0) continue;
    if (strpos($line, '=') === false) continue;
    
    list($name, $value) = explode('=', $line, 2);
    $name = trim($name);
    $value = trim($value);
    
    putenv("$name=$value");
    $_ENV[$name] = $value;
}

$testVars = ['TELECMI_APP_ID', 'TELECMI_APP_SECRET', 'TELECMI_SDK_BASE', 'TELECMI_REST_BASE', 'TELECMI_ACCESS_TOKEN'];

echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Variable</th><th>getenv()</th><th>\$_ENV</th></tr>";

foreach ($testVars as $var) {
    $getenvValue = getenv($var);
    $envValue = $_ENV[$var] ?? null;
    
    echo "<tr>";
    echo "<td><strong>$var</strong></td>";
    echo "<td>" . ($getenvValue ? "<code>" . htmlspecialchars($getenvValue) . "</code>" : "<span style='color:red;'>empty</span>") . "</td>";
    echo "<td>" . ($envValue ? "<code>" . htmlspecialchars($envValue) . "</code>" : "<span style='color:red;'>empty</span>") . "</td>";
    echo "</tr>";
}

echo "</table>";

echo "<hr>";
echo "<h2>Summary:</h2>";

$allSet = true;
foreach ($testVars as $var) {
    if (!getenv($var) && $var !== 'TELECMI_ACCESS_TOKEN') {
        $allSet = false;
        break;
    }
}

if ($allSet) {
    echo "<div style='background:#d4edda; padding:15px; border-radius:5px;'>";
    echo "<p style='color:#155724;'><strong>✅ All TeleCMI variables are set correctly!</strong></p>";
    echo "</div>";
} else {
    echo "<div style='background:#f8d7da; padding:15px; border-radius:5px;'>";
    echo "<p style='color:#721c24;'><strong>❌ Some TeleCMI variables are missing or empty</strong></p>";
    echo "</div>";
}
