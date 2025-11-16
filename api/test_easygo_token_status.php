<?php
/**
 * Test EasyGo Token Status
 * Check if EasyGo API token is configured and working
 */

require_once 'config.php';

header('Content-Type: application/json');

// EasyGo Configuration
define('EASYGO_USERNAME', 'admin@truckmitr.com');
define('EASYGO_PASSWORD', '6515a6cb823fcbe20f7287bd4659d5ba');
define('EASYGO_DID', '6882742');
define('EASYGO_TOKEN_URL', 'https://client.easygoivr.com/masterapiJwt/gentoken');
define('EASYGO_DIAL_URL', 'https://client.easygoivr.com/easygoapiJwt/request/dial');
define('EASYGO_MANUAL_TOKEN', 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN');

echo json_encode([
    'status' => 'EasyGo IVR Configuration Check',
    'username' => EASYGO_USERNAME,
    'did' => EASYGO_DID,
    'token_configured' => (EASYGO_MANUAL_TOKEN !== 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN'),
    'token_value' => (EASYGO_MANUAL_TOKEN !== 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN') ? 'Token is set' : 'NO TOKEN - Contact EasyGo Support',
    'message' => (EASYGO_MANUAL_TOKEN !== 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN') 
        ? 'Token is configured. Calls should work.' 
        : '⚠️ NO VALID TOKEN! You need to contact EasyGo support to get a valid API token and update EASYGO_MANUAL_TOKEN in api/easygo_ivr_api.php',
    'instructions' => [
        '1. Contact EasyGo support at support@easygoivr.com',
        '2. Request a new API token for your account',
        '3. Update EASYGO_MANUAL_TOKEN in api/easygo_ivr_api.php',
        '4. Test again'
    ]
], JSON_PRETTY_PRINT);
