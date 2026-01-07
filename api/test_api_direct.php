<?php
// Direct API Test
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain');

$callerId = 8;
$period = 'all';

echo "=== Direct API Test for Caller $callerId ===\n\n";

// Make direct HTTP request
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . 
       "/telecaller_analytics_api.php?caller_id={$callerId}&period={$period}";

echo "URL: $url\n\n";

$context = stream_context_create([
    'http' => [
        'ignore_errors' => true,
        'timeout' => 30
    ]
]);

$response = file_get_contents($url, false, $context);

if ($response === false) {
    echo "❌ Failed to fetch API\n";
    exit;
}

echo "Raw Response:\n";
echo "---\n";
echo $response;
echo "\n---\n\n";

$data = json_decode($response, true);

if (!$data) {
    echo "❌ Failed to decode JSON\n";
    echo "JSON Error: " . json_last_error_msg() . "\n";
    exit;
}

echo "Parsed Data:\n";
echo "Success: " . ($data['success'] ? 'true' : 'false') . "\n";

if ($data['success']) {
    $overview = $data['data']['overview'] ?? [];
    
    echo "\nOverview Data:\n";
    echo "  total_calls: " . ($overview['total_calls'] ?? 'MISSING') . "\n";
    echo "  connected_calls: " . ($overview['connected_calls'] ?? 'MISSING') . "\n";
    echo "  not_connected_calls: " . ($overview['not_connected_calls'] ?? 'MISSING') . "\n";
    echo "  callbacks_scheduled: " . ($overview['callbacks_scheduled'] ?? 'MISSING') . "\n";
    echo "  subscription_count: " . ($overview['subscription_count'] ?? 'MISSING') . "\n";
    
    if (!isset($overview['subscription_count'])) {
        echo "\n❌ subscription_count is MISSING from overview!\n";
        echo "\nAll overview keys:\n";
        print_r(array_keys($overview));
    } else {
        $subCount = $overview['subscription_count'];
        if ($subCount == 0) {
            echo "\n⚠️  subscription_count is 0 but should be 64!\n";
        } else {
            echo "\n✅ subscription_count is $subCount\n";
        }
    }
} else {
    echo "Error: " . ($data['error'] ?? 'Unknown') . "\n";
}

echo "\n=== Test Complete ===\n";
?>
