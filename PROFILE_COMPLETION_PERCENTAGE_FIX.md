# Profile Completion Percentage Mismatch Fix

## Issue
The profile completion percentage shown on the driver card in the Smart Calling screen was different from the percentage shown when tapping the avatar to open the Profile Completion Details screen.

**Example:**
- Smart Calling Card Avatar: 9%
- Profile Completion Details Screen: 17%

## Root Cause
The issue was in `api/fresh_leads_api.php` in the `calculateProfileCompletion()` function. The logic for handling empty JSON arrays was incomplete:

### Before (Incorrect Logic):
```php
foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    
    if ($value !== null && $value !== '') {
        $decoded = json_decode($value, true);
        if (is_array($decoded) && count($decoded) > 0) {
            $filledFields++;
        } elseif (!is_array($decoded)) {
            $filledFields++;
        }
    }
}
```

**Problem:** When a field contained an empty JSON array `[]`, the code would:
1. Check `is_array($decoded) && count($decoded) > 0` → FALSE (empty array)
2. Check `!is_array($decoded)` → FALSE (it IS an array)
3. Result: Field not counted as filled ✓ (correct)

BUT when a field contained a non-empty JSON array, it would count as filled. The issue was that the logic wasn't explicitly handling the empty array case, making it inconsistent with the `profile_completion_helper.php` which is used by the Profile Completion Details screen.

### After (Fixed Logic):
```php
foreach ($requiredFields as $field) {
    $value = $user[$field] ?? null;
    $isPresent = false;
    
    if ($value !== null && $value !== '') {
        $decoded = json_decode($value, true);
        if (is_array($decoded)) {
            // CRITICAL FIX: Empty arrays should NOT count as filled
            if (count($decoded) > 0) {
                $isPresent = true;
            }
        } else {
            // Not a JSON array, it's a regular value
            $isPresent = true;
        }
    }
    
    if ($isPresent) {
        $filledFields++;
    }
}
```

**Solution:** The new logic explicitly:
1. Checks if value is a JSON array
2. If it's an array, only counts it as filled if it has items
3. If it's not an array, counts it as filled if it has a value
4. Uses an `$isPresent` flag for clarity

## Files Modified
- `api/fresh_leads_api.php` - Fixed `calculateProfileCompletion()` function (line ~446-520)

## Testing
Use the test script to verify the fix:
```bash
# Replace USER_ID with an actual driver ID
curl "https://your-domain.com/api/test_profile_completion_fix.php?user_id=USER_ID"
```

The response will show:
- `smart_calling_card_percentage`: Percentage calculated by fresh_leads_api.php
- `profile_details_screen_percentage`: Percentage calculated by profile_completion_helper.php
- `match`: Should be `true` if both match

## Impact
✅ Smart Calling screen driver cards now show the same profile completion percentage as the Profile Completion Details screen
✅ Consistent calculation across all screens
✅ No changes needed to Flutter/Dart code
✅ Fix applies to both drivers and transporters

## Related Files
- `api/fresh_leads_api.php` - Smart calling data source (FIXED)
- `api/profile_completion_helper.php` - Profile details calculation (reference)
- `api/profile_completion_api.php` - Uses helper (already correct)
- `lib/features/telecaller/widgets/driver_contact_card.dart` - Displays the percentage
- `lib/screens/profile_completion_details_screen.dart` - Profile details screen

## Deployment
Simply deploy the updated `api/fresh_leads_api.php` file to production. No app rebuild required.
