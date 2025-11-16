<?php
/**
 * API to update user's tc_for (telecaller access levels)
 * Supports multiple values
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';
require_once 'tc_for_helper.php';

// Get request data
$data = json_decode(file_get_contents('php://input'), true);
$action = $_GET['action'] ?? $data['action'] ?? '';

switch ($action) {
    case 'get_user_access':
        getUserAccess($conn, $data);
        break;
    
    case 'update_user_access':
        updateUserAccess($conn, $data);
        break;
    
    case 'add_access':
        addAccess($conn, $data);
        break;
    
    case 'remove_access':
        removeAccess($conn, $data);
        break;
    
    default:
        echo json_encode([
            'success' => false,
            'error' => 'Invalid action'
        ]);
}

/**
 * Get user's current access levels
 */
function getUserAccess($conn, $data) {
    $userId = $data['user_id'] ?? null;
    
    if (!$userId) {
        echo json_encode(['success' => false, 'error' => 'User ID required']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT id, name, tc_for FROM admins WHERE id = ?");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        $accessLevels = getTcForArray($row['tc_for']);
        
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => $row['id'],
                'name' => $row['name'],
                'tc_for_raw' => $row['tc_for'],
                'access_levels' => $accessLevels
            ]
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => 'User not found']);
    }
    
    $stmt->close();
}

/**
 * Update user's access levels (replace all)
 */
function updateUserAccess($conn, $data) {
    $userId = $data['user_id'] ?? null;
    $accessLevels = $data['access_levels'] ?? [];
    
    if (!$userId) {
        echo json_encode(['success' => false, 'error' => 'User ID required']);
        return;
    }
    
    if (!is_array($accessLevels)) {
        echo json_encode(['success' => false, 'error' => 'access_levels must be an array']);
        return;
    }
    
    // Valid access levels
    $validLevels = ['driver', 'transporter', 'social_media', 'toll_free', 'jobs'];
    
    // Filter to only valid levels
    $accessLevels = array_filter($accessLevels, function($level) use ($validLevels) {
        return in_array($level, $validLevels);
    });
    
    $tcForJson = tcForArrayToJson($accessLevels);
    
    $stmt = $conn->prepare("UPDATE admins SET tc_for = ? WHERE id = ?");
    $stmt->bind_param('si', $tcForJson, $userId);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Access levels updated',
            'access_levels' => $accessLevels,
            'tc_for_json' => $tcForJson
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Failed to update']);
    }
    
    $stmt->close();
}

/**
 * Add a single access level to user
 */
function addAccess($conn, $data) {
    $userId = $data['user_id'] ?? null;
    $newAccess = $data['access_level'] ?? null;
    
    if (!$userId || !$newAccess) {
        echo json_encode(['success' => false, 'error' => 'User ID and access_level required']);
        return;
    }
    
    // Get current tc_for
    $stmt = $conn->prepare("SELECT tc_for FROM admins WHERE id = ?");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        $currentTcFor = $row['tc_for'];
        $newTcFor = addTcForValue($currentTcFor, $newAccess);
        
        // Update database
        $updateStmt = $conn->prepare("UPDATE admins SET tc_for = ? WHERE id = ?");
        $updateStmt->bind_param('si', $newTcFor, $userId);
        
        if ($updateStmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => "Added access: $newAccess",
                'access_levels' => getTcForArray($newTcFor)
            ]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to update']);
        }
        
        $updateStmt->close();
    } else {
        echo json_encode(['success' => false, 'error' => 'User not found']);
    }
    
    $stmt->close();
}

/**
 * Remove a single access level from user
 */
function removeAccess($conn, $data) {
    $userId = $data['user_id'] ?? null;
    $accessToRemove = $data['access_level'] ?? null;
    
    if (!$userId || !$accessToRemove) {
        echo json_encode(['success' => false, 'error' => 'User ID and access_level required']);
        return;
    }
    
    // Get current tc_for
    $stmt = $conn->prepare("SELECT tc_for FROM admins WHERE id = ?");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        $currentTcFor = $row['tc_for'];
        $newTcFor = removeTcForValue($currentTcFor, $accessToRemove);
        
        // Update database
        $updateStmt = $conn->prepare("UPDATE admins SET tc_for = ? WHERE id = ?");
        $updateStmt->bind_param('si', $newTcFor, $userId);
        
        if ($updateStmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => "Removed access: $accessToRemove",
                'access_levels' => getTcForArray($newTcFor)
            ]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to update']);
        }
        
        $updateStmt->close();
    } else {
        echo json_encode(['success' => false, 'error' => 'User not found']);
    }
    
    $stmt->close();
}
