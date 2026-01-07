# Fresh Leads & Backlog Persistence Fix

## Problem
After submitting feedback for a lead in Fresh Leads or Backlog screens:
- Lead would disappear temporarily
- After refreshing or reopening the app, the same lead would reappear
- This happened because the backend APIs didn't filter out leads with feedback

## Solution

### Backend Changes

#### 1. New API: `get_called_leads.php`
- Returns list of lead IDs that have been called with feedback
- Used by Fresh Leads screen to filter out already-called leads
- Checks `call_logs` table for entries with non-empty feedback

#### 2. Updated: `backlog_by_telecaller.php`
- Now filters out leads where callback has been completed
- Checks if a lead has been called AFTER the callback was scheduled
- Excludes these completed callbacks from the backlog list

### Frontend Changes

#### 1. Updated: `today_leads_service.dart`
- Added `_getCalledLeadIds()` method to fetch already-called lead IDs
- Filters out these leads before returning to the UI
- Ensures leads with feedback don't show up in Fresh Leads

#### 2. Updated: `fresh_leads_screen.dart`
- Removed in-memory tracking (no longer needed)
- Backend now handles filtering automatically
- Leads with feedback are permanently filtered out

#### 3. Updated: `backlog_screen.dart`
- Removed in-memory tracking (no longer needed)
- Backend filters out completed callbacks automatically
- Leads that have been called after callback are excluded

## How It Works

### Fresh Leads Flow
1. User submits feedback for a lead
2. Feedback is saved to `call_logs` table
3. Lead is removed from UI immediately
4. On next refresh/app restart:
   - `get_called_leads.php` returns IDs of all called leads
   - `today_leads_service.dart` filters these out
   - Lead doesn't reappear in Fresh Leads

### Backlog Flow
1. User submits feedback for a callback lead
2. Feedback is saved to `call_logs` table
3. Lead is removed from UI immediately
4. On next refresh/app restart:
   - `backlog_by_telecaller.php` checks for completed callbacks
   - Excludes leads that have been called after callback was scheduled
   - Lead doesn't reappear in Backlog

## Database Query Logic

### Fresh Leads Filter
```sql
SELECT DISTINCT user_id 
FROM call_logs 
WHERE caller_id = :caller_id 
AND user_id IS NOT NULL 
AND user_id > 0
AND feedback IS NOT NULL
AND feedback != ''
```

### Backlog Filter
```sql
SELECT DISTINCT cl1.user_id
FROM call_logs cl1
WHERE cl1.caller_id = :caller_id
AND cl1.call_status IN ('callback', 'callback_later')
AND EXISTS (
    SELECT 1 FROM call_logs cl2
    WHERE cl2.user_id = cl1.user_id
    AND cl2.caller_id = cl1.caller_id
    AND cl2.created_at > cl1.created_at
    AND cl2.feedback IS NOT NULL
    AND cl2.feedback != ''
)
```

## Testing

1. **Fresh Leads Test:**
   - Call a fresh lead and submit feedback
   - Lead should disappear immediately
   - Close and reopen app
   - Lead should NOT reappear in Fresh Leads

2. **Backlog Test:**
   - Call a backlog lead and submit feedback
   - Lead should disappear immediately
   - Close and reopen app
   - Lead should NOT reappear in Backlog

## Files Modified

### Backend
- `api/get_called_leads.php` (NEW)
- `api/backlog_by_telecaller.php` (UPDATED)

### Frontend
- `lib/core/services/today_leads_service.dart` (UPDATED)
- `lib/features/telecaller/screens/fresh_leads_screen.dart` (UPDATED)
- `lib/features/telecaller/screens/backlog_screen.dart` (UPDATED)

## Benefits

✅ Leads with feedback don't reappear after app restart
✅ Backend handles filtering (more reliable than client-side)
✅ Works across app sessions and devices
✅ No duplicate calls to the same lead
✅ Cleaner UI experience for telecallers
