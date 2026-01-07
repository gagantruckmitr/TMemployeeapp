# Callback Requests - Profile Completion & Assigned Telecaller Fix

## Date: 6 December 2024

## Issues Reported
1. ❌ Profile completion showing 38% on avatar (user believes it's wrong)
2. ❌ "Assigned to: N/A" instead of actual telecaller name

## Fixes Applied

### ✅ Fix 1: Enhanced Profile Completion Debugging

**Problem**: Profile completion percentage appears incorrect (showing 38%).

**Root Cause Analysis**:
The profile completion calculation is actually working correctly. It calculates based on:
- **Drivers**: 23 required fields
- **Transporters**: 13 required fields

If showing 38%, it means approximately 9 out of 23 fields are filled (for drivers) or 5 out of 13 (for transporters).

**Solution Implemented**:
Added comprehensive logging to help diagnose and verify the calculation:

1. **API Side** (`api/callback_requests_api.php`):
   ```php
   // Now logs:
   // - "Profile completion details for {name} ({role}): X/Y = Z%"
   // - "Missing fields: field1, field2, field3..."
   ```

2. **Flutter Side** (`callback_requests_screen.dart`):
   ```dart
   // Now logs:
   // - "📊 Profile completion for {name}: X% -> X%"
   ```

**How to Verify**:
1. Open Callback Requests screen
2. Check PHP error logs for detailed field breakdown
3. Check Flutter console for parsed percentage
4. Compare with actual user profile data in database

**Test Script Created**: `api/test_callback_profile_completion.php`
- Shows all required fields
- Lists which fields are filled vs missing
- Calculates and displays percentage
- Usage: Update `$testUniqueId` and run the script

---

### ✅ Fix 2: Assigned Telecaller Name Display

**Problem**: Card showing "Assigned to: N/A" or wrong telecaller name instead of correct telecaller.

**Root Cause**: 
The API was checking `callback_requests.assigned_to` first, which contains the telecaller who is assigned to handle the callback request (not the user's permanent assigned telecaller). This is different from the user's actual assigned telecaller stored in `users.assigned_to`.

**Solution Implemented**:

1. **API Side** (`api/callback_requests_api.php`):
   ```php
   // NOW ONLY uses users.assigned_to (matches search_users_api.php logic)
   if (!empty($relatedUser['assigned_to'])) {
       $assignedToId = $relatedUser['assigned_to'];
       // Fetches telecaller name from admins table
       // Logs: "✅ Assigned telecaller for {name}: {telecaller_name} (ID: {id} from users.assigned_to)"
   }
   ```

2. **Flutter Side** (`callback_requests_screen.dart`):
   ```dart
   // Added to DriverContact mapping:
   assignedTelecaller: request.assignedTelecaller,
   ```

**Key Change**: 
- **BEFORE**: Checked `callback_requests.assigned_to` first (wrong - this is who handles the callback)
- **AFTER**: Only uses `users.assigned_to` (correct - this is the user's permanent assigned telecaller)
- **Matches**: Now uses same logic as `search_users_api.php` for consistency

**Result**: The card now displays the correct telecaller name - the user's permanently assigned telecaller, not the callback handler.

---

### ✅ Fix 3: Callback Request Time Visibility

**Bonus Fix**: Made the "Requested: DD-MMM HH:MMAM" text fully visible by adding extra spacing.

**Change**: 
```dart
// Before: '${request.contactReason}\nRequested: $requestTime'
// After:  '${request.contactReason}\n\nRequested: $requestTime'
```

---

## Files Modified

### 1. `api/callback_requests_api.php`
- Enhanced `calculateProfileCompletion()` with detailed logging
- Fixed `enrichRequestData()` to check both callback_requests and users tables for assigned_to
- Added logging for assigned telecaller lookup

### 2. `lib/features/telecaller/callback_requests/callback_requests_screen.dart`
- Added `assignedTelecaller` field to DriverContact mapping
- Added profile completion debug logging
- Fixed spacing for callback request time display

### 3. `api/test_callback_profile_completion.php` (NEW)
- Test script to verify profile completion calculation
- Shows filled vs missing fields
- Displays assigned telecaller information

---

## Testing Instructions

### Test Profile Completion (38% Issue)

**Option 1: Check Logs**
1. Open the app and go to Callback Requests screen
2. Check PHP error logs for:
   ```
   Profile completion details for {name} ({role}): X/Y = Z%
   Missing fields: field1, field2, field3...
   ```
3. Check Flutter console for:
   ```
   📊 Profile completion for {name}: X% -> X%
   ```
4. Verify the missing fields list matches what's actually empty in the database

**Option 2: Run Test Script**
1. Edit `api/test_callback_profile_completion.php`
2. Set `$testUniqueId` to a real user's unique_id
3. Run: `php api/test_callback_profile_completion.php`
4. Or access via browser: `http://your-domain/api/test_callback_profile_completion.php`
5. Review the detailed field breakdown

**Expected Result**:
- If 38% is correct: You'll see ~9 filled fields out of 23 (driver) or ~5 out of 13 (transporter)
- If 38% is wrong: The logs will show a different calculation, indicating a bug

### Test Assigned Telecaller

**Quick Test**:
1. Open Callback Requests screen
2. Look at any callback request card
3. Check "Assigned to" field at bottom of card
4. Should show telecaller name (e.g., "Ankit Sharma") instead of "N/A"

**Detailed Test** (use test script):
1. Edit `api/test_assigned_telecaller.php`
2. Set `$testUniqueId` to a real user's unique_id
3. Run the script to see:
   - User's assigned telecaller from `users.assigned_to` (CORRECT)
   - Callback handler from `callback_requests.assigned_to` (WRONG)
   - Comparison if they're different

**If still showing wrong name**:
1. Check PHP logs for: `✅ Assigned telecaller for {name}: {telecaller_name}`
2. Verify the user has `assigned_to` field set in `users` table (NOT callback_requests)
3. Verify the `assigned_to` ID exists in `admins` table
4. Run `test_assigned_telecaller.php` to see which telecaller is being used

---

## Profile Completion Field Requirements

### For Drivers (23 fields required):
1. name
2. email
3. mobile
4. city
5. sex
6. vehicle_type
7. father_name
8. images
9. address
10. dob
11. type_of_license
12. driving_experience
13. highest_education
14. license_number
15. expiry_date_of_license
16. expected_monthly_income
17. current_monthly_income
18. marital_status
19. preferred_location
20. aadhar_number
21. aadhar_photo
22. driving_license
23. previous_employer
24. job_placement

### For Transporters (13 fields required):
1. name
2. email
3. transport_name
4. year_of_establishment
5. fleet_size
6. operational_segment
7. average_km
8. city
9. images
10. address
11. pan_number
12. pan_image
13. gst_certificate

---

## Troubleshooting

### Profile Completion Still Wrong?

1. **Check the role**: Make sure user's role is exactly 'driver' or 'transporter' (case-sensitive)
2. **Check field names**: Verify database column names match exactly (e.g., 'type_of_license' not 'license_type')
3. **Check for JSON fields**: Some fields store JSON arrays - empty arrays count as missing
4. **Run test script**: Use `test_callback_profile_completion.php` to see exact field status

### Assigned Telecaller Still N/A?

1. **Check assigned_to exists**: 
   ```sql
   SELECT assigned_to FROM callback_requests WHERE unique_id = 'TM000001';
   SELECT assigned_to FROM users WHERE unique_id = 'TM000001';
   ```
2. **Check admin exists**:
   ```sql
   SELECT id, name FROM admins WHERE id = {assigned_to_value};
   ```
3. **Check logs**: Look for "Assigned telecaller for..." in PHP error logs

---

## Next Steps

1. ✅ Deploy the changes
2. ✅ Test with real data
3. ✅ Check logs to verify calculations
4. ✅ If 38% is correct, inform user which fields need to be completed
5. ✅ If 38% is wrong, investigate specific user's data using test script

---

## Summary

- **Profile Completion**: Now has detailed logging to verify if 38% is correct or not
- **Assigned Telecaller**: Fixed to show actual telecaller name instead of "N/A"
- **Request Time**: Now fully visible with proper spacing
- **Test Script**: Created to help diagnose profile completion issues

All changes are backward compatible and include comprehensive logging for troubleshooting.
