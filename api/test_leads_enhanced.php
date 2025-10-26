<?php
// Test the enhanced leads API
header('Content-Type: text/html; charset=utf-8');

echo "<h1>Testing Enhanced Leads API</h1>";

// Test different status filters
$statuses = ['all', 'fresh', 'interested', 'callback', 'not_interested', 'no_response', 'connected'];

foreach ($statuses as $status) {
    echo "<h2>Testing Status: $status</h2>";
    
    $url = "http://localhost/api/admin_leads_api.php?status=$status";
    $response = file_get_contents($url);
    
    if ($response === false) {
        echo "<p style='color: red;'>Failed to fetch data for status: $status</p>";
        continue;
    }
    
    $data = json_decode($response, true);
    
    if ($data['success']) {
        echo "<p style='color: green;'>✓ Success! Found {$data['total']} leads</p>";
        
        if (isset($data['summary'])) {
            echo "<h3>Summary:</h3>";
            echo "<pre>" . print_r($data['summary'], true) . "</pre>";
        }
        
        if (!empty($data['data'])) {
            echo "<h3>Sample Lead (First Result):</h3>";
            echo "<pre>" . print_r($data['data'][0], true) . "</pre>";
        }
    } else {
        echo "<p style='color: red;'>✗ Error: {$data['message']}</p>";
    }
    
    echo "<hr>";
}

echo "<h2>API Response Structure Test</h2>";
$url = "http://localhost/api/admin_leads_api.php?status=all";
$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data['success'] && !empty($data['data'])) {
    $lead = $data['data'][0];
    echo "<h3>Lead Object Keys:</h3>";
    echo "<ul>";
    foreach (array_keys($lead) as $key) {
        echo "<li><strong>$key:</strong> " . gettype($lead[$key]) . "</li>";
    }
    echo "</ul>";
}

echo "<p><strong>Test completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
