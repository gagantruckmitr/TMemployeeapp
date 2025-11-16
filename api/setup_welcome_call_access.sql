-- Setup Welcome-Call Access for Telecallers
-- This script grants welcome-call access to telecallers

-- ============================================
-- OPTION 1: Single Value (Simple)
-- ============================================
-- Use this if you want ONLY welcome-call access

-- Update specific telecaller by ID
-- UPDATE admins SET tc_for = 'welcome-call' WHERE id = 1;

-- Update specific telecaller by mobile
-- UPDATE admins SET tc_for = 'welcome-call' WHERE mobile = '8888888888';

-- Update ALL telecallers to have welcome-call access
-- UPDATE admins SET tc_for = 'welcome-call' WHERE role = 'telecaller';


-- ============================================
-- OPTION 2: Multi-Value (JSON Array - Recommended)
-- ============================================
-- Use this if you want multiple access types

-- Single access type (welcome-call only)
-- UPDATE admins SET tc_for = '["welcome-call"]' WHERE id = 1;

-- Multiple access types (welcome-call + callback)
-- UPDATE admins SET tc_for = '["welcome-call", "call-back"]' WHERE id = 1;

-- Multiple access types (welcome-call + match-making)
-- UPDATE admins SET tc_for = '["welcome-call", "match-making"]' WHERE id = 1;

-- All access types
-- UPDATE admins SET tc_for = '["admin", "match-making", "manager", "welcome-call", "call-back"]' WHERE id = 1;


-- ============================================
-- VERIFY CHANGES
-- ============================================
-- Check all telecallers and their tc_for values
SELECT 
    id,
    name,
    mobile,
    role,
    tc_for,
    CASE 
        WHEN tc_for = 'welcome-call' THEN 'YES (single)'
        WHEN tc_for LIKE '%welcome-call%' THEN 'YES (multi)'
        ELSE 'NO'
    END as has_welcome_call_access
FROM admins 
WHERE role = 'telecaller'
ORDER BY id;


-- ============================================
-- EXAMPLE: Grant welcome-call to specific users
-- ============================================
-- Uncomment and modify as needed:

-- User 1: Welcome-call only
-- UPDATE admins SET tc_for = 'welcome-call' WHERE id = 1;

-- User 2: Welcome-call + callback
-- UPDATE admins SET tc_for = '["welcome-call", "call-back"]' WHERE id = 2;

-- User 3: All access
-- UPDATE admins SET tc_for = '["admin", "match-making", "manager", "welcome-call", "call-back"]' WHERE id = 3;


-- ============================================
-- NOTES
-- ============================================
-- tc_for = 'welcome-call': Telecaller sees ALL leads (not just assigned)
-- tc_for = other values: Telecaller sees only assigned_to leads
-- Each telecaller only sees leads they haven't personally called yet
-- 
-- The API (fresh_leads_api.php) automatically detects welcome-call access
-- and adjusts the query accordingly.
