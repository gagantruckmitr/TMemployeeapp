# Auto-Assign Fresh Leads - Complete Implementation

## Overview

This implementation creates database triggers to automatically assign fresh leads to telecallers in a round-robin fashion.

## Assignment Rules

### 1. **Drivers** (role = 'driver')
- **Fresh leads** (Created_at >= NOW() - 1 DAY) → Auto-assigned to telecallers with `tc_for = 'welcome-call'`
- **Old leads** (Created_at < NOW() - 1 DAY) → Remain unchanged
- **Distribution**: Round-robin among all welcome-call telecallers

### 2. **Transporters** (role = 'transporter')
- **NEVER assigned** via `assigned_to` column
- Use round-robin distribution in `transporter_leads_api.php`
- Only telecallers with `tc_for = 'match-making'` can access them

## Files Created

### 1. `api/auto_assign_fresh_leads_trigger.sql`
SQL file containing:
- Trigger definitions for INSERT and UPDATE operations
- One-time assignment of existing fresh leads
- Verification queries
- Complete documentation

### 2. `api/setup_auto_assign_triggers.php`
PHP script to:
- Execute the SQL trigger file
- Verify trigger creation
- Show assignment statistics
- Display distribution among telecallers

### 3. `api/test_auto_assign_trigger.php`
Comprehensive test script that:
- Tests fresh driver assignment
- Tests old driver (should NOT assign)
- Tests transporter (should NEVER assign)
- Tests role change triggers
- Tests round-robin distribution
- Cleans up test data automatically

## Installation

### Step 1: Run the Setup Script

```bash
php api/setup_auto_assign_triggers.php
```

This will:
- Create the database triggers
- Assign existing fresh leads (last 1 day)
- Clear any transporter assignments
- Show verification statistics

### Step 2: Verify Installation

```bash
php api/test_auto_assign_trigger.php
```

This will:
- Run comprehensive tests
- Verify all assignment rules work correctly
- Clean up test data automatically

## How It Works

### Trigger 1: `auto_assign_driver_on_insert`
- Fires **BEFORE INSERT** on `users` table
- Checks if role = 'driver' AND Created_at is fresh (>= NOW() - 1 DAY)
- Finds next telecaller in round-robin sequence
- Assigns driver to that telecaller
- Ensures transporters are NEVER assigned

### Trigger 2: `auto_assign_driver_on_update`
- Fires **BEFORE UPDATE** on `users` table
- Checks if role changed to 'driver' OR driver is unassigned and fresh
- Finds next telecaller in round-robin sequence
- Assigns driver to that telecaller
- Ensures transporters are NEVER assigned

### Round-Robin Algorithm
1. Get all active telecallers with `tc_for = 'welcome-call'`
2. Find the last assigned telecaller ID
3. Get the next telecaller in sequence (by ID)
4. If at end of list, wrap around to first telecaller
5. Assign driver to that telecaller

## Verification Queries

### Check Trigger Status
```sql
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
AND TRIGGER_NAME LIKE '%assign%';
```

### Check Fresh Driver Assignments
```sql
SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned,
    SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) AS unassigned
FROM users
WHERE role = 'driver'
AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY);
```

### Check Transporter Assignments (Should be 0)
```sql
SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned
FROM users
WHERE role = 'transporter';
```

### Check Distribution Among Telecallers
```sql
SELECT 
    a.id,
    a.name,
    a.tc_for,
    COUNT(u.id) AS assigned_fresh_drivers
FROM admins a
LEFT JOIN users u ON u.assigned_to = a.id 
    AND u.role = 'driver'
    AND u.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
WHERE a.role = 'telecaller'
AND a.tc_for = 'welcome-call'
GROUP BY a.id, a.name, a.tc_for
ORDER BY assigned_fresh_drivers DESC;
```

## API Integration

### Fresh Leads API (`api/fresh_leads_api.php`)
- Already configured to use `assigned_to` column
- Shows only drivers assigned to the logged-in telecaller
- Filters by `tc_for = 'welcome-call'`

