# TeleCMI Quick Start Guide

## 🚀 Your API is Ready!

All TeleCMI functionality has been implemented and is ready to use in your TMemployeeapp.

## 📋 Quick Setup Checklist

### 1. Database Setup (One-time)
```
Open: http://192.168.29.149/api/setup_telecmi_table.php
```
This creates the `call_logs` table needed for tracking calls.

### 2. Test the API
```
Open: http://192.168.29.149/api/test_telecmi_api.php
```
This verifies:
- ✅ TeleCMI credentials are correct
- ✅ SDK token generation works
- ✅ API endpoints are functional
- ✅ Database is ready

### 3. Add Access Token (if needed)
Edit `.env` file and add your TeleCMI access token:
```env
TELECMI_ACCESS_TOKEN=your_token_here
```

## 🔌 API Endpoints

### Get SDK Token
```
POST /api/telecmi_api.php?action=sdk_token
Body: {"user_id": "telecaller_123"}
```

### Make Call
```
POST /api/telecmi_api.php?action=click_to_call
Body: {
  "to": "919876543210",
  "callerid": "919123456789"
}
```

### Webhook (for TeleCMI)
```
POST /api/telecmi_api.php?action=webhook
```
Configure this URL in your TeleCMI dashboard.

## 📱 Flutter Integration

### Add to your service file:

```dart
class TelecmiService {
  final String baseUrl = 'http://192.168.29.149';
  
  Future<bool> makeCall(String to, String callerid) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/telecmi_api.php?action=click_to_call'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'to': to, 'callerid': callerid}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}
```

### Use in your app:

```dart
final telecmi = TelecmiService();
final success = await telecmi.makeCall('919876543210', '919123456789');

if (success) {
  print('Call initiated!');
}
```

## 🔍 Testing with Postman

**SDK Token:**
```
POST http://192.168.29.149/api/telecmi_api.php?action=sdk_token
Content-Type: application/json

{"user_id": "test_123"}
```

**Click-to-Call:**
```
POST http://192.168.29.149/api/telecmi_api.php?action=click_to_call
Content-Type: application/json

{
  "to": "919876543210",
  "callerid": "919123456789"
}
```

## 📊 Call Logs

All calls are automatically logged to the `call_logs` table with:
- Call ID
- From/To numbers
- Status (initiated, answered, ended)
- Duration
- Timestamps

Query example:
```sql
SELECT * FROM call_logs 
WHERE provider = 'telecmi' 
ORDER BY created_at DESC 
LIMIT 10;
```

## 🐛 Troubleshooting

**Issue:** API returns error
- Check PHP error logs
- Verify credentials in `.env`
- Run test suite

**Issue:** Call not initiated
- Verify TeleCMI account is active
- Check phone number format (with country code)
- Ensure access token is set (if required)

**Issue:** Webhook not working
- Configure webhook URL in TeleCMI dashboard
- Check server logs for incoming requests

## 📚 Full Documentation

See `TELECMI_API_SETUP.md` for complete documentation.

## ✅ You're All Set!

Your TeleCMI API is fully functional and ready for production use. Start making calls from your Flutter app!
