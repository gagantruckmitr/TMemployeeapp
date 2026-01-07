# Elechamps API - Quick Start Guide

## What is Elechamps API?

The Elechamps API provides access to users assigned to specific telecallers (admins). It's now integrated into the Smart Calling screen to give telecallers more leads to call.

## Quick Test

**Test the API directly:**
```
https://truckmitr.com/api/test_elechamps_api.php?admin_id=8
```

Replace `8` with your admin ID.

## Integration Points

### 1. Smart Calling Screen
- **Location**: `lib/features/telecaller/smart_calling_page.dart`
- **What it does**: Automatically fetches elechamps leads when loading drivers
- **User experience**: Telecallers see more leads without any extra action

### 2. API Service
- **Location**: `lib/core/services/api_service.dart`
- **Method**: `getElechampsLeads(adminId, limit)`
- **What it does**: Fetches and maps elechamps data to DriverContact model

### 3. Smart Calling Service
- **Location**: `lib/core/services/smart_calling_service.dart`
- **Method**: `getElechampsLeads(adminId, limit)`
- **What it does**: Convenience wrapper with error handling

## How to Use

### In Smart Calling Screen (Automatic)
Just open the Smart Calling screen - elechamps leads are fetched automatically!

### Programmatically
```dart
// Get current user
final currentUser = RealAuthService.instance.currentUser;

// Fetch elechamps leads
final leads = await SmartCallingService.instance.getElechampsLeads(
  adminId: currentUser.id,
  limit: 50,
);

print('Fetched ${leads.length} elechamps leads');
```

## API Response Structure

```json
{
  "status": "success",
  "admin_id": 8,
  "admin_name": "Sonam",
  "assigned_user_count": 173,
  "users": [...]
}
```

## Key Features

✅ **Automatic Integration** - Works seamlessly with existing Smart Calling
✅ **Duplicate Prevention** - Merges with today's leads, removes duplicates
✅ **Error Resilient** - Falls back gracefully if API fails
✅ **Profile Completion** - Shows profile completion percentage
✅ **Pagination Support** - Handles paginated responses
✅ **State Info** - Displays user's state
✅ **Registration Date** - Shows when user registered

## Console Logs to Watch

When Smart Calling loads, you'll see:
```
🔵 [SmartCalling] Fetching elechamps leads for admin: 8
📊 API Status: success
📊 Total assigned users: 173
📊 Page 12 of 18
✅ Fetched 10 elechamps leads
🔵 [SmartCalling] Final count: 25 drivers (15 from today + 10 from elechamps)
```

## Troubleshooting

### No elechamps leads showing?
1. Check console for error messages
2. Verify admin ID is correct
3. Test API directly using test script
4. Check if user has assigned leads in elechamps

### Duplicate leads?
- The system automatically removes duplicates by user ID
- If you see duplicates, check the merge logic in `_loadDriversFromLiveAPI()`

### API timeout?
- Default timeout is 30 seconds
- Check network connection
- Verify API endpoint is accessible

## Files Modified

1. `lib/core/services/api_service.dart` - Added elechamps API methods
2. `lib/core/services/smart_calling_service.dart` - Added convenience wrapper
3. `lib/features/telecaller/smart_calling_page.dart` - Integrated into loading logic
4. `api/test_elechamps_api.php` - Test script for API verification

## Next Steps

- Monitor console logs during testing
- Verify lead counts match expectations
- Test calling functionality with elechamps leads
- Check profile completion displays correctly
- Verify no performance issues with merged data

## Support

For issues or questions:
1. Check console logs for detailed error messages
2. Test API endpoint directly
3. Verify admin ID and permissions
4. Review integration documentation