### Transporter Leads API (`api/transporter_leads_api.php`)
- Uses round-robin distribution (NOT assigned_to column)
- Only accessible to telecallers with `tc_for = 'match-making'`
- Distributes transporters who haven't posted jobs

## Testing

### Manual Test: Insert New Driver
```sql
INSERT INTO users (name, mobile, role, Created_at, Updated_at)
VALUES ('Test Driver', '9999999999', 'driver', NOW(), NOW());

-- Check assignment
SELECT id, name, role, assigned_to, Created_at 
FROM users 
WHERE name = 'Test Driver';
```

### Manual Test: Insert Old Driver
```sql
INSERT INTO users (name, mobile, role, Created_at, Updated_at)
VALUES ('Old Driver', '9999999998', 'driver', DATE_SUB(NOW(), INTERVAL 2 DAY), NOW());

-- Check assignment (should be NULL)
SELECT id, name, role, assigned_to, Created_at 
FROM users 
WHERE name = 'Old Driver';
```

### Manual Test: Insert Transporter
```sql
INSERT INTO users (name, mobile, role, Created_at, Updated_at)
VALUES ('Test Transporter', '9999999997', 'transporter', NOW(), NOW());

-- Check assignment (should be NULL)
SELECT id, name, role, assigned_to, Created_at 
FROM users 
WHERE name = 'Test Transporter';
```

## Troubleshooting

### Issue: Triggers Not Working

**Check if triggers exist:**
```sql
SHOW TRIGGERS LIKE 'users';
```

**Recreate triggers:**
```bash
php api/setup_auto_assign_triggers.php
```

### Issue: Unbalanced Distribution

**Check telecaller count:**
```sql
SELECT COUNT(*) FROM admins 
WHERE role = 'telecaller' 
AND tc_for = 'welcome-call'
AND status = 'active';
```

**Manually rebalance:**
```bash
php api/setup_auto_assign_triggers.php
```

### Issue: Transporters Getting Assigned

**Clear transporter assignments:**
```sql
UPDATE users 
SET assigned_to = NULL 
WHERE role = 'transporter';
```

**Verify triggers prevent assignment:**
```bash
php api/test_auto_assign_trigger.php
```

## Important Notes

1. **Past Leads**: Leads older than 1 day are NOT reassigned. Only fresh leads are affected.

2. **Transporters**: NEVER use `assigned_to` column. They use round-robin in the API.

3. **Future Leads**: All new driver registrations will be automatically assigned.

4. **Telecaller Changes**: If you add/remove telecallers, the round-robin will automatically adjust.

5. **Performance**: Triggers are lightweight and execute in microseconds.

## Maintenance

### Adding New Telecallers
1. Insert into `admins` table with `tc_for = 'welcome-call'`
2. Triggers will automatically include them in round-robin
3. No manual intervention needed

### Removing Telecallers
1. Set `status = 'inactive'` in `admins` table
2. Triggers will automatically exclude them
3. Existing assignments remain unchanged

### Reassigning Old Leads
If you need to reassign old leads (>1 day), modify the trigger's date condition:
```sql
-- Change from:
AND NEW.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)

-- To (for 7 days):
AND NEW.Created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
```

## Success Criteria

✅ Fresh drivers (last 1 day) are auto-assigned to welcome-call telecallers  
✅ Old drivers (>1 day) remain unchanged  
✅ Transporters are NEVER assigned  
✅ Round-robin distribution is balanced  
✅ Future driver registrations are auto-assigned  
✅ Triggers work on INSERT and UPDATE operations  

## Support

If you encounter any issues:
1. Run the test script: `php api/test_auto_assign_trigger.php`
2. Check trigger status in database
3. Verify telecaller configuration (`tc_for` values)
4. Review error logs in PHP error log

---

**Status**: ✅ Ready for Production  
**Last Updated**: 2025-11-27  
**Version**: 1.0
