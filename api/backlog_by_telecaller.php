<?php
// Backlog API filtered by telecaller
// Returns only backlog leads assigned to the logged-in telecaller

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';

try {
    // Get Authorization header
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = $matches[1];
        }
    }
    
    if (!$token) {
        throw new Exception('Authorization token required');
    }
    
    // Get caller_id parameter (required)
    $callerId = $_GET['caller_id'] ?? null;
    
    if (!$callerId) {
        throw new Exception('caller_id parameter required');
    }
    
    // Fetch all pages from telehead backlog API
    $allLeads = [];
    $page = 1;
    $lastPage = 1;
    
    do {
        $url = 'https://truckmitr.com/api/telehead/backlog-leads?page=' . $page;
        
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: Bearer ' . $token
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode !== 200) {
            throw new Exception('Failed to fetch backlog from telehead API');
        }
        
        $backlogData = json_decode($response, true);
        
        if (!$backlogData || $backlogData['status'] !== true) {
            throw new Exception('Invalid response from telehead API');
        }
        
        // Add leads from this page
        $allLeads = array_merge($allLeads, $backlogData['data'] ?? []);
        
        // Get pagination info
        $lastPage = $backlogData['last_page'] ?? 1;
        $page++;
        
    } while ($page <= $lastPage);
    
    // Get database connection to check for completed callbacks
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get list of lead IDs that have been called AFTER their callback was scheduled
    // These should be removed from backlog
    $sql = "SELECT DISTINCT cl1.user_id
            FROM call_logs cl1
            WHERE cl1.caller_id = :caller_id
            AND cl1.user_id IS NOT NULL
            AND cl1.user_id > 0
            AND cl1.call_status IN ('callback', 'callback_later')
            AND EXISTS (
                SELECT 1 FROM call_logs cl2
                WHERE cl2.user_id = cl1.user_id
                AND cl2.caller_id = cl1.caller_id
                AND cl2.created_at > cl1.created_at
                AND cl2.feedback IS NOT NULL
                AND cl2.feedback != ''
            )";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['caller_id' => $callerId]);
    $completedCallbackIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
    $completedCallbackIds = array_map('intval', $completedCallbackIds);
    
    // Filter leads by assigned telecaller AND exclude completed callbacks
    $filteredLeads = [];
    
    foreach ($allLeads as $lead) {
        $assignedTo = $lead['assigned_to'] ?? null;
        $leadId = $lead['id'] ?? null;
        
        // Only include if assigned to this telecaller AND not a completed callback
        if ($assignedTo == $callerId && !in_array($leadId, $completedCallbackIds)) {
            $filteredLeads[] = $lead;
        }
    }
    
    // Return filtered data
    echo json_encode([
        'status' => true,
        'total_backlog' => count($filteredLeads),
        'filtered_by_telecaller' => (int)$callerId,
        'excluded_completed_callbacks' => count($completedCallbackIds),
        'data' => $filteredLeads
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => false,
        'message' => $e->getMessage()
    ]);
}
?>
