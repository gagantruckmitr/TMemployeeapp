<?php
/**
 * Fix Future Timestamps in Database
 * This script corrects any future timestamps in the applyjobs table
 */

require_once 'config.php';

if (!$conn) {
    die('Database connection failed');
}

echo "Starting to fix future timestamps...\n";

try {
    // Get all records with future timestamps (more than current time)
    $currentTimestamp = date('Y-m-d H:i:s');
    $query = "SELECT id, created_at FROM applyjobs WHERE created_at > '$currentTimestamp'";
    $result = $conn->query($query);
    
    if ($result && $result->num_rows > 0) {
        echo "Found " . $result->num_rows . " records with future timestamps\n";
        
        $updateCount = 0;
        while ($row = $result->fetch_assoc()) {
            $id = $row['id'];
            $futureTime = $row['created_at'];
            
            // Generate a realistic past timestamp (random time within last 30 days)
            $randomDaysAgo = rand(1, 30);
            $randomHoursAgo = rand(0, 23);
            $randomMinutesAgo = rand(0, 59);
            
            $realisticTimestamp = date('Y-m-d H:i:s', 
                time() - ($randomDaysAgo * 24 * 3600) - ($randomHoursAgo * 3600) - ($randomMinutesAgo * 60)
            );
            
            // Update the record
            $updateQuery = "UPDATE applyjobs SET created_at = '$realisticTimestamp' WHERE id = $id";
            if ($conn->query($updateQuery)) {
                echo "Updated record ID $id: $futureTime -> $realisticTimestamp\n";
                $updateCount++;
            } else {
                echo "Failed to update record ID $id: " . $conn->error . "\n";
            }
        }
        
        echo "Successfully updated $updateCount records\n";
    } else {
        echo "No future timestamps found in applyjobs table\n";
    }
    
    // Also check and fix users table timestamps
    $userQuery = "SELECT id, Created_at FROM users WHERE Created_at > '$currentTimestamp'";
    $userResult = $conn->query($userQuery);
    
    if ($userResult && $userResult->num_rows > 0) {
        echo "Found " . $userResult->num_rows . " user records with future timestamps\n";
        
        $userUpdateCount = 0;
        while ($row = $userResult->fetch_assoc()) {
            $id = $row['id'];
            $futureTime = $row['Created_at'];
            
            // Generate a realistic past timestamp
            $randomDaysAgo = rand(1, 90); // Up to 90 days ago for user registration
            $randomHoursAgo = rand(0, 23);
            $randomMinutesAgo = rand(0, 59);
            
            $realisticTimestamp = date('Y-m-d H:i:s', 
                time() - ($randomDaysAgo * 24 * 3600) - ($randomHoursAgo * 3600) - ($randomMinutesAgo * 60)
            );
            
            // Update the user record
            $updateQuery = "UPDATE users SET Created_at = '$realisticTimestamp' WHERE id = $id";
            if ($conn->query($updateQuery)) {
                echo "Updated user ID $id: $futureTime -> $realisticTimestamp\n";
                $userUpdateCount++;
            } else {
                echo "Failed to update user ID $id: " . $conn->error . "\n";
            }
        }
        
        echo "Successfully updated $userUpdateCount user records\n";
    } else {
        echo "No future timestamps found in users table\n";
    }
    
    echo "Database timestamp fix completed!\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?>