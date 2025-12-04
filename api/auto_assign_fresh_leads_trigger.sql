-- ============================================================================
-- AUTO ASSIGN FRESH LEADS TRIGGER
-- ============================================================================
-- Purpose: Automatically assign new driver and transporter leads to telecallers
-- 
-- RULES:
-- 1. Drivers (role='driver') → Assign to telecallers with tc_for='welcome-call'
-- 2. Transporters (role='transporter') → DO NOT ASSIGN (use round-robin in API)
-- 3. Only fresh leads (Created_at >= NOW() - INTERVAL 1 DAY)
-- 4. Round-robin distribution among available telecallers
-- 5. Past leads remain unchanged
-- ============================================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS auto_assign_driver_on_insert;
DROP TRIGGER IF EXISTS auto_assign_driver_on_update;
DROP TRIGGER IF EXISTS prevent_transporter_assignment;
DROP TRIGGER IF EXISTS prevent_transporter_assignment_insert;

-- ============================================================================
-- ONE-TIME ASSIGNMENT: Assign existing fresh leads (last 1 day)
-- ============================================================================

-- First, clear any transporter assignments (they should never be assigned)
UPDATE users 
SET assigned_to = NULL 
WHERE role = 'transporter' 
AND assigned_to IS NOT NULL;

-- Now assign fresh driver leads from the last 1 day that are unassigned
-- This is a one-time operation for existing data

SET @row_number = 0;
SET @telecaller_count = (
    SELECT COUNT(*) 
    FROM admins 
    WHERE role = 'telecaller' 
    AND tc_for = 'welcome-call'
);

-- Only proceed if we have telecallers
UPDATE users u
INNER JOIN (
    SELECT 
        id,
        @row_number := @row_number + 1 AS row_num
    FROM users
    WHERE role = 'driver'
    AND (assigned_to IS NULL OR assigned_to = 0)
    AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
    ORDER BY Created_at DESC
) AS numbered ON u.id = numbered.id
INNER JOIN (
    SELECT 
        id,
        @tc_row := @tc_row + 1 AS tc_index
    FROM admins, (SELECT @tc_row := 0) AS init
    WHERE role = 'telecaller'
    AND tc_for = 'welcome-call'
    ORDER BY id ASC
) AS telecallers ON telecallers.tc_index = ((numbered.row_num - 1) % @telecaller_count) + 1
SET u.assigned_to = telecallers.id
WHERE @telecaller_count > 0;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check trigger creation
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    ACTION_STATEMENT
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
AND TRIGGER_NAME IN (
    'auto_assign_driver_on_insert',
    'auto_assign_driver_on_update'
)
ORDER BY TRIGGER_NAME;

-- Check fresh driver assignments (last 1 day)
SELECT 
    'Fresh Drivers (Last 1 Day)' AS category,
    COUNT(*) AS total_count,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned_count,
    SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) AS unassigned_count
FROM users
WHERE role = 'driver'
AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY);

-- Check transporter assignments (should all be NULL)
SELECT 
    'Transporters' AS category,
    COUNT(*) AS total_count,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned_count,
    SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) AS unassigned_count
FROM users
WHERE role = 'transporter';

-- Show distribution of fresh drivers among telecallers
SELECT 
    a.id AS telecaller_id,
    a.name AS telecaller_name,
    a.tc_for,
    COUNT(u.id) AS assigned_fresh_drivers,
    MIN(u.Created_at) AS oldest_lead,
    MAX(u.Created_at) AS newest_lead
FROM admins a
LEFT JOIN users u ON u.assigned_to = a.id 
    AND u.role = 'driver'
    AND u.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
WHERE a.role = 'telecaller'
AND a.tc_for = 'welcome-call'
GROUP BY a.id, a.name, a.tc_for
ORDER BY assigned_fresh_drivers DESC;

-- Show old drivers (more than 1 day old) - these should NOT be reassigned
SELECT 
    'Old Drivers (>1 Day)' AS category,
    COUNT(*) AS total_count,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned_count,
    SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) AS unassigned_count
FROM users
WHERE role = 'driver'
AND Created_at < DATE_SUB(NOW(), INTERVAL 1 DAY);

-- ============================================================================
-- NOTES
-- ============================================================================
-- 
-- 1. DRIVERS:
--    - Fresh leads (last 1 day + future) are auto-assigned to welcome-call telecallers
--    - Assignment happens in round-robin fashion
--    - Old leads (>1 day) remain unchanged
--
-- 2. TRANSPORTERS:
--    - NEVER assigned via assigned_to column
--    - Use round-robin distribution in transporter_leads_api.php
--    - Only match-making telecallers can access them
--
-- 3. FUTURE LEADS:
--    - Triggers will automatically assign new driver registrations
--    - No manual intervention needed
--
-- 4. TESTING:
--    - Insert a new driver: INSERT INTO users (name, mobile, role, Created_at) 
--      VALUES ('Test Driver', '9999999999', 'driver', NOW());
--    - Check assignment: SELECT id, name, role, assigned_to, Created_at FROM users 
--      WHERE name = 'Test Driver';
--
-- ============================================================================
