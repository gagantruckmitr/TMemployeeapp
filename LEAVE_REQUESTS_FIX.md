# Leave Requests Not Showing in Manager Dashboard - FIX

## Issue
Telecallers can apply for leave, but the leave requests are not showing in the manager's dashboard.

## Root Causes Identified

### 1. Manager ID Not Passed to API
The Flutter app was calling `getAllLeaveRequests()` without passing the manager ID, but the API required it.

### 2. API Required Manager ID
The `getLeaveRequestsForApproval` function in the API was returning an error if manager_id was not provided.

## Fixes Applied

### 1. Updated Flutter App (lib/features/manager/screens/leave_approval_screen.dart)
```dart
// Now passes the current user's ID as manager_id
final response = await ApiService.getAllLeaveRequests(
  managerId: currentUser.id.toString(),
);
```

### 2. Updated API (api/enhanced_leave_management_api.php)
Made the `getLeaveRequestsForApproval` function more flexible:
- Manager ID is now optional
- If provided, filters by that manager's team
- If not provided, shows all leave requests
- Added telecaller_name to the SELECT query
- Changed ORDER BY to DESC (newest first)

## Testing

Run this command to test:
```bash
php api/test_leave_requests.php
```

This will show:
1. Leave requests table structure
2. Total number of leave requests
3. Recent leave requests with details
4. Telecaller-manager relationships
5. API endpoint to test

## Verification Steps

1. **Check if telecallers have manager_id set:**
   ```sql
   SELECT id, name, role, manager_id FROM admins WHERE role = 'telecaller';
   ```

2. **Check existing leave requests:**
   ```sql
   SELECT lr.*, a.name as telecaller_name, a.manager_id 
   FROM leave_requests lr
   LEFT JOIN admins a ON lr.telecaller_id = a.id
   ORDER BY lr.created_at DESC;
   ```

3. **Test API directly:**
   ```
   http://localhost/truckmitr/api/enhanced_leave_management_api.php?action=get_leave_requests_for_approval&manager_id=1
   ```

## Additional Notes

- Telecallers must have a `manager_id` set in the `admins` table for the filtering to work
- If manager_id is NULL for telecallers, they won't appear in any manager's dashboard
- The API now gracefully handles missing manager_id and shows all requests

## Status
✓ Flutter app updated to pass manager ID
✓ API updated to handle manager ID properly
✓ Test script created for verification
