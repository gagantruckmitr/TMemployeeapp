# Callback Request Call Logs - Deployment Checklist

## Pre-Deployment Verification ✅

- [x] Database structure verified
- [x] Test scripts pass successfully
- [x] Code changes implemented
- [x] No diagnostic errors
- [x] User ID mapping correct
- [x] History integration working

## Files to Deploy

### Flutter App
```
lib/features/telecaller/callback_requests/callback_requests_screen.dart
```

### API Files
```
api/call_logs_api.php
api/callback_requests_api.php
```

### Test Scripts (Optional)
```
api/test_callback_call_logs.php
api/test_callback_submission.php
api/verify_submission.php
api/verify_callback_call_logs.sql
```

## Deployment Steps

### 1. Backup Current Files
```bash
cp lib/features/telecaller/callback_requests/callback_requests_screen.dart callback_requests_screen.dart.backup
cp api/call_logs_api.php call_logs_api.php.backup
cp api/callback_requests_api.php callback_requests_api.php.backup
```

### 2. Deploy API Files
```bash
# Upload to server
scp api/call_logs_api.php user@server:/path/to/api/
scp api/callback_requests_api.php user@server:/path/to/api/
```

### 3. Build & Deploy Flutter App
```bash
# Build app
flutter build apk --release
# or
flutter build ios --release

# Deploy to app stores or distribute
```

### 4. Verify on Server
```bash
# Test database structure
curl https://your-server.com/api/test_callback_call_logs.php

# Expected: All checks pass
```

## Post-Deployment Testing

### Test 1: Make a Call
1. Open Callback Requests screen
2. Select a pending request
3. Make a call (Manual or IVR)
4. Submit feedback with remarks

### Test 2: Verify Database
```sql
SELECT 
    cl.id,
    cl.user_id,
    u.unique_id as tmid,
    cl.tc_for,
    cl.call_source,
    cl.feedback,
    cl.remarks
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
WHERE cl.call_source = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 1;
```

**Expected**:
- ✅ user_id is from users table
- ✅ tmid shows correct TM ID
- ✅ tc_for = 'callback_requests'
- ✅ call_source = 'callback_requests'
- ✅ feedback and remarks populated

### Test 3: Check History
1. Go to History tab in Callback Requests
2. Verify request appears
3. Check feedback is displayed
4. Verify remarks are shown

## Rollback Plan

If issues occur:

### 1. Restore API Files
```bash
cp call_logs_api.php.backup api/call_logs_api.php
cp callback_requests_api.php.backup api/callback_requests_api.php
```

### 2. Restore App
- Deploy previous app version
- Or revert code changes and rebuild

## Monitoring

### Check Logs
```bash
# API logs
tail -f /path/to/api/logs/error.log | grep callback

# Look for:
# ✅ "Set user_id=XXX for callback request"
# ✅ "Inserting call log: user_id=XXX"
```

### Check Database
```sql
-- Count recent callback call logs
SELECT COUNT(*) 
FROM call_logs 
WHERE call_source = 'callback_requests' 
AND created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY);

-- Check for invalid user_ids
SELECT COUNT(*) 
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
WHERE cl.call_source = 'callback_requests'
AND u.id IS NULL;
-- Should be 0
```

## Success Metrics

After 24 hours:
- [ ] No errors in logs
- [ ] All callback calls have valid user_id
- [ ] Requests moving to history correctly
- [ ] Feedback displaying properly
- [ ] No user complaints

## Support Contacts

- Developer: [Your contact]
- Database Admin: [DBA contact]
- Server Admin: [Server contact]

## Documentation

- Full Fix: `CALLBACK_REQUESTS_CALL_LOGS_FIX.md`
- Verification: `CALLBACK_SUBMISSION_VERIFIED.md`
- Quick Test: `CALLBACK_CALL_LOGS_QUICK_TEST.md`
- Summary: `CALLBACK_FIX_SUMMARY.md`

## Status: READY FOR DEPLOYMENT ✅

All pre-deployment checks passed. System tested and verified.
