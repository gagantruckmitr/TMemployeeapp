# TeleCMI API Integration for TMemployeeapp

## Overview
This document explains the TeleCMI IVR calling integration for your TMemployeeapp. The API is now fully configured and ready to use.

## Files Created

1. **api/telecmi_api.php** - Main API endpoint for TeleCMI operations
2. **api/test_telecmi_api.php** - Test suite to verify integration
3. **.env** - Updated with TeleCMI credentials

## Configuration

### Environment Variables Added to .env

```env
TELECMI_APP_ID=33336628
TELECMI_APP_SECRET=a7003cba-292c-4853-9792-66fe0f31270f
TELECMI_SDK_BASE=https://piopiy.telecmi.com/v1/agentLogin
TELECMI_REST_BASE=https://rest.telecmi.com/v2/click2call
TELECMI_ACCESS_TOKEN=
```

**Note:** You need to add your `TELECMI_ACCESS_TOKEN` if required by TeleCMI for click-to-call API.

## API Endpoints

### 1. Get SDK Token (for WebRTC Calling)

**Endpoint:** `POST /api/telecmi_api.php?action=sdk_token`

**Request Body:**
```json
{
  "user_id": "telecaller_123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "SDK token generated successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600
  }
}
```

**Usage in Flutter:**
```dart
Future<String?> getTelecmiToken(String userId) async {
  final response = await http.post(
    Uri.parse('${baseUrl}/api/telecmi_api.php?action=sdk_token'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data']['token'];
  }
  return null;
}
```

### 2. Click-to-Call (Initiate Call)

**Endpoint:** `POST /api/telecmi_api.php?action=click_to_call`

**Request Body:**
```json
{
  "to": "919876543210",
  "callerid": "919123456789",
  "token": "optional_bearer_token"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Call initiated successfully",
  "data": {
    "request_id": "abc123xyz",
    "status": "initiated"
  }
}
```

**Usage in Flutter:**
```dart
Future<bool> makeCall(String fromNumber, String toNumber) async {
  final response = await http.post(
    Uri.parse('${baseUrl}/api/telecmi_api.php?action=click_to_call'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'to': toNumber,
      'callerid': fromNumber,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }
  return false;
}
```

### 3. Webhook Receiver

**Endpoint:** `POST /api/telecmi_api.php?action=webhook`

**Purpose:** Receives call events from TeleCMI (call initiated, answered, ended)

**Configure in TeleCMI Dashboard:**
- Webhook URL: `https://yourdomain.com/api/telecmi_api.php?action=webhook`
- Events: call.initiated, call.answered, call.ended

## Database Setup

The API logs calls to the `call_logs` table. If it doesn't exist, create it:

```sql
CREATE TABLE IF NOT EXISTS call_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    call_id VARCHAR(255) UNIQUE,
    from_number VARCHAR(20),
    to_number VARCHAR(20),
    status VARCHAR(50),
    duration INT DEFAULT 0,
    provider VARCHAR(50) DEFAULT 'telecmi',
    initiated_at DATETIME,
    answered_at DATETIME NULL,
    ended_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_call_id (call_id),
    INDEX idx_from_number (from_number),
    INDEX idx_to_number (to_number),
    INDEX idx_status (status)
);
```

## Testing

### Step 1: Run Test Suite

Open in browser: `http://yourdomain.com/api/test_telecmi_api.php`

This will test:
- ✅ Configuration check
- ✅ SDK token generation
- ✅ API endpoint functionality
- ✅ Database table existence

### Step 2: Test from Postman

**Test SDK Token:**
```
POST http://yourdomain.com/api/telecmi_api.php?action=sdk_token
Content-Type: application/json

{
  "user_id": "test_user_123"
}
```

**Test Click-to-Call:**
```
POST http://yourdomain.com/api/telecmi_api.php?action=click_to_call
Content-Type: application/json

{
  "to": "919876543210",
  "callerid": "919123456789"
}
```

## Integration with Flutter App

### 1. Create TeleCMI Service

```dart
// lib/services/telecmi_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TelecmiService {
  final String baseUrl = 'http://192.168.29.149'; // Your API URL
  
  // Get SDK token for WebRTC
  Future<String?> getSdkToken(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/telecmi_api.php?action=sdk_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data']['token'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting SDK token: $e');
      return null;
    }
  }
  
  // Initiate click-to-call
  Future<Map<String, dynamic>?> makeCall({
    required String to,
    required String callerid,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/telecmi_api.php?action=click_to_call'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': to,
          'callerid': callerid,
          if (token != null) 'token': token,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error making call: $e');
      return null;
    }
  }
}
```

### 2. Use in Your App

```dart
// Example: Make a call from telecaller dashboard
final telecmiService = TelecmiService();

// Make call
final result = await telecmiService.makeCall(
  to: '919876543210',
  callerid: '919123456789',
);

if (result != null && result['success']) {
  print('Call initiated successfully');
  print('Request ID: ${result['data']['request_id']}');
} else {
  print('Call failed');
}
```

## Error Handling

The API returns standard error responses:

```json
{
  "success": false,
  "message": "Error description here"
}
```

Common errors:
- `400` - Missing required parameters
- `405` - Wrong HTTP method
- `500` - Server error or TeleCMI API failure

## Security Notes

1. **Access Token:** Add your TeleCMI access token to `.env` file if required
2. **Webhook Signature:** The API includes signature verification (currently disabled)
3. **CORS:** Already configured in `config.php` to allow Flutter app access

## Logs

All TeleCMI operations are logged to PHP error log:
- SDK token requests
- Click-to-call attempts
- Webhook events
- Database operations

Check logs at: `/var/log/php_errors.log` or your server's error log location

## Next Steps

1. ✅ Run test suite: `http://yourdomain.com/api/test_telecmi_api.php`
2. ✅ Create `call_logs` table if it doesn't exist
3. ✅ Add `TELECMI_ACCESS_TOKEN` to `.env` if needed
4. ✅ Configure webhook URL in TeleCMI dashboard
5. ✅ Integrate TeleCMI service in your Flutter app
6. ✅ Test calling functionality

## Support

If you encounter issues:
1. Check PHP error logs
2. Verify TeleCMI credentials in `.env`
3. Test with `test_telecmi_api.php`
4. Check TeleCMI dashboard for API status

## API is Ready! 🚀

Your TeleCMI API is fully configured and ready to use. No changes were made to the core logic - just adapted it to work with your existing PHP API structure.
