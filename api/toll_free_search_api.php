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
                        j.id as job_id,
                        j.job_id as job_code,
                        j.job_title,
                        j.job_location as location,
                        j.Salary_Range as salary,
                        j.status,
                        j.Created_at as created_at,
                        u.name as company_name,
                        u.transport_name,
                        (SELECT COUNT(*) FROM applyjobs WHERE job_id = j.id) as applicants_count
                      FROM jobs j
                      LEFT JOIN users u ON j.transporter_id = u.id
                      WHERE j.transporter_id = :user_id
                      ORDER BY j.Created_at DESC
                      LIMIT 50";
        $postedStmt = $pdo->prepare($postedSql);
        $postedStmt->execute(['user_id' => $user['id']]);
        $postedJobs = $postedStmt->fetchAll();
    }
    
    // Get call logs
    $callLogsSql = "SELECT * FROM call_logs 
                    WHERE user_number = :mobile 
                    OR user_id = :user_id
                    ORDER BY call_time DESC 
                    LIMIT 20";
    $callLogsStmt = $pdo->prepare($callLogsSql);
    $callLogsStmt->execute([
        'mobile' => $user['mobile'],
        'user_id' => $user['id']
    ]);
    $callLogs = $callLogsStmt->fetchAll();
    
    // Calculate profile completion
    $profileCompletion = calculateProfileCompletion($user);
    
    // Build response
    $response = [
        'success' => true,
        'user' => array_merge($user, [
            'profile_completion' => $profileCompletion . '%',
            'latest_successful_payment' => $payment ?: false,
            'applied_jobs' => $appliedJobs,
            'posted_jobs' => $postedJobs,
            'call_logs' => $callLogs
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
        $requiredFields = [
            'name', 'email', 'city', 'sex', 'vehicle_type',
            'Father_Name', 'images', 'address', 'DOB',
            'Type_of_License', 'Driving_Experience', 'Highest_Education', 'License_Number',
            'Expiry_date_of_License', 'Expected_Monthly_Income', 'Current_Monthly_Income',
            'Marital_Status', 'Preferred_Location', 'Aadhar_Number', 'Aadhar_Photo',
            'Driving_License', 'previous_employer', 'job_placement'
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
    
    return round(($filledFields / $totalFields) * 100);
}
?>
