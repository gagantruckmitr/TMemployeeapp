<?php
/**
 * Phase 2 Call Analytics API
 * Provides detailed call statistics and logs
 */

require_once 'config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['action'])) {
        $action = $_GET['action'];
        if ($action === 'stats') {
            getCallStats();
        } elseif ($action === 'logs') {
            getCallLogs();
        } else {
            sendError('Invalid action', 400);
        }
    } else {
        sendError('Action parameter required', 400);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    saveCallFeedback();
} else {
    sendError('Method not allowed', 405);
}

function getCallStats() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    // Get caller_id from query parameter (optional - if not provided, show all)
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    $whereClause = $callerId > 0 ? "WHERE caller_id = $callerId" : "";
    $andClause = $callerId > 0 ? "AND caller_id = $callerId" : "";
    
    try {
        // Get total calls
        $totalCallsQuery = "SELECT COUNT(*) as total FROM call_logs_match_making $whereClause";
        $totalResult = $conn->query($totalCallsQuery);
        $totalCalls = $totalResult ? $totalResult->fetch_assoc()['total'] : 0;
        
        // Get transporter calls
        $transporterCallsQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                                  WHERE unique_id_transporter IS NOT NULL AND unique_id_transporter != '' $andClause";
        $transporterResult = $conn->query($transporterCallsQuery);
        $transporterCalls = $transporterResult->fetch_assoc()['total'];
        
        // Get driver calls
        $driverCallsQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                            WHERE unique_id_driver IS NOT NULL AND unique_id_driver != '' $andClause";
        $driverResult = $conn->query($driverCallsQuery);
        $driverCalls = $driverResult->fetch_assoc()['total'];
        
        // Get match statistics
        $matchMakingDoneQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                                WHERE feedback = 'Match Making Done' $andClause";
        $matchMakingResult = $conn->query($matchMakingDoneQuery);
        $matchMakingDone = $matchMakingResult->fetch_assoc()['total'];
        
        $selectedQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                         WHERE match_status = 'Selected' $andClause";
        $selectedResult = $conn->query($selectedQuery);
        $selected = $selectedResult->fetch_assoc()['total'];
        
        $notSelectedQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                            WHERE feedback = 'Not Selected' $andClause";
        $notSelectedResult = $conn->query($notSelectedQuery);
        $notSelected = $notSelectedResult->fetch_assoc()['total'];
        
        // Connected calls statistics
        $interviewDoneQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                              WHERE feedback = 'Interview Done' $andClause";
        $interviewDoneResult = $conn->query($interviewDoneQuery);
        $interviewDone = $interviewDoneResult->fetch_assoc()['total'];
        
        $willConfirmQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                            WHERE feedback = 'Will Confirm Later' $andClause";
        $willConfirmResult = $conn->query($willConfirmQuery);
        $willConfirmLater = $willConfirmResult->fetch_assoc()['total'];
        
        // Call back statistics
        $ringingBusyQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                            WHERE feedback IN ('Ringing', 'Call Busy') $andClause";
        $ringingBusyResult = $conn->query($ringingBusyQuery);
        $ringingBusy = $ringingBusyResult->fetch_assoc()['total'];
        
        $switchedOffQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                            WHERE feedback IN ('Switched Off', 'Not Reachable', 'Disconnected') $andClause";
        $switchedOffResult = $conn->query($switchedOffQuery);
        $switchedOff = $switchedOffResult->fetch_assoc()['total'];
        
        $didntPickQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                          WHERE feedback = 'Didn\'t Pick' $andClause";
        $didntPickResult = $conn->query($didntPickQuery);
        $didntPick = $didntPickResult->fetch_assoc()['total'];
        
        // Call back later statistics
        $busyRightNowQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                             WHERE feedback = 'Busy Right Now' $andClause";
        $busyRightNowResult = $conn->query($busyRightNowQuery);
        $busyRightNow = $busyRightNowResult->fetch_assoc()['total'];
        
        $callTomorrowQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                             WHERE feedback = 'Call Tomorrow Morning' $andClause";
        $callTomorrowResult = $conn->query($callTomorrowQuery);
        $callTomorrow = $callTomorrowResult->fetch_assoc()['total'];
        
        $callEveningQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                            WHERE feedback = 'Call in Evening' $andClause";
        $callEveningResult = $conn->query($callEveningQuery);
        $callEvening = $callEveningResult->fetch_assoc()['total'];
        
        $callAfter2DaysQuery = "SELECT COUNT(*) as total FROM call_logs_match_making 
                               WHERE feedback = 'Call After 2 Days' $andClause";
        $callAfter2DaysResult = $conn->query($callAfter2DaysQuery);
        $callAfter2Days = $callAfter2DaysResult->fetch_assoc()['total'];
        
        $connectedCalls = $interviewDone + $notSelected + $willConfirmLater + $matchMakingDone;
        $callBacks = $ringingBusy + $switchedOff + $didntPick;
        $callBackLater = $busyRightNow + $callTomorrow + $callEvening + $callAfter2Days;
        
        $stats = [
            'totalCalls' => (int)$totalCalls,
            'transporterCalls' => (int)$transporterCalls,
            'driverCalls' => (int)$driverCalls,
            'totalMatches' => (int)$matchMakingDone,
            'selected' => (int)$selected,
            'notSelected' => (int)$notSelected,
            'connectedCalls' => (int)$connectedCalls,
            'callBacks' => (int)$callBacks,
            'callBackLater' => (int)$callBackLater,
            'interviewDone' => (int)$interviewDone,
            'willConfirmLater' => (int)$willConfirmLater,
            'matchMakingDone' => (int)$matchMakingDone,
            'ringingBusy' => (int)$ringingBusy,
            'switchedOff' => (int)$switchedOff,
            'didntPick' => (int)$didntPick,
            'busyRightNow' => (int)$busyRightNow,
            'callTomorrow' => (int)$callTomorrow,
            'callEvening' => (int)$callEvening,
            'callAfter2Days' => (int)$callAfter2Days,
        ];
        
        sendSuccess($stats, 'Call statistics fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function getCallLogs() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    
    // Filter by caller_id if provided
    $whereClause = $callerId > 0 ? "WHERE clm.caller_id = $callerId" : "";
    
    try {
        $query = "SELECT 
            clm.id,
            clm.caller_id,
            clm.unique_id_transporter,
            clm.unique_id_driver,
            clm.feedback,
            clm.match_status,
            clm.call_recording,
            clm.remark,
            clm.created_at,
            clm.updated_at,
            COALESCE(t.name, d.name, 'Unknown') as user_name,
            COALESCE(t.unique_id, d.unique_id, '') as user_tmid,
            CASE 
                WHEN clm.unique_id_transporter IS NOT NULL AND clm.unique_id_transporter != '' THEN 'Transporter'
                WHEN clm.unique_id_driver IS NOT NULL AND clm.unique_id_driver != '' THEN 'Driver'
                ELSE 'Unknown'
            END as user_type,
            a.name as caller_name
        FROM call_logs_match_making clm
        LEFT JOIN transporters t ON clm.unique_id_transporter = t.unique_id
        LEFT JOIN users d ON clm.unique_id_driver = d.unique_id
        LEFT JOIN admins a ON clm.caller_id = a.id
        $whereClause
        ORDER BY clm.created_at DESC
        LIMIT $limit OFFSET $offset";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $logs = [];
        while ($row = $result->fetch_assoc()) {
            $logs[] = [
                'id' => (int)$row['id'],
                'callerId' => (int)$row['caller_id'],
                'callerName' => $row['caller_name'] ?? '',
                'uniqueIdTransporter' => $row['unique_id_transporter'] ?? '',
                'uniqueIdDriver' => $row['unique_id_driver'] ?? '',
                'userType' => $row['user_type'],
                'userName' => $row['user_name'],
                'userTmid' => $row['user_tmid'],
                'feedback' => $row['feedback'] ?? '',
                'matchStatus' => $row['match_status'] ?? '',
                'callRecording' => $row['call_recording'] ?? '',
                'transporterJobRemark' => $row['remark'] ?? '',
                'additionalNotes' => $row['remark'] ?? '',
                'createdAt' => $row['created_at'] ?? '',
                'updatedAt' => $row['updated_at'] ?? '',
            ];
        }
        
        sendSuccess($logs, 'Call logs fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function saveCallFeedback() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        sendError('Invalid JSON data', 400);
    }
    
    $callerId = isset($data['callerId']) ? (int)$data['callerId'] : 0;
    
    // Handle empty strings as null
    $uniqueIdTransporter = (isset($data['uniqueIdTransporter']) && trim($data['uniqueIdTransporter']) !== '') 
        ? $conn->real_escape_string(trim($data['uniqueIdTransporter'])) : null;
    $uniqueIdDriver = (isset($data['uniqueIdDriver']) && trim($data['uniqueIdDriver']) !== '') 
        ? $conn->real_escape_string(trim($data['uniqueIdDriver'])) : null;
    $driverName = (isset($data['driverName']) && trim($data['driverName']) !== '') 
        ? $conn->real_escape_string(trim($data['driverName'])) : null;
    $transporterName = (isset($data['transporterName']) && trim($data['transporterName']) !== '') 
        ? $conn->real_escape_string(trim($data['transporterName'])) : null;
    $feedback = (isset($data['feedback']) && trim($data['feedback']) !== '') 
        ? $conn->real_escape_string(trim($data['feedback'])) : null;
    $matchStatus = (isset($data['matchStatus']) && trim($data['matchStatus']) !== '') 
        ? $conn->real_escape_string(trim($data['matchStatus'])) : null;
    $transporterJobRemark = isset($data['transporterJobRemark']) 
        ? $conn->real_escape_string($data['transporterJobRemark']) : '';
    $additionalNotes = isset($data['additionalNotes']) 
        ? $conn->real_escape_string($data['additionalNotes']) : '';
    $jobId = (isset($data['jobId']) && trim($data['jobId']) !== '') 
        ? $conn->real_escape_string(trim($data['jobId'])) : null;
    
    // Validation
    if ($callerId === 0) {
        sendError('Caller ID is required', 400);
    }
    
    // At least one ID must be provided (driver or transporter)
    // But we also accept driverId as fallback
    $driverId = isset($data['driverId']) ? (int)$data['driverId'] : 0;
    
    if (!$uniqueIdTransporter && !$uniqueIdDriver && $driverId === 0) {
        sendError('Either transporter ID, driver TMID, or driver ID is required', 400);
    }
    
    if (!$feedback) {
        sendError('Feedback is required', 400);
    }
    
    // If we have driverId but no uniqueIdDriver, use driverId to get the TMID
    if (!$uniqueIdDriver && $driverId > 0) {
        $driverQuery = "SELECT unique_id FROM users WHERE id = $driverId LIMIT 1";
        $driverResult = $conn->query($driverQuery);
        if ($driverResult && $driverResult->num_rows > 0) {
            $driverRow = $driverResult->fetch_assoc();
            $uniqueIdDriver = $driverRow['unique_id'];
        }
    }
    
    try {
        // Combine additional notes and transporter job remark into remark field
        $remarkText = '';
        if (!empty($transporterJobRemark)) {
            $remarkText = $transporterJobRemark;
        }
        if (!empty($additionalNotes)) {
            $remarkText .= (!empty($remarkText) ? ' | ' : '') . $additionalNotes;
        }
        
        // Build the INSERT query - use empty string instead of NULL for NOT NULL columns
        $query = "INSERT INTO call_logs_match_making 
                  (caller_id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, feedback, match_status, remark, job_id, created_at, updated_at) 
                  VALUES 
                  ($callerId, " . 
                  ($uniqueIdTransporter ? "'$uniqueIdTransporter'" : "''") . ", " .
                  ($uniqueIdDriver ? "'$uniqueIdDriver'" : "''") . ", " .
                  ($driverName ? "'$driverName'" : "NULL") . ", " .
                  ($transporterName ? "'$transporterName'" : "NULL") . ", " .
                  "'$feedback', " . 
                  ($matchStatus ? "'$matchStatus'" : "NULL") . ", " .
                  (!empty($remarkText) ? "'$remarkText'" : "NULL") . ", " .
                  ($jobId ? "'$jobId'" : "NULL") . ", NOW(), NOW())";
        
        if ($conn->query($query)) {
            sendSuccess(['id' => $conn->insert_id], 'Call feedback saved successfully');
        } else {
            sendError('Failed to save feedback: ' . $conn->error, 500);
        }
        
    } catch (Exception $e) {
        sendError('Exception: ' . $e->getMessage(), 500);
    }
}
?>
