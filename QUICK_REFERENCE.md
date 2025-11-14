# 📋 TeleCMI Quick Reference Card

## 🚀 Quick Start

### For Pooja (User ID: 3)
1. Login to app
2. Go to Smart Calling page
3. Click call button on driver
4. Select "TeleCMI IVR" (purple)
5. Your phone will ring
6. Answer and talk to driver
7. After call, submit feedback
8. Done!

---

## 🔑 Key Information

**Authorized User:** Only Pooja (user_id: 3)  
**TeleCMI User ID:** 5003  
**Full TeleCMI ID:** 5003_33336628  
**App ID:** 33336628  
**Provider:** telecmi  
**Call Type:** ivr

---

## 📡 API Endpoints

### Production API
```
http://truckmitr.com/api/telecmi_production_api.php
```

**Actions:**
- `?action=click_to_call` - Initiate call
- `?action=update_feedback` - Save feedback
- `?action=get_call_logs` - Get call history
- `?action=webhook` - Receive webhooks

---

## 🗄️ Database

**Table:** `call_logs`  
**Provider:** 'telecmi'  
**Caller ID:** 3 (Pooja)

**Quick Query:**
```sql
SELECT * FROM call_logs 
WHERE caller_id = 3 AND provider = 'telecmi' 
ORDER BY created_at DESC LIMIT 10;
```

---

## 🧪 Testing

**Test URL:**
```
http://truckmitr.com/api/test_telecmi_production.php
```

**Test Call:**
```bash
curl -X POST http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call \
  -H "Content-Type: application/json" \
  -d '{"caller_id":3,"driver_id":"test","driver_mobile":"919876543210"}'
```

---

## ⚠️ Common Errors

### 403 Forbidden
**Cause:** User is not Pooja  
**Solution:** Only user_id: 3 can use TeleCMI

### 404 Not Found
**Cause:** Driver doesn't exist  
**Solution:** Check driver_id is valid

### 400 Bad Request
**Cause:** Invalid phone number  
**Solution:** Phone must be 10-15 digits

### 500 Server Error
**Cause:** TeleCMI API issue  
**Solution:** Check .env credentials

---

## 📊 Monitoring

**Check Today's Calls:**
```sql
SELECT COUNT(*) FROM call_logs 
WHERE DATE(created_at) = CURDATE() 
AND provider = 'telecmi';
```

**Check Failed Calls:**
```sql
SELECT * FROM call_logs 
WHERE status = 'failed' 
AND provider = 'telecmi' 
ORDER BY created_at DESC;
```

---

## 🔧 Configuration Files

**Backend:** `api/telecmi_production_api.php`  
**Flutter:** `lib/core/services/api_service.dart`  
**Database:** `api/setup_call_logs_table.sql`  
**Environment:** `.env`

---

## 📞 Support

**Check Logs:**
```bash
tail -f /var/log/php_errors.log | grep "TeleCMI Production"
```

**Verify Database:**
```sql
DESCRIBE call_logs;
```

**Test API:**
```
http://truckmitr.com/api/test_telecmi_production.php
```

---

## ✅ Deployment Checklist

- [ ] Upload `api/telecmi_production_api.php`
- [ ] Run `api/setup_call_logs_table.sql`
- [ ] Verify `.env` credentials
- [ ] Test API with test file
- [ ] Test with Pooja's account
- [ ] Verify database logging
- [ ] Check error logs
- [ ] Monitor first calls

---

## 🎯 Call Flow

1. User clicks call → Dialog shows
2. Select TeleCMI IVR → API called
3. Server validates → TeleCMI called
4. Call logged → Success message
5. Phone rings → User answers
6. Call happens → Call ends
7. Feedback modal → Submit feedback
8. Database updated → Driver removed

---

## 📱 App Screens

**Smart Calling Page:**
- Driver list with call buttons
- Search functionality
- Pull to refresh

**Call Dialog:**
- TeleCMI IVR (purple icon)
- Manual Call (green icon)
- Cancel button

**Call Progress:**
- Loading indicator
- Status message
- "Call Ended" button

**Feedback Modal:**
- Status selection
- Feedback options
- Remarks field
- Submit button

---

## 🔐 Security

✅ Only Pooja can use TeleCMI  
✅ Server-side validation  
✅ SQL injection protection  
✅ Input sanitization  
✅ Phone number validation  
✅ Driver verification  
✅ Error logging  
✅ Secure credentials

---

## 📚 Documentation

1. `TELECMI_PRODUCTION_READY.md` - Complete guide
2. `DEPLOYMENT_CHECKLIST.md` - Deployment steps
3. `FINAL_IMPLEMENTATION_SUMMARY.md` - Summary
4. `QUICK_REFERENCE.md` - This file

---

## 🎉 Status

**Implementation:** ✅ COMPLETE  
**Testing:** ✅ READY  
**Security:** ✅ IMPLEMENTED  
**Documentation:** ✅ PROVIDED  
**Deployment:** ✅ READY

---

**Version:** 1.0.0  
**Date:** November 13, 2025  
**Status:** 🚀 PRODUCTION READY
