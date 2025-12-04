<?php
/**
 * Check job_brief_table existence and structure
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Job Brief Table Check</h1>";

// Check if table exists
echo "<h2>1. Check if table exists</h2>";
$checkQuery = "SHOW TABLES LIKE 'job_brief_table'";
$result = $conn->query($checkQuery);

if ($result && $result->num_rows > 0) {
    echo "<p style='color: green;'>✓ Table 'job_brief_table' exists</p>";
    
    // Get table structure
    echo "<h2>2. Table Structure</h2>";
    $structureQuery = "DESCRIBE job_brief_table";
    $result = $conn->query($structureQuery);
    
    if ($result) {
        echo "<table border='1' cellpadding='5' cellspacing='0' style='border-collapse: collapse;'>";
        echo "<tr style='background: #f0f0f0;'><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td><strong>{$row['Field']}</strong></td>";
            echo "<td>{$row['Type']}</td>";
            echo "<td>{$row['Null']}</td>";
            echo "<td>{$row['Key']}</td>";
            echo "<td>" . ($row['Default'] ?? 'NULL') . "</td>";
            echo "<td>{$row['Extra']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    // Get row count
    echo "<h2>3. Row Count</h2>";
    $countQuery = "SELECT COUNT(*) as total FROM job_brief_table";
    $result = $conn->query($countQuery);
    if ($result) {
        $row = $result->fetch_assoc();
        echo "<p>Total records: <strong>{$row['total']}</strong></p>";
    }
    
    // Get sample data
    echo "<h2>4. Sample Data (Last 5 records)</h2>";
    $sampleQuery = "SELECT * FROM job_brief_table ORDER BY created_at DESC LIMIT 5";
    $result = $conn->query($sampleQuery);
    
    if ($result && $result->num_rows > 0) {
        echo "<table border='1' cellpadding='5' cellspacing='0' style='border-collapse: collapse; font-size: 12px;'>";
        
        // Get column names
        $firstRow = $result->fetch_assoc();
        echo "<tr style='background: #f0f0f0;'>";
        foreach ($firstRow as $key => $value) {
            echo "<th>$key</th>";
        }
        echo "</tr>";
        
        // Display first row
        echo "<tr>";
        foreach ($firstRow as $value) {
            echo "<td>" . htmlspecialchars(substr($value ?? '', 0, 50)) . "</td>";
        }
        echo "</tr>";
        
        // Display remaining rows
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            foreach ($row as $value) {
                echo "<td>" . htmlspecialchars(substr($value ?? '', 0, 50)) . "</td>";
            }
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No records found in table</p>";
    }
    
    // Check for records with call_status_feedback
    echo "<h2>5. Records with Feedback</h2>";
    $feedbackQuery = "SELECT COUNT(*) as total FROM job_brief_table WHERE call_status_feedback IS NOT NULL";
    $result = $conn->query($feedbackQuery);
    if ($result) {
        $row = $result->fetch_assoc();
        echo "<p>Records with feedback: <strong>{$row['total']}</strong></p>";
    }
    
    // Check for records with call_recording
    echo "<h2>6. Records with Recording</h2>";
    $recordingQuery = "SELECT COUNT(*) as total FROM job_brief_table WHERE call_recording IS NOT NULL";
    $result = $conn->query($recordingQuery);
    if ($result) {
        $row = $result->fetch_assoc();
        echo "<p>Records with recording: <strong>{$row['total']}</strong></p>";
    }
    
} else {
    echo "<p style='color: red;'>✗ Table 'job_brief_table' does NOT exist</p>";
    echo "<p>You may need to create the table. Here's the SQL:</p>";
    echo "<pre>";
    echo "CREATE TABLE IF NOT EXISTS job_brief_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    unique_id VARCHAR(50) NOT NULL,
    job_id VARCHAR(50) NOT NULL,
    caller_id INT,
    name VARCHAR(255),
    job_location VARCHAR(255),
    route VARCHAR(255),
    vehicle_type VARCHAR(100),
    license_type VARCHAR(100),
    experience VARCHAR(100),
    salary_fixed DECIMAL(10,2),
    salary_variable DECIMAL(10,2),
    esi_pf VARCHAR(10) DEFAULT 'No',
    food_allowance DECIMAL(10,2),
    trip_incentive DECIMAL(10,2),
    rehne_ki_suvidha VARCHAR(10) DEFAULT 'No',
    mileage VARCHAR(50),
    fast_tag_road_kharcha VARCHAR(50) DEFAULT 'Company',
    call_status_feedback TEXT,
    call_recording VARCHAR(500),
    closed_job TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_unique_job (unique_id, job_id),
    INDEX idx_caller (caller_id),
    INDEX idx_created (created_at)
);";
    echo "</pre>";
}

$conn->close();
?>
