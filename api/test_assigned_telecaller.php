<?php
/**
 * Test Script: Verify Assigned Telecaller Logic
 * 
 * This script compares:
 * 1. callback_requests.assigned_to (who handles the callback)
 * 2. users.assigned_to (user's permanent assigned telecaller)
 * 
 * Usage: 
 * - Update $testUniqueId with a real unique_id
 * - Run: php api/test_assigned_telecaller.php
 * - Or access via browser
 */

require_once 'config.php';

// TEST CONFIGURATION
$testUniqueId = 'TM000001'; // Change this to test a specific user

echo "<h1>Assigned Telecaller Test</h1>\n";
echo "<p>Testing unique_id: <strong>$testUniqueId</strong></p>\n";
echo "<hr>\n";

// 1. Get user info
$userSql = "SELECT id, unique_id, name, mobile, role, assigned_to FROM users WHERE unique_id = ? LIMIT 1";
$stmt = $conn->prepare($userSql);
$stmt->bind_param("s", $testUniqueId);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if (!$user) {
    echo "<p style='color: red;'>❌ User not found with unique_id: $testUniqueId</p>\n";
    exit;
}

echo "<h2>User Information</h2>\n";
echo "<table border='1' cellpadding='5'>\n";
echo "<tr><th>Field</th><th>Value</th></tr>\n";
echo "<tr><td>ID</td><td>{$user['id']}</td></tr>\n";
echo "<tr><td>Unique ID</td><td>{$user['unique_id']}</td></tr>\n";
echo "<tr><td>Name</td><td>{$user['name']}</td></tr>\n";
echo "<tr><td>Role</td><td>{$user['role']}</td></tr>\n";
echo "<tr><td><strong>users.assigned_to</strong></td><td><strong>" . ($user['assigned_to'] ?? 'NULL') . "</strong></td></tr>\n";
echo "</table>\n";

// 2. Get callback request info (if exists)
$cbSql = "SELECT id, assigned_to, status, contact_reason FROM callback_requests WHERE unique_id = ? LIMIT 1";
$cbStmt = $conn->prepare($cbSql);
$cbStmt->bind_param("s", $testUniqueId);
$cbStmt->execute();
$cbRequest = $cbStmt->get_result()->fetch_assoc();

echo "<h2>Callback Request Information</h2>\n";
if ($cbRequest) {
    echo "<table border='1' cellpadding='5'>\n";
    echo "<tr><th>Field</th><th>Value</th></tr>\n";
    echo "<tr><td>Callback Request ID</td><td>{$cbRequest['id']}</td></tr>\n";
    echo "<tr><td>Status</td><td>{$cbRequest['status']}</td></tr>\n";
    echo "<tr><td>Reason</td><td>{$cbRequest['contact_reason']}</td></tr>\n";
    echo "<tr><td><strong>callback_requests.assigned_to</strong></td><td><strong>" . ($cbRequest['assigned_to'] ?? 'NULL') . "</strong></td></tr>\n";
    echo "</table>\n";
} else {
    echo "<p style='color: orange;'>⚠️ No callback request found for this user</p>\n";
}

echo "<hr>\n";
echo "<h2>Telecaller Lookup Results</h2>\n";

// 3. Get telecaller from users.assigned_to (CORRECT - what we should use)
$userAssignedTo = $user['assigned_to'] ?? null;
$userTelecaller = null;
if ($userAssignedTo) {
    $tcSql = "SELECT id, name, role FROM admins WHERE id = ? LIMIT 1";
    $tcStmt = $conn->prepare($tcSql);
    $tcStmt->bind_param("i", $userAssignedTo);
    $tcStmt->execute();
    $userTelecaller = $tcStmt->get_result()->fetch_assoc();
}

