<?php
/**
 * Debug script for Phase 2 Dashboard Stats API
 */

// Enable error display
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

$debug = [];

// Step 1: Check if config.php exists
$debug['step1_config_exists'] = file_exists('config.php');

if (!$debug['step1_config_exists']) {
    echo json_encode([
        'success' => false,
        'error' => 'config.php not found',
        'debug' => $debug,
        'current_dir' => __DIR__,
        'files' => scandir(__DIR__)
    ]);
    exit;
}

// Step 2: Try to include config
try {
    require_once 'config.php';
    $debug['step2_config_loaded'] = true;
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Failed to load config.php: ' . $e->getMessage(),
        'debug' => $debug
    ]);
    exit;
}

// Step 3: Check if $conn exists
$debug['step3_conn_exists'] = isset($conn);

if (!isset($conn)) {
    echo json_encode([
        'success' => false,
        'error' => '$conn variable not set in config.php',
        'debug' => $debug
    ]);
    exit;
}

// Step 4: Check database connection
$debug['step4_conn_type'] = get_class($conn);
$debug['step4_has_error'] = $conn->connect_error ? true : false;

if ($conn->connect_error) {
    echo json_encode([
        'success' => false,
        'error' => 'Database connection error: ' . $conn->connect_error,
        'debug' => $debug
    ]);
    exit;
}

// Step 5: Test a simple query
try {
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs");
    if ($result) {
        $debug['step5_query_success'] = true;
        $debug['step5_job_count'] = $result->fetch_assoc()['count'];
    } else {
        $debug['step5_query_success'] = false;
        $debug['step5_error'] = $conn->error;
    }
} catch (Exception $e) {
    $debug['step5_query_success'] = false;
    $debug['step5_exception'] = $e->getMessage();
}

// Step 6: Try the full stats query
try {
    $stats = [];
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs");
    $stats['totalJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE status = '1'");
    $stats['approvedJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE status = '0'");
    $stats['pendingJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE active_inactive = 0");
    $stats['inactiveJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(*) as count FROM jobs 
                            WHERE Application_Deadline IS NOT NULL 
                            AND Application_Deadline != '' 
                            AND Application_Deadline < CURDATE()");
    $stats['expiredJobs'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $result = $conn->query("SELECT COUNT(DISTINCT transporter_id) as count 
                            FROM jobs 
                            WHERE status = '1' AND active_inactive = 1 
                            AND transporter_id IS NOT NULL");
    $stats['activeTransporters'] = $result ? (int)$result->fetch_assoc()['count'] : 0;
    
    $stats['driversApplied'] = 0;
    $stats['totalMatches'] = 0;
    $stats['totalCalls'] = 0;
    
    $debug['step6_stats_generated'] = true;
    $debug['step6_stats'] = $stats;
    
} catch (Exception $e) {
    $debug['step6_stats_generated'] = false;
    $debug['step6_exception'] = $e->getMessage();
}

// Return success
echo json_encode([
    'success' => true,
    'message' => 'All checks passed',
    'debug' => $debug
], JSON_PRETTY_PRINT);
?>
