<?php
/**
 * Driver Detailed Info API
 * Fetches comprehensive information about a driver including:
 * - Basic Profile
 * - All Applied Jobs (with assigned telecaller and feedback)
 * - Complete Call History
 */

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    getDriverDetailedInfo();
} else {
    sendError('Method not allowed', 405);
}

function getDriverDetailedInfo() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $driverId = isset($_GET['driver_id']) ? (int)$_GET['driver_id'] : 0;
    
    if ($driverId === 0) {
        sendError('driver_id parameter is required', 400);
    }
    
    try {
        // 1. Fetch Driver Basic Info
        $driverQuery = "SELECT id, unique_id, name, mobile, city, states, vehicle_type, 
                        Driving_Experience, Type_of_License, Preferred_Location 
                        FROM users WHERE id = $driverId";
        $driverResult = $conn->query($driverQuery);
        
        if (!$driverResult || $driverResult->num_rows === 0) {
            sendError('Driver not found', 404);
        }
        
        $driverData = $driverResult->fetch_assoc();
        $driverTmid = $driverData['unique_id'];
        
        // Get state name
        if (!empty($driverData['states'])) {
            $stateQuery = "SELECT name FROM states WHERE id = " . (int)$driverData['states'];
            $stateResult = $conn->query($stateQuery);
            if ($stateResult && $stateResult->num_rows > 0) {
                $driverData['state_name'] = $stateResult->fetch_assoc()['name'];
            }
        }
        
        // 2. Fetch All Applied Jobs
        $jobsQuery = "SELECT 
            j.id,
            j.job_id,
            j.job_title,
            j.job_location,
            j.created_at as job_posted_date,
            t.name as transporter_name,
            tc.name as assigned_telecaller_name,
            a.created_at as applied_date,
            cl.feedback as call_feedback,
            cl.match_status,
            cl.remark as feedback_notes,
            cl.updated_at as feedback_date,
            caller.name as feedback_by
        FROM applyjobs a
        INNER JOIN jobs j ON a.job_id = j.id
        LEFT JOIN users t ON j.transporter_id = t.id
        LEFT JOIN admins tc ON j.assigned_to = tc.id
        LEFT JOIN (
            SELECT cl1.*
            FROM call_logs_match_making cl1
            INNER JOIN (
                SELECT unique_id_driver, job_id, MAX(created_at) as max_created
                FROM call_logs_match_making
                WHERE unique_id_driver = '$driverTmid'
                GROUP BY unique_id_driver, job_id
            ) cl2 ON cl1.unique_id_driver = cl2.unique_id_driver 
                  AND cl1.job_id = cl2.job_id 
                  AND cl1.created_at = cl2.max_created
        ) cl ON j.job_id = cl.job_id
        LEFT JOIN admins caller ON cl.caller_id = caller.id
        WHERE a.driver_id = $driverId
        ORDER BY a.created_at DESC";
        
        $jobsResult = $conn->query($jobsQuery);
        $appliedJobs = [];
        
        if ($jobsResult) {
            while ($row = $jobsResult->fetch_assoc()) {
                $appliedJobs[] = [
                    'jobId' => $row['job_id'],
                    'jobTitle' => $row['job_title'],
                    'location' => $row['job_location'],
                    'transporterName' => $row['transporter_name'] ?? 'Unknown',
                    'assignedTelecaller' => $row['assigned_telecaller_name'] ?? 'Unassigned',
                    'appliedDate' => $row['applied_date'],
                    'feedback' => $row['call_feedback'],
                    'matchStatus' => $row['match_status'],
                    'notes' => $row['feedback_notes'],
                    'feedbackDate' => $row['feedback_date'],
                    'feedbackBy' => $row['feedback_by']
                ];
            }
        }
        
        // 3. Fetch Call History (from call_logs_match_making)
        $historyQuery = "SELECT 
            cl.id,
            cl.created_at as call_time,
            cl.feedback,
            cl.match_status,
            cl.remark,
            cl.job_id,
            u.name as caller_name,
            j.job_title
        FROM call_logs_match_making cl
        LEFT JOIN admins u ON cl.caller_id = u.id
        LEFT JOIN jobs j ON cl.job_id = j.job_id
        WHERE cl.unique_id_driver = '$driverTmid'
        ORDER BY cl.created_at DESC";
        
        $historyResult = $conn->query($historyQuery);
        $callHistory = [];
        
        if ($historyResult) {
            while ($row = $historyResult->fetch_assoc()) {
                $callHistory[] = [
                    'id' => $row['id'],
                    'callTime' => $row['call_time'],
                    'callerName' => $row['caller_name'] ?? 'Unknown',
                    'feedback' => $row['feedback'],
                    'matchStatus' => $row['match_status'],
                    'notes' => $row['remark'],
                    'jobId' => $row['job_id'],
                    'jobTitle' => $row['job_title']
                ];
            }
        }
        
        $response = [
            'driver' => [
                'id' => $driverData['id'],
                'tmid' => $driverData['unique_id'],
                'name' => $driverData['name'],
                'mobile' => $driverData['mobile'],
                'location' => $driverData['city'] . ', ' . ($driverData['state_name'] ?? ''),
                'vehicleType' => $driverData['vehicle_type'],
                'experience' => $driverData['Driving_Experience']
            ],
            'appliedJobs' => $appliedJobs,
            'callHistory' => $callHistory
        ];
        
        sendSuccess($response, 'Driver details fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
?>
