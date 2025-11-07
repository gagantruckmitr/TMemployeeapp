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
    global $pdo;
    
    try {
        $query = "SELECT 
            a.id,
            a.name,
            a.email,
            a.mobile as phone,
            '' as location,
            'active' as status,
            COALESCE(a.telecaller_type, 'driver') as telecaller_type,
            COALESCE(a.calling_level, 1) as calling_level,
            a.created_at,
            COUNT(DISTINCT cl.id) as total_calls,
            COUNT(DISTINCT CASE WHEN cl.call_status = 'connected' THEN cl.id END) as connected_calls,
            ROUND(COUNT(DISTINCT CASE WHEN cl.call_status = 'connected' THEN cl.id END) * 100.0 / NULLIF(COUNT(DISTINCT cl.id), 0), 1) as conversion_rate
        FROM admins a
        LEFT JOIN call_logs cl ON a.id = cl.caller_id
        WHERE a.role = 'telecaller'
        GROUP BY a.id, a.name, a.email, a.mobile, a.telecaller_type, a.calling_level, a.created_at
        ORDER BY a.created_at DESC";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute();
        $telecallers = $stmt->fetchAll();
        
        // If no telecallers found, return empty array with success
        sendSuccess($telecallers);
        
    } catch(Exception $e) {
        sendError('Failed to fetch telecallers: ' . $e->getMessage());
    }
}

function createTelecaller() {
    global $pdo;
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        validateRequired($data, ['name', 'email', 'phone', 'password']);
        
        $name = trim($data['name']);
        $email = trim($data['email']);
        $phone = trim($data['phone']);
        $password = password_hash($data['password'], PASSWORD_DEFAULT);
        $telecaller_type = $data['telecaller_type'] ?? 'driver';
        $calling_level = (int)($data['calling_level'] ?? 1);
        
        $query = "INSERT INTO admins (name, email, mobile, password, role, telecaller_type, calling_level, created_at) 
                  VALUES (?, ?, ?, ?, 'telecaller', ?, ?, NOW())";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute([$name, $email, $phone, $password, $telecaller_type, $calling_level]);
        
        sendSuccess(['id' => $pdo->lastInsertId()], 'Telecaller created successfully');
        
    } catch(Exception $e) {
        sendError('Failed to create telecaller: ' . $e->getMessage());
    }
}

function updateTelecaller() {
    global $pdo;
    
    try {
        $data = json_decode(file_get_contents('php://input'), true);
        validateRequired($data, ['id', 'name', 'email', 'phone']);
        
        $id = (int)$data['id'];
        $name = trim($data['name']);
        $email = trim($data['email']);
        $phone = trim($data['phone']);
        $telecaller_type = $data['telecaller_type'] ?? 'driver';
        $calling_level = (int)($data['calling_level'] ?? 1);
        
        $query = "UPDATE admins SET name = ?, email = ?, mobile = ?, telecaller_type = ?, calling_level = ?, updated_at = NOW() 
                  WHERE id = ? AND role = 'telecaller'";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute([$name, $email, $phone, $telecaller_type, $calling_level, $id]);
        
        if ($stmt->rowCount() > 0) {
            sendSuccess(null, 'Telecaller updated successfully');
        } else {
            sendError('Telecaller not found or no changes made');
        }
        
    } catch(Exception $e) {
        sendError('Failed to update telecaller: ' . $e->getMessage());
    }
}

function deleteTelecaller() {
    global $pdo;
    
    try {
        $id = (int)$_GET['id'];
        
        if (!$id) {
            sendError('Invalid telecaller ID');
            return;
        }
        
        $query = "DELETE FROM admins WHERE id = ? AND role = 'telecaller'";
        $stmt = $pdo->prepare($query);
        $stmt->execute([$id]);
        
        if ($stmt->rowCount() > 0) {
            sendSuccess(null, 'Telecaller deleted successfully');
        } else {
            sendError('Telecaller not found');
        }
        
    } catch(Exception $e) {
        sendError('Failed to delete telecaller: ' . $e->getMessage());
    }
}
