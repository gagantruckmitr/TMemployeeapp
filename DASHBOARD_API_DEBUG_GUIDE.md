# Dashboard API Debugging Guide

## Current Status ✅

The dashboard IS correctly calling the API endpoint `/api/margdarshak/dashboard`. The implementation is correct:

1. ✅ API Config has `margdarshakDashboardApi` endpoint
2. ✅ API Service uses `ApiConfig.margdarshakDashboardApi`
3. ✅ Dashboard calls `_apiService.getDashboardStats()`
4. ✅ Bearer token authentication included
5. ✅ Response parsing handles new structure

## If You're Seeing Zero Data

The dashboard shows zeros when the API call fails and falls back to offline mode. Here's how to debug:

### Check Console Logs

When you run the app, look for these logs:

```
🔵 Fetching dashboard stats...
   URL: https://devtruckmitr.in/api/margdarshak/dashboard
   Has Auth Token: true

🔵 Dashboard API Response:
   Status Code: 200
   Body: {"status":true,"message":"Dashboard data fetched successfully",...}

✅ Dashboard stats fetched successfully
   Response Status: true
   Response Message: Dashboard data fetched successfully
```

### Common Issues

#### 1. API Returns Error (401 Unauthorized)
**Symptom:** Status Code 401
**Cause:** Bearer token missing or invalid
**Solution:** 
- Check if user is logged in
- Verify token is saved after login
- Check `_authService.authToken` is not null

#### 2. API Returns Error (404 Not Found)
**Symptom:** Status Code 404
**Cause:** Endpoint doesn't exist on server
**Solution:**
- Verify backend has `/api/margdarshak/dashboard` endpoint
- Check API base URL is correct

#### 3. Network Error
**Symptom:** Exception thrown, no status code
**Cause:** Network connectivity issue
**Solution:**
- Check internet connection
- Verify server is running
- Check firewall/proxy settings

#### 4. API Returns Success But No Data
**Symptom:** Status 200, but data fields are 0
**Cause:** Backend returns empty data (no shops/drivers registered yet)
**Solution:**
- This is normal if no data exists in database
- Add test data via backend
- Register some shops/drivers

### Debug Steps

1. **Check Logs**
   - Run app in debug mode
   - Watch console for API logs
   - Look for error messages

2. **Verify Token**
   ```dart
   print('Auth Token: ${_authService.authToken}');
   ```

3. **Test API Directly**
   - Use Postman/curl to test endpoint
   - Include Bearer token in headers
   - Verify response structure

4. **Check Response**
   - Look at full response body in logs
   - Verify `status: true`
   - Check `data` object exists

### Expected Response Structure

```json
{
  "status": true,
  "message": "Dashboard data fetched successfully",
  "data": {
    "territory": {
      "state_name": "Uttar Pradesh",
      "districts_count": 2,
      "districts": ["Agra", "Aligarh"]
    },
    "shops": {
      "total_onboarded": 3,
      "dhaba_count": 2,
      "puncture_count": 1,
      "blocked_shops": 0
    },
    "drivers": {
      "total": 0,
      "today": 0,
      "this_week": 0,
      "this_month": 0
    },
    "earnings": {
      "total_amount": 0,
      "monthly_amount": 0,
      "pending_amount": 0
    }
  }
}
```

### Error Handling

The dashboard now shows:
- ⚠️ Orange snackbar with error message
- 🔄 "Retry" button to try again
- 📊 Fallback to offline mode with zeros

### Testing Checklist

- [ ] User is logged in as Margdarshak
- [ ] Auth token exists in SharedPreferences
- [ ] API endpoint exists on backend
- [ ] Backend returns correct response structure
- [ ] Network connectivity is working
- [ ] Console shows successful API call
- [ ] Dashboard displays real data

## Summary

**The code is correct!** If you're seeing zeros, it's because:
1. API call is failing (check logs for error)
2. OR backend has no data yet (normal for new system)

Check the console logs to see exactly what's happening with the API call.
