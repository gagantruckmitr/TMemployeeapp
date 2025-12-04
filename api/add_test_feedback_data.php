<?php
// Add test feedback data to verify the analytics is working
require_once 'config.php';

$callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 3;

echo "<h2>Adding Test Feedback Data for Caller ID: $callerId</h2>";

// Add some test calls with interested feedback
$interestedFeedbacks = [
    'Driver is interested in the job',
    'Very interested, will join soon',
    'Interested and agreed to terms',
    'Showing interest',
];

// Add some test calls with not interested feedback
$notInterestedFeedbacks = [
    'Not interested in this job',
    'Driver said not_interested',
    'Not Interested - has another job',
    'NotInterested',
];

echo "<h3>Adding Interested Calls...</h3>";
foreach ($interestedFeedbacks as $feedback) {
    $stmt = $pdo->prepare("
        INSERT INTO call_logs 
        (caller_id, driver_name, call_status, feedback, created_at, updated_at)
        VALUES (?, 'Test Driver', 'connected', ?, NOW(), NOW())
    ");
    $stmt->execute([$callerId, $feedback]);
    echo "✓ Added: $feedback<br>";
}

echo "<h3>Adding Not Interested Calls...</h3>";
foreach ($notInterestedFeedbacks as $feedback) {
    $stmt = $pdo->prepare("
        INSERT INTO call_logs 
        (caller_id, driver_name, call_status, feedback, created_at, updated_at)
        VALUES (?, 'Test Driver', 'connected', ?, NOW(), NOW())
    ");
    $stmt->execute([$callerId, $feedback]);
    echo "✓ Added: $feedback<br>";
}

// Add one with not_interested status
$stmt = $pdo->prepare("
    INSERT INTO call_logs 
    (caller_id, driver_name, call_status, feedback, created_at, updated_at)
    VALUES (?, 'Test Driver', 'not_interested', 'Driver declined', NOW(), NOW())
");
$stmt->execute([$callerId]);
echo "✓ Added call with status 'not_interested'<br>";

echo "<h3>✅ Test data added successfully!</h3>";
echo "<p>Now check your analytics page - you should see:</p>";
echo "<ul>";
echo "<li>Interested: 4 calls</li>";
echo "<li>Not Interested: 5 calls</li>";
echo "</ul>";
echo "<p><a href='test_analytics_feedback.php'>View Feedback Data</a></p>";
?>
