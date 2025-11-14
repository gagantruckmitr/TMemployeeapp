<?php
/**
 * Phase 2 Jobs API - Safe version
 */

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    getJobs();
} else {
    sendError('Method not allowed', 405);
}

function getJobs() {
    $conn = getDBConnection();
    
    if (!$conn) {
        sendError('Database connection not available', 500);
        return;
    }
    
    // Get user_id from request
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    if ($userId === 0) {
        sendError('user_id parameter is required', 400);
        return;
    }
    
    try {
        $filter = isset($_GET['filter']) ? $conn->real_escape_string($_GET['filter']) : 'all';
        
        // Check if Application_Deadline column exists
        $columnCheck = $conn->query("SHOW COLUMNS FROM jobs LIKE 'Application_Deadline'");
        $hasDeadlineColumn = $columnCheck && $columnCheck->num_rows > 0;
        
        // Get jobs with vehicle type name - FILTER BY ASSIGNED USER
        $query = "SELECT 
            j.*,
            COALESCE(vt.vehicle_name, j.vehicle_type) as vehicle_type_name
        FROM jobs j
        LEFT JOIN vehicle_type vt ON j.vehicle_type = vt.id
        WHERE j.assigned_to = $userId";
        
        // Check if job_brief_table exists and has closed_job column
        $jobBriefCheck = $conn->query("SHOW TABLES LIKE 'job_brief_table'");
        $hasJobBriefTable = $jobBriefCheck && $jobBriefCheck->num_rows > 0;
        
        // Apply filters
        if ($filter === 'closed') {
            // Show only closed jobs from job_brief_table
            if ($hasJobBriefTable) {
                $query = "SELECT DISTINCT
                    j.*,
                    COALESCE(vt.vehicle_name, j.vehicle_type) as vehicle_type_name
                FROM jobs j
                LEFT JOIN vehicle_type vt ON j.vehicle_type = vt.id
                INNER JOIN job_brief_table jb ON j.job_id = jb.job_id
                WHERE j.assigned_to = $userId AND jb.closed_job = 1";
                // Skip the ORDER BY at the end, add it here
                $query .= " ORDER BY jb.updated_at DESC LIMIT 50";
            } else {
                // No job_brief_table, return empty
                $query .= " AND 1 = 0 ORDER BY j.Created_at DESC LIMIT 50";
            }
        } else {
            // For all other filters, exclude closed jobs
            if ($hasJobBriefTable) {
                $query .= " AND j.job_id NOT IN (SELECT job_id FROM job_brief_table WHERE closed_job = 1)";
            }
            
            if ($hasDeadlineColumn) {
                // Use deadline-aware filters
                if ($filter === 'approved') {
                    $query .= " AND j.status = '1' AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
                } elseif ($filter === 'pending') {
                    $query .= " AND j.status = '0' AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
                } elseif ($filter === 'active') {
                    $query .= " AND j.active_inactive = 1 AND j.status = '1' AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
                } elseif ($filter === 'inactive') {
                    $query .= " AND j.active_inactive = 0 AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
                } elseif ($filter === 'expired') {
                    $query .= " AND j.Application_Deadline IS NOT NULL AND j.Application_Deadline != '' AND j.Application_Deadline < NOW()";
                } elseif ($filter === 'all') {
                    // For 'all' filter, exclude expired jobs by default to show only active jobs
                    $query .= " AND (j.Application_Deadline IS NULL OR j.Application_Deadline = '' OR j.Application_Deadline >= NOW())";
                }
            } else {
                // Use simple filters without deadline checks
                if ($filter === 'approved') {
                    $query .= " AND j.status = '1'";
                } elseif ($filter === 'pending') {
                    $query .= " AND j.status = '0'";
                } elseif ($filter === 'active') {
                    $query .= " AND j.active_inactive = 1 AND j.status = '1'";
                } elseif ($filter === 'inactive') {
                    $query .= " AND j.active_inactive = 0";
                } elseif ($filter === 'expired') {
                    // Return no results if no deadline column
                    $query .= " AND 1 = 0";
                }
            }
            
            $query .= " ORDER BY j.Created_at DESC LIMIT 50";
        }
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $jobs = [];
        while ($row = $result->fetch_assoc()) {
            // Get transporter info with profile completion
            $transporterName = 'Unknown';
            $transporterTmid = '';
            $transporterPhone = '';
            $transporterCity = '';
            $transporterState = '';
            $transporterCreatedAt = '';
            $profileCompletion = 0;
            
            if (!empty($row['transporter_id'])) {
                $userQuery = "SELECT u.*, s.name as state_name 
                              FROM users u 
                              LEFT JOIN states s ON CAST(u.states AS UNSIGNED) = s.id 
                              WHERE u.id = " . (int)$row['transporter_id'];
                $userResult = $conn->query($userQuery);
                if ($userResult && $userResult->num_rows > 0) {
                    $user = $userResult->fetch_assoc();
                    $transporterName = $user['name'] ?? 'Unknown';
                    $transporterTmid = $user['unique_id'] ?? '';
                    $transporterPhone = $user['mobile'] ?? '';
                    $transporterCity = $user['city'] ?? '';
                    $transporterState = $user['state_name'] ?? '';
                    
                    // Get subscription date from payments table where payment_status = 'captured'
                    $transporterCreatedAt = '';
                    if (!empty($transporterTmid)) {
                        $paymentQuery = "SELECT created_at 
                                        FROM payments 
                                        WHERE unique_id = '" . $conn->real_escape_string($transporterTmid) . "' 
                                        AND payment_status = 'captured' 
                                        ORDER BY created_at ASC 
                                        LIMIT 1";
                        $paymentResult = $conn->query($paymentQuery);
                        if ($paymentResult && $paymentResult->num_rows > 0) {
                            $payment = $paymentResult->fetch_assoc();
                            $transporterCreatedAt = $payment['created_at'] ?? '';
                        }
                    }
                    
                    // Calculate profile completion for transporter (EXACT same logic as profile_completion_api.php)
                    $transporterFields = [
                        'name', 'email', 'city', 'address', 'transport_name',
                        'year_of_establishment', 'fleet_size', 'operational_segment', 'average_km',
                        'pan_number', 'pan_image', 'gst_certificate', 'images'
                    ];
                    
                    $filledCount = 0;
                    $totalFields = count($transporterFields);
                    
                    foreach ($transporterFields as $field) {
                        $value = $user[$field] ?? null;
                        $isFilled = !empty($value) && $value !== '0000-00-00';
                        if ($isFilled) {
                            $filledCount++;
                        }
                    }
                    
                    $profileCompletion = ($totalFields > 0) ? round(($filledCount / $totalFields) * 100) : 0;
                }
            }
            
            // Count applicants using the numeric id column
            $applicantsCount = 0;
            if (!empty($row['id'])) {
                // Use id (numeric) not job_id (string)
                $countQuery = "SELECT COUNT(*) as count FROM applyjobs WHERE job_id = " . (int)$row['id'];
                $countResult = $conn->query($countQuery);
                if ($countResult) {
                    $applicantsCount = (int)$countResult->fetch_assoc()['count'];
                }
            }
            
            $jobs[] = [
                'id' => (int)($row['id'] ?? 0),
                'jobId' => $row['job_id'] ?? '',
                'jobTitle' => $row['job_title'] ?? '',
                'transporterId' => (string)($row['transporter_id'] ?? ''),
                'transporterName' => $transporterName,
                'transporterTmid' => $transporterTmid,
                'transporterPhone' => $transporterPhone,
                'transporterCity' => $transporterCity,
                'transporterState' => $transporterState,
                'transporterCreatedAt' => $transporterCreatedAt,
                'transporterProfileCompletion' => $profileCompletion,
                'jobLocation' => $row['job_location'] ?? '',
                'jobDescription' => $row['Job_Description'] ?? '',
                'salaryRange' => $row['Salary_Range'] ?? '',
                'requiredExperience' => $row['Required_Experience'] ?? '',
                'preferredStatus' => '',
                'typeOfLicense' => $row['Type_of_License'] ?? '',
                'vehicleType' => $row['vehicle_type_name'] ?? $row['vehicle_type'] ?? '',
                'vehicleTypeDetail' => $row['vehicle_type_name'] ?? '',
                'applicationDeadline' => $row['Application_Deadline'] ?? '',
                'jobManagementDate' => $row['Created_at'] ?? '',
                'jobManagementId' => '',
                'jobDescriptionId' => '',
                'numberOfDriverRequired' => (int)($row['number_of_drivers_required'] ?? 1),
                'activePosition' => (int)($row['active_inactive'] ?? 1),
                'createdVehicleDetail' => '',
                'createdAt' => $row['Created_at'] ?? '',
                'updatedAt' => $row['Updated_at'] ?? '',
                'status' => ($row['status'] === '1') ? 1 : 0,
                'applicantsCount' => (int)$applicantsCount,
                'isApproved' => $row['status'] === '1',
                'isActive' => (int)($row['active_inactive'] ?? 1) === 1,
                'isExpired' => $hasDeadlineColumn && !empty($row['Application_Deadline']) && strtotime($row['Application_Deadline']) < time(),
                'assignedTo' => $userId, // Since we filtered by assigned_to, all jobs are assigned to this user
                'assignedToName' => null, // Current user's own jobs
                'isAssignedToMe' => true, // All jobs in this API are assigned to the current user
            ];
        }
        
        sendSuccess($jobs, 'Jobs fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
