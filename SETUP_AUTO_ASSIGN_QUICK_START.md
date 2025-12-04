# Auto-Assign Fresh Leads - Quick Start Guide

## 🚀 Quick Setup (2 Minutes)

### Step 1: Run Setup Script
```bash
cd api
php setup_auto_assign_triggers.php
```

**Expected Output:**
```
=== AUTO-ASSIGN FRESH LEADS TRIGGER SETUP ===

✅ Created trigger: auto_assign_driver_on_insert
✅ Created trigger: auto_assign_driver_on_update
📝 Executed assignment update

=== VERIFICATION ===

✅ Active Triggers:
   - auto_assign_driver_on_insert (BEFORE INSERT)
   - auto_assign_driver_on_update (BEFORE UPDATE)

📊 Fresh Drivers (Last 1 Day):
   - Total: X
   - Assigned: X
   - Unassigned: 0

📊 Transporters:
   - Total: X
   - Assigned: 0 (should be 0)
   ✅ Correct: No transporters assigned

📊 Distribution Among Welcome-Call Telecallers:
   - TC #1 (Name): X fresh drivers
   - TC #2 (Name): X fresh drivers
   ...

=== SETUP COMPLETE ===
```

### Step 2: Test the Triggers
```bash
php test_auto_assign_trigger.php
```

**Expected Output:**
```
=== TESTING AUTO-ASSIGN TRIGGER ===

✅ Found X welcome-call telecallers

TEST 1: Insert Fresh Driver
✅ Driver auto-assigned to telecaller #X

TEST 2: Insert Old Driver (2 days ago)
✅ Old driver NOT assigned (correct behavior)

TEST 3: Insert Transporter
✅ Transporter NOT assigned (correct behavior)

TEST 4: Update Role to Driver
✅ Driver auto-assigned after role change

TEST 5: Round-Robin Distribution
✅ Round-robin distribution is balanced

=== TEST COMPLETE ===

🎉 All tests passed! Trigger is working correctly.
```

## ✅ What Just Happened?

### Drivers (role = 'driver')
- ✅ Fresh leads (last 1 day) → Auto-assigned to welcome-call telecallers
- ✅ Old leads (>1 day) → Remain unchanged
- ✅ Future registrations → Auto-assigned in round-robin

### Transporters (role = 'transporter')
- ✅ NEVER assigned via assigned_to column
- ✅ Use round-robin in transporter_leads_api.php
- ✅ Only match-making telecallers can access them

## 🔍 Verify It's Working

### Check Fresh Driver Assignments
```bash
cd api
php -r "
require_once 'config.php';
\$pdo = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME, DB_USER, DB_PASS);
\$stmt = \$pdo->query('
    SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) as assigned
    FROM users
    WHERE role = \"driver\"
    AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
');
\$result = \$stmt->fetch();
echo \"Fresh Drivers: {\$result['total']} total, {\$result['assigned']} assigned\n\";
"
```

### Check Transporter Assignments (Should be 0)
```bash
php -r "
require_once 'config.php';
\$pdo = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME, DB_USER, DB_PASS);
\$stmt = \$pdo->query('
    SELECT COUNT(*) as assigned
    FROM users
    WHERE role = \"transporter\"
    AND assigned_to IS NOT NULL
');
\$result = \$stmt->fetch();
echo \"Transporters Assigned: {\$result['assigned']} (should be 0)\n\";
"
```

## 🧪 Test New Registration

### Test Fresh Driver Assignment
```sql
-- Insert a test driver
INSERT INTO users (name, mobile, role, Created_at, Updated_at)
VALUES ('Test Fresh Driver', '9999999999', 'driver', NOW(), NOW());

-- Check if assigned
SELECT id, name, role, assigned_to, Created_at 
FROM users 
WHERE name = 'Test Fresh Driver';

-- Clean up
DELETE FROM users WHERE name = 'Test Fresh Driver';
```

### Test Transporter (Should NOT Assign)
```sql
-- Insert a test transporter
INSERT INTO users (name, mobile, role, Created_at, Updated_at)
VALUES ('Test Transporter', '9999999998', 'transporter', NOW(), NOW());

-- Check if assigned (should be NULL)
SELECT id, name, role, assigned_to, Created_at 
FROM users 
WHERE name = 'Test Transporter';

-- Clean up
DELETE FROM users WHERE name = 'Test Transporter';
```

## 📊 View Distribution

```sql
SELECT 
    a.id AS telecaller_id,
    a.name AS telecaller_name,
    COUNT(u.id) AS assigned_fresh_drivers
FROM admins a
LEFT JOIN users u ON u.assigned_to = a.id 
    AND u.role = 'driver'
    AND u.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
WHERE a.role = 'telecaller'
AND a.tc_for = 'welcome-call'
GROUP BY a.id, a.name
ORDER BY assigned_fresh_drivers DESC;
```

## 🔧 Troubleshooting

### Problem: "No welcome-call telecallers found"

**Solution:** Ensure telecallers have `tc_for = 'welcome-call'` in admins table:
```sql
UPDATE admins 
SET tc_for = 'welcome-call' 
WHERE role = 'telecaller' 
AND id IN (1, 2, 3); -- Replace with your telecaller IDs
```

### Problem: Triggers not working

**Solution:** Recreate triggers:
```bash
php api/setup_auto_assign_triggers.php
```

### Problem: Transporters getting assigned

**Solution:** Clear and prevent:
```sql
UPDATE users SET assigned_to = NULL WHERE role = 'transporter';
```
Then run: `php api/setup_auto_assign_triggers.php`

## 📝 Important Notes

1. **Only Fresh Leads**: Only leads from the last 1 day are assigned. Old leads remain unchanged.

2. **Automatic**: Future driver registrations will be automatically assigned. No manual work needed.

3. **Transporters**: Never use assigned_to. They use round-robin in the API.

4. **Round-Robin**: Distribution is balanced automatically among all welcome-call telecallers.

## ✅ Success Checklist

- [ ] Setup script ran successfully
- [ ] Test script passed all tests
- [ ] Fresh drivers are assigned
- [ ] Old drivers remain unchanged
- [ ] Transporters are NOT assigned
- [ ] Distribution is balanced

## 🎉 Done!

Your auto-assignment system is now active. All new driver registrations will be automatically assigned to welcome-call telecallers in round-robin fashion.

---

**Need Help?** Check `AUTO_ASSIGN_FRESH_LEADS_COMPLETE.md` for detailed documentation.
