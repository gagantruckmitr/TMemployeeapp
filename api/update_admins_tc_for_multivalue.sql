-- Update existing admins.tc_for column to support multiple values
-- Changes from ENUM/VARCHAR to TEXT to store JSON array
-- Supports values: admin, match-making, manager, welcome-call, call-back, etc.

-- BACKUP FIRST!
-- CREATE TABLE admins_backup AS SELECT * FROM admins;

-- Step 1: Check current column type and values
-- SHOW COLUMNS FROM admins LIKE 'tc_for';
-- SELECT DISTINCT tc_for FROM admins ORDER BY tc_for;

-- Step 2: Modify column to TEXT type (preserves existing data)
ALTER TABLE admins 
MODIFY COLUMN tc_for TEXT DEFAULT NULL 
COMMENT 'JSON array of roles: ["admin", "match-making", "manager", "welcome-call", "call-back"]';

-- Step 3: Convert existing single values to JSON array format
-- This updates all existing records to use JSON array format
UPDATE admins 
SET tc_for = CONCAT('["', tc_for, '"]')
WHERE tc_for IS NOT NULL 
  AND tc_for NOT LIKE '[%'  -- Skip if already JSON format
  AND tc_for != '';

-- Step 4: Set NULL for empty strings
UPDATE admins 
SET tc_for = NULL 
WHERE tc_for = '';

-- Verify the changes
SELECT id, name, tc_for, role 
FROM admins 
WHERE tc_for IS NOT NULL 
ORDER BY id
LIMIT 20;

-- Example values after migration:
-- Before: 'admin'           → After: '["admin"]'
-- Before: 'match-making'    → After: '["match-making"]'
-- Before: 'welcome-call'    → After: '["welcome-call"]'
--
-- To add multiple values manually:
-- User with admin and match-making access:
UPDATE admins SET tc_for = '["admin", "match-making"]' WHERE id = 1;

-- User with welcome-call and call-back access:
UPDATE admins SET tc_for = '["welcome-call", "call-back"]' WHERE id = 2;

-- User with all access:
UPDATE admins SET tc_for = '["admin", "match-making", "manager", "welcome-call", "call-back"]' WHERE id = 3;

-- Manager with match-making access:
UPDATE admins SET tc_for = '["manager", "match-making"]' WHERE id = 4;
