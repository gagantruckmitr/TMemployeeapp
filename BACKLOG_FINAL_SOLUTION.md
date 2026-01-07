# Backlog Telecaller Filter - Final Solution

## Problem
- Telehead API returns ALL backlog leads (148 total) regardless of telecaller
- KPI shows total count instead of telecaller-specific count
- Backlog screen shows leads from all telecallers

## Root Cause
The telehead API (`https://truckmitr.com/api/telehead/backlog-leads`) does NOT filter by telecaller automatically. It returns all backlog leads across all telecallers.

## Solution
Created a wrapper API that:
1. Fetches ALL pages from telehead API
2. Filters leads by `assigned_to` field in local database
3. Returns only leads assigned to the logged-in telecaller
4. Enhances leads with call history, jobs, training info

## Implementation

### API Endpoint
**File**: `api/backlog_by_telecaller.php`

**URL**: `https://truckmitr.com/api/backlog_by_telecaller.php?caller_id=3`

**Features**:
- Fetches all pages from telehead API (handles pagination automatically)
- Filters by `assigned_to` field in users table
- Adds call history, jobs, training info to each lead
- Returns exact count for the telecaller

### Flutter Integration

**Backlog Screen**: `lib/features/telecaller/screens/backlog_screen.dart`
```dart
final url = '${ApiConfig.baseUrl}/backlog_by_telecaller.php?caller_id=$callerId';
```

**KPI Service**: `lib/core/services/telecaller_service.dart`
```dart
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/backlog_by_telecaller.php?caller_id=$callerId'),
  headers: {'Authorization': 'Bearer $token'},
);
return data['total_backlog'] ?? 0;
```

## API Response
```json
{
  "status": true,
  "total_backlog": 5,
  "filtered_by_telecaller": 3,
  "data": [
    {
      "id": 178,
      "name": "Sanjay Singh Tomar",
      "role": "driver",
      "mobile": "9876543210",
      "call_history": [...],
      "applied_jobs": [...],
      "training_info": {...}
    }
  ]
}
```

## Deployment

### 1. Upload API File
Upload `api/backlog_by_telecaller.php` to server:
```bash
scp api/backlog_by_telecaller.php user@truckmitr.com:/var/www/html/api/
```

### 2. Test API
```bash
curl -X GET "https://truckmitr.com/api/backlog_by_telecaller.php?caller_id=3" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Rebuild Flutter App
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## How It Works

1. **User logs in** → Gets bearer token with caller_id
2. **Dashboard loads** → Calls `backlog_by_telecaller.php?caller_id=3`
3. **API fetches** → Gets all pages from telehead API
4. **API filters** → Checks `assigned_to` field in database
5. **API returns** → Only leads assigned to caller_id=3
6. **KPI shows** → Exact count for this telecaller
7. **Screen displays** → Only assigned leads

## Database Schema
```sql
-- Users table has assigned_to field
ALTER TABLE users ADD COLUMN assigned_to INT(11) DEFAULT NULL;

-- Check assignments
SELECT assigned_to, COUNT(*) 
FROM users 
WHERE assigned_to IS NOT NULL 
GROUP BY assigned_to;
```

## Testing Results

### Pooja (caller_id=3)
- Total users assigned: 405
- Backlog leads: Depends on callback_later status
- API filters correctly by assigned_to=3

### Expected Behavior
✅ KPI shows only Pooja's backlog count
✅ Backlog screen shows only Pooja's leads
✅ Count matches between KPI and screen
✅ No leads from other telecallers visible

## Notes
- Telehead API pagination: 20 leads per page
- Wrapper fetches ALL pages automatically
- Local filtering ensures correct telecaller assignment
- Enhanced data includes call history, jobs, training
