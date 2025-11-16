<?php
/**
 * Phase 2 Job Brief API
 * Handles job brief feedback from telecallers when calling transporters
 * 
 * Table columns: id, caller_id, unique_id, job_id, name, job_location, route, 
 * vehicle_type, license_type, experience, salary_fixed, salary_variable, esi_pf, 
 * food_allowance, trip_incentive, rehne_ki_suvidha, mileage, fast_tag_road_kharcha, 
 * created_at, updated_at, call_status_feedback
 */

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 0); // Don't display errors in output
ini_set('log_errors', 1);

require_once 'config.php';

// Ensure we have helper functions
if (!function_exists('sendError')) {
    function sendError($message, $code = 400, $data = null) {
        http_response_code($code);
        echo json_encode([
            'success' => false,
            'message' => $message,
            'data' => $data
        ]);
        exit();
    }
}

if (!function_exists('sendSuccess')) {
    function sendSuccess($data = null, $message = 'Success') {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data
        ]);
        exit();
    }
}

header('Content-Type: application/json');

$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if ($action === 'insert') {
        insertJobBrief();
    } elseif ($action === 'update') {
        updateJobBrief();
    } elseif ($action === 'delete') {
        deleteJobBrief();
    } else {
        saveJobBrief(); // Legacy endpoint
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($action === 'get_all') {
        getAllJobBriefs();
    } elseif ($action === 'get_by_id') {
        getJobBriefById();
    } elseif ($action === 'get_table_structure') {
        getTableStructure();
    } elseif ($action === 'history') {
        getCallHistory();
    } elseif ($action === 'transporters_list') {
        getTransportersList();
    } else {
        getJobBriefs(); // Legacy endpoint
    }
} else {
    sendError('Method not allowed', 405);
}

