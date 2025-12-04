# Driver/Transporter Separation Fix

## Issue

Transporter leads were showing up in the driver section for `tc_for = 'welcome-call'` users. Drivers and transporters were mixed together in `fresh_leads_api.php`.

## Root Cause

In `api/fresh_leads_api.php`, the query was fetching both drivers AND transporters:

```php
WHERE u.role IN ('driver', 'transporter')
```

This caused:
- Welcome-call telecallers saw transporters mixed with drivers
- No separation between driver and transporter leads
- Confusion about which leads belong to which telecaller type

## Solution

### 1. Updated `fresh_leads_api.php`

**Changed:**
- Now checks telecaller's `tc_for` value
- **ONLY shows drivers** (never transporters)
- Match-making users are redirected to use `transporter_leads_api.php`

**Key Changes:**
```php
// Check tc_for value
$tcForStmt = $pdo->prepare("SELECT tc_for FROM admins WHERE id = ? AND role = 'telecaller'");
$tcFor = $tcForRow['tc_for'] ?? null;

// Match-making users should use transporter_leads_api.php
if ($tcFor === 'match-making') {
    return error: 'Use transporter_leads_api.php for transporter leads';
}

// For all others: ONLY show drivers
WHERE u.role = 'driver'  // Changed from IN ('driver', 'transporter')
```

### 2. Updated `transporter_leads_api.php`

**Already done in previous fix:**
- Only allows `tc_for = 'match-making'` users
- Shows ONLY transporters
- Denies access to other tc_for values

## API Separation

### ✅ Correct Usage:

| tc_for Value | API to Use | Shows |
|--------------|-----------|-------|
| `welcome-call` | `fresh_leads_api.php` | **Drivers ONLY** |
| `match-making` | `transporter_leads_api.php` | **Transporters ONLY** |
| `toll-free` | `toll_free_search_api.php` | Toll-free leads |
| `social-media` | `social-media-leads.php` | Social media leads |

### ❌ What's Blocked:

- Welcome-call users **CANNOT** see transporters
- Match-making users **CANNOT** use fresh_leads_api.php
- Match-making users **CANNOT** see drivers
- Complete separation between driver and transporter leads

## Files Modified

1. **`api/fresh_leads_api.php`**
   - Added tc_for check
   - Changed `role IN ('driver', 'transporter')` to `role = 'driver'`
   - Block match-making users from accessing
   - Updated all 3 functions: `getFreshLeads()`, `getDriversByStatus()`, `markAsCalled()`

2. **`api/transporter_leads_api.php`** (previous fix)
   - Only allows `tc_for = 'match-making'`
   - Shows only transporters

## Testing

### Quick Test:
Visit: `https://truckmitr.com/truckmitr-app/api/test_driver_transporter_separation.php`

This will:
1. Show all telecallers and their tc_for values
2. Test welcome-call user (should see only drivers)
3. Test match-making user (should see only transporters)
4. Verify no mixing occurs

### Manual Testing:

**Test 1: Welcome-Call User (Should See Drivers Only)**
```
https://truckmitr.com/truckmitr-app/api/fresh_leads_api.php?action=fresh_leads&caller_id=5&limit=10
```
Expected: Only drivers, no transporters

**Test 2: Match-Making User with Fresh Leads API (Should Be Denied)**
```
https://truckmitr.com/truckmitr-app/api/fresh_leads_api.php?action=fresh_leads&caller_id=3&limit=10
```
Expected: Error message "Use transporter_leads_api.php"

**Test 3: Match-Making User with Transporter API (Should Succeed)**
```
https://truckmitr.com/truckmitr-app/api/transporter_leads_api.php?action=transporter_leads&caller_id=3&limit=10
```
Expected: Only transporters

## Database Verification

Check what each user should see:

```sql
-- Check drivers assigned to welcome-call user
SELECT u.id, u.name, u.role, u.assigned_to
FROM users u
WHERE u.role = 'driver'
AND u.assigned_to = 5;  -- Replace with welcome-call user ID

-- Check transporters for match-making (not assigned, round-robin)
SELECT u.id, u.name, u.role
FROM users u
WHERE u.role = 'transporter'
AND u.id NOT IN (
    SELECT DISTINCT transporter_id FROM jobs WHERE transporter_id IS NOT NULL
);
```

## Impact

### ✅ Benefits:
- **Complete separation** of drivers and transporters
- **No mixing** of leads between different telecaller types
- **Clear responsibility** - each telecaller type has specific leads
- **Better organization** - easier to manage and track

### 📊 Lead Distribution:

**Welcome-Call Telecallers:**
- See: Drivers assigned to them
- Don't see: Transporters (ever)
- API: `fresh_leads_api.php`

**Match-Making Telecallers:**
- See: Transporters (round-robin distribution)
- Don't see: Drivers (ever)
- API: `transporter_leads_api.php`

## Before vs After

### Before ❌:
```
welcome-call user → fresh_leads_api.php → Drivers + Transporters (MIXED!)
match-making user → transporter_leads_api.php → Transporters
```

### After ✅:
```
welcome-call user → fresh_leads_api.php → Drivers ONLY
match-making user → transporter_leads_api.php → Transporters ONLY
match-making user → fresh_leads_api.php → DENIED (use transporter API)
```

## Files Created

- ✅ `api/test_driver_transporter_separation.php` - Separation test
- ✅ `DRIVER_TRANSPORTER_SEPARATION_FIX.md` - This documentation

## Summary

**Drivers and transporters are now completely separated:**
- Welcome-call users see ONLY drivers
- Match-making users see ONLY transporters
- No mixing between the two types
- Each telecaller type has their own dedicated API

**The separation is complete!** 🎯
