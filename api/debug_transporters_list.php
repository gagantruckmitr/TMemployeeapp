<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

header('Content-Type: text/plain');

try {
    echo "Step 1: Loading config...\n";
    require_once 'config.php';
    echo "✓ Config loaded\n\n";

    if (!$conn) {
        die("✗ DB connection failed: " . mysqli_connect_error() . "\n");
    }
    echo "✓ Database connected\n\n";

    // First, check what tables exist
    echo "Step 2: Checking tables...\n";
    $tables = ['users', 'job_brief_table'];
    foreach ($tables as $table) {
        $check = $conn->query("SHOW TABLES LIKE '$table'");
        if ($check && $check->num_rows > 0) {
            echo "✓ Table '$table' exists\n";
            
            // Show columns
            $cols = $conn->query("DESCRIBE $table");
            if ($cols) {
                echo "  Columns: ";
                $colNames = [];
                while ($col = $cols->fetch_assoc()) {
                    $colNames[] = $col['Field'];
                }
                echo implode(', ', $colNames) . "\n";
            }
        } else {
            echo "✗ Table '$table' NOT FOUND\n";
        }
    }
    echo "\n";

    // Test simple query first
    echo "Step 3: Testing simple query...\n";
    $simpleQuery = "SELECT unique_id FROM job_brief_table GROUP BY unique_id LIMIT 3";
    $simpleResult = $conn->query($simpleQuery);
    
    if (!$simpleResult) {
        die("✗ Simple query failed: " . $conn->error . "\n");
    }
    echo "✓ Simple query works, found " . $simpleResult->num_rows . " unique transporters\n\n";

    // Test users table query
    echo "Step 4: Testing users table query...\n";
    $userQuery = "SELECT unique_id, name FROM users LIMIT 3";
    $userResult = $conn->query($userQuery);
    
    if (!$userResult) {
        echo "✗ Users query failed: " . $conn->error . "\n";
        echo "This means 'users' table doesn't have 'unique_id' or 'name' columns\n\n";
    } else {
        echo "✓ Users query works\n";
        while ($row = $userResult->fetch_assoc()) {
            echo "  - {$row['unique_id']}: {$row['name']}\n";
        }
        echo "\n";
    }

    // Test the full query
    echo "Step 5: Testing full query...\n";
    $query = "SELECT 
                jb.unique_id as tmid,
                (SELECT name FROM users WHERE unique_id = jb.unique_id LIMIT 1) as name,
                COUNT(jb.id) as call_count,
                MAX(jb.created_at) as last_call_date
              FROM job_brief_table jb
              GROUP BY jb.unique_id
              ORDER BY last_call_date DESC
              LIMIT 3";

    $result = $conn->query($query);

    if (!$result) {
        echo "✗ Full query failed\n";
        echo "Error: " . $conn->error . "\n";
        echo "Error Number: " . $conn->errno . "\n";
    } else {
        echo "✓ Full query works!\n";
        echo "Results:\n";
        while ($row = $result->fetch_assoc()) {
            echo "  - TMID: {$row['tmid']}, Name: " . ($row['name'] ?? 'NULL') . ", Calls: {$row['call_count']}\n";
        }
    }

    echo "\n=== Test Complete ===\n";

} catch (Exception $e) {
    echo "\n✗ EXCEPTION: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . "\n";
    echo "Line: " . $e->getLine() . "\n";
}
?>
