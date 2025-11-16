# Call Logs API Documentation

Complete API documentation for `call_logs_api.php` based on actual database table structure.

## Base URL
```
http://127.0.0.1/api/call_logs_api.php
```

---

## Table Structure

The `call_logs` table has the following columns:

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint(20) UNSIGNED | Primary key (auto-increment) |
| `caller_id` | bigint(20) UNSIGNED | Telecaller ID from admins table |
| `tc_for` | varchar(100) | TC for field |
| `user_id` | bigint(20) UNSIGNED | Driver/User ID from users table |
| `driver_name` | varchar(255) | Driver name |
| `call_status` | enum | pending, connected, not_connected, busy, no_answer, callback, callback_later, not_reachable, not_interested, invalid, completed, failed, cancelled |
| `feedback` | text | Call feedback |
| `remarks` | text | Call remarks/notes from telecaller |
| `notes` | text | Additional notes |
| `call_duration` | int(11) | Call duration in seconds |
| `caller_number` | varchar(255) | Telecaller phone number |
| `user_number` | varchar(255) | Driver/User phone number |
| `call_time` | timestamp | Call timestamp |
| `reference_id` | varchar(255) | Reference ID (e.g., MyOperator) |
| `api_response` | longtext | API response JSON |
| `created_at` | timestamp | Record creation time |
| `updated_at` | timestamp | Record update time |
| `call_initiated_at` | datetime | When call was initiated |
| `call_completed_at` | datetime | When call was completed |
| `ip_address` | varchar(45) | IP address of caller |
| `recording_url` | varchar(500) | Call recording URL from MyOperator |
| `manual_call_recording_url` | varchar(500) | Manually uploaded recording URL |
| `myoperator_unique_id` | varchar(100) | MyOperator unique call ID |
| `webhook_data` | text | Full webhook JSON data |
| `call_start_time` | datetime | Actual call start time from MyOperator |
| `call_end_time` | datetime | Actual call end time from MyOperator |

---

## 1. Get Table Structure

**Method:** `GET`

**Endpoint:** `?action=get_table_structure`

**URL:**
```
http://127.0.0.1/api/call_logs_api.php?action=get_table_structure
```

**Response:**
```json
{
  "success": true,
  "columns": [
    {
      "Field": "id",
      "Type": "bigint(20) unsigned",
      "Null": "NO",
      "Key": "PRI",
      "Default": null,
      "Extra": "auto_increment"
    },
    ...
  ],
  "timestamp": "2024-11-20 10:30:00"
}
```

---

## 2. Insert Call Log

**Method:** `POST`

**Endpoint:** `?action=insert`

**URL:**
```
http://127.0.0.1/api/call_logs_api.php?action=insert
```

**Headers:**
```
Content-Type: application/json
```

**Body (Complete Example):**
```json
{
  "caller_id": 3,
  "tc_for": "driver_onboarding",
  "user_id": 13474,
  "driver_name": "John Doe",
  "call_status": "connected",
  "feedback": "Driver is interested in subscription",
  "remarks": "Will call back tomorrow",
  "notes": "Prefers morning calls",
  "call_duration": 120,
  "caller_number": "+917678361210",
  "user_number": "+919813117429",
  "call_time": "2024-11-20 10:30:00",
  "reference_id": "TM_1732147200_3_13474",
  "api_response": "{\"status\":\"success\",\"call_id\":\"12345\"}",
  "call_initiated_at": "2024-11-20 10:29:50",
  "call_completed_at": "2024-11-20 10:32:10",
  "ip_address": "192.168.1.100",
  "recording_url": "https://recordings.myoperator.co/call_12345.mp3",
  "manual_call_recording_url": null,
  "myoperator_unique_id": "MO_12345",
  "webhook_data": "{\"event\":\"call_completed\"}",
  "call_start_time": "2024-11-20 10:30:00",
  "call_end_time": "2024-11-20 10:32:00"
}
```

**Minimal Example:**
```json
{
  "caller_id": 3,
  "user_id": 13474,
  "user_number": "+919813117429"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Call log inserted successfully",
  "id": 123,
  "data": {
    "id": 123,
    "caller_id": 3,
    "user_id": 13474,
    "driver_name": "John Doe",
    "call_status": "connected",
    ...
  },
  "timestamp": "2024-11-20 10:30:00"
}
```

---

## 3. Get All Call Logs

**Method:** `GET`

**Endpoint:** `?action=get_all`

**URL:**
```
http://127.0.0.1/api/call_logs_api.php?action=get_all
```

**Query Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `limit` | integer | Number of records (default: 50) | `limit=20` |
| `offset` | integer | Pagination offset (default: 0) | `offset=0` |
| `caller_id` | integer | Filter by telecaller ID | `caller_id=3` |
| `user_id` | integer | Filter by driver/user ID | `user_id=13474` |
| `call_status` | string | Filter by status | `call_status=connected` |
| `tc_for` | string | Filter by tc_for | `tc_for=driver_onboarding` |
| `reference_id` | string | Filter by reference ID | `reference_id=TM_123` |
| `from_date` | datetime | Filter from date | `from_date=2024-11-01` |
| `to_date` | datetime | Filter to date | `to_date=2024-11-30` |

**Examples:**

Get all call logs:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all
```

Get call logs for specific telecaller:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all&caller_id=3
```

Get call logs for specific user:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all&user_id=13474
```

Get connected calls only:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all&call_status=connected
```

Get with pagination:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all&limit=10&offset=0
```

Get by date range:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all&from_date=2024-11-01&to_date=2024-11-30
```

