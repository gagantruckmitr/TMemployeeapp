<?php
/**
 * Activity Update Middleware for PDO
 * Include this at the top of any API file using PDO to automatically update last_activity
 */

function updateTelecallerActivityPDO($pdo, $telecallerId) {
    if (!$telecallerId) return;
    
    try {
        $stmt = $pdo->prepare("
            UPDATE telecaller_status 
            SET last_activity = NOW(), updated_at = NOW() 
            WHERE telecaller_id = ? AND current_status = 'online'
        ");
        $stmt->execute([$telecallerId]);
    } catch (Exception $e) {
        // Silently fail - don't break the main API call
        error_log("Activity update failed: " . $e->getMessage());
    }
}

// Auto-update activity if telecaller_id or caller_id is in the request
if (isset($_GET['telecaller_id'])) {
    updateTelecallerActivityPDO($pdo, intval($_GET['telecaller_id']));
} elseif (isset($_GET['caller_id'])) {
    updateTelecallerActivityPDO($pdo, intval($_GET['caller_id']));
} elseif (isset($_POST['telecaller_id'])) {
    updateTelecallerActivityPDO($pdo, intval($_POST['telecaller_id']));
} elseif (isset($_POST['caller_id'])) {
    updateTelecallerActivityPDO($pdo, intval($_POST['caller_id']));
}

// Also check JSON body
$input = json_decode(file_get_contents('php://input'), true);
if ($input) {
    if (isset($input['telecaller_id'])) {
        updateTelecallerActivityPDO($pdo, intval($input['telecaller_id']));
    } elseif (isset($input['caller_id'])) {
        updateTelecallerActivityPDO($pdo, intval($input['caller_id']));
    }
}
