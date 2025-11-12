# Call Logs Timestamp Fix

## Problem
Timestamps in `call_logs_match_making` table are showing UTC time instead of IST time.
- Current time: 5:14 PM IST
- Database shows: 11:44 AM (6 hours behind)
- Difference: ~5.5 hours (IST offset)

## Root Cause
When we removed `SET time_zone = '+05:30'` from config.php to fix the reading issue, it caused INSERT operations to use UTC instead of IST.

## Solution

### 1. Re-enable Timezone Setting
**File:** `api/config.php`

Re-added `SET time_zone = '+05:30'` for both mysqli and PDO connections.

**Why this works now:**
- The issue before was that EXISTING data was already in IST
- Setting timezone was converting it again (double conversion)
- Now we know the data format, we can handle it correctly

### 2. Fix Existing Wrong Timestamps
**Script:** `api/fix_call_logs_timestamps.php`

This script:
- Identifies records with UTC timestamps (4-10 hours in the past)
- Adds 5 hours 30 minutes to correct them to IST
- Updates both `created_at` and `updated_at` columns

## How to Fix

### Step 1: Check Current Status
Visit: `https://truckmitr.com/truckmitr-app/api/fix_call_logs_timestamps.php`

This shows:
- Current PHP and MySQL time
- List of records that need fixing
- Dry run mode (no changes made)

### Step 2: Fix the Timestamps
Visit: `https://truckmitr.com/truckmitr-app/api/fix_call_logs_timestamps.php?fix=yes`

This will:
- Update all wrong timestamps
- Add 5.5 hours to UTC timestamps
- Show summary of fixed records

### Step 3: Verify
1. Check the database - timestamps should now show IST time
2. Create a new call log - should insert with correct IST time
3. Check the app - times should display correctly

## Technical Details

### MySQL Timezone Setting
```sql
SET time_zone = '+05:30'
```

This tells MySQL:
- `NOW()` returns IST time
- `CURRENT_TIMESTAMP` uses IST
- New inserts use IST
- Existing data is read as-is (no conversion)

### Timestamp Correction Formula
```php
$correctedTime = $originalTime + (5 hours * 3600 seconds) + (30 minutes * 60 seconds)
$correctedTime = $originalTime + 19800 seconds
```

### Detection Logic
Records are considered "wrong" if:
- Created in last 7 days
- 4-10 hours behind current time
- (Indicates UTC instead of IST)

## Prevention

With the timezone setting back in place:
- ✅ New records insert with IST time
- ✅ Existing records read correctly
- ✅ No double conversion
- ✅ Consistent timestamps across all tables

## Testing

### Test New Inserts
1. Submit a call feedback now
2. Check database immediately
3. Time should match current IST time

### Test Reads
1. View call history in app
2. Times should display correctly
3. No future timestamps

### Test Old Records
1. After running fix script
2. Old records should show correct IST time
3. No 6-hour difference

## Notes

- Script only fixes last 7 days (can be adjusted)
- Dry run mode by default (safe to test)
- Only fixes records that are clearly wrong
- Skips records that are already correct