echo "<h3>✅ From users.assigned_to (CORRECT - User's Permanent Telecaller)</h3>\n";
if ($userTelecaller) {
    echo "<div style='background: #d4edda; padding: 15px; border: 2px solid #28a745; border-radius: 5px;'>\n";
    echo "<p><strong>Telecaller Name:</strong> <span style='font-size: 18px; color: green;'>{$userTelecaller['name']}</span></p>\n";
    echo "<p><strong>Telecaller ID:</strong> {$userTelecaller['id']}</p>\n";
    echo "<p><strong>Telecaller Role:</strong> {$userTelecaller['role']}</p>\n";
    echo "<p style='color: green;'><strong>✅ This is the CORRECT telecaller to display</strong></p>\n";
    echo "</div>\n";
} else {
    echo "<p style='color: orange;'>⚠️ No telecaller assigned in users.assigned_to</p>\n";
}

// 4. Get telecaller from callback_requests.assigned_to (WRONG - callback handler, not user's telecaller)
$cbAssignedTo = $cbRequest['assigned_to'] ?? null;
$cbTelecaller = null;
if ($cbAssignedTo) {
    $tcSql = "SELECT id, name, role FROM admins WHERE id = ? LIMIT 1";
    $tcStmt = $conn->prepare($tcSql);
    $tcStmt->bind_param("i", $cbAssignedTo);
    $tcStmt->execute();
    $cbTelecaller = $tcStmt->get_result()->fetch_assoc();
}

echo "<h3>❌ From callback_requests.assigned_to (WRONG - Callback Handler)</h3>\n";
if ($cbTelecaller) {
    echo "<div style='background: #f8d7da; padding: 15px; border: 2px solid #dc3545; border-radius: 5px;'>\n";
    echo "<p><strong>Telecaller Name:</strong> <span style='font-size: 18px; color: red;'>{$cbTelecaller['name']}</span></p>\n";
    echo "<p><strong>Telecaller ID:</strong> {$cbTelecaller['id']}</p>\n";
    echo "<p><strong>Telecaller Role:</strong> {$cbTelecaller['role']}</p>\n";
    echo "<p style='color: red;'><strong>❌ This is who handles the callback, NOT the user's assigned telecaller</strong></p>\n";
    echo "</div>\n";
} else {
    echo "<p style='color: gray;'>No callback handler assigned</p>\n";
}

echo "<hr>\n";
echo "<h2>Summary</h2>\n";

if ($userTelecaller && $cbTelecaller) {
    if ($userTelecaller['id'] === $cbTelecaller['id']) {
        echo "<p style='color: green;'>✅ Both fields point to the same telecaller: <strong>{$userTelecaller['name']}</strong></p>\n";
    } else {
        echo "<div style='background: #fff3cd; padding: 15px; border: 2px solid #ffc107; border-radius: 5px;'>\n";
        echo "<p style='color: #856404;'><strong>⚠️ DIFFERENT TELECALLERS:</strong></p>\n";
        echo "<ul>\n";
        echo "<li><strong>User's Assigned Telecaller (users.assigned_to):</strong> {$userTelecaller['name']} (ID: {$userTelecaller['id']})</li>\n";
        echo "<li><strong>Callback Handler (callback_requests.assigned_to):</strong> {$cbTelecaller['name']} (ID: {$cbTelecaller['id']})</li>\n";
        echo "</ul>\n";
        echo "<p><strong>✅ CORRECT CHOICE:</strong> Use <span style='color: green;'>{$userTelecaller['name']}</span> from users.assigned_to</p>\n";
        echo "</div>\n";
    }
} elseif ($userTelecaller) {
    echo "<p style='color: green;'>✅ User's assigned telecaller: <strong>{$userTelecaller['name']}</strong></p>\n";
} else {
    echo "<p style='color: red;'>❌ No telecaller assigned to this user</p>\n";
}

echo "<hr>\n";
echo "<h2>Recommendation</h2>\n";
echo "<div style='background: #d1ecf1; padding: 15px; border: 2px solid #0c5460; border-radius: 5px;'>\n";
echo "<p><strong>Always use:</strong> <code>users.assigned_to</code></p>\n";
echo "<p><strong>Never use:</strong> <code>callback_requests.assigned_to</code> (this is for callback routing, not user assignment)</p>\n";
echo "<p><strong>This matches:</strong> search_users_api.php logic</p>\n";
echo "</div>\n";

echo "<p><em>Test completed at " . date('Y-m-d H:i:s') . "</em></p>\n";
?>
