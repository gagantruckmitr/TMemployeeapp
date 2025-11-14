<?php
header('Content-Type: text/plain; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "Testing TeleCMI Production API directly...\n\n";

// Set up request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_GET['action'] = 'click_to_call';

// Simulate POST data
$postData = json_encode([
    'caller_id' => 3,
    'driver_id' => '99999',
    'driver_mobile' => '6394756798'
]);

// Mock php://input
file_put_contents('php://input', $postData);

echo "Including telecmi_production_api.php...\n\n";

// Include the API file
ob_start();
include 'telecmi_production_api.php';
$output = ob_get_clean();

echo "Output:\n";
echo $output . "\n";
?>
