<?php
/**
 * Webhook API
 * Handles GET and POST operations for web_hook table
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            handleGet($conn);
            break;
        case 'POST':
            handlePost($conn);
            break;
        default:
            sendError('Method not allowed', 405);
    }
} catch (Exception $e) {
    sendError($e->getMessage(), 500);
}

/**
 * Handle GET requests
 * Supports:
 * - Get all webhooks: ?action=list
 * - Get single webhook: ?action=get&id=1
 * - Get by filters: ?action=list&status=active&limit=10
 */
function handleGet($conn) {
    $action = $_GET['action'] ?? 'list';
    
    switch ($action) {
        case 'get':
            getSingleWebhook($conn);
            break;
        case 'list':
        default:
            getWebhooks($conn);
            break;
    }
}

/**
 * Get single webhook by ID
 */
function getSingleWebhook($conn) {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        sendError('Webhook ID is required');
    }
    
    $query = "SELECT * FROM web_hook WHERE id = ?";
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        sendError('Failed to prepare statement: ' . $conn->error);
    }
    
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendError('Webhook not found', 404);
    }
    
    $webhook = $result->fetch_assoc();
    
    sendSuccess($webhook, 'Webhook retrieved successfully');
}

/**
 * Get list of webhooks with optional filters
 */
function getWebhooks($conn) {
    // Get filter parameters
    $client = $_GET['client'] ?? null;
    $call_type = $_GET['call_type'] ?? null;
    $caller_id = $_GET['caller_id'] ?? null;
    $disposition = $_GET['disposition'] ?? null;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    // Build query
    $query = "SELECT * FROM web_hook WHERE 1=1";
    $params = [];
    $types = '';
    
    // Add filters
    if ($client) {
        $query .= " AND client = ?";
        $params[] = $client;
        $types .= 's';
    }
    
    if ($call_type) {
        $query .= " AND call_type = ?";
        $params[] = $call_type;
        $types .= 's';
    }
    
    if ($caller_id) {
        $query .= " AND caller_id = ?";
        $params[] = $caller_id;
        $types .= 's';
    }
    
    if ($disposition) {
        $query .= " AND disposition = ?";
        $params[] = $disposition;
        $types .= 's';
    }
    
    // Add ordering and pagination
    $query .= " ORDER BY created_at DESC LIMIT ? OFFSET ?";
    $params[] = $limit;
    $params[] = $offset;
    $types .= 'ii';
    
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        sendError('Failed to prepare statement: ' . $conn->error);
    }
    
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $webhooks = [];
    while ($row = $result->fetch_assoc()) {
        $webhooks[] = $row;
    }
    
    // Get total count
    $countQuery = "SELECT COUNT(*) as total FROM web_hook WHERE 1=1";
    $countParams = [];
    $countTypes = '';
    
    if ($client) {
        $countQuery .= " AND client = ?";
        $countParams[] = $client;
        $countTypes .= 's';
    }
    
    if ($call_type) {
        $countQuery .= " AND call_type = ?";
        $countParams[] = $call_type;
        $countTypes .= 's';
    }
    
    if ($caller_id) {
        $countQuery .= " AND caller_id = ?";
        $countParams[] = $caller_id;
        $countTypes .= 's';
    }
    
    if ($disposition) {
        $countQuery .= " AND disposition = ?";
        $countParams[] = $disposition;
        $countTypes .= 's';
    }
    
    $countStmt = $conn->prepare($countQuery);
    if (!empty($countParams)) {
        $countStmt->bind_param($countTypes, ...$countParams);
    }
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $total = $countResult->fetch_assoc()['total'];
    
    sendSuccess([
        'webhooks' => $webhooks,
        'count' => count($webhooks),
        'total' => (int)$total,
        'limit' => $limit,
        'offset' => $offset
    ], 'Webhooks retrieved successfully');
}

/**
 * Handle POST requests
 * Creates a new webhook entry
 */