function saveJobBrief() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        sendError('Invalid JSON data', 400);
    }
    
    // Required fields
    $uniqueId = isset($data['uniqueId']) ? $conn->real_escape_string($data['uniqueId']) : '';
    $jobId = isset($data['jobId']) ? $conn->real_escape_string($data['jobId']) : '';
    $callerId = isset($data['callerId']) ? (int)$data['callerId'] : NULL;
    
    if (empty($uniqueId) || empty($jobId)) {
        sendError('Transporter ID and Job ID are required', 400);
    }
    
    // Optional fields
    $name = isset($data['name']) ? $conn->real_escape_string($data['name']) : NULL;
    $jobLocation = isset($data['jobLocation']) ? $conn->real_escape_string($data['jobLocation']) : NULL;
    $route = isset($data['route']) ? $conn->real_escape_string($data['route']) : NULL;
    $vehicleType = isset($data['vehicleType']) ? $conn->real_escape_string($data['vehicleType']) : NULL;
    $licenseType = isset($data['licenseType']) ? $conn->real_escape_string($data['licenseType']) : NULL;
    $experience = isset($data['experience']) ? $conn->real_escape_string($data['experience']) : NULL;
    $salaryFixed = isset($data['salaryFixed']) && !empty($data['salaryFixed']) ? (float)$data['salaryFixed'] : NULL;
    $salaryVariable = isset($data['salaryVariable']) && !empty($data['salaryVariable']) ? (float)$data['salaryVariable'] : NULL;
    $esiPf = isset($data['esiPf']) ? $conn->real_escape_string($data['esiPf']) : 'No';
    $foodAllowance = isset($data['foodAllowance']) && !empty($data['foodAllowance']) ? (float)$data['foodAllowance'] : NULL;
    $tripIncentive = isset($data['tripIncentive']) && !empty($data['tripIncentive']) ? (float)$data['tripIncentive'] : NULL;
    $rehneKiSuvidha = isset($data['rehneKiSuvidha']) ? $conn->real_escape_string($data['rehneKiSuvidha']) : 'No';
    $mileage = isset($data['mileage']) ? $conn->real_escape_string($data['mileage']) : NULL;
    $fastTagRoadKharcha = isset($data['fastTagRoadKharcha']) ? $conn->real_escape_string($data['fastTagRoadKharcha']) : 'Company';
    $callStatusFeedback = isset($data['callStatusFeedback']) ? $conn->real_escape_string($data['callStatusFeedback']) : NULL;
    $callRecording = isset($data['callRecording']) ? $conn->real_escape_string($data['callRecording']) : NULL;
    
    // Check if job should be closed (when feedback is "Not a Transporter", "He is Driver...", or "Close Job")
    $closedJob = 0;
    if ($callStatusFeedback !== NULL) {
        if (stripos($callStatusFeedback, 'Not a Transporter') !== false ||
            stripos($callStatusFeedback, 'He is Driver') !== false ||
            stripos($callStatusFeedback, 'Close Job') !== false) {
            $closedJob = 1;
        }
    }
    
    try {
        // First check if a record exists for this unique_id and job_id combination
        $checkQuery = "SELECT id FROM job_brief_table WHERE unique_id = '$uniqueId' AND job_id = '$jobId' LIMIT 1";
        $checkResult = $conn->query($checkQuery);
        
        if ($checkResult && $checkResult->num_rows > 0) {
            // Record exists, update it
            $row = $checkResult->fetch_assoc();
            $existingId = $row['id'];
            
            $updateFields = [];
            if ($callerId !== NULL) $updateFields[] = "caller_id = $callerId";
            if ($name !== NULL) $updateFields[] = "name = '$name'";
            if ($jobLocation !== NULL) $updateFields[] = "job_location = '$jobLocation'";
            if ($route !== NULL) $updateFields[] = "route = '$route'";
            if ($vehicleType !== NULL) $updateFields[] = "vehicle_type = '$vehicleType'";
            if ($licenseType !== NULL) $updateFields[] = "license_type = '$licenseType'";
            if ($experience !== NULL) $updateFields[] = "experience = '$experience'";
            if ($salaryFixed !== NULL) $updateFields[] = "salary_fixed = $salaryFixed";
            if ($salaryVariable !== NULL) $updateFields[] = "salary_variable = $salaryVariable";
            $updateFields[] = "esi_pf = '$esiPf'";
            if ($foodAllowance !== NULL) $updateFields[] = "food_allowance = $foodAllowance";
            if ($tripIncentive !== NULL) $updateFields[] = "trip_incentive = $tripIncentive";
            $updateFields[] = "rehne_ki_suvidha = '$rehneKiSuvidha'";
            if ($mileage !== NULL) $updateFields[] = "mileage = '$mileage'";
            $updateFields[] = "fast_tag_road_kharcha = '$fastTagRoadKharcha'";
            if ($callStatusFeedback !== NULL) $updateFields[] = "call_status_feedback = '$callStatusFeedback'";
            if ($callRecording !== NULL) $updateFields[] = "call_recording = '$callRecording'";
            $updateFields[] = "closed_job = $closedJob";
            $updateFields[] = "updated_at = NOW()";
            
            $query = "UPDATE job_brief_table SET " . implode(', ', $updateFields) . " WHERE id = $existingId";
            
            if ($conn->query($query)) {
                sendSuccess([
                    'id' => $existingId,
                    'uniqueId' => $uniqueId,
                    'jobId' => $jobId,
                    'updated' => true
                ], 'Job brief updated successfully');
            } else {
                sendError('Failed to update job brief: ' . $conn->error, 500);
            }
        } else {
            // Record doesn't exist, insert new one
            $query = "INSERT INTO job_brief_table (
                unique_id, job_id, caller_id, name, job_location, route, vehicle_type, license_type, 
                experience, salary_fixed, salary_variable, esi_pf, food_allowance, 
                trip_incentive, rehne_ki_suvidha, mileage, fast_tag_road_kharcha, 
                call_status_feedback, call_recording, closed_job, created_at, updated_at
            ) VALUES (
                '$uniqueId', '$jobId', " . ($callerId !== NULL ? $callerId : "NULL") . ", " . 
                ($name ? "'$name'" : "NULL") . ", " .
                ($jobLocation ? "'$jobLocation'" : "NULL") . ", " .
                ($route ? "'$route'" : "NULL") . ", " .
                ($vehicleType ? "'$vehicleType'" : "NULL") . ", " .
                ($licenseType ? "'$licenseType'" : "NULL") . ", " .
                ($experience ? "'$experience'" : "NULL") . ", " .
                ($salaryFixed !== NULL ? $salaryFixed : "NULL") . ", " .
                ($salaryVariable !== NULL ? $salaryVariable : "NULL") . ", " .
                "'$esiPf', " .
                ($foodAllowance !== NULL ? $foodAllowance : "NULL") . ", " .
                ($tripIncentive !== NULL ? $tripIncentive : "NULL") . ", " .
                "'$rehneKiSuvidha', " .
                ($mileage ? "'$mileage'" : "NULL") . ", " .
                "'$fastTagRoadKharcha', " .
                ($callStatusFeedback ? "'$callStatusFeedback'" : "NULL") . ", " .
                ($callRecording ? "'$callRecording'" : "NULL") . ", " .
                "$closedJob, " .
                "NOW(), NOW()
            )";
            
            if ($conn->query($query)) {
                sendSuccess([
                    'id' => $conn->insert_id,
                    'uniqueId' => $uniqueId,
                    'jobId' => $jobId,
                    'updated' => false
                ], 'Job brief saved successfully');
            } else {
                sendError('Failed to save job brief: ' . $conn->error, 500);
            }
        }
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function getJobBriefs() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $jobId = isset($_GET['job_id']) ? $conn->real_escape_string($_GET['job_id']) : '';
    $uniqueId = isset($_GET['unique_id']) ? $conn->real_escape_string($_GET['unique_id']) : '';
    
    $whereConditions = [];
    if (!empty($jobId)) {
        $whereConditions[] = "job_id = '$jobId'";
    }
    if (!empty($uniqueId)) {
        $whereConditions[] = "unique_id = '$uniqueId'";
    }
    
    $whereClause = !empty($whereConditions) ? 'WHERE ' . implode(' AND ', $whereConditions) : '';
    
    try {
        $query = "SELECT 
                    jb.*,
                    COALESCE(jb.name, u.Transport_Name, u.name_eng, u.name) as transporter_name
                  FROM job_brief_table jb
                  LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
                  $whereClause 
                  ORDER BY jb.created_at DESC 
                  LIMIT 100";
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $briefs = [];
        while ($row = $result->fetch_assoc()) {
            // Override the name field with the joined transporter name
            $row['name'] = $row['transporter_name'];
            $briefs[] = formatJobBriefRow($row);
        }
        
        sendSuccess($briefs, 'Job briefs fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function getCallHistory() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $uniqueId = isset($_GET['unique_id']) ? $conn->real_escape_string($_GET['unique_id']) : '';
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    
    if (empty($uniqueId)) {
        sendError('Transporter ID is required', 400);
    }
    
    try {
        // Query with JOIN to get transporter name from users table
        // Filter by caller_id so each telecaller only sees their own call history
        $query = "SELECT 
                    jb.*,
                    COALESCE(jb.name, u.Transport_Name, u.name_eng, u.name) as transporter_name
                  FROM job_brief_table jb
                  LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
                  WHERE jb.unique_id = '$uniqueId'";
        
        // Add caller_id filter if provided
        if ($callerId > 0) {
            $query .= " AND jb.caller_id = $callerId";
        }
        
        $query .= " ORDER BY jb.created_at DESC";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $history = [];
        while ($row = $result->fetch_assoc()) {
            try {
                // Override the name field with the joined transporter name
                $row['name'] = $row['transporter_name'];
                $brief = formatJobBriefRow($row);
                // Add placeholder values for optional fields
                $brief['jobTitle'] = 'Job Brief';
                $brief['companyName'] = null;
                $brief['jobCity'] = $row['job_location'];
                $brief['callerName'] = null;
                $history[] = $brief;
            } catch (Exception $e) {
                // Log the error but continue processing other rows
                error_log('Error formatting row: ' . $e->getMessage());
                continue;
            }
        }
        
        sendSuccess($history, 'Call history fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error in getCallHistory: ' . $e->getMessage(), 500);
    }
}

function getTransportersList() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    
    try {
        // Build the WHERE clause for caller_id filtering
        $whereClause = $callerId > 0 ? "WHERE jb.caller_id = $callerId" : "";
        
        // Query to get transporters with their names and phone numbers from users table
        // Filter by caller_id so each telecaller only sees transporters they called
        $query = "SELECT 
                    jb.unique_id as tmid,
                    COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown') as name,
                    u.mobile as phone,
                    jb.job_location as location,
                    COUNT(jb.id) as call_count,
                    MAX(jb.created_at) as last_call_date
                  FROM job_brief_table jb
                  LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
                  $whereClause
                  GROUP BY jb.unique_id, COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown'), u.mobile, jb.job_location
                  ORDER BY last_call_date DESC";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $transporters = [];
        while ($row = $result->fetch_assoc()) {
            $transporters[] = [
                'tmid' => $row['tmid'],
                'name' => $row['name'],
                'phone' => $row['phone'] ?? '',
                'location' => $row['location'],
                'callCount' => (int)$row['call_count'],
                'lastCallDate' => $row['last_call_date'],
            ];
        }
        
        sendSuccess($transporters, 'Transporters list fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error in getTransportersList: ' . $e->getMessage(), 500);
    }
}

