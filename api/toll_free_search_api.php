<?php
/**
 * Toll-Free Search API
 * Search users by TMID or mobile number with complete profile data
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->exec("SET time_zone = '+05:30'");
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$query = $_GET['query'] ?? '';

if (empty($query)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Query parameter is required']);
    exit;
}

try {
    // Search by TMID or mobile number
    $sql = "SELECT * FROM users 
            WHERE unique_id = :query 
            OR mobile = :query 
            LIMIT 1";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['query' => $query]);
    $user = $stmt->fetch();
    
    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }
    
    // Get latest successful payment
    $paymentSql = "SELECT * FROM payments 
                   WHERE unique_id = :tmid 
                   AND payment_status = 'captured' 
                   ORDER BY created_at DESC 
                   LIMIT 1";
    $paymentStmt = $pdo->prepare($paymentSql);
    $paymentStmt->execute(['tmid' => $user['unique_id']]);
    $payment = $paymentStmt->fetch();
    
    // Get applied jobs for drivers
    $appliedJobs = [];
    if ($user['role'] === 'driver') {
        $jobsSql = "SELECT 
                        aj.id as application_id,
                        aj.job_id,
                        aj.created_at as applied_date,
                        j.job_id as job_code,
                        j.job_title,
                        j.job_location as location,
                        j.Salary_Range as salary,
                        j.status,
                        t.name as company_name,
                        t.transport_name
                    FROM applyjobs aj
                    LEFT JOIN jobs j ON aj.job_id = j.id
                    LEFT JOIN users t ON j.transporter_id = t.id
                    WHERE aj.driver_id = :user_id
                    ORDER BY aj.created_at DESC
                    LIMIT 50";
        $jobsStmt = $pdo->prepare($jobsSql);
        $jobsStmt->execute(['user_id' => $user['id']]);
        $appliedJobs = $jobsStmt->fetchAll();
    }
    
    // Get posted jobs for transporters
    $postedJobs = [];
    if ($user['role'] === 'transporter') {
        $postedSql = "SELECT 
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
                      LIMIT 50";
        $postedStmt = $pdo->prepare($postedSql);
        $postedStmt->execute(['user_id' => $user['id']]);
        $postedJobs = $postedStmt->fetchAll();
    }
    
    // Get match making history for transporters
    $matchMakingHistory = [];
    if ($user['role'] === 'transporter') {
        $matchMakingSql = "SELECT 
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
                          LIMIT 50";
        $matchMakingStmt = $pdo->prepare($matchMakingSql);
        $matchMakingStmt->execute(['tmid' => $user['unique_id']]);
        $matchMakingHistory = $matchMakingStmt->fetchAll();
    }
    
    // Get complete call history with telecaller names and match-making calls
    $tmid = $user['unique_id'];
    $callHistorySql = "
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
    ";
    $callHistoryStmt = $pdo->prepare($callHistorySql);
    $callHistoryStmt->execute([
        'user_id' => $user['id'],
        'tmid' => $tmid
    ]);
    $callHistory = $callHistoryStmt->fetchAll();
    
    // Get training info for drivers
    $trainingInfo = null;
    if ($user['role'] === 'driver') {
        $trainingInfo = getDriverTrainingCompletion($pdo, $user['id']);
    }
    
    // Calculate profile completion
    $profileCompletion = calculateProfileCompletion($user);
    
    // Build response
    $response = [
        'success' => true,
        'user' => array_merge($user, [
            'profile_completion' => $profileCompletion . '%',
            'latest_successful_payment' => $payment ?: false,
            'appliedJobs' => $appliedJobs,
            'postedJobs' => $postedJobs,
            'matchMakingHistory' => $matchMakingHistory,
            'callHistory' => $callHistory,
            'trainingInfo' => $trainingInfo
        ])
    ];
    
    echo json_encode($response);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Search failed: ' . $e->getMessage()
    ]);
}

function calculateProfileCompletion($user) {
    $role = $user['role'] ?? 'driver';
    
    $requiredFields = [];
    if ($role === 'driver') {
        // EXACT MATCH with profile_completion_helper.php
        $requiredFields = [
            'name', 'email', 'city', 'sex', 'vehicle_type',
            'father_name', 'images', 'address', 'dob',
            'type_of_license', 'driving_experience', 'highest_education', 'license_number',
            'expiry_date_of_license', 'expected_monthly_income', 'current_monthly_income',
            'marital_status', 'preferred_location', 'aadhar_number', 'aadhar_photo',
            'driving_license', 'previous_employer', 'job_placement'
        ];
    } elseif ($role === 'transporter') {
        // EXACT MATCH with profile_completion_helper.php - MUST include mobile and states
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
    
    return round(($filledFields / $totalFields) * 100);
}

function getDriverTrainingCompletion($pdo, $driver_id) 
{
    try {
        // Query quiz_results table for this driver
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as total_questions,
                SUM(CASE WHEN user_answer = correct_answer THEN 1 ELSE 0 END) as correct_answers
            FROM quiz_results
            WHERE user_id = ?
        ");
        $stmt->execute([$driver_id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        $totalQuestions = (int)($result['total_questions'] ?? 0);
        $correctAnswers = (int)($result['correct_answers'] ?? 0);

        // Calculate percentage
        $percentage = $totalQuestions > 0 ? ($correctAnswers / $totalQuestions) * 100 : 0;

        // Calculate rating (1-5 stars)
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

        // Calculate ranking percentage (based on 12 questions)
        $rankingPercentage = round(($correctAnswers / 12) * 100, 2);

        // Determine tier
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

        // Check if training is completed
        $isCompleted = ($totalQuestions > 0 && $rating > 0);

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
?>
