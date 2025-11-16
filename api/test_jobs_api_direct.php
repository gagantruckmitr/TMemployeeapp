<?php
/**
 * Direct test of jobs API
 */

// Simulate the API call
$_GET['user_id'] = 1; // Change this to your actual telecaller user ID
$_GET['filter'] = 'all';
$_SERVER['REQUEST_METHOD'] = 'GET';

// Include the jobs API
require_once 'phase2_jobs_api.php';
?>
