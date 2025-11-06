<?php
/**
 * Phase 2 Recent Activities API
 * Fetches recent activities from database
 */

require_once 'config.php';

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    getRecentActivities();
} else {
    sendError('Method not allowed', 405);
}

function getRecentActivities() {
    global $conn;
    
    // Get limit parameter
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $limit = min($limit, 100); // Max 100 activities
    
    $activities = [];
    
    // Get recent job postings - join with users table
    $jobsQuery = "SELECT 
        j.job_id,
        j.job_location,
        j.Created_at as created_at,
        u.name as transporter_name,
        u.unique_id as transporter_tmid,
        u.city
    FROM jobs j
    LEFT JOIN users u ON j.transporter_id = u.id
    WHERE j.Created_at IS NOT NULL
    ORDER BY j.Created_at DESC
    LIMIT " . ($limit / 2);
    
    $jobsResult = $conn->query($jobsQuery);
    if ($jobsResult) {
        while ($row = $jobsResult->fetch_assoc()) {
            $activities[] = [
                'type' => 'transporter',
                'name' => $row['transporter_name'] ?? 'Unknown Transporter',
                'tmid' => $row['transporter_tmid'] ?? '',
                'activity' => 'Posted new job: ' . ($row['job_location'] ?? 'Location not specified'),
                'time' => getTimeAgo($row['created_at']),
                'city' => $row['city'] ?? '',
                'timestamp' => strtotime($row['created_at']),
            ];
        }
    }
    
    // Get recent driver applications - check if tables exist first
    $driversTableCheck = $conn->query("SHOW TABLES LIKE 'drivers'");
    if ($driversTableCheck && $driversTableCheck->num_rows > 0) {
        $applicationsQuery = "SELECT 
            la.created_at,
            d.name as driver_name,
            d.driver_id,
            d.city,
            j.job_id
        FROM lead_assignment_new la
        LEFT JOIN drivers d ON la.driver_id = d.driver_id
        LEFT JOIN jobs j ON la.job_id = j.id
        WHERE la.created_at IS NOT NULL
        ORDER BY la.created_at DESC
        LIMIT " . ($limit / 2);
        
        $applicationsResult = $conn->query($applicationsQuery);
        if ($applicationsResult) {
            while ($row = $applicationsResult->fetch_assoc()) {
                $activities[] = [
                    'type' => 'driver',
                    'name' => $row['driver_name'] ?? 'Unknown Driver',
                    'tmid' => $row['driver_id'] ?? '',
                    'activity' => 'Applied for job ' . ($row['job_id'] ?? ''),
                    'time' => getTimeAgo($row['created_at']),
                    'city' => $row['city'] ?? '',
                    'timestamp' => strtotime($row['created_at']),
                ];
            }
        }
    }
    
    // Sort all activities by timestamp
    usort($activities, function($a, $b) {
        return $b['timestamp'] - $a['timestamp'];
    });
    
    // Remove timestamp field and limit results
    $activities = array_slice($activities, 0, $limit);
    foreach ($activities as &$activity) {
        unset($activity['timestamp']);
    }
    
    sendSuccess($activities, 'Recent activities fetched successfully');
}

function getTimeAgo($datetime) {
    if (empty($datetime)) return 'Unknown time';
    
    $timestamp = strtotime($datetime);
    $diff = time() - $timestamp;
    
    if ($diff < 60) {
        return 'Just now';
    } elseif ($diff < 3600) {
        $mins = floor($diff / 60);
        return $mins . ' min' . ($mins > 1 ? 's' : '') . ' ago';
    } elseif ($diff < 86400) {
        $hours = floor($diff / 3600);
        return $hours . ' hour' . ($hours > 1 ? 's' : '') . ' ago';
    } elseif ($diff < 604800) {
        $days = floor($diff / 86400);
        return $days . ' day' . ($days > 1 ? 's' : '') . ' ago';
    } else {
        return date('M d, Y', $timestamp);
    }
}
