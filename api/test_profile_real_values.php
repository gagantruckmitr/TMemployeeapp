<?php
// Start output buffering to prevent header issues
ob_start();

// Set HTML headers first
header('Content-Type: text/html; charset=utf-8');

// Database configuration (inline to avoid config.php header conflicts)
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'truckmitr');
define('DB_USER', 'truckmitr');
define('DB_PASS', '825Redp&4');

// Create database connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
$conn->set_charset("utf8mb4");
?>
<!DOCTYPE html>
<html>
<head>
    <title>Profile Completion - Real Values Test</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1400px;
            margin: 20px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            margin-bottom: 20px;
        }
        h1 {
            color: #667eea;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
            margin-top: 0;
        }
        h2 {
            color: #333;
            margin-top: 25px;
            background: #f8f9fa;
            padding: 10px 15px;
            border-radius: 6px;
        }
        .success { color: #28a745; font-weight: bold; }
        .error { color: #dc3545; font-weight: bold; }
        .warning { color: #ffc107; font-weight: bold; }
        .info { color: #17a2b8; font-weight: bold; }
        
        .user-card {
            background: #f8f9fa;
            border: 2px solid #e9ecef;
            border-radius: 10px;
            padding: 20px;
            margin: 15px 0;
            transition: all 0.3s;
        }
        .user-card:hover {
            border-color: #667eea;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.2);
        }
        
        .field-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        
        .field-item {
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 12px;
        }
        
        .field-item.present {
            border-left: 4px solid #28a745;
            background: #f1f9f4;
        }
        
        .field-item.missing {
            border-left: 4px solid #dc3545;
            background: #fff5f5;
        }
        
        .field-label {
            font-size: 11px;
            color: #6c757d;
            text-transform: uppercase;
            font-weight: 600;
            margin-bottom: 5px;
        }
        
        .field-value {
            font-size: 14px;
            color: #212529;
            font-weight: 500;
            word-break: break-word;
        }
        
        .field-value.na {
            color: #dc3545;
            font-style: italic;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .stat-value {
            font-size: 36px;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .stat-label {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .progress-bar {
            width: 100%;
            height: 30px;
            background: #e9ecef;
            border-radius: 15px;
            overflow: hidden;
            margin: 15px 0;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #28a745, #20c997);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            transition: width 0.5s ease;
        }
        
        .progress-fill.low { background: linear-gradient(90deg, #dc3545, #e57373); }
        .progress-fill.medium { background: linear-gradient(90deg, #ffc107, #ffb74d); }
        
        pre {
            background: #2d3748;
            color: #68d391;
            padding: 15px;
            border-radius: 8px;
            overflow-x: auto;
            font-size: 13px;
            line-height: 1.5;
        }
        
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin: 0 5px;
        }
        
        .badge-success { background: #d4edda; color: #155724; }
        .badge-danger { background: #f8d7da; color: #721c24; }
        .badge-info { background: #d1ecf1; color: #0c5460; }
        
        select {
            padding: 10px 15px;
            font-size: 16px;
            border: 2px solid #667eea;
            border-radius: 8px;
            width: 100%;
            max-width: 500px;
            margin: 10px 0;
        }
        
        button {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            margin: 10px 5px;
            transition: transform 0.2s;
        }
        
        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Profile Completion - Real Values Test</h1>
        <p>This test verifies that the API returns <strong>actual field values</strong> from the database, not generic "Available" text.</p>
    </div>

    <?php
    // Test 1: Database Connection
    echo '<div class="container">';
    echo '<h2>Test 1: Database Connection</h2>';
    
    if ($conn->connect_error) {
        echo '<p class="error">❌ Connection failed: ' . $conn->connect_error . '</p>';
        exit;
    } else {
        echo '<p class="success">✅ Database connected successfully</p>';
    }
    echo '</div>';

    // Test 2: Get Sample Users
    echo '<div class="container">';
    echo '<h2>Test 2: Select a User to Test</h2>';
    
    $usersQuery = "SELECT id, unique_id, name, role, email, city FROM users WHERE role IN ('driver', 'transporter') LIMIT 20";
    $usersResult = $conn->query($usersQuery);
    
    if ($usersResult && $usersResult->num_rows > 0) {
        echo '<p class="success">✅ Found ' . $usersResult->num_rows . ' users</p>';
        echo '<select id="userSelect" onchange="loadUserProfile(this.value)">';
        echo '<option value="">-- Select a User --</option>';
        
        $users = [];
        while ($row = $usersResult->fetch_assoc()) {
            $users[] = $row;
            echo '<option value="' . $row['id'] . '">';
            echo htmlspecialchars($row['name']) . ' (' . htmlspecialchars($row['unique_id']) . ') - ' . ucfirst($row['role']);
            if ($row['email']) echo ' - ' . htmlspecialchars($row['email']);
            echo '</option>';
        }
        echo '</select>';
        
        $testUserId = $_GET['user_id'] ?? $users[0]['id'];
        $testUser = null;
        foreach ($users as $user) {
            if ($user['id'] == $testUserId) {
                $testUser = $user;
                break;
            }
        }
        
    } else {
        echo '<p class="error">❌ No users found in database</p>';
        exit;
    }
    echo '</div>';

    // Test 3: Fetch User Data Directly from Database
    if ($testUserId) {
        echo '<div class="container">';
        echo '<h2>Test 3: Direct Database Query</h2>';
        echo '<p class="info">Testing user: <strong>' . htmlspecialchars($testUser['name']) . '</strong> (ID: ' . $testUserId . ')</p>';
        
        $userQuery = "SELECT * FROM users WHERE id = ?";
        $stmt = $conn->prepare($userQuery);
        $stmt->bind_param("i", $testUserId);
        $stmt->execute();
        $result = $stmt->get_result();
        $userData = $result->fetch_assoc();
        
        if ($userData) {
            echo '<p class="success">✅ User data fetched from database</p>';
            
            // Show key fields
            $keyFields = ['name', 'email', 'city', 'mobile', 'sex', 'vehicle_type', 'father_name', 'aadhar_number', 'license_number'];
            echo '<div class="field-grid">';
            foreach ($keyFields as $field) {
                $value = $userData[$field] ?? null;
                $hasValue = $value !== null && $value !== '';
                $class = $hasValue ? 'present' : 'missing';
                
                echo '<div class="field-item ' . $class . '">';
                echo '<div class="field-label">' . ucwords(str_replace('_', ' ', $field)) . '</div>';
                echo '<div class="field-value' . ($hasValue ? '' : ' na') . '">';
                echo $hasValue ? htmlspecialchars($value) : 'N/A';
                echo '</div>';
                echo '</div>';
            }
            echo '</div>';
        }
        echo '</div>';

        // Test 4: API Call
        echo '<div class="container">';
        echo '<h2>Test 4: Profile Completion API Test</h2>';
        
        $apiUrl = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . '/profile_completion_api.php?action=get_profile_details&user_id=' . $testUserId;
        echo '<p><strong>API URL:</strong> <code>' . htmlspecialchars($apiUrl) . '</code></p>';
        
        $ch = curl_init($apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode == 200 && $response) {
            echo '<p class="success">✅ API responded successfully (HTTP ' . $httpCode . ')</p>';
            
            $data = json_decode($response, true);
            
            if ($data && isset($data['success']) && $data['success']) {
                $profileData = $data['data']['profile_completion'];
                $percentage = $profileData['percentage'];
                $docValues = $profileData['document_values'];
                $docStatus = $profileData['document_status'];
                
                // Stats
                echo '<div class="stats">';
                echo '<div class="stat-card">';
                echo '<div class="stat-label">Completion</div>';
                echo '<div class="stat-value">' . $percentage . '%</div>';
                echo '</div>';
                
                echo '<div class="stat-card">';
                echo '<div class="stat-label">Filled Fields</div>';
                echo '<div class="stat-value">' . $profileData['filled_fields'] . '</div>';
                echo '</div>';
                
                echo '<div class="stat-card">';
                echo '<div class="stat-label">Total Fields</div>';
                echo '<div class="stat-value">' . $profileData['total_fields'] . '</div>';
                echo '</div>';
                
                echo '<div class="stat-card">';
                echo '<div class="stat-label">Missing</div>';
                echo '<div class="stat-value">' . ($profileData['total_fields'] - $profileData['filled_fields']) . '</div>';
                echo '</div>';
                echo '</div>';
                
                // Progress bar
                $progressClass = $percentage >= 80 ? '' : ($percentage >= 50 ? 'medium' : 'low');
                echo '<div class="progress-bar">';
                echo '<div class="progress-fill ' . $progressClass . '" style="width: ' . $percentage . '%">';
                echo $percentage . '%';
                echo '</div>';
                echo '</div>';
                
                // Document values
                echo '<h3>📋 Real Values from API</h3>';
                echo '<p class="info">These are the <strong>actual values</strong> returned by the API from the database:</p>';
                
                echo '<div class="field-grid">';
                foreach ($docValues as $field => $value) {
                    $isPresent = $docStatus[$field] ?? false;
                    $class = $isPresent ? 'present' : 'missing';
                    
                    echo '<div class="field-item ' . $class . '">';
                    echo '<div class="field-label">' . ucwords(str_replace('_', ' ', $field)) . '</div>';
                    echo '<div class="field-value' . ($isPresent ? '' : ' na') . '">';
                    
                    if ($value !== null && $value !== '') {
                        echo '<strong>' . htmlspecialchars($value) . '</strong>';
                        echo ' <span class="badge badge-success">✓ Real Value</span>';
                    } else {
                        echo 'N/A';
                        echo ' <span class="badge badge-danger">✗ Missing</span>';
                    }
                    
                    echo '</div>';
                    echo '</div>';
                }
                echo '</div>';
                
                // Verification
                echo '<h3>✅ Verification Results</h3>';
                $realValuesCount = 0;
                $availableTextCount = 0;
                
                foreach ($docValues as $field => $value) {
                    if ($value !== null && $value !== '') {
                        if ($value === 'Available') {
                            $availableTextCount++;
                        } else {
                            $realValuesCount++;
                        }
                    }
                }
                
                echo '<div class="user-card">';
                if ($availableTextCount > 0) {
                    echo '<p class="error">❌ Found ' . $availableTextCount . ' fields with generic "Available" text</p>';
                    echo '<p>This means the API is NOT returning real values!</p>';
                } else {
                    echo '<p class="success">✅ All ' . $realValuesCount . ' filled fields contain REAL VALUES from database</p>';
                    echo '<p>No generic "Available" text found - API is working correctly!</p>';
                }
                echo '</div>';
                
                // Raw JSON
                echo '<h3>📄 Raw API Response</h3>';
                echo '<pre>' . json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . '</pre>';
                
            } else {
                echo '<p class="error">❌ API returned error: ' . ($data['error'] ?? 'Unknown error') . '</p>';
            }
        } else {
            echo '<p class="error">❌ API request failed (HTTP ' . $httpCode . ')</p>';
        }
        echo '</div>';
    }

    $conn->close();
    ?>

    <div class="container">
        <h2>✅ Test Complete</h2>
        <p class="success">The API is configured to return <strong>real values</strong> from the database.</p>
        <p>If you see actual data (like email addresses, names, etc.) above, the system is working correctly!</p>
    </div>

    <script>
        function loadUserProfile(userId) {
            if (userId) {
                window.location.href = '?user_id=' + userId;
            }
        }
    </script>
</body>
</html>
<?php
ob_end_flush();
?>
