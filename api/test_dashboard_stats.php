<?php
/**
 * Test Dashboard Stats API - Minimal version for debugging
 */

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    testDashboardStats();
} else {
    sendError('Method not allowed', 405);
}

function testDashboardStats() {
    try {
        $conn = getDBConnection();
        
        if (!$conn) {
            sendError('Database connection failed', 500);
            return;
        }
        
        $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 1;
        
        // Test basic query
        $result = $conn->query("SELECT COUNT(*) as count FROM jobs WHERE assigned_to = $userId");
        if (!$result) {
            sendError('Basic query failed: ' . $conn->error, 500);
            return;
        }
        
        $totalJobs = (int)$result->fetch_assoc()['count'];
        
        $stats = [
            'totalJobs' => $totalJobs,
            'approvedJobs' => 0,
            'pendingJobs' => 0,
            'inactiveJobs' => 0,
            'expiredJobs' => 0,
            'activeTransporters' => 0,
            'driversApplied' => 0,
            'totalMatches' => 0,
            'totalCalls' => 0
        ];
        
        sendSuccess($stats, 'Test stats fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
?>