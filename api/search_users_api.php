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
                    p.amount as payment_amount,
                    p.end_at as payment_end_date,
                    p.created_at as payment_created_date,
                    p.payment_status as payment_status
                FROM users u
                LEFT JOIN payments p ON u.unique_id = p.unique_id
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
        
        // Add subscription filter (based on payment_status)
        if ($filterSubscription === 'active') {
            $sql .= " AND p.payment_status = 'captured' AND p.end_at > NOW()";
        } elseif ($filterSubscription === 'expired') {
            $sql .= " AND p.payment_status = 'captured' AND p.end_at <= NOW()";
        } elseif ($filterSubscription === 'inactive') {
            $sql .= " AND (p.payment_status IS NULL OR p.payment_status != 'captured')";
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
            
            // Build payment info with created date
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
            } elseif ($paymentStatus === 'pending') {
                // Show pending payment info
                $paymentInfo = [
                    'subscriptionType' => 'pending',
                    'paymentStatus' => 'pending',
                    'paymentDate' => $user['payment_created_date'],
                    'amount' => $user['payment_amount'],
                    'expiryDate' => null
                ];
            }
            
            // Calculate profile completion (fast version)
            $profileCompletion = calculateProfileCompletionFast($user);
            
            // Build company name (simplified)
            $company = ($user['city'] ?? 'Unknown') . ' Transport';
            
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
                'profile_completion' => $profileCompletion . '%'
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

function calculateProfileCompletionFast($user) {
    $role = $user['role'] ?? 'driver';
    
    // Define required fields based on role - EXACT MATCH with profile_completion_api.php
    $requiredFields = [];
    if ($role === 'driver') {
        $requiredFields = [
            'name', 'email', 'city', 'sex', 'vehicle_type',
            'father_name', 'images', 'address', 'dob',
            'type_of_license', 'driving_experience', 'highest_education', 'license_number',
            'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
            'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
            'driving_license', 'previous_employer', 'job_placement'
        ];
    } elseif ($role === 'transporter') {
        $requiredFields = [
            'name', 'email', 'transport_name', 'year_of_establishment',
            'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
            'pan_number', 'pan_image', 'gst_certificate'
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
                name, email, city, status, sex, vehicle_type, role,
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
                'name', 'email', 'city', 'sex', 'vehicle_type',
                'father_name', 'images', 'address', 'dob',
                'type_of_license', 'driving_experience', 'highest_education', 'license_number',
                'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
                'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
                'driving_license', 'previous_employer', 'job_placement'
            ];
        } elseif ($role === 'transporter') {
            $requiredFields = [
                'name', 'email', 'transport_name', 'year_of_establishment',
                'fleet_size', 'operational_segment', 'average_km', 'city', 'images', 'address',
                'pan_number', 'pan_image', 'gst_certificate'
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
?>