function updateJobBrief() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data || !isset($data['id'])) {
        sendError('Invalid data or missing ID', 400);
    }
    
    $id = (int)$data['id'];
    
    $updateFields = [];
    
    if (isset($data['name'])) $updateFields[] = "name = '" . $conn->real_escape_string($data['name']) . "'";
    if (isset($data['jobLocation'])) $updateFields[] = "job_location = '" . $conn->real_escape_string($data['jobLocation']) . "'";
    if (isset($data['route'])) $updateFields[] = "route = '" . $conn->real_escape_string($data['route']) . "'";
    if (isset($data['vehicleType'])) $updateFields[] = "vehicle_type = '" . $conn->real_escape_string($data['vehicleType']) . "'";
    if (isset($data['licenseType'])) $updateFields[] = "license_type = '" . $conn->real_escape_string($data['licenseType']) . "'";
    if (isset($data['experience'])) $updateFields[] = "experience = '" . $conn->real_escape_string($data['experience']) . "'";
    if (isset($data['salaryFixed'])) $updateFields[] = "salary_fixed = " . (float)$data['salaryFixed'];
    if (isset($data['salaryVariable'])) $updateFields[] = "salary_variable = " . (float)$data['salaryVariable'];
    if (isset($data['esiPf'])) $updateFields[] = "esi_pf = '" . $conn->real_escape_string($data['esiPf']) . "'";
    if (isset($data['foodAllowance'])) $updateFields[] = "food_allowance = " . (float)$data['foodAllowance'];
    if (isset($data['tripIncentive'])) $updateFields[] = "trip_incentive = " . (float)$data['tripIncentive'];
    if (isset($data['rehneKiSuvidha'])) $updateFields[] = "rehne_ki_suvidha = '" . $conn->real_escape_string($data['rehneKiSuvidha']) . "'";
    if (isset($data['mileage'])) $updateFields[] = "mileage = '" . $conn->real_escape_string($data['mileage']) . "'";
    if (isset($data['fastTagRoadKharcha'])) $updateFields[] = "fast_tag_road_kharcha = '" . $conn->real_escape_string($data['fastTagRoadKharcha']) . "'";
    if (isset($data['callStatusFeedback'])) $updateFields[] = "call_status_feedback = '" . $conn->real_escape_string($data['callStatusFeedback']) . "'";
    if (isset($data['callRecording'])) $updateFields[] = "call_recording = '" . $conn->real_escape_string($data['callRecording']) . "'";
    
    if (empty($updateFields)) {
        sendError('No fields to update', 400);
    }
    
    $updateFields[] = "updated_at = NOW()";
    
    try {
        $query = "UPDATE job_brief_table SET " . implode(', ', $updateFields) . " WHERE id = $id";
        
        if ($conn->query($query)) {
            sendSuccess(['id' => $id], 'Job brief updated successfully');
        } else {
            sendError('Failed to update job brief: ' . $conn->error, 500);
        }
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function deleteJobBrief() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data || !isset($data['id'])) {
        sendError('Invalid data or missing ID', 400);
    }
    
    $id = (int)$data['id'];
    
    try {
        $query = "DELETE FROM job_brief_table WHERE id = $id";
        
        if ($conn->query($query)) {
            sendSuccess(['id' => $id], 'Job brief deleted successfully');
        } else {
            sendError('Failed to delete job brief: ' . $conn->error, 500);
        }
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

/**
 * Get table structure
 */
function getTableStructure() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    try {
        $query = "DESCRIBE job_brief_table";
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $columns = [];
        while ($row = $result->fetch_assoc()) {
            $columns[] = $row;
        }
        
        sendSuccess($columns, 'Table structure fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

/**
 * Insert new job brief (explicit insert endpoint)
 * POST /api/phase2_job_brief_api.php?action=insert
 */
function insertJobBrief() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        sendError('Invalid JSON data', 400);
    }
    
    // Required fields
    $uniqueId = isset($data['unique_id']) ? $conn->real_escape_string($data['unique_id']) : '';
    $jobId = isset($data['job_id']) ? $conn->real_escape_string($data['job_id']) : '';
    
    if (empty($uniqueId) || empty($jobId)) {
        sendError('unique_id and job_id are required', 400);
    }
    
    // Optional fields
    $callerId = isset($data['caller_id']) ? (int)$data['caller_id'] : NULL;
    $name = isset($data['name']) ? $conn->real_escape_string($data['name']) : NULL;
    $jobLocation = isset($data['job_location']) ? $conn->real_escape_string($data['job_location']) : NULL;
    $route = isset($data['route']) ? $conn->real_escape_string($data['route']) : NULL;
    $vehicleType = isset($data['vehicle_type']) ? $conn->real_escape_string($data['vehicle_type']) : NULL;
    $licenseType = isset($data['license_type']) ? $conn->real_escape_string($data['license_type']) : NULL;
    $experience = isset($data['experience']) ? $conn->real_escape_string($data['experience']) : NULL;
    $salaryFixed = isset($data['salary_fixed']) && !empty($data['salary_fixed']) ? (float)$data['salary_fixed'] : NULL;
    $salaryVariable = isset($data['salary_variable']) && !empty($data['salary_variable']) ? (float)$data['salary_variable'] : NULL;
    $esiPf = isset($data['esi_pf']) ? $conn->real_escape_string($data['esi_pf']) : 'No';
    $foodAllowance = isset($data['food_allowance']) && !empty($data['food_allowance']) ? (float)$data['food_allowance'] : NULL;
    $tripIncentive = isset($data['trip_incentive']) && !empty($data['trip_incentive']) ? (float)$data['trip_incentive'] : NULL;
    $rehneKiSuvidha = isset($data['rehne_ki_suvidha']) ? $conn->real_escape_string($data['rehne_ki_suvidha']) : 'No';
    $mileage = isset($data['mileage']) ? $conn->real_escape_string($data['mileage']) : NULL;
    $fastTagRoadKharcha = isset($data['fast_tag_road_kharcha']) ? $conn->real_escape_string($data['fast_tag_road_kharcha']) : 'Company';
    $callStatusFeedback = isset($data['call_status_feedback']) ? $conn->real_escape_string($data['call_status_feedback']) : NULL;
    $callRecording = isset($data['call_recording']) ? $conn->real_escape_string($data['call_recording']) : NULL;
    $closedJob = isset($data['closed_job']) ? (int)$data['closed_job'] : 0;
    
    try {
        $query = "INSERT INTO job_brief_table (
                    unique_id, job_id, caller_id, name, job_location, route, vehicle_type, license_type, 
                    experience, salary_fixed, salary_variable, esi_pf, food_allowance, 
                    trip_incentive, rehne_ki_suvidha, mileage, fast_tag_road_kharcha, 
                    call_status_feedback, call_recording, closed_job, created_at, updated_at
                ) VALUES (
                    '$uniqueId', '$jobId', " . ($callerId !== NULL ? $callerId : "NULL") . ", " . 
                    ($name ? "'$name'" : "NULL") . ", " .
                    ($jobLocation ? "'$jobLocation'" : "NULL") . ", " .
                    ($route ? "'$route'" : "NULL") . ", " .
                    ($vehicleType ? "'$vehicleType'" : "NULL") . ", " .
                    ($licenseType ? "'$licenseType'" : "NULL") . ", " .
                    ($experience ? "'$experience'" : "NULL") . ", " .
                    ($salaryFixed !== NULL ? $salaryFixed : "NULL") . ", " .
                    ($salaryVariable !== NULL ? $salaryVariable : "NULL") . ", " .
                    "'$esiPf', " .
                    ($foodAllowance !== NULL ? $foodAllowance : "NULL") . ", " .
                    ($tripIncentive !== NULL ? $tripIncentive : "NULL") . ", " .
                    "'$rehneKiSuvidha', " .
                    ($mileage ? "'$mileage'" : "NULL") . ", " .
                    "'$fastTagRoadKharcha', " .
                    ($callStatusFeedback ? "'$callStatusFeedback'" : "NULL") . ", " .
                    ($callRecording ? "'$callRecording'" : "NULL") . ", " .
                    "$closedJob, " .
                    "NOW(), NOW()
                )";
        
        if ($conn->query($query)) {
            $insertedId = $conn->insert_id;
            
            // Fetch the inserted record
            $selectQuery = "SELECT * FROM job_brief_table WHERE id = $insertedId";
            $result = $conn->query($selectQuery);
            $insertedRecord = $result->fetch_assoc();
            
            sendSuccess([
                'id' => $insertedId,
                'data' => formatJobBriefRow($insertedRecord)
            ], 'Job brief inserted successfully');
        } else {
            sendError('Failed to insert job brief: ' . $conn->error, 500);
        }
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

/**
 * Get all job briefs with filters
 * GET /api/phase2_job_brief_api.php?action=get_all
 */
function getAllJobBriefs() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    $whereConditions = [];
    $params = [];
    
    // Filters
    if (!empty($_GET['job_id'])) {
        $whereConditions[] = "jb.job_id = '" . $conn->real_escape_string($_GET['job_id']) . "'";
    }
    if (!empty($_GET['unique_id'])) {
        $whereConditions[] = "jb.unique_id = '" . $conn->real_escape_string($_GET['unique_id']) . "'";
    }
    if (!empty($_GET['caller_id'])) {
        $whereConditions[] = "jb.caller_id = " . (int)$_GET['caller_id'];
    }
    if (!empty($_GET['call_status_feedback'])) {
        $whereConditions[] = "jb.call_status_feedback = '" . $conn->real_escape_string($_GET['call_status_feedback']) . "'";
    }
    if (isset($_GET['closed_job'])) {
        $whereConditions[] = "jb.closed_job = " . (int)$_GET['closed_job'];
    }
    
    $whereClause = !empty($whereConditions) ? 'WHERE ' . implode(' AND ', $whereConditions) : '';
    
    try {
        $query = "SELECT 
                    jb.*,
                    COALESCE(jb.name, u.Transport_Name, u.name_eng, u.name) as transporter_name,
                    u.mobile as transporter_mobile
                  FROM job_brief_table jb
                  LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
                  $whereClause 
                  ORDER BY jb.created_at DESC 
                  LIMIT $limit OFFSET $offset";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        // Get total count
        $countQuery = "SELECT COUNT(*) as total FROM job_brief_table jb $whereClause";
        $countResult = $conn->query($countQuery);
        $totalCount = $countResult->fetch_assoc()['total'];
        
        $briefs = [];
        while ($row = $result->fetch_assoc()) {
            $row['name'] = $row['transporter_name'];
            $briefs[] = formatJobBriefRow($row);
        }
        
        sendSuccess([
            'data' => $briefs,
            'count' => count($briefs),
            'total' => (int)$totalCount,
            'limit' => $limit,
            'offset' => $offset
        ], 'Job briefs fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

/**
 * Get single job brief by ID
 * GET /api/phase2_job_brief_api.php?action=get_by_id&id=123
 */
function getJobBriefById() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($id <= 0) {
        sendError('Valid ID is required', 400);
    }
    
    try {
        $query = "SELECT 
                    jb.*,
                    COALESCE(jb.name, u.Transport_Name, u.name_eng, u.name) as transporter_name,
                    u.mobile as transporter_mobile,
                    u.email as transporter_email
                  FROM job_brief_table jb
                  LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
                  WHERE jb.id = $id";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        if ($result->num_rows === 0) {
            sendError('Job brief not found', 404);
        }
        
        $row = $result->fetch_assoc();
        $row['name'] = $row['transporter_name'];
        
        sendSuccess(formatJobBriefRow($row), 'Job brief fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function formatJobBriefRow($row) {
    return [
        'id' => (int)$row['id'],
        'unique_id' => $row['unique_id'],
        'job_id' => $row['job_id'],
        'caller_id' => isset($row['caller_id']) && $row['caller_id'] ? (int)$row['caller_id'] : null,
        'name' => $row['name'],
        'job_location' => $row['job_location'],
        'route' => $row['route'],
        'vehicle_type' => $row['vehicle_type'],
        'license_type' => $row['license_type'],
        'experience' => $row['experience'],
        'salary_fixed' => $row['salary_fixed'],
        'salary_variable' => $row['salary_variable'],
        'esi_pf' => $row['esi_pf'],
        'food_allowance' => $row['food_allowance'],
        'trip_incentive' => $row['trip_incentive'],
        'rehne_ki_suvidha' => $row['rehne_ki_suvidha'],
        'mileage' => $row['mileage'],
        'fast_tag_road_kharcha' => $row['fast_tag_road_kharcha'],
        'call_status_feedback' => $row['call_status_feedback'],
        'call_recording' => isset($row['call_recording']) ? $row['call_recording'] : null,
        'closed_job' => isset($row['closed_job']) ? (int)$row['closed_job'] : 0,
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
        // Legacy camelCase format for backward compatibility
        'uniqueId' => $row['unique_id'],
        'jobId' => $row['job_id'],
        'callerId' => isset($row['caller_id']) && $row['caller_id'] ? (int)$row['caller_id'] : null,
        'jobLocation' => $row['job_location'],
        'vehicleType' => $row['vehicle_type'],
        'licenseType' => $row['license_type'],
        'salaryFixed' => $row['salary_fixed'],
        'salaryVariable' => $row['salary_variable'],
        'esiPf' => $row['esi_pf'],
        'foodAllowance' => $row['food_allowance'],
        'tripIncentive' => $row['trip_incentive'],
        'rehneKiSuvidha' => $row['rehne_ki_suvidha'],
        'fastTagRoadKharcha' => $row['fast_tag_road_kharcha'],
        'callStatusFeedback' => $row['call_status_feedback'],
        'callRecording' => isset($row['call_recording']) ? $row['call_recording'] : null,
        'closedJob' => isset($row['closed_job']) ? (int)$row['closed_job'] : 0,
        'createdAt' => $row['created_at'],
        'updatedAt' => $row['updated_at'],
    ];
}
?>
