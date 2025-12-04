<?php
/**
 * Test Toll-Free Search API
 */

// Test with a sample TMID or mobile number
$testQuery = 'TM000001'; // Change this to a real TMID or mobile number

$url = 'http://localhost/api/toll_free_search_api.php?query=' . urlencode($testQuery);

echo "Testing Toll-Free Search API\n";
echo "URL: $url\n\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
echo json_encode(json_decode($response), JSON_PRETTY_PRINT);
echo "\n";
?>
