# Social Media Lead Assignment Filter Implementation

## Overview
Modified the social media leads feature to allow **ALL telecallers** to access social media leads, but each telecaller can only see leads that are assigned to them specifically (filtered by `assigned_id`).

## Changes Made

### 1. API Changes (`api/social-media-leads.php`)

**Before:**
- Only telecallers with `tc_for = 'social-media'` could access social media leads
- All social media telecallers could see ALL social media leads
- No filtering by assignment

**After:**
- **ALL telecallers** (regardless of `tc_for` value) can access social media leads
- Removed `tc_for = 'social-media'` restriction
- Added filtering by `assigned_id` field in the `social_media_leads` table
- Each telecaller now only sees leads where `assigned_id` matches their admin ID
- Query now includes: `WHERE cl.id IS NULL AND sml.assigned_id = ?`

**Key Changes:**
```php
// REMOVED: tc_for = 'social-media' check
// All telecallers can now access social media leads

// Get the admin ID for filtering assigned leads
$adminId = $user['id'];

// Updated SQL query with assignment filter
$sql = "SELECT sml.* 
        FROM social_media_leads sml
        LEFT JOIN call_logs cl ON sml.mobile COLLATE utf8mb4_unicode_ci = cl.user_number COLLATE utf8mb4_unicode_ci
            AND cl.tc_for = 'social-media'
        WHERE cl.id IS NULL
            AND sml.assigned_id = ?  // NEW: Filter by assigned telecaller
        ORDER BY sml.created_at DESC 
        LIMIT 100";

// Use prepared statement for security
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $adminId);
$stmt->execute();
```

### 2. API Changes (`api/social_media_feedback_api.php`)

**Changes:**
- Removed `tc_for = 'social-media'` restriction for feedback submission
- All telecallers can now submit feedback for social media leads
- Corrected table name from `admin` to `admins` in authentication queries (2 occurrences)
- This ensures proper authentication checks work correctly

### 3. Flutter App Changes (`lib/features/telecaller/social_media/social_media_screen.dart`)

**Changes:**
- Removed `tc_for = 'social-media'` check in `_checkAccess()` method
- Simplified access logic - all telecallers can access the screen
- Updated access denied message to be more generic

### 4. Call History
- Call history already filtered by `caller_id`, so telecallers only see their own call logs
- No changes needed for history functionality

## How It Works

### Lead Assignment Flow:
1. **Authentication**: User logs in and their ID is retrieved
2. **Authorization**: All authenticated telecallers have access (no `tc_for` restriction)
3. **Assignment Filter**: API fetches only leads where `assigned_id` matches the user's admin ID
4. **Display**: Flutter app displays only the assigned leads

### Data Model:
```
social_media_leads table:
- id (primary key)
- assigned_id (foreign key to admins.id)
- name
- mobile
- source
- role
- remarks
- chat_date_time
- created_at
- updated_at
```

## Testing

Created comprehensive test files:
- `api/test_social_media_assigned_leads.php` - Basic assignment testing
- `api/test_social_media_assignment_complete.php` - Complete isolation testing
- `api/test_all_telecallers_social_media.php` - Test all telecaller types can access

### Test Results:
✅ **All telecallers** (regardless of `tc_for`) can access social media leads
✅ Assignment filtering works correctly
✅ Each telecaller only sees their assigned leads
✅ Call history properly filtered by caller_id
✅ Leads that have been called are excluded from active list
✅ No cross-contamination between telecallers
✅ Telecallers with different `tc_for` values (match-making, welcome-call, etc.) can all access their assigned social media leads

## Security Benefits

1. **Data Isolation**: Telecallers cannot access leads assigned to other team members
2. **Privacy**: Each telecaller's work is isolated and private
3. **Accountability**: Clear assignment tracking for performance monitoring
4. **Prepared Statements**: SQL injection protection with parameterized queries
5. **Universal Access**: All telecallers can handle social media leads when assigned, improving flexibility

## Frontend Impact

**No changes required** in the Flutter app:
- The `SocialMediaScreen` already uses the API correctly
- The `SocialMediaService` passes the user ID to the API
- The filtering happens transparently on the backend
- UI automatically shows only assigned leads

## Database Schema

The implementation relies on the existing `assigned_id` field in the `social_media_leads` table:

```sql
-- Example lead assignment
UPDATE social_media_leads 
SET assigned_id = 18  -- Admin ID of the telecaller
WHERE id = 5;
```

## Usage

### For Administrators:
To assign leads to telecallers, update the `assigned_id` field:

```sql
-- Assign lead to telecaller with admin ID 18
UPDATE social_media_leads 
SET assigned_id = 18 
WHERE id IN (3, 4, 5);
```

### For Telecallers:
- Simply open the Social Media Leads screen
- Only leads assigned to them will appear
- Call history shows only their own calls
- No configuration needed

## API Endpoints

### Get Assigned Leads
```
GET /api/social-media-leads.php?action=get_social_media_leads&user_id={user_id}
```

**Response:**
```json
{
  "success": true,
  "message": "Social media leads fetched successfully.",
  "data": [
    {
      "id": 5,
      "assigned_id": 18,
      "name": "Pradumn Dubey",
      "mobile": "9998361474",
      "source": "Instagram",
      "role": "driver",
      "remarks": null,
      "chat_date_time": "2024-01-15 10:30:00",
      "created_at": "2024-01-15 10:30:00",
      "updated_at": "2024-01-15 10:30:00"
    }
  ],
  "debug": {
    "query_used": "LEFT JOIN with COLLATE and assigned_id filter",
    "total_leads": 1,
    "admin_id": 18
  }
}
```

### Get Call History
```
GET /api/social_media_feedback_api.php?action=get_history&caller_id={caller_id}
```

**Response:**
```json
{
  "success": true,
  "message": "History fetched successfully",
  "data": [
    {
      "id": 123,
      "caller_id": 18,
      "tc_for": "social-media",
      "driver_name": "Pradumn Dubey",
      "user_number": "9998361474",
      "feedback": "Connected",
      "remarks": "Interested in registration",
      "created_at": "2024-01-15 11:00:00"
    }
  ]
}
```

## Deployment

No special deployment steps required:
1. Deploy updated `api/social-media-leads.php`
2. Deploy updated `api/social_media_feedback_api.php`
3. Ensure `assigned_id` field exists in `social_media_leads` table
4. Assign leads to telecallers using admin panel or SQL

## Verification

To verify the implementation is working:

```bash
# Run the comprehensive test for all telecaller types
php api/test_all_telecallers_social_media.php

# Expected output:
# ✅ All telecallers (regardless of tc_for) can access social media leads
# ✅ Each telecaller only sees leads assigned to them (assigned_id filter)
# ✅ Assignment isolation is maintained
# ✅ No tc_for restriction on social media access

# Or run the complete assignment test
php api/test_social_media_assignment_complete.php
```

## Notes

- **All telecallers** can access social media leads, regardless of their `tc_for` value
- The `assigned_id` field must be populated for leads to appear for telecallers
- Leads with `assigned_id = 0` or `NULL` will not appear for any telecaller
- Call logs are automatically created when feedback is submitted
- Once a lead is called, it moves to history and is removed from the active list
- This allows flexible assignment - you can assign social media leads to any telecaller (match-making, welcome-call, etc.)

## Example Use Cases

1. **Match-Making Telecaller**: Can be assigned social media leads and will see them in the Social Media screen
2. **Welcome-Call Telecaller**: Can be assigned social media leads and will see them in the Social Media screen
3. **Any Telecaller**: Can handle social media leads when assigned, providing maximum flexibility in workload distribution
