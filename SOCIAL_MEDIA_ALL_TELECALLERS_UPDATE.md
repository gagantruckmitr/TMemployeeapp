# Social Media Access - All Telecallers Update

## Summary
Updated the social media leads feature to allow **ALL telecallers** to access social media leads, with each telecaller only seeing leads assigned to them.

## What Changed

### Before:
- ❌ Only telecallers with `tc_for = 'social-media'` could access social media leads
- ❌ Limited flexibility in assigning social media work

### After:
- ✅ **ALL telecallers** can access social media leads (match-making, welcome-call, etc.)
- ✅ Each telecaller only sees leads where `assigned_id` matches their admin ID
- ✅ Maximum flexibility in workload distribution

## Files Modified

1. **`api/social-media-leads.php`**
   - Removed `tc_for = 'social-media'` restriction
   - Kept `assigned_id` filtering for data isolation

2. **`api/social_media_feedback_api.php`**
   - Removed `tc_for = 'social-media'` restriction for feedback submission
   - Fixed table name from `admin` to `admins`

3. **`lib/features/telecaller/social_media/social_media_screen.dart`**
   - Removed `tc_for` check in access logic
   - Simplified access flow

## How It Works Now

```
┌─────────────────────────────────────────────────────────────┐
│                    Social Media Leads                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Telecaller A (match-making)                                │
│  ├─ Can see: Leads where assigned_id = A's admin ID        │
│  └─ Cannot see: Leads assigned to other telecallers        │
│                                                              │
│  Telecaller B (welcome-call)                                │
│  ├─ Can see: Leads where assigned_id = B's admin ID        │
│  └─ Cannot see: Leads assigned to other telecallers        │
│                                                              │
│  Telecaller C (any tc_for value)                           │
│  ├─ Can see: Leads where assigned_id = C's admin ID        │
│  └─ Cannot see: Leads assigned to other telecallers        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Assignment Example

```sql
-- Assign social media leads to different telecaller types

-- Assign to match-making telecaller (ID: 4)
UPDATE social_media_leads SET assigned_id = 4 WHERE id IN (1, 2, 3);

-- Assign to welcome-call telecaller (ID: 8)
UPDATE social_media_leads SET assigned_id = 8 WHERE id IN (4, 5, 6);

-- Assign to any other telecaller (ID: 10)
UPDATE social_media_leads SET assigned_id = 10 WHERE id IN (7, 8, 9);
```

## Testing

Run the test to verify all telecaller types can access:

```bash
php api/test_all_telecallers_social_media.php
```

**Expected Results:**
- ✅ Telecallers with `tc_for = 'match-making'` can access their assigned social media leads
- ✅ Telecallers with `tc_for = 'welcome-call'` can access their assigned social media leads
- ✅ Telecallers with any `tc_for` value can access their assigned social media leads
- ✅ Each telecaller only sees their own assigned leads
- ✅ No cross-contamination between telecallers

## Benefits

1. **Flexibility**: Assign social media leads to any available telecaller
2. **Load Balancing**: Distribute social media work across the entire team
3. **Efficiency**: No need to wait for specific "social-media" telecallers
4. **Security**: Data isolation maintained through `assigned_id` filtering
5. **Scalability**: Easy to scale social media operations with existing team

## No Action Required

- ✅ No app reinstall needed
- ✅ No database migration needed
- ✅ Works with existing `assigned_id` field
- ✅ Backward compatible with existing assignments

## Quick Test

1. Assign a social media lead to any telecaller:
   ```sql
   UPDATE social_media_leads SET assigned_id = [telecaller_admin_id] WHERE id = [lead_id];
   ```

2. Login as that telecaller in the app

3. Navigate to Social Media Leads screen

4. Verify the assigned lead appears

5. Verify other telecallers' leads don't appear

## Support

If you encounter any issues:
- Check that `assigned_id` is set correctly in the database
- Verify the telecaller is logged in with correct credentials
- Run the test script to verify system integrity
- Check API logs for any errors
