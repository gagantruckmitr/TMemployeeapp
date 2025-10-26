<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    // Get POST data
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    if (!$data) {
        throw new Exception("Invalid JSON data");
    }
    
    $leadIds = $data['lead_ids'] ?? [];
    $telecallerId = (int)($data['telecaller_id'] ?? 0);
    
    // Validate input
    if (!is_array($leadIds) || empty($leadIds)) {
        throw new Exception("Invalid or empty lead IDs");
    }
    
    if ($telecallerId <= 0) {
        throw new Exception("Invalid telecaller ID");
    }
    
    // Verify telecaller exists
    $stmt = $conn->prepare("SELECT id, name FROM admins WHERE id = ? AND role = 'telecaller'");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    $telecaller = $result->fetch_assoc();
    
    if (!$telecaller) {
        throw new Exception("Telecaller not found");
    }
    
    // Update users table to assign leads
    $placeholders = implode(',', array_fill(0, count($leadIds), '?'));
    $query = "UPDATE users SET assigned_to = ?, Updated_at = NOW() WHERE id IN ($placeholders) AND role = 'driver'";
    
    $stmt = $conn->prepare($query);
    
    // Build bind parameters
    $types = 'i' . str_repeat('i', count($leadIds));
    $params = array_merge([$telecallerId], $leadIds);
    
    // Bind parameters dynamically
    $bindParams = [$types];
    foreach ($params as $key => $value) {
        $bindParams[] = &$params[$key];
    }
    call_user_func_array([$stmt, 'bind_param'], $bindParams);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to assign leads: " . $stmt->error);
    }
    
    $affectedRows = $stmt->affected_rows;
    
    if ($affectedRows === 0) {
        throw new Exception("No leads were updated. Please check if the lead IDs are valid.");
    }
    
    echo json_encode([
        'success' => true,
        'message' => "$affectedRows lead(s) assigned to {$telecaller['name']} successfully",
        'assigned_count' => $affectedRows,
        'telecaller_id' => $telecallerId,
        'telecaller_name' => $telecaller['name'],
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
    $conn->close();
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?>
