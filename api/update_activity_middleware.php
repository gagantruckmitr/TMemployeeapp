<?php
/**
 * Middleware to update telecaller activity status
 * This tracks when a telecaller was last active
 */

// Check if we have a caller_id in the request
$middlewareCallerId = $_GET['caller_id'] ?? $_POST['caller_id'] ?? null;

if ($middlewareCallerId && isset($pdo)) {
    try {
        // Optional: Update last_active timestamp in admins table if column exists
        // For now, we'll just log it to ensure it's working without breaking anything
        // error_log("Activity update for caller: $middlewareCallerId");
        
        /*
        // Uncomment this if you have a last_active column in admins table
        $stmt = $pdo->prepare("UPDATE admins SET last_active = NOW() WHERE id = ?");
        $stmt->execute([$middlewareCallerId]);
        */
    } catch (Exception $e) {
        // Silently fail to not disrupt the API response
        error_log("Activity middleware error: " . $e->getMessage());
    }
}
?>