Multiple filters:
```
http://127.0.0.1/api/call_logs_api.php?action=get_all&caller_id=3&call_status=connected&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "caller_id": 3,
      "tc_for": "driver_onboarding",
      "user_id": 13474,
      "driver_name": "John Doe",
      "call_status": "connected",
      "feedback": "Driver is interested",
      "remarks": "Will call back tomorrow",
      "notes": "Prefers morning calls",
      "call_duration": 120,
      "caller_number": "+917678361210",
      "user_number": "+919813117429",
      "call_time": "2024-11-20 10:30:00",
      "reference_id": "TM_1732147200_3_13474",
      "recording_url": "https://recordings.myoperator.co/call_12345.mp3",
      "user_name": "John Doe",
      "user_mobile": "9813117429",
      "caller_name": "Telecaller Name",
      "caller_mobile": "7678361210"
    }
  ],
  "count": 1,
  "total": 150,
  "limit": 50,
  "offset": 0,
  "timestamp": "2024-11-20 10:30:00"
}
```

---

## 4. Get Call Log by ID

**Method:** `GET`

**Endpoint:** `?action=get_by_id&id=123`

**URL:**
```
http://127.0.0.1/api/call_logs_api.php?action=get_by_id&id=123
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "caller_id": 3,
    "tc_for": "driver_onboarding",
    "user_id": 13474,
    "driver_name": "John Doe",
    "call_status": "connected",
    "feedback": "Driver is interested",
    "remarks": "Will call back tomorrow",
    "notes": "Prefers morning calls",
    "call_duration": 120,
    "caller_number": "+917678361210",
    "user_number": "+919813117429",
    "call_time": "2024-11-20 10:30:00",
    "reference_id": "TM_1732147200_3_13474",
    "api_response": "{\"status\":\"success\"}",
    "created_at": "2024-11-20 10:30:00",
    "updated_at": "2024-11-20 10:30:00",
    "call_initiated_at": "2024-11-20 10:29:50",
    "call_completed_at": "2024-11-20 10:32:10",
    "ip_address": "192.168.1.100",
    "recording_url": "https://recordings.myoperator.co/call_12345.mp3",
    "manual_call_recording_url": null,
    "myoperator_unique_id": "MO_12345",
    "webhook_data": "{\"event\":\"call_completed\"}",
    "call_start_time": "2024-11-20 10:30:00",
    "call_end_time": "2024-11-20 10:32:00",
    "user_name": "John Doe",
    "user_mobile": "9813117429",
    "user_email": "john@example.com",
    "caller_name": "Telecaller Name",
    "caller_mobile": "7678361210",
    "caller_email": "telecaller@example.com"
  },
  "timestamp": "2024-11-20 10:30:00"
}
```

---

## 5. Update Call Log

**Method:** `POST`

**Endpoint:** `?action=update`

**URL:**
```
http://127.0.0.1/api/call_logs_api.php?action=update
```

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "id": 123,
  "call_status": "completed",
  "feedback": "Call completed successfully",
  "call_duration": 180,
  "recording_url": "https://recordings.myoperator.co/call_12345.mp3"
}
```

**Note:** You can update any field(s). Only include the fields you want to update.

**Response:**
```json
{
  "success": true,
  "message": "Call log updated successfully",
  "data": {
    "id": 123,
    "call_status": "completed",
    "feedback": "Call completed successfully",
    "call_duration": 180,
    ...
  },
  "timestamp": "2024-11-20 10:30:00"
}
```

---

## 6. Delete Call Log

**Method:** `POST`

**Endpoint:** `?action=delete`

**URL:**
```
http://127.0.0.1/api/call_logs_api.php?action=delete
```

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "id": 123
}
```

**Response:**
```json
{
  "success": true,
  "message": "Call log deleted successfully",
  "timestamp": "2024-11-20 10:30:00"
}
```

---

## Call Status Values

The `call_status` field accepts these values:
- `pending` - Call not yet made
- `connected` - Call connected successfully
- `not_connected` - Call not connected
- `busy` - Line busy
- `no_answer` - No answer
- `callback` - Callback requested
- `callback_later` - Call back later
- `not_reachable` - Phone not reachable
- `not_interested` - Not interested
- `invalid` - Invalid number
- `completed` - Call completed
- `failed` - Call failed
- `cancelled` - Call cancelled

---

## Testing Workflow

1. **Check table structure:**
   ```
   GET http://127.0.0.1/api/call_logs_api.php?action=get_table_structure
   ```

2. **Insert a call log:**
   ```
   POST http://127.0.0.1/api/call_logs_api.php?action=insert
   Body: {"caller_id": 3, "user_id": 13474, "user_number": "+919813117429"}
   ```

3. **Get all call logs:**
   ```
   GET http://127.0.0.1/api/call_logs_api.php?action=get_all
   ```

4. **Get specific call log:**
   ```
   GET http://127.0.0.1/api/call_logs_api.php?action=get_by_id&id=1
   ```

5. **Update call log:**
   ```
   POST http://127.0.0.1/api/call_logs_api.php?action=update
   Body: {"id": 1, "call_status": "completed", "feedback": "Success"}
   ```

6. **Delete call log:**
   ```
   POST http://127.0.0.1/api/call_logs_api.php?action=delete
   Body: {"id": 1}
   ```

---

## Error Responses

All errors return this format:
```json
{
  "success": false,
  "error": "Error message here"
}
```

Common errors:
- `Database connection failed` - Database connection issue
- `Method not allowed` - Wrong HTTP method used
- `ID required` - Missing required ID parameter
- `No fields to update` - Update request with no fields
- `Call log not found` - Record doesn't exist
