<?php
/**
 * Phase 2 Job Applicants API
 * Fetches all drivers who applied for a specific job
 */

require_once 'config.php';
require_once 'profile_completion_helper.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    getJobApplicants();
} else {
    sendError('Method not allowed', 405);
}

function getJobApplicants() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    // Get job_id parameter (this is the string like TMJB00418)
    $jobIdString = isset($_GET['job_id']) ? $conn->real_escape_string($_GET['job_id']) : '';
    
    if (empty($jobIdString)) {
        sendError('job_id parameter is required', 400);
    }
    
    try {
        // First get the numeric id from the job_id string
        $jobQuery = "SELECT id FROM jobs WHERE job_id = '$jobIdString' LIMIT 1";
        $jobResult = $conn->query($jobQuery);
        
        if (!$jobResult || $jobResult->num_rows === 0) {
            sendError('Job not found', 404);
        }
        
        $jobRow = $jobResult->fetch_assoc();
        $numericJobId = $jobRow['id'];
        
        // Now get applicants using the numeric id with vehicle name, state name, subscription details, transporter info, and call feedback
        // Use a subquery to get only the most recent subscription payment per driver
        // Also get the most recent call feedback for this driver and job
        $query = "SELECT 
            j.id AS job_id,
            j.job_title,
            j.job_id AS job_id_string,
            j.transporter_id AS contractor_id,
            t.unique_id AS transporter_tmid,
            t.name AS transporter_name,
            u.id AS driver_id,
            u.unique_id AS driver_tmid,
            u.name,
            u.mobile,
            u.email,
            u.city,
            u.states as state_id,
            s.name as state_name,
            u.sex as gender,
            u.images as profile_image,
            COALESCE(vt.vehicle_name, u.vehicle_type) as vehicle_type,
            s2.name as preferred_location_name,
            u.Driving_Experience,
            u.Type_of_License,
            u.License_Number,
            u.Preferred_Location,
            u.Aadhar_Number,
            u.PAN_Number,
            u.GST_Number,
            u.status,
            u.Created_at,
            u.Updated_at,
            a.created_at as applied_at,
            p.amount as subscription_amount,
            p.created_at as subscription_start_date,
            p.end_at as subscription_end_date,
            p.payment_status as payment_status,
            p.payment_type as payment_type,
            cl.feedback as call_feedback,
            cl.match_status as match_status,
            cl.remark as feedback_notes
        FROM applyjobs a
        INNER JOIN users u ON a.driver_id = u.id
        INNER JOIN jobs j ON a.job_id = j.id
        LEFT JOIN users t ON j.transporter_id = t.id AND t.role = 'transporter'
        LEFT JOIN vehicle_type vt ON CAST(u.vehicle_type AS UNSIGNED) = vt.id
        LEFT JOIN states s ON CAST(u.states AS UNSIGNED) = s.id
        LEFT JOIN states s2 ON CAST(u.Preferred_Location AS UNSIGNED) = s2.id
        LEFT JOIN (
            SELECT p1.*
            FROM payments p1
            INNER JOIN (
                SELECT unique_id, MAX(created_at) as max_created
                FROM payments
                WHERE payment_type = 'subscription'
                GROUP BY unique_id
            ) p2 ON p1.unique_id = p2.unique_id AND p1.created_at = p2.max_created
            WHERE p1.payment_type = 'subscription'
        ) p ON u.unique_id = p.unique_id
        LEFT JOIN (
            SELECT cl1.*
            FROM call_logs_match_making cl1
            INNER JOIN (
                SELECT unique_id_driver, job_id, MAX(created_at) as max_created
                FROM call_logs_match_making
                WHERE unique_id_driver IS NOT NULL AND unique_id_driver != ''
                GROUP BY unique_id_driver, job_id
            ) cl2 ON cl1.unique_id_driver = cl2.unique_id_driver 
                  AND cl1.job_id = cl2.job_id 
                  AND cl1.created_at = cl2.max_created
        ) cl ON u.unique_id = cl.unique_id_driver AND j.job_id = cl.job_id
        WHERE a.job_id = $numericJobId
        GROUP BY a.id, u.id
        ORDER BY a.created_at DESC";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $applicants = [];
        while ($row = $result->fetch_assoc()) {
            // Calculate profile completion using shared helper function
            $driverId = $row['driver_id'];
            $profileCompletion = calculateProfileCompletion($conn, $driverId);
            
            // Calculate subscription status - only for subscription payment type
            $subscriptionStatus = 'inactive';
            $paymentStatus = strtolower($row['payment_status'] ?? '');
            $paymentType = strtolower($row['payment_type'] ?? '');
            
            if ($paymentType === 'subscription' && $paymentStatus === 'captured') {
                if (!empty($row['subscription_end_date'])) {
                    $endDate = strtotime($row['subscription_end_date']);
                    $now = time();
                    $subscriptionStatus = ($endDate > $now) ? 'active' : 'expired';
                } else {
                    $subscriptionStatus = 'active';
                }
            }
            
            // Get timestamps from database
            $appliedAt = $row['applied_at'] ?? '';
            $subscriptionStartDate = $row['subscription_start_date'] ?? null;
            
            // Debug: Log timezone info
            error_log("=== TIMESTAMP DEBUG ===");
            error_log("Raw applied_at from DB: " . $appliedAt);
            error_log("PHP timezone: " . date_default_timezone_get());
            error_log("Current PHP time: " . date('Y-m-d H:i:s'));
            error_log("MySQL timezone should be: +05:30");
            
            // Verify the timestamp is not in the future
            if (!empty($appliedAt)) {
                $appliedTimestamp = strtotime($appliedAt);
                $currentTimestamp = time();
                if ($appliedTimestamp > $currentTimestamp) {
                    error_log("WARNING: Future timestamp detected!");
                    error_log("Applied: " . date('Y-m-d H:i:s', $appliedTimestamp));
                    error_log("Current: " . date('Y-m-d H:i:s', $currentTimestamp));
                    error_log("Difference: " . ($appliedTimestamp - $currentTimestamp) . " seconds");
                }
            }

            $applicants[] = [
                'jobId' => (int)$row['job_id'],
                'jobTitle' => $row['job_title'] ?? '',
                'contractorId' => (int)$row['contractor_id'],
                'transporterTmid' => $row['transporter_tmid'] ?? '',
                'transporterName' => $row['transporter_name'] ?? '',
                'driverId' => (int)$row['driver_id'],
                'driverTmid' => $row['driver_tmid'] ?? '',
                'name' => $row['name'] ?? '',
                'mobile' => $row['mobile'] ?? '',
                'email' => $row['email'] ?? '',
                'city' => $row['city'] ?? '',
                'state' => $row['state_name'] ?? '',
                'gender' => $row['gender'] ?? '',
                'profileImage' => $row['profile_image'] ?? '',
                'vehicleType' => $row['vehicle_type'] ?? '',
                'drivingExperience' => $row['Driving_Experience'] ?? '',
                'licenseType' => $row['Type_of_License'] ?? '',
                'licenseNumber' => $row['License_Number'] ?? '',
                'preferredLocation' => $row['preferred_location_name'] ?? $row['Preferred_Location'] ?? '',
                'aadharNumber' => $row['Aadhar_Number'] ?? '',
                'panNumber' => $row['PAN_Number'] ?? '',
                'gstNumber' => $row['GST_Number'] ?? '',
                'status' => $row['status'] ?? '',
                'createdAt' => $row['Created_at'] ?? '',
                'updatedAt' => $row['Updated_at'] ?? '',
                'appliedAt' => $appliedAt,
                'profileCompletion' => $profileCompletion,
                'subscriptionAmount' => $row['subscription_amount'] ?? null,
                'subscriptionStartDate' => $subscriptionStartDate,
                'subscriptionEndDate' => $row['subscription_end_date'] ?? null,
                'subscriptionStatus' => $subscriptionStatus,
                'callFeedback' => $row['call_feedback'] ?? null,
                'matchStatus' => $row['match_status'] ?? null,
                'feedbackNotes' => $row['feedback_notes'] ?? null,
            ];
        }
        
        // Add debug info about timestamps
        $debugInfo = [
            'server_time' => [
                'current_datetime' => date('Y-m-d H:i:s'),
                'current_timestamp' => time(),
                'timezone' => date_default_timezone_get(),
                'mysql_now' => $conn->query("SELECT NOW() as now")->fetch_assoc()['now']
            ]
        ];
        
        // Log sample timestamp for debugging
        if (!empty($applicants)) {
            $sampleAppliedAt = $applicants[0]['appliedAt'];
            error_log("Sample appliedAt: $sampleAppliedAt");
            error_log("Server time: " . date('Y-m-d H:i:s'));
            error_log("MySQL NOW: " . $debugInfo['server_time']['mysql_now']);
        }
        
        // Return applicants with server time for reference
        $response = [
            'applicants' => $applicants,
            'server_time' => $debugInfo['server_time']
        ];
        
        sendSuccess($response, 'Job applicants fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
