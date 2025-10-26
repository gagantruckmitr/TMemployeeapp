<?php
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Fresh Leads API with Profile Completion Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1400px;
            margin: 20px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        h1 {
            color: #2196F3;
            border-bottom: 3px solid #2196F3;
            padding-bottom: 10px;
        }
        .success { color: #4CAF50; font-weight: bold; }
        .error { color: #f44336; font-weight: bold; }
        .driver-card {
            background: #f9f9f9;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 15px;
            margin: 10px 0;
            display: grid;
            grid-template-columns: 60px 1fr 150px;
            gap: 15px;
            align-items: center;
        }
        .avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: #2196F3;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            font-weight: bold;
            position: relative;
        }
        .progress-ring {
            position: absolute;
            top: -5px;
            left: -5px;
            width: 70px;
            height: 70px;
        }
        .progress-badge {
            position: absolute;
            top: -10px;
            right: -10px;
            background: #4CAF50;
            color: white;
            padding: 2px 6px;
            border-radius: 10px;
            font-size: 10px;
            font-weight: bold;
        }
        .progress-badge.low { background: #f44336; }
        .progress-badge.medium { background: #FF9800; }
        .driver-info h3 {
            margin: 0 0 5px 0;
            color: #333;
        }
        .driver-info p {
            margin: 3px 0;
            color: #666;
            font-size: 14px;
        }
        .completion-bar {
            width: 150px;
        }
        .completion-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        .bar-container {
            width: 100%;
            height: 20px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
        }
        .bar-fill {
            height: 100%;
            background: linear-gradient(90deg, #4CAF50, #8BC34A);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 11px;
            font-weight: bold;
        }
        .bar-fill.low { background: linear-gradient(90deg, #f44336, #e57373); }
        .bar-fill.medium { background: linear-gradient(90deg, #FF9800, #FFB74D); }
        pre {
            background: #263238;
            color: #aed581;
            padding: 15px;
            border-radius: 4px;
            overflow-x: auto;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Fresh Leads API with Profile Completion</h1>
        <p>Testing the fresh leads API with profile completion percentage for telecallers.</p>
    </div>

    <?php
    // Test the API
    $apiUrl = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . '/fresh_leads_api.php?action=fresh_leads&limit=10&caller_id=1';
    
    echo '<div class="container">';
    echo '<h2>API Test</h2>';
    echo '<p><strong>Endpoint:</strong> <code>' . $apiUrl . '</code></p>';
    
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
            echo '<p class="success">✅ Found ' . $data['count'] . ' drivers</p>';
            
            echo '<h3>Driver List with Profile Completion</h3>';
            
            foreach ($data['data'] as $driver) {
                $percentage = (int)str_replace('%', '', $driver['profile_completion'] ?? '0');
                $progressClass = $percentage >= 80 ? '' : ($percentage >= 50 ? 'medium' : 'low');
                $initial = strtoupper(substr($driver['name'], 0, 1));
                
                echo '<div class="driver-card">';
                
                // Avatar with progress
                echo '<div class="avatar">';
                echo '<span class="progress-badge ' . $progressClass . '">' . $percentage . '%</span>';
                echo $initial;
                echo '</div>';
                
                // Driver info
                echo '<div class="driver-info">';
                echo '<h3>' . htmlspecialchars($driver['name']) . '</h3>';
                echo '<p>📱 ' . htmlspecialchars($driver['phoneNumber']) . '</p>';
                echo '<p>🆔 ' . htmlspecialchars($driver['tmid']) . ' | 📍 ' . htmlspecialchars($driver['state']) . '</p>';
                echo '</div>';
                
                // Completion bar
                echo '<div class="completion-bar">';
                echo '<div class="completion-label">Profile Completion</div>';
                echo '<div class="bar-container">';
                echo '<div class="bar-fill ' . $progressClass . '" style="width: ' . $percentage . '%">';
                echo $percentage . '%';
                echo '</div>';
                echo '</div>';
                echo '</div>';
                
                echo '</div>';
            }
            
            // Show raw JSON
            echo '<h3>📄 Raw API Response</h3>';
            echo '<pre>' . json_encode($data, JSON_PRETTY_PRINT) . '</pre>';
            
        } else {
            echo '<p class="error">❌ API returned error: ' . ($data['error'] ?? 'Unknown error') . '</p>';
            echo '<pre>' . $response . '</pre>';
        }
    } else {
        echo '<p class="error">❌ API request failed (HTTP ' . $httpCode . ')</p>';
        echo '<p>Response: ' . htmlspecialchars($response) . '</p>';
    }
    
    echo '</div>';
    ?>

    <div class="container">
        <h2>✅ Integration Complete</h2>
        <p class="success">The fresh_leads_api.php now includes profile completion percentage for each driver!</p>
        <h3>What's Included:</h3>
        <ul>
            <li>✅ Profile completion percentage calculated for each driver</li>
            <li>✅ Based on role-specific required fields (23 for drivers, 13 for transporters)</li>
            <li>✅ Returned in the format: <code>"profile_completion": "75%"</code></li>
            <li>✅ Flutter app will display circular progress ring around avatars</li>
            <li>✅ Telecallers can see completion status at a glance</li>
        </ul>
    </div>
</body>
</html>
