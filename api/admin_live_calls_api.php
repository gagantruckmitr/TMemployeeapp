<?php
require_once 'config.php';

$query = "SELECT 
    cl.id,
    cl.call_time,
    cl.call_status,
    cl.duration,
    u.name as telecaller_name,
    d.name as driver_name,
    d.phone
FROM call_logs cl
JOIN users u ON cl.telecaller_id = u.id
JOIN drivers d ON cl.driver_id = d.id
WHERE cl.call_status = 'in_progress' OR cl.call_time >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
ORDER BY cl.call_time DESC";

$result = $conn->query($query);
$calls = [];

while ($row = $result->fetch_assoc()) {
    $calls[] = $row;
}

sendSuccess($calls);
