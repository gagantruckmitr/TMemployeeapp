# Backlog - Direct Telehead API Integration

## Solution
Using telehead API directly without any wrapper or filtering layer.

## API Endpoint
```
https://truckmitr.com/api/telehead/backlog-leads
```

### Authentication
- Bearer token in Authorization header
- Token automatically identifies the telecaller
- API returns only backlog leads for that telecaller

### Pagination
- Use `?page=1`, `?page=2`, etc. for pagination
- Response includes:
  - `total_backlog`: Total count across all pages
  - `current_page`: Current page number
  - `last_page`: Total number of pages
  - `data`: Array of leads (20 per page)

## Implementation

### 1. Backlog Screen
**File**: `lib/features/telecaller/screens/backlog_screen.dart`

```dart
// Direct telehead API call
final url = 'https://truckmitr.com/api/telehead/backlog-leads';
final response = await http.get(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
```

### 2. KPI Count
**File**: `lib/core/services/telecaller_service.dart`

```dart
// Get count from telehead API
final response = await http.get(
  Uri.parse('https://truckmitr.com/api/telehead/backlog-leads'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);

// Use total_backlog field
return data['total_backlog'] ?? 0;
```

## Response Structure
```json
{
  "status": true,
  "total_backlog": 148,
  "current_page": 1,
  "last_page": 8,
  "data": [
    {
      "id": 20678,
      "name": "Pritesh",
      "role": "transporter",
      "mobile": "9876543210",
      ...
    }
  ]
}
```

## Key Points
✅ No wrapper API needed
✅ Telehead API handles telecaller filtering automatically
✅ Bearer token identifies the telecaller
✅ KPI shows exact `total_backlog` count
✅ Screen shows leads from current page
✅ Pagination supported with `?page=N` parameter

## Testing
```bash
# Test with Pooja's token (caller_id=3)
curl -X GET "https://truckmitr.com/api/telehead/backlog-leads" \
  -H "Authorization: Bearer 84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90"

# Test page 2
curl -X GET "https://truckmitr.com/api/telehead/backlog-leads?page=2" \
  -H "Authorization: Bearer 84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90"
```

## Result
- KPI displays the exact total_backlog count from telehead API
- Backlog screen shows only leads for the logged-in telecaller
- Pooja (caller_id=3) sees only her assigned backlog leads
- Count matches between KPI and screen
