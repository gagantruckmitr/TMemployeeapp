-- Setup Welcome-Call Telecallers
-- This script updates telecallers to have tc_for = 'welcome-call'
-- Run this in your database to enable Smart Calling access for all telecallers

-- 1. Check current telecaller assignments
SELECT id, name, mobile, role, tc_for 
FROM admins 
WHERE role = 'telecaller'
ORDER BY id;

-- 2. Update ALL telecallers to welcome-call (if you want all to have access)
-- Uncomment the line below to execute:
-- UPDATE admins SET tc_for = 'welcome-call' WHERE role = 'telecaller';

-- 3. Update SPECIFIC telecallers to welcome-call (replace IDs as needed)
-- Uncomment and modify the line below:
-- UPDATE admins SET tc_for = 'welcome-call' WHERE id IN (1, 2, 3);

-- 4. Verify the changes
SELECT id, name, mobile, role, tc_for 
FROM admins 
WHERE role = 'telecaller' AND tc_for = 'welcome-call'
ORDER BY id;

-- 5. Check how many leads each telecaller will see
SELECT 
    a.id as telecaller_id,
    a.name as telecaller_name,
    a.tc_for,
    COUNT(DISTINCT u.id) as total_leads_visible,
    COUNT(DISTINCT CASE WHEN u.assigned_to = a.id THEN u.id END) as assigned_leads,
    COUNT(DISTINCT cl.user_id) as already_called
FROM admins a
LEFT JOIN users u ON (
    (a.tc_for = 'welcome-call' AND u.role IN ('driver', 'transporter'))
    OR (a.tc_for != 'welcome-call' AND u.assigned_to = a.id)
)
LEFT JOIN call_logs cl ON cl.user_id = u.id AND cl.caller_id = a.id
WHERE a.role = 'telecaller'
GROUP BY a.id, a.name, a.tc_for
ORDER BY a.id;

-- Notes:
-- - tc_for = 'welcome-call': Telecaller sees ALL leads
-- - tc_for = other values: Telecaller sees only assigned_to leads
-- - Each telecaller only sees leads they haven't personally called yet
