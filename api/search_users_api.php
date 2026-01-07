<?php
// Search Users API - Search all users in database for telecaller
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'search';

switch($action) {
    case 'search':
        searchUsers($pdo);
        break;
    case 'one':
        searchOneUser($pdo);
        break;
    default:
        echo json_encode(['error' => 'Invalid action']);
}

function searchUsers($pdo) {
    try {
        $searchQuery = $_GET['query'] ?? '';
        $callerId = (int)($_GET['caller_id'] ?? 0);
        $limit = (int)($_GET['limit'] ?? 50);
        
        // Filter parameters
        $filterRole = $_GET['filter_role'] ?? null; // 'driver' or 'transporter'
        $filterSubscription = $_GET['filter_subscription'] ?? null; // 'active', 'inactive', 'expired'
        $filterProfileMin = (int)($_GET['filter_profile_min'] ?? 0); // 0-100
        $filterProfileMax = (int)($_GET['filter_profile_max'] ?? 100); // 0-100
        $filterState = $_GET['filter_state'] ?? null;
        $filterDateFrom = $_GET['filter_date_from'] ?? null; // YYYY-MM-DD
        $filterDateTo = $_GET['filter_date_to'] ?? null; // YYYY-MM-DD
        $filterMonth = $_GET['filter_month'] ?? null; // 1-12
        $filterYear = $_GET['filter_year'] ?? null; // YYYY
        $filterCallStatus = $_GET['filter_call_status'] ?? null; // 'pending', 'connected', etc.
        
        // Create indexes for faster search (only once)
        createSearchIndexes($pdo);
        
        // Optimized query - fetch ALL fields needed for accurate profile completion
        // Optimized query - fetch ALL fields needed for accurate profile completion
        // Use subqueries for payment info to avoid duplicates (1 row per user)
        $sql = "SELECT 
                    u.id,
                    u.unique_id,
                    u.name,
                    u.mobile,
                    u.email,
                    u.city,
                    u.states,
                    u.status,
                    u.role,
                    u.assigned_to,
                    u.Created_at,
                    u.sex,
                    u.vehicle_type,
                    u.father_name,
                    u.images,
                    u.address,
                    u.dob,
                    u.type_of_license,
                    u.driving_experience,
                    u.highest_education,
                    u.license_number,
                    u.expiry_date_of_license,
                    u.expected_monthly_income,
                    u.current_monthly_income,
                    u.marital_status,
                    u.preferred_location,
                    u.aadhar_number,
                    u.aadhar_photo,
                    u.driving_license,
                    u.previous_employer,
                    u.job_placement,
                    u.transport_name,
                    u.year_of_establishment,
                    u.fleet_size,
                    u.operational_segment,
                    u.average_km,
                    u.pan_number,
                    u.pan_image,
                    u.gst_certificate,
                    (SELECT amount FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_amount,
                    (SELECT end_at FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_end_date,
                    (SELECT created_at FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_created_date,
                    (SELECT payment_status FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_status
                FROM users u
                WHERE u.role IN ('driver', 'transporter')";
        
        // Add search conditions if query provided
        if (!empty($searchQuery)) {
            $searchParam = $searchQuery . '%'; // Prefix search is faster
            
            $sql .= " AND (
                u.name LIKE :search 
                OR u.mobile LIKE :search 
                OR u.unique_id LIKE :search
                OR u.city LIKE :search
            )";
        }
        
        // Add role filter
        if ($filterRole && in_array($filterRole, ['driver', 'transporter'])) {
            $sql .= " AND u.role = :filter_role";
        }
        
        // Add state filter
        if ($filterState) {
            $sql .= " AND u.states = :filter_state";
        }
        
        // Add date filters
        if ($filterDateFrom) {
            $sql .= " AND DATE(u.Created_at) >= :filter_date_from";
        }
        if ($filterDateTo) {
            $sql .= " AND DATE(u.Created_at) <= :filter_date_to";
        }
        
        // Add month/year filter
        if ($filterMonth) {
            $sql .= " AND MONTH(u.Created_at) = :filter_month";
        }
        if ($filterYear) {
            $sql .= " AND YEAR(u.Created_at) = :filter_year";
        }
        
        // Add subscription filter (based on payment_status subquery)
        // Note: We can't use WHERE on alias in same level, so we use HAVING or repeat subquery
        // For simplicity and performance, we'll filter in PHP for subscription status if needed, 
        // or use HAVING which is cleaner here
        if ($filterSubscription) {
            if ($filterSubscription === 'active') {
                $sql .= " HAVING payment_status = 'captured' AND payment_end_date > NOW()";
            } elseif ($filterSubscription === 'expired') {
                $sql .= " HAVING payment_status = 'captured' AND payment_end_date <= NOW()";
            } elseif ($filterSubscription === 'inactive') {
                $sql .= " HAVING (payment_status IS NULL OR payment_status != 'captured')";
            }
        }
        
        // Increase limit if we have post-processing filters (profile completion or call status)
        // This ensures we get enough results after filtering
        $sqlLimit = $limit;
        if ($filterProfileMin > 0 || $filterProfileMax < 100 || $filterCallStatus) {
            $sqlLimit = $limit * 3; // Fetch 3x more to account for filtering
        }
        
        $sql .= " ORDER BY u.id DESC LIMIT :limit";
        
        $stmt = $pdo->prepare($sql);
        
        // Bind search parameter
        if (!empty($searchQuery)) {
            $stmt->bindValue(':search', $searchParam, PDO::PARAM_STR);
        }
        
        // Bind filter parameters
        if ($filterRole && in_array($filterRole, ['driver', 'transporter'])) {
            $stmt->bindValue(':filter_role', $filterRole, PDO::PARAM_STR);
        }
        if ($filterState) {
            $stmt->bindValue(':filter_state', $filterState, PDO::PARAM_STR);
        }
        if ($filterDateFrom) {
            $stmt->bindValue(':filter_date_from', $filterDateFrom, PDO::PARAM_STR);
        }
        if ($filterDateTo) {
            $stmt->bindValue(':filter_date_to', $filterDateTo, PDO::PARAM_STR);
        }
        if ($filterMonth) {
            $stmt->bindValue(':filter_month', $filterMonth, PDO::PARAM_INT);
        }
        if ($filterYear) {
            $stmt->bindValue(':filter_year', $filterYear, PDO::PARAM_INT);
        }
        
        $stmt->bindValue(':limit', $sqlLimit, PDO::PARAM_INT);
        $stmt->execute();
        $users = $stmt->fetchAll();
        
        // Batch fetch call logs for all users at once (much faster)
        $userIds = array_column($users, 'id');
        $callLogsMap = [];
        
        if ($callerId > 0 && !empty($userIds)) {
            $placeholders = str_repeat('?,', count($userIds) - 1) . '?';
            $stmt = $pdo->prepare("
                SELECT user_id, call_status, feedback, remarks, call_time 
                FROM call_logs 
                WHERE user_id IN ($placeholders) AND caller_id = ?
                ORDER BY call_time DESC
            ");
            $stmt->execute([...$userIds, $callerId]);
            $callLogs = $stmt->fetchAll();
            
            // Group by user_id (keep only latest)
            foreach ($callLogs as $log) {
                if (!isset($callLogsMap[$log['user_id']])) {
                    $callLogsMap[$log['user_id']] = $log;
                }
            }
        }
        
        // Get call status for each user
        $usersWithCallStatus = array_map(function($user) use ($pdo, $callerId, $callLogsMap) {
            $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
            
            // Get call status from pre-fetched map
            $callStatus = 'pending';
            $lastFeedback = null;
            $lastCallTime = null;
            $remarks = null;
            
            if (isset($callLogsMap[$user['id']])) {
                $callLog = $callLogsMap[$user['id']];
                $callStatus = $callLog['call_status'];
                $lastFeedback = $callLog['feedback'];
                $lastCallTime = $callLog['call_time'];
                $remarks = $callLog['remarks'];
            }
            
            // Determine subscription status based on payment_status column
            $subscriptionStatus = 'inactive';
            $paymentStatus = strtolower($user['payment_status'] ?? '');
            
            // Check if payment status is "captured" (successful payment)
            if ($paymentStatus === 'captured') {
                // Payment is captured, check if subscription is still active
                if (!empty($user['payment_end_date'])) {
                    $endDate = strtotime($user['payment_end_date']);
                    $now = time();
                    if ($endDate > $now) {
                        $subscriptionStatus = 'active';
                    } else {
                        $subscriptionStatus = 'expired';
                    }
                } else {
                    // If no end date but payment captured, consider active
                    $subscriptionStatus = 'active';
                }
            } elseif ($paymentStatus === 'pending') {
                // Payment is pending, not subscribed yet
                $subscriptionStatus = 'pending';
            } else {
                // No payment or other status, check user status
                if (!empty($user['status'])) {
                    switch(strtolower($user['status'])) {
                        case 'active':
                        case 'verified':
                        case 'approved':
                            $subscriptionStatus = 'pending';
                            break;
                    }
                }
            }
            
            // Build payment info with created date - ONLY for captured status
            $paymentInfo = null;
            if ($paymentStatus === 'captured') {
                // Format payment created date as DD/MM/YYYY
                $paymentDateFormatted = null;
                if (!empty($user['payment_created_date'])) {
                    $date = new DateTime($user['payment_created_date']);
                    $paymentDateFormatted = $date->format('d/m/Y');
                }
                
                $paymentInfo = [
                    'subscriptionType' => $paymentDateFormatted ?? 'subscription',
                    'paymentStatus' => 'success',
                    'paymentDate' => $user['payment_created_date'],
                    'amount' => $user['payment_amount'],
                    'expiryDate' => $user['payment_end_date']
                ];
            }
            // Don't show payment info for pending or other statuses
            
            // Calculate profile completion (fast version)
            $profileCompletion = calculateProfileCompletionFast($user);
            
            // Build company name (simplified)
            $company = $user['city'] ? $user['city'] . ' Transport' : '';

            // Parse profile picture - same logic as fresh_leads_api.php
            $profilePicture = null;
            if (!empty($user['images'])) {
                $images = json_decode($user['images'], true);
                if (is_array($images) && count($images) > 0) {
                    $imagePath = $images[0];
                    // Construct full URL with base URL
                    $profilePicture = 'https://truckmitr.com/public/' . $imagePath;
                } elseif (!is_array($images) && is_string($user['images'])) {
                    // Handle case where images is a plain string, not JSON
                    $profilePicture = 'https://truckmitr.com/public/' . $user['images'];
                }
            }
            
            // Get applied jobs for drivers
            $appliedJobs = [];
            if ($user['role'] === 'driver') {
                $jobsStmt = $pdo->prepare("
                    SELECT 
                        aj.id as application_id,
                        aj.job_id,
                        aj.created_at as applied_date,
                        j.job_id as job_code,
                        j.job_title,
                        j.job_location as location,
                        j.Salary_Range as salary,
                        t.name as company_name,
                        t.transport_name
                    FROM applyjobs aj
                    LEFT JOIN jobs j ON aj.job_id = j.id
                    LEFT JOIN users t ON j.transporter_id = t.id
                    WHERE aj.driver_id = :user_id
                    ORDER BY aj.created_at DESC
                    LIMIT 50
                ");
                $jobsStmt->execute(['user_id' => $user['id']]);
                $appliedJobs = $jobsStmt->fetchAll();
            }

            // Get posted jobs for transporters
            $postedJobs = [];
            if ($user['role'] === 'transporter') {
                $postedJobsStmt = $pdo->prepare("
                    SELECT 
                        j.id,
                        j.job_id as job_code,
                        j.job_title,
                        j.job_location as location,
                        j.Salary_Range as salary,
                        j.Created_at as posted_date,
                        j.status,
                        j.active_inactive,
                        (SELECT COUNT(*) FROM applyjobs WHERE job_id = j.id) as applicant_count
                    FROM jobs j
                    WHERE j.transporter_id = :user_id
                    ORDER BY j.Created_at DESC
                    LIMIT 50
                ");
                $postedJobsStmt->execute(['user_id' => $user['id']]);
                $postedJobs = $postedJobsStmt->fetchAll();
            }

            // Get match making history (handshake) for transporters
            $matchMakingHistory = [];
            if ($user['role'] === 'transporter') {
                $matchMakingStmt = $pdo->prepare("
                    SELECT 
                        clm.id,
                        clm.created_at as match_date,
                        clm.driver_name,
                        clm.unique_id_driver as driver_tmid,
                        clm.job_id,
                        clm.match_status,
                        clm.feedback
                    FROM call_logs_match_making clm
                    WHERE clm.unique_id_transporter = :tmid
                    AND (clm.feedback LIKE '%Match Making Done%' OR clm.match_status = 'Match Making Done')
                    ORDER BY clm.created_at DESC
                    LIMIT 50
                ");
                $matchMakingStmt->execute(['tmid' => $tmid]);
                $matchMakingHistory = $matchMakingStmt->fetchAll();
            }
            
            // Get complete call history for this user from ALL telecallers
            // Priority: match_making calls > welcome calls (no duplicates, no pending)
            
            // First, get all match-making calls for this user
            $callHistoryStmt = $pdo->prepare("
                SELECT 
                    clm.id,
                    clm.caller_id,
                    a.name as telecaller_name,
                    'connected' as call_status,
                    clm.feedback,
                    clm.remark as remarks,
                    NULL as call_duration,
                    clm.call_recording as recording_url,
                    NULL as manual_call_recording_url,
                    clm.created_at as call_time,
                    clm.created_at,
                    'match_making' as call_type,
                    clm.match_status,
                    clm.job_id,
                    CASE 
                        WHEN clm.unique_id_driver = :tmid THEN clm.transporter_name
                        ELSE clm.driver_name
                    END as other_party_name,
                    CASE 
                        WHEN clm.unique_id_driver = :tmid THEN clm.unique_id_transporter
                        ELSE clm.unique_id_driver
                    END as other_party_tmid
                FROM call_logs_match_making clm
                LEFT JOIN admins a ON clm.caller_id = a.id
                WHERE (clm.unique_id_driver = :tmid OR clm.unique_id_transporter = :tmid)
                AND clm.feedback IS NOT NULL 
                AND clm.feedback != ''
                AND clm.feedback != 'pending'
                
                UNION ALL
                
                SELECT 
                    cl.id,
                    cl.caller_id,
                    a.name as telecaller_name,
                    cl.call_status,
                    cl.feedback,
                    cl.remarks,
                    cl.call_duration,
                    cl.recording_url,
                    cl.manual_call_recording_url,
                    COALESCE(cl.call_initiated_at, cl.call_time, cl.created_at) as call_time,
                    cl.created_at,
                    'welcome_call' as call_type,
                    NULL as match_status,
                    NULL as job_id,
                    NULL as other_party_name,
                    NULL as other_party_tmid
                FROM call_logs cl
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE cl.user_id = :user_id
                AND cl.call_status != 'pending'
                AND (cl.feedback IS NOT NULL AND cl.feedback != '' AND cl.feedback != 'pending')
                AND NOT EXISTS (
                    -- Exclude if this user has a match-making call with same caller around same time
                    SELECT 1 FROM call_logs_match_making clm2
                    WHERE (clm2.unique_id_driver = :tmid OR clm2.unique_id_transporter = :tmid)
                    AND clm2.caller_id = cl.caller_id
                    AND ABS(TIMESTAMPDIFF(MINUTE, clm2.created_at, COALESCE(cl.call_initiated_at, cl.call_time, cl.created_at))) <= 5
                )
                
                ORDER BY call_time DESC
                LIMIT 100
            ");
            $callHistoryStmt->execute([
                'user_id' => $user['id'],
                'tmid' => $tmid
            ]);
            $callHistory = $callHistoryStmt->fetchAll();
            
            // Get assigned telecaller from assigned_to column in users table
            $assignedTelecaller = null;
            if (!empty($user['assigned_to'])) {
                $telecallerStmt = $pdo->prepare("
                    SELECT name FROM admins WHERE id = :telecaller_id LIMIT 1
                ");
                $telecallerStmt->execute(['telecaller_id' => $user['assigned_to']]);
                $telecallerRow = $telecallerStmt->fetch();
                if ($telecallerRow) {
                    $assignedTelecaller = $telecallerRow['name'];
                }
            }
            
            return [
                'id' => (string)$user['id'],
                'tmid' => $tmid,
                'name' => $user['name'] ?? 'User ' . $user['id'],
                'company' => $company,
                'phoneNumber' => $user['mobile'] ?? '',
                'email' => $user['email'] ?? '',
                'city' => $user['city'] ?? 'Unknown',
                'state' => $user['states'] ?? 'Unknown',
                'role' => $user['role'] ?? 'driver',
                'subscriptionStatus' => $subscriptionStatus,
                'userStatus' => $user['status'] ?? 'inactive',
                'callStatus' => $callStatus,
                'lastFeedback' => $lastFeedback,
                'lastCallTime' => $lastCallTime,
                'remarks' => $remarks,
                'paymentInfo' => $paymentInfo,
                'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
                'profile_completion' => $profileCompletion . '%',
                'profilePicture' => $profilePicture,
                'licenseType' => $user['type_of_license'] ?? null,
                'fleetSize' => $user['fleet_size'] ?? null,
                'appliedJobs' => $appliedJobs,
                'postedJobs' => $postedJobs,
                'matchMakingHistory' => $matchMakingHistory,
                'assignedTelecaller' => $assignedTelecaller,
                'role' => $user['role'] ?? 'driver',
                'callHistory' => $callHistory,
                'trainingInfo' => ($user['role'] === 'driver') ? getDriverTrainingCompletion($pdo, $user['id']) : null
            ];
        }, $users);
        
        // Apply profile completion filter (post-processing)
        if ($filterProfileMin > 0 || $filterProfileMax < 100) {
            $usersWithCallStatus = array_filter($usersWithCallStatus, function($user) use ($filterProfileMin, $filterProfileMax) {
                $completion = (int)str_replace('%', '', $user['profile_completion']);
                return $completion >= $filterProfileMin && $completion <= $filterProfileMax;
            });
            $usersWithCallStatus = array_values($usersWithCallStatus); // Re-index array
        }
        
        // Apply call status filter (post-processing)
        if ($filterCallStatus) {
            $usersWithCallStatus = array_filter($usersWithCallStatus, function($user) use ($filterCallStatus) {
                return $user['callStatus'] === $filterCallStatus;
            });
            $usersWithCallStatus = array_values($usersWithCallStatus); // Re-index array
        }
        
        // Limit final results to requested limit
        if (count($usersWithCallStatus) > $limit) {
            $usersWithCallStatus = array_slice($usersWithCallStatus, 0, $limit);
        }
        
        echo json_encode([
            'success' => true,
            'data' => $usersWithCallStatus,
            'count' => count($usersWithCallStatus),
            'query' => $searchQuery,
            'filters_applied' => [
                'role' => $filterRole,
                'subscription' => $filterSubscription,
                'profile_range' => [$filterProfileMin, $filterProfileMax],
                'state' => $filterState,
                'date_from' => $filterDateFrom,
                'date_to' => $filterDateTo,
                'month' => $filterMonth,
                'year' => $filterYear,
                'call_status' => $filterCallStatus
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to search users: ' . $e->getMessage()
        ]);
    }
}

function searchOneUser($pdo) {
    try {
        $userId = $_GET['user_id'] ?? null;
        $tmid = $_GET['tmid'] ?? null;
        $callerId = (int)($_GET['caller_id'] ?? 0);
        
        if (!$userId && !$tmid) {
            echo json_encode([
                'success' => false,
                'error' => 'Either user_id or tmid parameter is required'
            ]);
            return;
        }
        
        // Build query to find user by ID or TMID
        $sql = "SELECT 
                    u.id,
                    u.unique_id,
                    u.name,
                    u.mobile,
                    u.email,
                    u.city,
                    u.states,
                    u.status,
                    u.role,
                    u.assigned_to,
                    u.Created_at,
                    u.sex,
                    u.vehicle_type,
                    u.father_name,
                    u.images,
                    u.address,
                    u.dob,
                    u.type_of_license,
                    u.driving_experience,
                    u.highest_education,
                    u.license_number,
                    u.expiry_date_of_license,
                    u.expected_monthly_income,
                    u.current_monthly_income,
                    u.marital_status,
                    u.preferred_location,
                    u.aadhar_number,
                    u.aadhar_photo,
                    u.driving_license,
                    u.previous_employer,
                    u.job_placement,
                    u.transport_name,
                    u.year_of_establishment,
                    u.fleet_size,
                    u.operational_segment,
                    u.average_km,
                    u.pan_number,
                    u.pan_image,
                    u.gst_certificate,
                    (SELECT amount FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_amount,
                    (SELECT end_at FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_end_date,
                    (SELECT created_at FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_created_date,
                    (SELECT payment_status FROM payments WHERE unique_id = u.unique_id ORDER BY CASE WHEN payment_status = 'captured' THEN 1 ELSE 2 END, created_at DESC LIMIT 1) as payment_status
                FROM users u
                WHERE ";
        
        if ($userId) {
            $sql .= "u.id = :user_id";
        } else {
            $sql .= "u.unique_id = :tmid";
        }
        
        $sql .= " LIMIT 1";
        
        $stmt = $pdo->prepare($sql);
        
        if ($userId) {
            $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        } else {
            $stmt->bindValue(':tmid', $tmid, PDO::PARAM_STR);
        }
        
        $stmt->execute();
        $user = $stmt->fetch();
        
        if (!$user) {
            echo json_encode([
                'success' => false,
                'error' => 'User not found'
            ]);
            return;
        }
        
        // Get call logs for this user
        $callLogsMap = [];
        if ($callerId > 0) {
            $stmt = $pdo->prepare("
                SELECT user_id, call_status, feedback, remarks, call_time 
                FROM call_logs 
                WHERE user_id = ? AND caller_id = ?
                ORDER BY call_time DESC
                LIMIT 1
            ");
            $stmt->execute([$user['id'], $callerId]);
            $callLog = $stmt->fetch();
            
            if ($callLog) {
                $callLogsMap[$user['id']] = $callLog;
            }
        }
        
        // Process user data (same logic as searchUsers)
        $tmid = $user['unique_id'] ?? 'TM' . str_pad($user['id'], 6, '0', STR_PAD_LEFT);
        
        // Get call status
        $callStatus = 'pending';
        $lastFeedback = null;
        $lastCallTime = null;
        $remarks = null;
        
        if (isset($callLogsMap[$user['id']])) {
            $callLog = $callLogsMap[$user['id']];
            $callStatus = $callLog['call_status'];
            $lastFeedback = $callLog['feedback'];
            $lastCallTime = $callLog['call_time'];
            $remarks = $callLog['remarks'];
        }
        
        // Determine subscription status
        $subscriptionStatus = 'inactive';
        $paymentStatus = strtolower($user['payment_status'] ?? '');
        
        if ($paymentStatus === 'captured') {
            if (!empty($user['payment_end_date'])) {
                $endDate = strtotime($user['payment_end_date']);
                $now = time();
                if ($endDate > $now) {
                    $subscriptionStatus = 'active';
                } else {
                    $subscriptionStatus = 'expired';
                }
            } else {
                $subscriptionStatus = 'active';
            }
        } elseif ($paymentStatus === 'pending') {
            $subscriptionStatus = 'pending';
        } else {
            if (!empty($user['status'])) {
                switch(strtolower($user['status'])) {
                    case 'active':
                    case 'verified':
                    case 'approved':
                        $subscriptionStatus = 'pending';
                        break;
                }
            }
        }
        
        // Build payment info - ONLY for captured status
        $paymentInfo = null;
        if ($paymentStatus === 'captured') {
            $paymentDateFormatted = null;
            if (!empty($user['payment_created_date'])) {
                $date = new DateTime($user['payment_created_date']);
                $paymentDateFormatted = $date->format('d/m/Y');
            }
            
            $paymentInfo = [
                'subscriptionType' => $paymentDateFormatted ?? 'subscription',
                'paymentStatus' => 'success',
                'paymentDate' => $user['payment_created_date'],
                'amount' => $user['payment_amount'],
                'expiryDate' => $user['payment_end_date']
            ];
        }
        // Don't show payment info for pending or other statuses
        
        // Calculate profile completion
        $profileCompletion = calculateProfileCompletionFast($user);
        
        // Build company name
        $company = $user['city'] ? $user['city'] . ' Transport' : '';

        // Parse profile picture
        $profilePicture = null;
        if (!empty($user['images'])) {
            $images = json_decode($user['images'], true);
            if (is_array($images) && count($images) > 0) {
                $imagePath = $images[0];
                $profilePicture = 'https://truckmitr.com/public/' . $imagePath;
            } elseif (!is_array($images) && is_string($user['images'])) {
                $profilePicture = 'https://truckmitr.com/public/' . $user['images'];
            }
        }
        
        // Get applied jobs for drivers
        $appliedJobs = [];
        if ($user['role'] === 'driver') {
            $jobsStmt = $pdo->prepare("
                SELECT 
                    aj.id as application_id,
                    aj.job_id,
                    aj.created_at as applied_date,
                    j.job_id as job_code,
                    j.job_title,
                    j.job_location as location,
                    j.Salary_Range as salary,
                    t.name as company_name,
                    t.transport_name
                FROM applyjobs aj
                LEFT JOIN jobs j ON aj.job_id = j.id
                LEFT JOIN users t ON j.transporter_id = t.id
                WHERE aj.driver_id = :user_id
                ORDER BY aj.created_at DESC
                LIMIT 50
            ");
            $jobsStmt->execute(['user_id' => $user['id']]);
            $appliedJobs = $jobsStmt->fetchAll();
        }

        // Get posted jobs for transporters
        $postedJobs = [];
        if ($user['role'] === 'transporter') {
            $postedJobsStmt = $pdo->prepare("
                SELECT 
                    j.id,
                    j.job_id as job_code,
                    j.job_title,
                    j.job_location as location,
                    j.Salary_Range as salary,
                    j.Created_at as posted_date,
                    j.status,
                    j.active_inactive,
                    (SELECT COUNT(*) FROM applyjobs WHERE job_id = j.id) as applicant_count
                FROM jobs j
                WHERE j.transporter_id = :user_id
                ORDER BY j.Created_at DESC
                LIMIT 50
            ");
            $postedJobsStmt->execute(['user_id' => $user['id']]);
            $postedJobs = $postedJobsStmt->fetchAll();
        }

        // Get match making history for transporters
        $matchMakingHistory = [];
        if ($user['role'] === 'transporter') {
            $matchMakingStmt = $pdo->prepare("
                SELECT 
                    clm.id,
                    clm.created_at as match_date,
                    clm.driver_name,
                    clm.unique_id_driver as driver_tmid,
                    clm.job_id,
                    clm.match_status,
                    clm.feedback
                FROM call_logs_match_making clm
                WHERE clm.unique_id_transporter = :tmid
                AND (clm.feedback LIKE '%Match Making Done%' OR clm.match_status = 'Match Making Done')
                ORDER BY clm.created_at DESC
                LIMIT 50
            ");
            $matchMakingStmt->execute(['tmid' => $tmid]);
            $matchMakingHistory = $matchMakingStmt->fetchAll();
        }
        
        // Get complete call history
        $callHistoryStmt = $pdo->prepare("
            SELECT 
                clm.id,
                clm.caller_id,
                a.name as telecaller_name,
                'connected' as call_status,
                clm.feedback,
                clm.remark as remarks,
                NULL as call_duration,
                clm.call_recording as recording_url,
                NULL as manual_call_recording_url,
                clm.created_at as call_time,
                clm.created_at,
                'match_making' as call_type,
                clm.match_status,
                clm.job_id,
                CASE 
                    WHEN clm.unique_id_driver = :tmid THEN clm.transporter_name
                    ELSE clm.driver_name
                END as other_party_name,
                CASE 
                    WHEN clm.unique_id_driver = :tmid THEN clm.unique_id_transporter
                    ELSE clm.unique_id_driver
                END as other_party_tmid
            FROM call_logs_match_making clm
            LEFT JOIN admins a ON clm.caller_id = a.id
            WHERE (clm.unique_id_driver = :tmid OR clm.unique_id_transporter = :tmid)
            AND clm.feedback IS NOT NULL 
            AND clm.feedback != ''
            AND clm.feedback != 'pending'
            
            UNION ALL
            
            SELECT 
                cl.id,
                cl.caller_id,
                a.name as telecaller_name,
                cl.call_status,
                cl.feedback,
                cl.remarks,
                cl.call_duration,
                cl.recording_url,
                cl.manual_call_recording_url,
                COALESCE(cl.call_initiated_at, cl.call_time, cl.created_at) as call_time,
                cl.created_at,
                'welcome_call' as call_type,
                NULL as match_status,
                NULL as job_id,
                NULL as other_party_name,
                NULL as other_party_tmid
            FROM call_logs cl
            LEFT JOIN admins a ON cl.caller_id = a.id
            WHERE cl.user_id = :user_id
            AND cl.call_status != 'pending'
            AND (cl.feedback IS NOT NULL AND cl.feedback != '' AND cl.feedback != 'pending')
            AND NOT EXISTS (
                SELECT 1 FROM call_logs_match_making clm2
                WHERE (clm2.unique_id_driver = :tmid OR clm2.unique_id_transporter = :tmid)
                AND clm2.caller_id = cl.caller_id
                AND ABS(TIMESTAMPDIFF(MINUTE, clm2.created_at, COALESCE(cl.call_initiated_at, cl.call_time, cl.created_at))) <= 5
            )
            
            ORDER BY call_time DESC
            LIMIT 100
        ");
        $callHistoryStmt->execute([
            'user_id' => $user['id'],
            'tmid' => $tmid
        ]);
        $callHistory = $callHistoryStmt->fetchAll();
        
        // Get assigned telecaller
        $assignedTelecaller = null;
        if (!empty($user['assigned_to'])) {
            $telecallerStmt = $pdo->prepare("
                SELECT name FROM admins WHERE id = :telecaller_id LIMIT 1
            ");
            $telecallerStmt->execute(['telecaller_id' => $user['assigned_to']]);
            $telecallerRow = $telecallerStmt->fetch();
            if ($telecallerRow) {
                $assignedTelecaller = $telecallerRow['name'];
            }
        }
        
        $userData = [
            'id' => (string)$user['id'],
            'tmid' => $tmid,
            'name' => $user['name'] ?? 'User ' . $user['id'],
            'company' => $company,
            'phoneNumber' => $user['mobile'] ?? '',
            'email' => $user['email'] ?? '',
            'city' => $user['city'] ?? 'Unknown',
            'state' => $user['states'] ?? 'Unknown',
            'role' => $user['role'] ?? 'driver',
            'subscriptionStatus' => $subscriptionStatus,
            'userStatus' => $user['status'] ?? 'inactive',
            'callStatus' => $callStatus,
            'lastFeedback' => $lastFeedback,
            'lastCallTime' => $lastCallTime,
            'remarks' => $remarks,
            'paymentInfo' => $paymentInfo,
            'registrationDate' => $user['Created_at'] ?? date('Y-m-d H:i:s'),
            'profile_completion' => $profileCompletion . '%',
            'profilePicture' => $profilePicture,
            'licenseType' => $user['type_of_license'] ?? null,
            'fleetSize' => $user['fleet_size'] ?? null,
            'appliedJobs' => $appliedJobs,
            'postedJobs' => $postedJobs,
            'matchMakingHistory' => $matchMakingHistory,
            'assignedTelecaller' => $assignedTelecaller,
            'callHistory' => $callHistory,
            'trainingInfo' => ($user['role'] === 'driver') ? getDriverTrainingCompletion($pdo, $user['id']) : null
        ];
        
        echo json_encode([
            'success' => true,
            'data' => $userData,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch user: ' . $e->getMessage()
        ]);
    }
}

function calculateProfileCompletionFast($user) {
    $role = $user['role'] ?? 'driver';
    
    // Define required fields based on role - EXACT MATCH with profile_completion_helper.php
    $requiredFields = [];
    if ($role === 'driver') {
        $requiredFields = [
            'name', 'email', 'mobile', 'states', 'city', 'sex', 'vehicle_type',
            'father_name', 'images', 'address', 'dob',
            'type_of_license', 'driving_experience', 'highest_education', 'license_number',
            'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
            'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
            'driving_license', 'previous_employer', 'job_placement'
        ];
    } elseif ($role === 'transporter') {
        $requiredFields = [
            'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
            'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
            'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
        ];
    } else {
        return 0;
    }
    
    $filledFields = 0;
    $totalFields = count($requiredFields);
    
    if ($totalFields === 0) {
        return 0;
    }
    
    foreach ($requiredFields as $field) {
        $value = $user[$field] ?? null;
        
        // Check if field has a value - EXACT MATCH with profile_completion_api.php logic
        if ($value !== null && $value !== '') {
            // Check if it's a JSON array with content
            $decoded = json_decode($value, true);
            if (is_array($decoded) && count($decoded) > 0) {
                $filledFields++;
            } elseif (!is_array($decoded)) {
                // Not a JSON array, so it's a regular value
                $filledFields++;
            }
            // Empty JSON arrays don't count
        }
    }
    
    $completionPercentage = round(($filledFields / $totalFields) * 100);
    
    return $completionPercentage;
}

function createSearchIndexes($pdo) {
    try {
        // Create indexes for faster search (if not exists)
        $indexes = [
            "CREATE INDEX IF NOT EXISTS idx_users_name ON users(name(50))",
            "CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile)",
            "CREATE INDEX IF NOT EXISTS idx_users_unique_id ON users(unique_id)",
            "CREATE INDEX IF NOT EXISTS idx_users_city ON users(city)",
            "CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)",
            "CREATE INDEX IF NOT EXISTS idx_payments_unique_id ON payments(unique_id)",
            "CREATE INDEX IF NOT EXISTS idx_call_logs_user_caller ON call_logs(user_id, caller_id)"
        ];
        
        foreach ($indexes as $indexSql) {
            try {
                $pdo->exec($indexSql);
            } catch (Exception $e) {
                // Index might already exist, continue
            }
        }
    } catch (Exception $e) {
        error_log('Index creation error: ' . $e->getMessage());
    }
}

function calculateProfileCompletion($pdo, $userId) {
    try {
        $stmt = $pdo->prepare("
            SELECT 
                name, email, mobile, city, states, status, sex, vehicle_type, role,
                father_name, images, address, dob,
                type_of_license, driving_experience, highest_education, license_number,
                expiry_date_of_license, expected_monthly_income, current_monthly_income,
                marital_status, preferred_location, aadhar_number, aadhar_photo,
                driving_license, previous_employer, job_placement,
                transport_name, year_of_establishment, fleet_size, operational_segment,
                average_km, pan_number, pan_image, gst_certificate
            FROM users 
            WHERE id = ?
        ");
        
        $stmt->execute([$userId]);
        $user = $stmt->fetch();
        
        if (!$user) {
            return 0;
        }
        
        $role = $user['role'];
        
        $requiredFields = [];
        if ($role === 'driver') {
            $requiredFields = [
                'name', 'email', 'mobile', 'states', 'city', 'sex', 'vehicle_type',
                'father_name', 'images', 'address', 'dob',
                'type_of_license', 'driving_experience', 'highest_education', 'license_number',
                'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
                'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
                'driving_license', 'previous_employer', 'job_placement'
            ];
        } elseif ($role === 'transporter') {
            $requiredFields = [
                'name', 'email', 'mobile', 'transport_name', 'year_of_establishment',
                'fleet_size', 'operational_segment', 'average_km', 'city', 'states',
                'images', 'address', 'pan_number', 'pan_image', 'gst_certificate'
            ];
        }
        
        $filledFields = 0;
        $totalFields = count($requiredFields);
        
        if ($totalFields === 0) {
            return 0;
        }
        
        foreach ($requiredFields as $field) {
            $value = $user[$field] ?? null;
            
            if ($value !== null && $value !== '') {
                $decoded = json_decode($value, true);
                if (is_array($decoded) && count($decoded) > 0) {
                    $filledFields++;
                } elseif (!is_array($decoded)) {
                    $filledFields++;
                }
            }
        }
        
        $completionPercentage = round(($filledFields / $totalFields) * 100);
        
        return $completionPercentage;
        
    } catch(Exception $e) {
        error_log('Profile completion calculation error: ' . $e->getMessage());
        return 0;
    }
}


function getDriverTrainingCompletion($pdo, $driver_id) 
{
    try {
        // STEP 1: Query quiz_results table for this driver
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_questions,
                SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) as correct_answers
            FROM quiz_results
            WHERE user_id = ?
        ");
        $stmt->execute([$driver_id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        // STEP 2: Get counts
        $totalQuestions = (int)($result['total_questions'] ?? 0);
        $correctAnswers = (int)($result['correct_answers'] ?? 0);

        // STEP 3: Calculate percentage
        $percentage = $totalQuestions > 0 ? ($correctAnswers / $totalQuestions) * 100 : 0;

        // STEP 4: Calculate rating (1-5 stars)
        if ($percentage <= 20) {
            $rating = 1;
        } elseif ($percentage <= 40) {
            $rating = 2;
        } elseif ($percentage <= 60) {
            $rating = 3;
        } elseif ($percentage <= 80) {
            $rating = 4;
        } else {
            $rating = 5;
        }

        // STEP 5: Calculate ranking percentage (based on 12 questions)
        $rankingPercentage = round(($correctAnswers / 12) * 100, 2);

        // STEP 6: Determine tier
        if ($rankingPercentage >= 95) {
            $tier = 'Diamond';
        } elseif ($rankingPercentage >= 81) {
            $tier = 'Platinum';
        } elseif ($rankingPercentage >= 61) {
            $tier = 'Gold';
        } elseif ($rankingPercentage >= 41) {
            $tier = 'Silver';
        } elseif ($rankingPercentage > 0) {
            $tier = 'Bronze';
        } else {
            $tier = 'N/A';
        }

        // STEP 7: Check if training is completed
        $isCompleted = ($totalQuestions > 0 && $rating > 0);

        // STEP 8: Return all data
        return [
            'is_completed' => $isCompleted,
            'total_questions' => $totalQuestions,
            'correct_answers' => $correctAnswers,
            'percentage' => round($percentage, 2),
            'rating' => $rating,
            'ranking_percentage' => $rankingPercentage,
            'tier' => $tier,
        ];
    } catch (Exception $e) {
        // Return default values on error
        return [
            'is_completed' => false,
            'total_questions' => 0,
            'correct_answers' => 0,
            'percentage' => 0,
            'rating' => 0,
            'ranking_percentage' => 0,
            'tier' => 'N/A',
        ];
    }
}

