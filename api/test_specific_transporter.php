<?php
/**
 * Test specific transporter profile completion
 * Shows field-by-field comparison
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

$transporterId = $_GET['id'] ?? null;

if (!$transporterId) {
    die("Usage: test_specific_transporter.php?id=TRANSPORTER_ID\n");
}

echo "<h1>Transporter Profile Completion Test</h1>";
echo "<h2>Transporter ID: $transporterId</h2>";
echo "<hr>";

try {
    // Get data using helper
    $helperData = getProfileCompletionData($conn, $transporterId);
    
    echo "<h3>Method 1: profile_completion_helper.php</h3>";
    echo "<p><strong>Percentage:</strong> " . $helperData['percentage'] . "%</p>";
    echo "<p><strong>Filled:</strong> " . $helperData['filled_fields'] . " / " . $helperData['total_fields'] . "</p>";
    
    echo "<h4>Field Status:</h4>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Field</th><th>Present?</th><th>Value</th></tr>";
    foreach ($helperData['document_status'] as $field => $isPresent) {
        $value = $helperData['document_values'][$field] ?? 'NULL';
        $color = $isPresent ? '#d4edda' : '#f8d7da';
        $status = $isPresent ? '✅ YES' : '❌ NO';
        echo "<tr style='background-color: $color;'>";
        echo "<td><strong>$field</strong></td>";
        echo "<td>$status</td>";
        echo "<td>" . htmlspecialchars(substr($value, 0, 100)) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    echo "<hr>";
    
    // Get data using transporter_leads_api logic
    $stmt = $conn->prepare("
        SELECT 
            name, email, transport_name, year_of_establishment,
            fleet_size, operational_segment, average_km, city, images, address,
            pan_number, pan_image, gst_certificate, mobile, states
        FROM users 
        WHERE id = ? AND role = 'transporter'
    ");
    
    $stmt->bind_param("i", $transporterId);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    
    if (!$user) {
        die("Transporter not found!");
    }
    
    $requiredFields = [
        'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
        'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
        'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
    ];
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    $fieldStatus = [];
    
    foreach ($requiredFields as $field) {
        $value = $user[$field] ?? null;
        $isPresent = false;
        
        if ($value !== null && $value !== '') {
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $isPresent = true;
                $filledFields++;
            } elseif (is_array($decoded) && count($decoded) === 0) {
                $isPresent = false;
            } else {
                $isPresent = true;
                $filledFields++;
            }
        }
        
        $fieldStatus[$field] = [
            'present' => $isPresent,
            'value' => $value
        ];
    }
    
    $completionPercentage = round(($filledFields / $totalFields) * 100);
    
    echo "<h3>Method 2: transporter_leads_api.php logic</h3>";
    echo "<p><strong>Percentage:</strong> $completionPercentage%</p>";
    echo "<p><strong>Filled:</strong> $filledFields / $totalFields</p>";
    
    echo "<h4>Field Status:</h4>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Field</th><th>Present?</th><th>Value</th></tr>";
    foreach ($fieldStatus as $field => $data) {
        $isPresent = $data['present'];
        $value = $data['value'] ?? 'NULL';
        $color = $isPresent ? '#d4edda' : '#f8d7da';
        $status = $isPresent ? '✅ YES' : '❌ NO';
        echo "<tr style='background-color: $color;'>";
        echo "<td><strong>$field</strong></td>";
        echo "<td>$status</td>";
        echo "<td>" . htmlspecialchars(substr($value, 0, 100)) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    echo "<hr>";
    echo "<h2>COMPARISON RESULT</h2>";
    
    if ($helperData['percentage'] === $completionPercentage) {
        echo "<div style='background-color: #d4edda; padding: 20px; border: 2px solid #28a745; border-radius: 5px;'>";
        echo "<h3 style='color: #155724;'>✅ SUCCESS: Both methods match!</h3>";
        echo "<p><strong>Percentage:</strong> " . $helperData['percentage'] . "%</p>";
        echo "<p><strong>Filled Fields:</strong> " . $helperData['filled_fields'] . " / " . $helperData['total_fields'] . "</p>";
        echo "</div>";
    } else {
        echo "<div style='background-color: #f8d7da; padding: 20px; border: 2px solid #dc3545; border-radius: 5px;'>";
        echo "<h3 style='color: #721c24;'>❌ MISMATCH: Different percentages!</h3>";
        echo "<p><strong>Helper:</strong> " . $helperData['percentage'] . "% (" . $helperData['filled_fields'] . " fields)</p>";
        echo "<p><strong>API:</strong> $completionPercentage% ($filledFields fields)</p>";
        echo "<p><strong>Difference:</strong> " . abs($helperData['percentage'] - $completionPercentage) . "%</p>";
        echo "</div>";
        
        // Show differences
        echo "<h3>Field Differences:</h3>";
        echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
        echo "<tr><th>Field</th><th>Helper</th><th>API</th></tr>";
        foreach ($requiredFields as $field) {
            $helperPresent = $helperData['document_status'][$field] ?? false;
            $apiPresent = $fieldStatus[$field]['present'] ?? false;
            
            if ($helperPresent !== $apiPresent) {
                echo "<tr style='background-color: #fff3cd;'>";
                echo "<td><strong>$field</strong></td>";
                echo "<td>" . ($helperPresent ? '✅ YES' : '❌ NO') . "</td>";
                echo "<td>" . ($apiPresent ? '✅ YES' : '❌ NO') . "</td>";
                echo "</tr>";
            }
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo "<div style='background-color: #f8d7da; padding: 20px;'>";
    echo "<h3>ERROR:</h3>";
    echo "<p>" . $e->getMessage() . "</p>";
    echo "</div>";
}
?>
