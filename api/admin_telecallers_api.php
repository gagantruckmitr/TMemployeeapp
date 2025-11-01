<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        getTelecallers();
        break;
    case 'POST':
        createTelecaller();
        break;
    case 'PUT':
        updateTelecaller();
        break;
    case 'DELETE':
        deleteTelecaller();
        break;
    default:
        sendError('Method not allowed', 405);
}

function getTelecallers() {
    global $conn;
    
    $query = "SELECT 
        a.id,
        a.name,
        a.email,
        a.mobile as phone,
        '' as location,
        'active' as status,
        a.telecaller_type,
        a.calling_level,
        a.created_at,
        COUNT(DISTINCT cl.id) as total_calls,
        COUNT(DISTINCT CASE WHEN cl.call_status = 'connected' THEN cl.id END) as connected_calls,
        ROUND(COUNT(DISTINCT CASE WHEN cl.call_status = 'connected' THEN cl.id END) * 100.0 / NULLIF(COUNT(DISTINCT cl.id), 0), 1) as conversion_rate
    FROM admins a
    LEFT JOIN call_logs cl ON a.id = cl.telecaller_id
    WHERE a.role = 'telecaller'
    GROUP BY a.id
    ORDER BY a.created_at DESC";
    
    $result = $conn->query($query);
    $telecallers = [];
    
    while ($row = $result->fetch_assoc()) {
        $telecallers[] = $row;
    }
    
    sendSuccess($telecallers);
}

function createTelecaller() {
    global $conn;
    
    $data = json_decode(file_get_contents('php://input'), true);
    validateRequired($data, ['name', 'email', 'phone', 'password']);
    
    $name = sanitizeInput($conn, $data['name']);
    $email = sanitizeInput($conn, $data['email']);
    $phone = sanitizeInput($conn, $data['phone']);
    $password = password_hash($data['password'], PASSWORD_DEFAULT);
    $location = sanitizeInput($conn, $data['location'] ?? '');
    $status = sanitizeInput($conn, $data['status'] ?? 'active');
    $telecaller_type = sanitizeInput($conn, $data['telecaller_type'] ?? 'driver');
    $calling_level = (int)($data['calling_level'] ?? 1);
    
    $query = "INSERT INTO admins (name, email, mobile, password, role, telecaller_type, calling_level) 
              VALUES (?, ?, ?, ?, 'telecaller', ?, ?)";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('sssssi', $name, $email, $phone, $password, $telecaller_type, $calling_level);
    
    if ($stmt->execute()) {
        sendSuccess(['id' => $conn->insert_id], 'Telecaller created successfully');
    } else {
        sendError('Failed to create telecaller');
    }
}

function updateTelecaller() {
    global $conn;
    
    $data = json_decode(file_get_contents('php://input'), true);
    validateRequired($data, ['id', 'name', 'email', 'phone']);
    
    $id = (int)$data['id'];
    $name = sanitizeInput($conn, $data['name']);
    $email = sanitizeInput($conn, $data['email']);
    $phone = sanitizeInput($conn, $data['phone']);
    $location = sanitizeInput($conn, $data['location'] ?? '');
    $status = sanitizeInput($conn, $data['status'] ?? 'active');
    $telecaller_type = sanitizeInput($conn, $data['telecaller_type'] ?? 'driver');
    $calling_level = (int)($data['calling_level'] ?? 1);
    
    $query = "UPDATE admins SET name = ?, email = ?, mobile = ?, telecaller_type = ?, calling_level = ? WHERE id = ? AND role = 'telecaller'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('sssii', $name, $email, $phone, $telecaller_type, $calling_level, $id);
    
    if ($stmt->execute()) {
        sendSuccess(null, 'Telecaller updated successfully');
    } else {
        sendError('Failed to update telecaller');
    }
}

function deleteTelecaller() {
    global $conn;
    
    $id = (int)$_GET['id'];
    
    $query = "DELETE FROM admins WHERE id = ? AND role = 'telecaller'";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $id);
    
    if ($stmt->execute()) {
        sendSuccess(null, 'Telecaller deleted successfully');
    } else {
        sendError('Failed to delete telecaller');
    }
}
