<?php
/**
 * Activity Update Middleware
 * Include this at the top of any API file to automatically update last_activity
 */

function updateTelecallerActivity($conn, $telecallerId) {
    if (!$telecallerId) return;
    
    try {
        // Check current status
        $stmt = $conn->prepare("SELECT current_status FROM telecaller_status WHERE telecaller_id = ?");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $currentStatus = $row['current_status'];
            
            // If offline, change to online (telecaller is active again)
            // If on break or on_call, keep that status but update activity
            if ($currentStatus === 'offline') {
                // Change to online since they're making API calls
                $stmt = $conn->prepare("
                    UPDATE telecaller_status 
                    SET current_status = 'online', 
                        last_activity = NOW(), 
                        updated_at = NOW() 
                    WHERE telecaller_id = ?
                ");
            } else {
                // Just update activity time
                $stmt = $conn->prepare("
                    UPDATE telecaller_status 
                    SET last_activity = NOW(), 
                        updated_at = NOW() 
                    WHERE telecaller_id = ?
                ");
            }
            $stmt->bind_param("i", $telecallerId);
            $stmt->execute();
        }
    } catch (Exception $e) {
        // Silently fail - don't break the main API call
        error_log("Activity update failed: " . $e->getMessage());
    }
}

// Auto-update activity if telecaller_id or caller_id is in the request
if (isset($_GET['telecaller_id'])) {
    updateTelecallerActivity($conn, intval($_GET['telecaller_id']));
} elseif (isset($_GET['caller_id'])) {
    updateTelecallerActivity($conn, intval($_GET['caller_id']));
} elseif (isset($_POST['telecaller_id'])) {
    updateTelecallerActivity($conn, intval($_POST['telecaller_id']));
} elseif (isset($_POST['caller_id'])) {
    updateTelecallerActivity($conn, intval($_POST['caller_id']));
}

// Also check JSON body
$input = json_decode(file_get_contents('php://input'), true);
if ($input) {
    if (isset($input['telecaller_id'])) {
        updateTelecallerActivity($conn, intval($input['telecaller_id']));
    } elseif (isset($input['caller_id'])) {
        updateTelecallerActivity($conn, intval($input['caller_id']));
    }
}
