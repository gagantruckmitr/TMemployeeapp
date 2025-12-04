<?php
/**
 * Background worker for EasyGo IVR calls
 * This script is spawned by easygo_ivr_api.php to handle the API call asynchronously
 */

// Include configuration and API logic
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/easygo_ivr_api.php';

// Get arguments
if ($argc < 2) {
    error_log("EasyGo Background: Missing arguments");
    exit(1);
}

$encodedData = $argv[1];
$data = json_decode(base64_decode($encodedData), true);

if (!$data) {
    error_log("EasyGo Background: Invalid data");
    exit(1);
}

// Extract parameters
$exten = $data['exten'] ?? '';
$number = $data['number'] ?? '';
$duration = $data['duration'] ?? '';
$callerId = $data['caller_id'] ?? null;
$contactId = $data['contact_id'] ?? null;
$contactType = $data['contact_type'] ?? 'driver';
$driverName = $data['driver_name'] ?? null;
$callSource = $data['call_source'] ?? null;
$referenceId = $data['reference_id'] ?? null;

error_log("EasyGo Background: Starting call for Reference ID: " . ($referenceId ?? 'NEW'));

// Initiate the call using the synchronous function
// Now accepting referenceId as the last parameter
$result = initiateEasyGoCall(
    $exten, 
    $number, 
    $duration, 
    $callerId, 
    $contactId, 
    $contactType, 
    $driverName, 
    $callSource,
    $referenceId
);

if ($result['success']) {
    error_log("EasyGo Background: Call initiated successfully. Call Log ID: " . ($result['call_log_id'] ?? 'Unknown'));
} else {
    error_log("EasyGo Background: Call failed. Error: " . ($result['error'] ?? 'Unknown'));
    
    // If call failed, we should probably update the call log if it was created?
    // But initiateEasyGoCall only logs if httpCode is 200.
    // If it failed with curl error or non-200, it might not have logged anything.
    // But we returned a reference_id to the frontend.
    // So the frontend thinks it's "Calling...".
    // If we don't log anything, the user will never see it in history.
    
    // We should log the failure too.
    // But initiateEasyGoCall returns error array if it fails before logging.
    
    // Let's manually log the failure if initiateEasyGoCall didn't log it.
    // But we don't have access to logEasyGoCall easily unless we expose it or copy logic.
    // Fortunately logEasyGoCall is in easygo_ivr_api.php and is just a function.
    
    if (!isset($result['call_log_id'])) {
        // Log the failure
        logEasyGoCall(
            $exten,
            $number,
            ['error' => $result['error']],
            500, // Internal error code
            $callerId,
            $contactId,
            $contactType,
            $referenceId,
            $driverName,
            $callSource
        );
        error_log("EasyGo Background: Logged failure to database.");
    }
}

$conn->close();
?>
