<?php
// Test the actual API endpoint
$_SERVER['REQUEST_METHOD'] = 'GET';
$_GET['action'] = 'stats';
$_GET['caller_id'] = 3;

include 'phase2_call_analytics_api.php';
?>
