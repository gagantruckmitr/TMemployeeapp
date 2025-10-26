<?php
require_once 'config.php';

// Revenue calculation (mock data - replace with actual logic)
$revenue = [
    'total' => 125000,
    'growth' => 15.5
];

// Conversion rate
$conversionQuery = "SELECT 
    COUNT(*) as total_calls,
    COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected,
    ROUND(COUNT(CASE WHEN call_status = 'connected' THEN 1 END) * 100.0 / COUNT(*), 1) as rate
FROM call_logs
WHERE call_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)";

$conversionResult = $conn->query($conversionQuery);
$conversion = $conversionResult->fetch_assoc();

// Average duration
$durationQuery = "SELECT 
    AVG(CAST(SUBSTRING_INDEX(duration, 's', 1) AS UNSIGNED)) as avg_seconds
FROM call_logs
WHERE duration IS NOT NULL AND call_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)";

$durationResult = $conn->query($durationQuery);
$durationRow = $durationResult->fetch_assoc();
$avgDuration = round($durationRow['avg_seconds'] / 60) . 'm';

// Trends (last 30 days)
$trendsQuery = "SELECT 
    DATE(call_time) as date,
    COUNT(*) as calls
FROM call_logs
WHERE call_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(call_time)
ORDER BY date";

$trendsResult = $conn->query($trendsQuery);
$trends = [];
while ($row = $trendsResult->fetch_assoc()) {
    $trends[] = $row;
}

// Telecaller comparison
$comparisonQuery = "SELECT 
    u.name,
    COUNT(cl.id) as calls,
    COUNT(CASE WHEN cl.call_status = 'connected' THEN 1 END) as connected,
    COUNT(CASE WHEN d.status = 'interested' THEN 1 END) as conversions
FROM users u
LEFT JOIN call_logs cl ON u.id = cl.telecaller_id AND cl.call_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
LEFT JOIN drivers d ON cl.driver_id = d.id
WHERE u.role = 'telecaller'
GROUP BY u.id
ORDER BY calls DESC
LIMIT 10";

$comparisonResult = $conn->query($comparisonQuery);
$telecallerComparison = [];
while ($row = $comparisonResult->fetch_assoc()) {
    $telecallerComparison[] = $row;
}

sendSuccess([
    'revenue' => $revenue,
    'conversion' => [
        'rate' => $conversion['rate'],
        'total' => $conversion['connected']
    ],
    'avg_duration' => $avgDuration,
    'trends' => $trends,
    'telecaller_comparison' => $telecallerComparison
]);
