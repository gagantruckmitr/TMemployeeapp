<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        getManagers();
        break;
    case 'POST':
        createManager();
        break;
    case 'PUT':
        updateManager();
        break;
    case 'DELETE':
        deleteManager();
        break;
    default:
        sendError('Method not allowed', 405);
}

function getManagers() {
    global $conn;
    
    $query = "SELECT 
        u.id,
        u.name,
        u.email,
        u.phone,
        u.created_at,
        COUNT(DISTINCT t.id) as team_size,
        COUNT(DISTINCT cl.id) as total_calls,
        ROUND(AVG(CASE WHEN cl.call_status = 'connected' THEN 100 ELSE 0 END), 1) as performance
    FROM users u
    LEFT JOIN users t ON t.manager_id = u.id AND t.role = 'telecaller'
    LEFT JOIN call_logs cl ON t.id = cl.telecaller_id
    WHERE u.role = 'manager'
    GROUP BY u.id
    ORDER BY u.created_at DESC";
    
    $result = $conn->query($query);
    $managers = [];
    
    while ($row = $result->fetch_assoc()) {
        $managers[] = $row;
    }
    
    sendSuccess($managers);
}

function createManager() {
    global $conn;
    
    $data = json_decode(file_get_contents('php://input'), true);
    validateRequired($data, ['name', 'email', 'phone', 'password']);
    
    $name = sanitizeInput($conn, $data['name']);
    $email = sanitizeInput($conn, $data['email']);
    $phone = sanitizeInput($conn, $data['phone']);
    $password = password_hash($data['password'], PASSWORD_DEFAULT);
    
    $query = "INSERT INTO users (name, email, phone, password, role, status) 
              VALUES (?, ?, ?, ?, 'manager', 'active')";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('ssss', $name, $email, $phone, $password);
    
    if ($stmt->execute()) {
        sendSuccess(['id' => $conn->insert_id], 'Manager created successfully');
    } else {
        sendError('Failed to create manager');
    }
}

function updateManager() {
    global $conn;
    
    $data = json_decode(file_get_contents('php://input'), true);
    validateRequired($data, ['id', 'name', 'email', 'phone']);
    
    $id = (int)$data['id'];
    $name = sanitizeInput($conn, $data['name']);
    $email = sanitizeInput($conn, $data['email']);
    $phone = sanitizeInput($conn, $data['phone']);
    
    $query = "UPDATE users SET name = ?, email = ?, phone = ? WHERE id = ? AND role = 'manager'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('sssi', $name, $email, $phone, $id);
    
    if ($stmt->execute()) {
        sendSuccess(null, 'Manager updated successfully');
    } else {
        sendError('Failed to update manager');
    }
}

function deleteManager() {
    global $conn;
    
    $id = (int)$_GET['id'];
    
    $query = "DELETE FROM users WHERE id = ? AND role = 'manager'";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $id);
    
    if ($stmt->execute()) {
        sendSuccess(null, 'Manager deleted successfully');
    } else {
        sendError('Failed to delete manager');
    }
}
