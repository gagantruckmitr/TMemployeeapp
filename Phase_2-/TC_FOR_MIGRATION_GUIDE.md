# Match-Making Authentication Update Guide

## Overview
Updated the Phase 2 authentication system to use `match-making` (with hyphen) instead of `match_making` (with underscore) for the `tc_for` column.

## Changes Made

### 1. Authentication API Update
**File:** `api/phase2_auth_api.php`

Updated the login query to accept both formats for backward compatibility:
```sql
WHERE mobile = '$mobile' 
AND role = 'telecaller' 
AND (tc_for = 'match-making' OR tc_for = 'match_making')
```

This ensures existing users with `match_making` can still login while new users use `match-making`.

### 2. Migration Script
**File:** `api/update_tc_for_to_hyphen.php`

Created a migration script to update all existing records from `match_making` to `match-making`:
- Updates all telecaller records in the `admins` table
- Uses transaction for safety
- Returns affected rows and updated records
- Can be rolled back if needed

### 3. Test Script
**File:** `api/test_match_making_auth.php`

Created a comprehensive test script to verify:
- Current `tc_for` values in database
- Count of records with hyphen vs underscore
- Sample telecaller records
- Authentication query functionality
- Migration recommendations

## Migration Steps

### Step 1: Test Current State
```bash
# Check current tc_for values
curl http://your-domain.com/api/test_match_making_auth.php
```

### Step 2: Run Migration
```bash
# Update all match_making to match-making
curl http://your-domain.com/api/update_tc_for_to_hyphen.php
```

### Step 3: Verify Migration
```bash
# Verify all records updated
curl http://your-domain.com/api/test_match_making_auth.php
```

### Step 4: Test Login
Test login with a match-making telecaller account to ensure authentication works.

## Database Changes

### Before Migration
```
tc_for = 'match_making'
```

### After Migration
```
tc_for = 'match-making'
```

## App Behavior

### Flutter App (Phase 2)
- No code changes needed in the app
- The `tcFor` field in `Phase2User` model will automatically display the new value
- Profile screen will show "match-making" instead of "match_making"

### Authentication
- Login works with both formats during transition
- After migration, all users will have `match-making` format
- Backward compatibility maintained in auth query

## Files Modified

1. **api/phase2_auth_api.php** - Updated authentication query
2. **api/update_tc_for_to_hyphen.php** - New migration script
3. **api/test_match_making_auth.php** - New test script

## No Changes Needed

- Phase_2-/lib/models/phase2_user_model.dart (just displays the value)
- Phase_2-/lib/features/profile/profile_screen.dart (just displays the value)
- Phase_2-/lib/core/services/phase2_auth_service.dart (uses API response)

## Rollback Plan

If you need to rollback:

```sql
UPDATE admins 
SET tc_for = 'match_making' 
WHERE tc_for = 'match-making' 
AND role = 'telecaller';
```

## Notes

- The authentication API accepts both formats for smooth transition
- Migration is safe and uses database transactions
- No app updates required - just run the migration script
- All existing login credentials remain valid
- Profile display will automatically show the new format

## Testing Checklist

- [ ] Run test script to check current state
- [ ] Run migration script
- [ ] Verify all records updated
- [ ] Test login with match-making telecaller
- [ ] Check profile screen shows "match-making"
- [ ] Verify no authentication errors

## Support

If you encounter any issues:
1. Check the test script output
2. Verify database connection
3. Check API error logs
4. Use rollback SQL if needed
