# Transporter Leads - Match-Making Only Access

## Change Summary

Updated `api/transporter_leads_api.php` to **only allow telecallers with `tc_for = 'match-making'`** to access transporter leads.

## What Changed

### Before:
```php
// Get all telecallers where tc_for = 'welcome-call'
AND tc_for = 'welcome-call'

// Error message
'Access denied: Only telecallers with tc_for = welcome-call can access these leads'
```

### After:
```php
// Get all telecallers where tc_for = 'match-making'
AND tc_for = 'match-making'

// Error message
'Access denied: Only telecallers with tc_for = match-making can access these leads'
```

## Access Control

### ✅ Allowed:
- Telecallers with `tc_for = 'match-making'`
- These users will see transporter leads distributed via round-robin

### ❌ Denied:
- Telecallers with `tc_for = 'welcome-call'`
- Telecallers with `tc_for = 'toll-free'`
- Telecallers with `tc_for = 'social-media'`
- Any other `tc_for` value

## API Response

### For Allowed Users:
```json
{
  "success": true,
  "data": [...transporter leads...],
  "count": 10,
  "caller_id": 3,
  "distribution": "round_robin",
  "note": "Round-robin assignment: transporters without jobs and not called",
  "timestamp": "2024-01-20 10:30:00"
}
```

### For Denied Users:
```json
{
  "success": false,
  "error": "Access denied: Only telecallers with tc_for = match-making can access these leads",
  "caller_id": 5,
  "timestamp": "2024-01-20 10:30:00"
}
```

## Testing

### Quick Test:
Visit: `https://truckmitr.com/truckmitr-app/api/test_transporter_leads_access.php`

This will:
1. Show all telecallers and their `tc_for` values
2. Test API access with a match-making user (should succeed)
3. Test API access with a non-match-making user (should fail)

### Manual Test:

**Test with match-making user:**
```
https://truckmitr.com/truckmitr-app/api/transporter_leads_api.php?action=transporter_leads&caller_id=3&limit=10
```

**Test with non-match-making user:**
```
https://truckmitr.com/truckmitr-app/api/transporter_leads_api.php?action=transporter_leads&caller_id=5&limit=10
```

## Database Query

To see which users have access:

```sql
-- Users with access (tc_for = 'match-making')
SELECT id, name, email, tc_for 
FROM admins 
WHERE role = 'telecaller' 
AND tc_for = 'match-making';

-- Users without access
SELECT id, name, email, tc_for 
FROM admins 
WHERE role = 'telecaller' 
AND tc_for != 'match-making';
```

## Round-Robin Distribution

Transporter leads are distributed evenly among all telecallers with `tc_for = 'match-making'`:

- If 3 telecallers have match-making access
- Telecaller 1 gets: leads 0, 3, 6, 9, 12...
- Telecaller 2 gets: leads 1, 4, 7, 10, 13...
- Telecaller 3 gets: leads 2, 5, 8, 11, 14...

## Impact

### ✅ Benefits:
- Clear separation of responsibilities
- Match-making telecallers focus on transporter leads
- Other telecallers focus on their assigned tasks
- Better lead management and tracking

### 📊 Who Gets What:
- `tc_for = 'match-making'` → Transporter leads (this API)
- `tc_for = 'welcome-call'` → Welcome call leads (different API)
- `tc_for = 'toll-free'` → Toll-free leads (different API)
- `tc_for = 'social-media'` → Social media leads (different API)

## Files Modified

- ✅ `api/transporter_leads_api.php` - Updated access control

## Files Created

- ✅ `api/test_transporter_leads_access.php` - Access control test
- ✅ `TRANSPORTER_LEADS_MATCH_MAKING_ONLY.md` - This documentation

## Summary

**Only telecallers with `tc_for = 'match-making'` can now access transporter leads through this API.** All other users will receive an "Access denied" error. 🎯
