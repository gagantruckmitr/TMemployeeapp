-- Fix Transporter Assignments
-- Remove all assigned_to values for transporters
-- Transporters should NEVER be assigned to telecallers
-- They use round-robin distribution in transporter_leads_api.php

-- Step 1: Clear all existing transporter assignments
UPDATE users 
SET assigned_to = NULL 
WHERE role = 'transporter' 
AND assigned_to IS NOT NULL;

-- Step 2: Create trigger to prevent future transporter assignments
DROP TRIGGER IF EXISTS prevent_transporter_assignment;

DELIMITER $$

CREATE TRIGGER prevent_transporter_assignment
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- If role is transporter, always set assigned_to to NULL
    IF NEW.role = 'transporter' THEN
        SET NEW.assigned_to = NULL;
    END IF;
END$$

DELIMITER ;

-- Step 3: Create trigger for INSERT to prevent assignment on creation
DROP TRIGGER IF EXISTS prevent_transporter_assignment_insert;

DELIMITER $$

CREATE TRIGGER prevent_transporter_assignment_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    -- If role is transporter, always set assigned_to to NULL
    IF NEW.role = 'transporter' THEN
        SET NEW.assigned_to = NULL;
    END IF;
END$$

DELIMITER ;

-- Verification queries
SELECT 
    'Before Fix' as stage,
    COUNT(*) as total_transporters,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) as assigned_count,
    SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) as unassigned_count
FROM users 
WHERE role = 'transporter';

-- After running the UPDATE, check again
SELECT 
    'After Fix' as stage,
    COUNT(*) as total_transporters,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) as assigned_count,
    SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) as unassigned_count
FROM users 
WHERE role = 'transporter';

-- Show which telecallers had transporters assigned (for reference)
SELECT 
    a.id as telecaller_id,
    a.name as telecaller_name,
    a.tc_for,
    COUNT(u.id) as transporter_count
FROM users u
INNER JOIN admins a ON u.assigned_to = a.id
WHERE u.role = 'transporter'
AND u.assigned_to IS NOT NULL
GROUP BY a.id, a.name, a.tc_for
ORDER BY transporter_count DESC;
