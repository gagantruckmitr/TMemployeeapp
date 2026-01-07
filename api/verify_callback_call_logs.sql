-- Verification SQL Script for Callback Requests Call Logs Fix
-- Run these queries to verify the fix is working correctly

-- ============================================================================
-- 1. Check callback_requests table has unique_id linking to users
-- ============================================================================
SELECT 
    'Callback Requests with User Mapping' as check_name,
    COUNT(*) as total_requests,
    COUNT(DISTINCT cr.unique_id) as unique_users,
    SUM(CASE WHEN u.id IS NOT NULL THEN 1 ELSE 0 END) as requests_with_user_match
FROM callback_requests cr
LEFT JOIN users u ON cr.unique_id = u.unique_id;

-- ============================================================================
-- 2. Sample callback requests with user_id mapping
-- ============================================================================
SELECT 
    'Sample Callback Requests' as section,
    cr.id as callback_request_id,
    cr.unique_id as tmid,
    cr.user_name,
    cr.mobile_number,
    cr.status,
    u.id as user_id,
    u.name as user_name_from_users_table,
    CASE 
        WHEN u.id IS NOT NULL THEN '✅ Mapped'
        ELSE '❌ No User Found'
    END as mapping_status
FROM callback_requests cr
LEFT JOIN users u ON cr.unique_id = u.unique_id
ORDER BY cr.created_at DESC
LIMIT 10;

-- ============================================================================
-- 3. Check call_logs from callback_requests with correct user_id
-- ============================================================================
SELECT 
    'Call Logs from Callback Requests' as section,
    cl.id as call_log_id,
    cl.user_id,
    u.unique_id as tmid,
    u.name as user_name,
    cl.caller_id,
    a.name as telecaller_name,
    cl.tc_for,
    cl.call_status,
    cl.feedback,
    cl.remarks,
    cl.created_at,
    CASE 
        WHEN cl.user_id IS NOT NULL AND u.id IS NOT NULL THEN '✅ Valid'
        WHEN cl.user_id IS NULL THEN '❌ Missing user_id'
        WHEN u.id IS NULL THEN '❌ Invalid user_id'
        ELSE '⚠️ Unknown'
    END as validation_status
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
LEFT JOIN admins a ON cl.caller_id = a.id
WHERE cl.tc_for = 'callback_requests' 
   OR cl.reference_id LIKE 'CALLBACK_%'
ORDER BY cl.created_at DESC
LIMIT 10;

-- ============================================================================
-- 4. Check for orphaned call_logs (user_id doesn't exist in users table)
-- ============================================================================
SELECT 
    'Orphaned Call Logs' as section,
    cl.id as call_log_id,
    cl.user_id,
    cl.driver_name,
    cl.user_number,
    cl.tc_for,
    cl.created_at,
    '❌ User ID not found in users table' as issue
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
WHERE cl.tc_for = 'callback_requests'
  AND u.id IS NULL
ORDER BY cl.created_at DESC
LIMIT 10;

-- ============================================================================
-- 5. Callback requests in history with their latest call log
-- ============================================================================
SELECT 
    'History with Call Logs' as section,
    cr.id as callback_request_id,
    cr.unique_id as tmid,
    cr.user_name,
    cr.status as callback_status,
    cr.notes as callback_notes,
    cl.id as latest_call_log_id,
    cl.feedback as call_feedback,
    cl.remarks as call_remarks,
    cl.call_time,
    CASE 
        WHEN cl.id IS NOT NULL THEN '✅ Has Call Log'
        ELSE '⚠️ No Call Log'
    END as call_log_status
FROM callback_requests cr
LEFT JOIN users u ON cr.unique_id = u.unique_id
LEFT JOIN call_logs cl ON cl.user_id = u.id 
    AND cl.tc_for = 'callback_requests'
    AND cl.id = (
        SELECT id FROM call_logs 
        WHERE user_id = u.id 
        AND tc_for = 'callback_requests'
        ORDER BY call_time DESC 
        LIMIT 1
    )
WHERE cr.status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')
ORDER BY cr.updated_at DESC
LIMIT 10;

-- ============================================================================
-- 6. Summary statistics
-- ============================================================================
SELECT 
    'Summary Statistics' as section,
    (SELECT COUNT(*) FROM callback_requests) as total_callback_requests,
    (SELECT COUNT(*) FROM callback_requests WHERE status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')) as requests_in_history,
    (SELECT COUNT(*) FROM call_logs WHERE tc_for = 'callback_requests') as total_callback_call_logs,
    (SELECT COUNT(*) FROM call_logs cl 
     LEFT JOIN users u ON cl.user_id = u.id 
     WHERE cl.tc_for = 'callback_requests' AND u.id IS NOT NULL) as valid_call_logs,
    (SELECT COUNT(*) FROM call_logs cl 
     LEFT JOIN users u ON cl.user_id = u.id 
     WHERE cl.tc_for = 'callback_requests' AND u.id IS NULL) as invalid_call_logs;

-- ============================================================================
-- 7. Recent activity (last 24 hours)
-- ============================================================================
SELECT 
    'Recent Activity (24h)' as section,
    cl.id as call_log_id,
    cl.user_id,
    u.unique_id as tmid,
    u.name as user_name,
    a.name as telecaller_name,
    cl.feedback,
    cl.remarks,
    cl.created_at,
    TIMESTAMPDIFF(MINUTE, cl.created_at, NOW()) as minutes_ago
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
LEFT JOIN admins a ON cl.caller_id = a.id
WHERE cl.tc_for = 'callback_requests'
  AND cl.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY cl.created_at DESC;

-- ============================================================================
-- 8. Check for duplicate call logs (same user, same time)
-- ============================================================================
SELECT 
    'Potential Duplicates' as section,
    cl1.id as call_log_1,
    cl2.id as call_log_2,
    cl1.user_id,
    u.unique_id as tmid,
    u.name,
    cl1.feedback,
    cl1.created_at,
    TIMESTAMPDIFF(SECOND, cl1.created_at, cl2.created_at) as seconds_apart
FROM call_logs cl1
JOIN call_logs cl2 ON cl1.user_id = cl2.user_id 
    AND cl1.id < cl2.id
    AND cl1.tc_for = 'callback_requests'
    AND cl2.tc_for = 'callback_requests'
    AND TIMESTAMPDIFF(SECOND, cl1.created_at, cl2.created_at) < 60
LEFT JOIN users u ON cl1.user_id = u.id
ORDER BY cl1.created_at DESC
LIMIT 10;
