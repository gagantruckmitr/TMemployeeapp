<?php
/**
 * Phase 2 Jobs Search API
 * Live search across multiple fields
 */

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    searchJobs();
} else {
    sendError('Method not allowed', 405);
}

function searchJobs() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    // Get user_id from request
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    if ($userId === 0) {
        sendError('user_id parameter is required', 400);
        return;
    }
    
    try {
        $searchQuery = isset($_GET['query']) ? $conn->real_escape_string($_GET['query']) : '';
        $filter = isset($_GET['filter']) ? $conn->real_escape_string($_GET['filter']) : 'all';
        
        // Build search query with JOINs - SEARCH ALL JOBS (not filtered by user)
        // Include assigned_to info and telecaller name from jobs table
        $query = "SELECT 
            j.*,
            COALESCE(vt.vehicle_name, j.vehicle_type) as vehicle_type_name,
            u.name as transporter_name,
            u.unique_id as transporter_tmid,
            u.mobile as transporter_phone,
            u.city as transporter_city,
            u.states as transporter_state_id,
            a.name as assigned_to_name
        FROM jobs j
        LEFT JOIN vehicle_type vt ON j.vehicle_type = vt.id
        LEFT JOIN users u ON j.transporter_id = u.id
        LEFT JOIN admins a ON j.assigned_to = a.id
        WHERE 1=1";
        
        // Add search conditions if query provided
        if (!empty($searchQuery)) {
            $query .= " AND (
                j.job_id LIKE '%$searchQuery%' OR
                j.job_title LIKE '%$searchQuery%' OR
                j.job_location LIKE '%$searchQuery%' OR
                j.Job_Description LIKE '%$searchQuery%' OR
                u.name LIKE '%$searchQuery%' OR
                u.unique_id LIKE '%$searchQuery%' OR
                u.mobile LIKE '%$searchQuery%' OR
                u.city LIKE '%$searchQuery%' OR
                COALESCE(vt.vehicle_name, j.vehicle_type) LIKE '%$searchQuery%' OR
                DATE_FORMAT(j.Created_at, '%d/%m/%Y') LIKE '%$searchQuery%' OR
                DATE_FORMAT(j.Application_Deadline, '%d/%m/%Y') LIKE '%$searchQuery%'
            )";
        }
        
        // Apply filters
        if ($filter === 'approved') {
            $query .= " AND j.status = '1'";
        } elseif ($filter === 'pending') {
            $query .= " AND j.status = '0'";
        } elseif ($filter === 'active') {
            $query .= " AND j.active_inactive = 1 AND j.status = '1'";
        } elseif ($filter === 'inactive') {
            $query .= " AND j.active_inactive = 0";
        }
        
        // Order by relevance: exact matches first, then partial matches, then by date
        if (!empty($searchQuery)) {
            $query .= " ORDER BY 
                CASE 
                    WHEN j.job_id = '$searchQuery' THEN 1
                    WHEN u.unique_id = '$searchQuery' THEN 2
                    WHEN j.job_id LIKE '$searchQuery%' THEN 3
                    WHEN u.unique_id LIKE '$searchQuery%' THEN 4
                    WHEN u.name LIKE '$searchQuery%' THEN 5
                    ELSE 6
                END,
                j.Created_at DESC 
                LIMIT 100";
        } else {
            $query .= " ORDER BY j.Created_at DESC LIMIT 100";
        }
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $jobs = [];
        while ($row = $result->fetch_assoc()) {
            // Get profile completion for transporter
            $profileCompletion = 0;
            if (!empty($row['transporter_id'])) {
                $userQuery = "SELECT * FROM users WHERE id = " . (int)$row['transporter_id'];
                $userResult = $conn->query($userQuery);
                if ($userResult && $userResult->num_rows > 0) {
                    $user = $userResult->fetch_assoc();
                    
                    $transporterFields = [
                        'name', 'email', 'city', 'address', 'transport_name',
                        'year_of_establishment', 'fleet_size', 'operational_segment', 'average_km',
                        'pan_number', 'pan_image', 'gst_certificate', 'images'
                    ];
                    
                    $filledCount = 0;
                    $totalFields = count($transporterFields);
                    
                    foreach ($transporterFields as $field) {
                        $value = $user[$field] ?? null;
                        if (!empty($value) && $value !== '0000-00-00') {
                            $filledCount++;
                        }
                    }
                    
                    $profileCompletion = ($totalFields > 0) ? round(($filledCount / $totalFields) * 100) : 0;
                }
            }
            
            // Count applicants
            $applicantsCount = 0;
            if (!empty($row['id'])) {
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
                'transporterName' => $row['transporter_name'] ?? 'Unknown',
                'transporterTmid' => $row['transporter_tmid'] ?? '',
                'transporterPhone' => $row['transporter_phone'] ?? '',
                'transporterCity' => $row['transporter_city'] ?? '',
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
                'isExpired' => false,
                'assignedTo' => !empty($row['assigned_to']) ? (int)$row['assigned_to'] : null,
                'assignedToName' => $row['assigned_to_name'] ?? null,
            ];
        }
        
        sendSuccess($jobs, 'Jobs searched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
?>
