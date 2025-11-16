<?php
// Reset transporter calls for testing
// WARNING: This will delete call logs for transporters
require_once 'config.php';

$confirm = $_GET['confirm'] ?? '';

if ($confirm !== 'yes') {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Reset Transporter Calls</title>
        <style>
            body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
            .warning { background: #fff3cd; border: 2px solid #ffc107; padding: 20px; border-radius: 5px; }
            .danger { background: #f8d7da; border: 2px solid #dc3545; padding: 20px; border-radius: 5px; margin: 20px 0; }
            button { padding: 15px 30px; font-size: 16px; cursor: pointer; margin: 10px; }
            .btn-danger { background: #dc3545; color: white; border: none; }
            .btn-secondary { background: #6c757d; color: white; border: none; }
        </style>
    </head>
    <body>
        <h1>⚠️ Reset Transporter Call Logs</h1>
        
        <div class="warning">
            <h3>What this does:</h3>
            <ul>
                <li>Deletes all call_logs entries for transporters</li>
                <li>Makes all transporters available for calling again</li>
                <li>Useful for testing the round-robin assignment</li>
            </ul>
        </div>
        
        <div class="danger">
            <h3>⚠️ WARNING:</h3>
            <p><strong>This action cannot be undone!</strong></p>
            <p>Only use this in development/testing environments.</p>
            <p>DO NOT use in production unless you know what you're doing.</p>
        </div>
        
        <h3>Are you sure you want to proceed?</h3>
        <button class="btn-danger" onclick="location.href='?confirm=yes'">
            Yes, Reset Call Logs
        </button>
        <button class="btn-secondary" onclick="history.back()">
            Cancel
        </button>
    </body>
    </html>
    <?php
    exit;
}

// Confirmed - proceed with reset
try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Count before deletion
    $beforeCount = $pdo->query("
        SELECT COUNT(*) 
        FROM call_logs 
        WHERE user_id IN (SELECT id FROM users WHERE role = 'transporter')
    ")->fetchColumn();
    
    // Delete call logs for transporters
    $stmt = $pdo->prepare("
        DELETE FROM call_logs 
        WHERE user_id IN (SELECT id FROM users WHERE role = 'transporter')
    ");
    $stmt->execute();
    
    $deletedCount = $stmt->rowCount();
    
    echo "<!DOCTYPE html>
    <html>
    <head>
        <title>Reset Complete</title>
        <style>
            body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
            .success { background: #d4edda; border: 2px solid #28a745; padding: 20px; border-radius: 5px; }
            button { padding: 15px 30px; font-size: 16px; cursor: pointer; margin: 10px; background: #007bff; color: white; border: none; }
        </style>
    </head>
    <body>
        <h1>✅ Reset Complete</h1>
        <div class='success'>
            <p><strong>Call logs deleted:</strong> $deletedCount records</p>
            <p><strong>Transporters now available:</strong> All uncalled transporters are now available for assignment</p>
        </div>
        <button onclick=\"location.href='check_transporters.php'\">Check Status</button>
        <button onclick=\"location.href='test_transporter_assignment.html'\">Test Assignment</button>
    </body>
    </html>";
    
} catch (Exception $e) {
    echo "<!DOCTYPE html>
    <html>
    <head><title>Error</title></head>
    <body>
        <h1>❌ Error</h1>
        <p>" . htmlspecialchars($e->getMessage()) . "</p>
        <button onclick='history.back()'>Go Back</button>
    </body>
    </html>";
}
?>
