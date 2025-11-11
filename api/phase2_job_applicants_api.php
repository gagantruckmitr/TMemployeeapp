<?php
/**
 * Phase 2 Job Applicants API
 * Fetches all drivers who applied for a specific job
 */

require_once 'config.php';

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
        
        // Now get applicants using the numeric id with vehicle name, state name, and subscription details
        $query = "SELECT 
            j.id AS job_id,
            j.job_title,
            j.transporter_id AS contractor_id,
            u.id AS driver_id,
            u.unique_id AS driver_tmid,
            u.name,
            u.mobile,
            u.email,
            u.city,
            u.states as state_id,
            s.name as state_name,
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
            p.payment_type as payment_type
        FROM applyjobs a
        INNER JOIN users u ON a.driver_id = u.id
        INNER JOIN jobs j ON a.job_id = j.id
        LEFT JOIN vehicle_type vt ON CAST(u.vehicle_type AS UNSIGNED) = vt.id
        LEFT JOIN states s ON CAST(u.states AS UNSIGNED) = s.id
        LEFT JOIN states s2 ON CAST(u.Preferred_Location AS UNSIGNED) = s2.id
        LEFT JOIN payments p ON u.unique_id = p.unique_id AND p.payment_type = 'subscription'
        WHERE a.job_id = $numericJobId
        ORDER BY a.created_at DESC";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $applicants = [];
        while ($row = $result->fetch_assoc()) {
            // Calculate profile completion using EXACT same logic as profile_completion_api.php
            $driverId = $row['driver_id'];
            
            // Fetch full user data
            $userQuery = "SELECT * FROM users WHERE id = $driverId";
            $userResult = $conn->query($userQuery);
            $userData = $userResult->fetch_assoc();
            
            // Use EXACT same fields and logic as phase2_profile_completion_api.php
            // Define fields in same structure - using exact database column names (case-sensitive)
            $fields = [
                'Basic Info' => ['name', 'email', 'city', 'sex', 'father_name', 'address', 'dob'],
                'Professional' => ['vehicle_type', 'Type_of_License', 'Driving_Experience', 'highest_education', 'License_Number', 'expiry_date_of_license'],
                'Income' => ['expected_monthly_income', 'current_monthly_income', 'marital_status', 'Preferred_Location'],
                'Documents' => ['Aadhar_Number', 'aadhar_photo', 'driving_license', 'images'],
                'Employment' => ['previous_employer', 'job_placement']
            ];
            
            $totalFields = 0;
            $filledFields = 0;
            
            foreach ($fields as $category => $fieldList) {
                foreach ($fieldList as $field) {
                    $value = $userData[$field] ?? null;
                    $isFilled = !empty($value) && $value !== '0000-00-00';
                    
                    $totalFields++;
                    if ($isFilled) $filledFields++;
                }
            }
            
            $profileCompletion = $totalFields > 0 ? round(($filledFields / $totalFields) * 100) : 0;
            
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
            
            // Debug: Log the raw date from database
            error_log("Raw applied_at from DB: " . ($row['applied_at'] ?? 'NULL'));
            error_log("Raw subscription_start_date from DB: " . ($row['subscription_start_date'] ?? 'NULL'));
            
            // Return the actual database timestamp without modification
            $appliedAt = $row['applied_at'] ?? '';
            
            // Return the actual database subscription timestamp without modification
            $subscriptionStartDate = $row['subscription_start_date'] ?? null;

            $applicants[] = [
                'jobId' => (int)$row['job_id'],
                'jobTitle' => $row['job_title'] ?? '',
                'contractorId' => (int)$row['contractor_id'],
                'driverId' => (int)$row['driver_id'],
                'driverTmid' => $row['driver_tmid'] ?? '',
                'name' => $row['name'] ?? '',
                'mobile' => $row['mobile'] ?? '',
                'email' => $row['email'] ?? '',
                'city' => $row['city'] ?? '',
                'state' => $row['state_name'] ?? '',
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
            ];
        }
        
        // Return applicants with server time for reference
        $response = [
            'applicants' => $applicants,
            'server_time' => [
                'current_datetime' => date('Y-m-d H:i:s'),
                'current_timestamp' => time(),
                'timezone' => date_default_timezone_get()
            ]
        ];
        
        sendSuccess($response, 'Job applicants fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
