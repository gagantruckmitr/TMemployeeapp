<?php
/**
 * Test script to compare profile completion between two APIs
 * Usage: test_compare_profile_apis.php?user_id=123&job_id=TMJB00418
 */

header('Content-Type: application/json');
require_once 'config.php';

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$jobId = isset($_GET['job_id']) ? $_GET['job_id'] : '';

if ($userId === 0) {
    echo json_encode(['error' => 'Please provide user_id parameter']);
    exit;
}

// Test 1: Call profile_completion_api.php logic
$url1 = "https://truckmitr.com/truckmitr-app/api/profile_completion_api.php?action=get_profile_details&user_id=$userId";
$response1 = file_get_contents($url1);
$data1 = json_decode($response1, true);

$percentage1 = null;
if ($data1 && isset($data1['success']) && $data1['success']) {
    $percentage1 = $data1['data']['profile_completion']['percentage'] ?? null;
}

// Test 2: Call phase2_job_applicants_api.php if job_id provided
$percentage2 = null;
$applicantData = null;
if (!empty($jobId)) {
    $url2 = "https://truckmitr.com/truckmitr-app/api/phase2_job_applicants_api.php?job_id=$jobId";
    $response2 = file_get_contents($url2);
    $data2 = json_decode($response2, true);
    
    if ($data2 && isset($data2['data']['applicants'])) {
        // Find the applicant with matching user_id
        foreach ($data2['data']['applicants'] as $applicant) {
            if ($applicant['driverId'] == $userId) {
                $percentage2 = $applicant['profileCompletion'];
                $applicantData = $applicant;
                break;
            }
        }
    }
}

// Test 3: Use the shared helper function directly
require_once 'profile_completion_helper.php';
$percentage3 = calculateProfileCompletion($conn, $userId);

// Get user details for reference
$userQuery = "SELECT id, unique_id, name, role FROM users WHERE id = ?";
$stmt = $conn->prepare($userQuery);
$stmt->bind_param("i", $userId);
$stmt->execute();
$userResult = $stmt->get_result();
$user = $userResult->fetch_assoc();

// Output comparison
$result = [
    'user' => [
        'id' => $user['id'] ?? null,
        'unique_id' => $user['unique_id'] ?? null,
        'name' => $user['name'] ?? null,
        'role' => $user['role'] ?? null
    ],
    'test_1_profile_completion_api' => [
        'url' => $url1,
        'percentage' => $percentage1,
        'raw_response' => $data1
    ],
    'test_2_job_applicants_api' => [
        'url' => !empty($jobId) ? $url2 : 'N/A (no job_id provided)',
        'percentage' => $percentage2,
        'applicant_data' => $applicantData
    ],
    'test_3_helper_function_direct' => [
        'percentage' => $percentage3,
        'note' => 'Direct call to calculateProfileCompletion()'
    ],
    'comparison' => [
        'all_match' => ($percentage1 === $percentage2 && $percentage2 === $percentage3),
        'api1_vs_api2' => [
            'match' => $percentage1 === $percentage2,
            'difference' => $percentage2 !== null ? abs($percentage1 - $percentage2) : 'N/A'
        ],
        'api1_vs_helper' => [
            'match' => $percentage1 === $percentage3,
            'difference' => abs($percentage1 - $percentage3)
        ],
        'api2_vs_helper' => [
            'match' => $percentage2 === $percentage3,
            'difference' => $percentage2 !== null ? abs($percentage2 - $percentage3) : 'N/A'
        ]
    ]
];

echo json_encode($result, JSON_PRETTY_PRINT);
?>
