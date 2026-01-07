# Callback Requests - Display Fixes

## Date: 6 December 2024

## Issues Fixed

### 1. Callback Request Time Not Fully Visible ✅
**Problem**: The "Requested: 22-Nov 01:28AM" text was being cut off and not fully visible on the card.

**Solution**: Added extra line break (`\n\n` instead of `\n`) between the reason and the requested time to give more vertical space.

**Files Modified**:
- `lib/features/telecaller/callback_requests/callback_requests_screen.dart`
  - Updated both requests list and history list to use `\n\n` for better spacing
  - Changed from: `'${request.contactReason}\nRequested: $requestTime'`
  - Changed to: `'${request.contactReason}\n\nRequested: $requestTime'`

**Result**: The full callback request timestamp is now clearly visible with proper spacing.

---

### 2. Profile Completion Percentage - Enhanced Logging ✅
**Problem**: User reported that profile completion percentage on avatar shows 38% but expected different value.

**Solution**: Added comprehensive debug logging to track profile completion calculation and identify missing fields:

**Files Modified**:
- `api/callback_requests_api.php`
  - Added detailed error_log showing:
    - Calculated profile completion percentage
    - Number of filled fields vs total required fields
    - List of missing fields for each user
  - Logs: "Profile completion details for {name} ({role}): X/Y = Z%"
  - Logs: "Missing fields: field1, field2, field3..."

- `lib/features/telecaller/callback_requests/callback_requests_screen.dart`
  - Added debugPrint to show received and parsed profile completion
  - Logs: "📊 Profile completion for {name}: X% -> X%"

**How to Diagnose**:
1. Open Callback Requests screen
2. Check server logs (PHP error log) for detailed field breakdown
3. Check Flutter console for parsed percentage
4. Compare missing fields with actual user profile data
5. If calculation is correct but percentage seems wrong, user may need to complete more profile fields

**How Profile Completion Works**:
1. API calculates percentage using `calculateProfileCompletion()` function
2. Returns as string with % sign (e.g., "75%")
3. Flutter parses using `ProfileCompletion.fromPercentageString()`
4. Removes % sign and converts to integer
5. Displays on avatar with color coding:
   - Red: < 50%
   - Orange: 50-79%
   - Green: 80%+

---

### 3. Assigned Telecaller Showing "N/A" ✅
**Problem**: The "Assigned to" field was showing "N/A" instead of the actual telecaller name.

**Solution**: Fixed the API to properly fetch telecaller name and updated Flutter to use the field.

**Files Modified**:
- `api/callback_requests_api.php`
  - Updated to check `callback_requests.assigned_to` first, then fallback to `users.assigned_to`
  - Added logging: "Assigned telecaller for {name}: {telecaller_name} (ID: {id})"
  - Fetches telecaller name from `admins` table using the assigned_to ID

- `lib/features/telecaller/callback_requests/callback_requests_screen.dart`
  - Added `assignedTelecaller: request.assignedTelecaller` to DriverContact mapping
  - Now properly passes the telecaller name from API to the contact card

**Result**: The card now displays the actual telecaller name instead of "N/A".

---

## Testing

### Test Callback Request Time Display
1. Open Callback Requests screen
2. Check both "Requests" and "History" tabs
3. Verify "Requested: DD-MMM HH:MMAM/PM" is fully visible below the reason
4. Confirm there's adequate spacing between reason and timestamp

### Test Profile Completion Percentage
1. Open Callback Requests screen
2. Check console/logs for profile completion debug messages
3. Compare displayed percentage on avatar with:
   - Actual user profile data in database
   - Calculated percentage in logs
4. Verify color coding matches percentage:
   - Red for low completion
   - Orange for medium completion
   - Green for high completion

---

## Technical Details

### Profile Completion Calculation (API)
Located in: `api/callback_requests_api.php`

**For Drivers** (23 required fields):
- name, email, mobile, city, sex, vehicle_type
- father_name, images, address, dob
- type_of_license, driving_experience, highest_education, license_number
- expiry_date_of_license, expected_monthly_income, current_monthly_income
- marital_status, preferred_location, aadhar_number, aadhar_photo
- driving_license, previous_employer, job_placement

**For Transporters** (13 required fields):
- name, email, transport_name, year_of_establishment
- fleet_size, operational_segment, average_km, city, images, address
- pan_number, pan_image, gst_certificate

Formula: `(filled_fields / total_fields) * 100`

### Profile Completion Display (Flutter)
Located in: `lib/features/telecaller/widgets/profile_completion_avatar.dart`

- Circular progress ring around avatar
- Percentage badge in top-right corner
- Color-coded based on completion level
- Tappable to view detailed profile completion page

---

## Summary of Changes

### API Changes (`api/callback_requests_api.php`)
1. **Profile Completion Logging**: Added detailed logging showing filled/missing fields
2. **Assigned Telecaller Fix**: Now checks callback_requests.assigned_to first, then users.assigned_to
3. **Enhanced Debugging**: All calculations now logged for troubleshooting

### Flutter Changes (`lib/features/telecaller/callback_requests/callback_requests_screen.dart`)
1. **Spacing Fix**: Added extra line break for callback request time visibility
2. **Assigned Telecaller**: Added assignedTelecaller field to DriverContact mapping
3. **Debug Logging**: Added profile completion percentage logging

## Files Changed
1. `lib/features/telecaller/callback_requests/callback_requests_screen.dart` - Spacing, assignedTelecaller, debug logs
2. `api/callback_requests_api.php` - Profile completion logging, assigned telecaller fix
3. `CALLBACK_REQUESTS_IVR_IMPLEMENTATION.md` - This documentation file

## What to Check Now

### For Profile Completion (38% issue):
1. Open the app and navigate to Callback Requests
2. Check PHP error logs for: "Profile completion details for {name}"
3. Review the "Missing fields" log to see which fields are empty
4. Verify if the user actually has those fields filled in the database
5. If fields are filled but not counted, check field names match exactly

### For Assigned Telecaller:
1. Open Callback Requests screen
2. Verify "Assigned to" shows actual telecaller name (not "N/A")
3. Check PHP logs for: "Assigned telecaller for {name}: {telecaller_name}"
4. If still showing N/A, verify callback_requests.assigned_to or users.assigned_to has valid admin ID