function handlePost($conn) {
    // Get POST data
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendError('Invalid JSON data');
    }
    
    // Extract fields based on actual web_hook table structure
    $client = $input['client'] ?? null;
    $call_type = $input['call_type'] ?? null;
    $Linkedid = $input['Linkedid'] ?? null;
    $extension_no = $input['extension_no'] ?? null;
    $did = $input['did'] ?? null;
    $caller_id = $input['caller_id'] ?? null;
    $ACD = $input['ACD'] ?? null;
    $recfile = $input['recfile'] ?? null;
    $exten_ring_time = $input['exten_ring_time'] ?? null;
    $exten_ans_time = $input['exten_ans_time'] ?? null;
    $durn = $input['durn'] ?? null;
    $billsec = $input['billsec'] ?? null;
    $disposition = $input['disposition'] ?? null;
    $action = $input['action'] ?? null;
    $start_time = $input['start_time'] ?? null;
    $acd_durn = $input['acd_durn'] ?? null;
    $acd_time = $input['acd_time'] ?? null;
    $end_time = $input['end_time'] ?? null;
    $dtmf = $input['dtmf'] ?? null;
    $agent_disconnect = $input['agent_disconnect'] ?? 0;
    $transfer = $input['transfer'] ?? 0;
    $feedback = $input['feedback'] ?? null;
    $conf = $input['conf'] ?? 0;
    $endcall = $input['endcall'] ?? 0;
    
    // Prepare insert query with all columns
    $query = "INSERT INTO web_hook (
        client,
        call_type,
        Linkedid,
        extension_no,
        did,
        caller_id,
        ACD,
        recfile,
        exten_ring_time,
        exten_ans_time,
        durn,
        billsec,
        disposition,
        action,
        start_time,
        acd_durn,
        acd_time,
        end_time,
        dtmf,
        agent_disconnect,
        transfer,
        feedback,
        conf,
        endcall,
        created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
    
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        sendError('Failed to prepare statement: ' . $conn->error);
    }
    
    // Type string: 24 parameters (s=string, i=integer)
    // 1-7: client, call_type, Linkedid, extension_no, did, caller_id, ACD (7 strings)
    // 8: recfile (1 string - text/URL)
    // 9-10: exten_ring_time, exten_ans_time (2 strings - datetime)
    // 11-12: durn, billsec (2 integers)
    // 13-14: disposition, action (2 strings)
    // 15: start_time (1 string - datetime)
    // 16: acd_durn (1 integer)
    // 17: acd_time (1 string)
    // 18: end_time (1 string - datetime)
    // 19: dtmf (1 string)
    // 20-21: agent_disconnect, transfer (2 integers)
    // 22: feedback (1 string - text)
    // 23-24: conf, endcall (2 integers)
    $stmt->bind_param(
        'ssssssssssiissssississii',
        $client,
        $call_type,
        $Linkedid,
        $extension_no,
        $did,
        $caller_id,
        $ACD,
        $recfile,
        $exten_ring_time,
        $exten_ans_time,
        $durn,
        $billsec,
        $disposition,
        $action,
        $start_time,
        $acd_durn,
        $acd_time,
        $end_time,
        $dtmf,
        $agent_disconnect,
        $transfer,
        $feedback,
        $conf,
        $endcall
    );
    
    if ($stmt->execute()) {
        $webhookId = $conn->insert_id;
        
        // Fetch the created webhook
        $selectStmt = $conn->prepare("SELECT * FROM web_hook WHERE id = ?");
        $selectStmt->bind_param('i', $webhookId);
        $selectStmt->execute();
        $result = $selectStmt->get_result();
        $webhook = $result->fetch_assoc();
        
        sendSuccess($webhook, 'Webhook created successfully');
    } else {
        sendError('Failed to create webhook: ' . $stmt->error);
    }
}

$conn->close();
?>
