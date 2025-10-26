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
        u.id,
        u.name,
        u.email,
        u.phone,
        u.location,
        u.status,
        u.created_at,
        COUNT(DISTINCT cl.id) as total_calls,
        COUNT(DISTINCT CASE WHEN cl.call_status = 'connected' THEN cl.id END) as connected_calls,
        ROUND(COUNT(DISTINCT CASE WHEN cl.call_status = 'connected' THEN cl.id END) * 100.0 / NULLIF(COUNT(DISTINCT cl.id), 0), 1) as conversion_rate
    FROM users u
    LEFT JOIN call_logs cl ON u.id = cl.telecaller_id
    WHERE u.role = 'telecaller'
    GROUP BY u.id
    ORDER BY u.created_at DESC";
    
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
    
    $query = "INSERT INTO users (name, email, phone, password, role, location, status) 
              VALUES (?, ?, ?, ?, 'telecaller', ?, ?)";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('ssssss', $name, $email, $phone, $password, $location, $status);
    
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
    
    $query = "UPDATE users SET name = ?, email = ?, phone = ?, location = ?, status = ? WHERE id = ? AND role = 'telecaller'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('sssssi', $name, $email, $phone, $location, $status, $id);
    
    if ($stmt->execute()) {
        sendSuccess(null, 'Telecaller updated successfully');
    } else {
        sendError('Failed to update telecaller');
    }
}

function deleteTelecaller() {
    global $conn;
    
    $id = (int)$_GET['id'];
    
    $query = "DELETE FROM users WHERE id = ? AND role = 'telecaller'";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $id);
    
    if ($stmt->execute()) {
        sendSuccess(null, 'Telecaller deleted successfully');
    } else {
        sendError('Failed to delete telecaller');
    }
}
