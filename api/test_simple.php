<?php
/**
 * Simple API Test - Check if API files are accessible
 */

header('Content-Type: application/json');

echo json_encode([
    'success' => true,
    'message' => 'API is accessible!',
    'timestamp' => date('Y-m-d H:i:s'),
    'file' => __FILE__
]);
?>
