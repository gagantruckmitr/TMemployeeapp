-- Setup Social Media User Access
-- Run this SQL to grant social media access to a user

-- Example 1: Grant social media access to a specific user by ID
UPDATE admin 
SET tc_for = 'social-media' 
WHERE id = 1; -- Replace 1 with actual user ID

-- Example 2: Grant social media access to a user by mobile number
UPDATE admin 
SET tc_for = 'social-media' 
WHERE mobile = '9876543210'; -- Replace with actual mobile number

-- Example 3: Check current tc_for values for all users
SELECT id, name, mobile, tc_for 
FROM admin 
ORDER BY tc_for, name;

-- Example 4: List all users with social media access
SELECT id, name, mobile, tc_for 
FROM admin 
WHERE LOWER(tc_for) = 'social-media';

-- Example 5: Remove social media access from a user
UPDATE admin 
SET tc_for = 'other-value' -- Replace with appropriate value
WHERE id = 1; -- Replace with actual user ID

-- Example 6: Check if tc_for column exists
SHOW COLUMNS FROM admin LIKE 'tc_for';

-- Example 7: Add tc_for column if it doesn't exist (run only if needed)
-- ALTER TABLE admin ADD COLUMN tc_for VARCHAR(50) DEFAULT 'general' AFTER role;
