# 🚀 TeleCMI Production Deployment Checklist

## Pre-Deployment

### 1. Database Setup
- [ ] Run `api/setup_call_logs_table.sql` to create/update call_logs table
- [ ] Verify table structure with `DESCRIBE call_logs;`
- [ ] Check indexes are created
- [ ] Verify timezone is set to IST in config.php

### 2. Environment Configuration
- [ ] Verify `.env` file exists in project root
- [ ] Check `TELECMI_APP_ID=33336628` is set
- [ ] Check `TELECMI_APP_SECRET` is set correctly
- [ ] Verify `.env` file is NOT in git repository

### 3. Backend Files
- [ ] Upload `api/telecmi_production_api.php` to server
- [ ] Verify `api/config.php` has correct database credentials
- [ ] Check file permissions (644 for PHP files)
- [ ] Verify PHP version >= 7.4

### 4. Flutter App
- [ ] Verify `lib/core/services/api_service.dart` uses production endpoint
- [ ] Check `lib/core/services/smart_calling_service.dart` is updated
- [ ] Verify `lib/features/telecaller/smart_calling_page.dart` has TeleCMI option
- [ ] Build and test Flutter app

---

## Testing Phase

### 1. API Testing
- [ ] Run `api/test_telecmi_production.php` in browser
- [ ] Test with Pooja's account (user_id: 3) - Should succeed
- [ ] Test with different user_id - Should fail with 403
- [ ] Verify error messages are user-friendly
- [ ] Check PHP error logs for any issues

### 2. Database Testing
```sql
-- Run these queries to verify
SELECT * FROM call_logs WHERE provider = 'telecmi' ORDER BY created_at DESC LIMIT 5;
SELECT COUNT(*) FROM call_logs WHERE caller_id = 3 AND provider = 'telecmi';
```
- [ ] Verify call logs are being created
- [ ] Check all fields are populated correctly
- [ ] Verify timestamps are in IST
- [ ] Check indexes are working (query should be fast)

### 3. Flutter App Testing
- [ ] Login as Pooja (user_id: 3)
- [ ] Navigate to Smart Calling page
- [ ] Verify driver list loads
- [ ] Click call button on a driver
- [ ] Verify dialog shows "TeleCMI IVR" and "Manual Call" options
- [ ] Select "TeleCMI IVR"
- [ ] Verify success message appears
- [ ] Check "Call in Progress" dialog shows
- [ ] Wait for call to complete
- [ ] Click "Call Ended - Submit Feedback"
- [ ] Submit feedback
- [ ] Verify driver is removed from list
- [ ] Check database for call log entry

### 4. Security Testing
- [ ] Try to make TeleCMI call with user_id != 3
- [ ] Verify 403 Forbidden error is returned
- [ ] Check error message: "You are not authorized to use TeleCMI calling"
- [ ] Verify manual calls still work for all users
- [ ] Test with invalid phone numbers
- [ ] Test with non-existent driver IDs

---

## Production Deployment

### 1. Server Upload
```bash
# Upload files to server
scp api/telecmi_production_api.php user@server:/path/to/api/
scp api/setup_call_logs_table.sql user@server:/path/to/api/
scp .env user@server:/path/to/project/
```
- [ ] Files uploaded successfully
- [ ] File permissions set correctly
- [ ] .env file is secure (not publicly accessible)

### 2. Database Migration
```bash
# Run SQL setup
mysql -u username -p database_name < api/setup_call_logs_table.sql
```
- [ ] SQL executed successfully
- [ ] Table structure verified
- [ ] Indexes created
- [ ] No errors in output

### 3. Configuration Verification
- [ ] Check `api/config.php` database connection
- [ ] Verify timezone is set to Asia/Kolkata
- [ ] Test database connection
- [ ] Check CORS headers are set

### 4. API Endpoint Testing
```bash
# Test click_to_call endpoint
curl -X POST http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call \
  -H "Content-Type: application/json" \
  -d '{"caller_id":3,"driver_id":"test","driver_mobile":"919876543210"}'

# Test unauthorized access
curl -X POST http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call \
  -H "Content-Type: application/json" \
  -d '{"caller_id":999,"driver_id":"test","driver_mobile":"919876543210"}'
```
- [ ] Authorized call succeeds
- [ ] Unauthorized call fails with 403
- [ ] Error messages are correct
- [ ] Response format is valid JSON

---

## Post-Deployment

### 1. Monitoring Setup
- [ ] Set up error log monitoring
- [ ] Configure database query monitoring
- [ ] Set up call success rate tracking
- [ ] Create dashboard for call statistics

### 2. User Training
- [ ] Train Pooja on TeleCMI calling
- [ ] Explain call flow and feedback process
- [ ] Show how to handle errors
- [ ] Provide support contact information

### 3. Documentation
- [ ] Share `TELECMI_PRODUCTION_READY.md` with team
- [ ] Document any custom configurations
- [ ] Create troubleshooting guide
- [ ] Update API documentation

### 4. Backup
- [ ] Backup database before deployment
- [ ] Backup old API files
- [ ] Create rollback plan
- [ ] Document rollback procedure

---

## Monitoring Queries

### Daily Monitoring
```sql
-- Today's TeleCMI calls
SELECT COUNT(*) as total_calls, status, 
       AVG(call_duration) as avg_duration
FROM call_logs 
WHERE DATE(created_at) = CURDATE() 
  AND provider = 'telecmi' 
  AND caller_id = 3
GROUP BY status;

-- Failed calls today
SELECT * FROM call_logs 
WHERE DATE(created_at) = CURDATE() 
  AND provider = 'telecmi' 
  AND status IN ('failed', 'error')
ORDER BY created_at DESC;

-- Feedback distribution
SELECT feedback, COUNT(*) as count
FROM call_logs 
WHERE provider = 'telecmi' 
  AND caller_id = 3
  AND feedback IS NOT NULL
GROUP BY feedback
ORDER BY count DESC;
```

### Weekly Monitoring
```sql
-- This week's statistics
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_calls,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
  SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
  AVG(call_duration) as avg_duration
FROM call_logs 
WHERE provider = 'telecmi' 
  AND caller_id = 3
  AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## Troubleshooting

### Issue: Calls not initiating
**Check:**
1. PHP error logs: `tail -f /var/log/php_errors.log`
2. TeleCMI credentials in .env file
3. Database connection in config.php
4. User is Pooja (user_id: 3)

### Issue: 403 Forbidden error
**Solution:**
- This is expected for users other than Pooja
- Only user_id: 3 can make TeleCMI calls
- Other users should use Manual Call option

### Issue: Calls not logged to database
**Check:**
1. Database connection
2. call_logs table exists
3. Table structure is correct
4. PHP has write permissions

### Issue: Feedback not saving
**Check:**
1. reference_id is correct
2. Call exists in database
3. Provider is 'telecmi'
4. Database connection is active

---

## Rollback Plan

If issues occur:

1. **Immediate Rollback:**
   ```bash
   # Restore old API file
   cp api/telecmi_api.php.backup api/telecmi_api.php
   
   # Update Flutter app to use old endpoint
   # Redeploy Flutter app
   ```

2. **Database Rollback:**
   ```sql
   -- Restore from backup
   mysql -u username -p database_name < backup_call_logs.sql
   ```

3. **Notify Users:**
   - Inform Pooja about the rollback
   - Provide alternative calling method
   - Estimate time to fix

---

## Success Criteria

✅ **Deployment is successful when:**
- [ ] Pooja can make TeleCMI calls
- [ ] Other users cannot make TeleCMI calls (403 error)
- [ ] All calls are logged to database
- [ ] Feedback is saved correctly
- [ ] No errors in PHP logs
- [ ] Call success rate > 95%
- [ ] Average response time < 2 seconds
- [ ] Database queries are fast (< 100ms)

---

## Support Contacts

- **Developer:** [Your Name]
- **Database Admin:** [DBA Name]
- **TeleCMI Support:** support@telecmi.com
- **Emergency Contact:** [Phone Number]

---

## Sign-off

- [ ] Developer tested and approved
- [ ] QA tested and approved
- [ ] Database admin approved
- [ ] Product owner approved
- [ ] Deployed to production
- [ ] Post-deployment verification complete
- [ ] Monitoring active
- [ ] Documentation updated

**Deployed by:** _______________  
**Date:** _______________  
**Time:** _______________  
**Version:** 1.0.0

---

🎉 **Deployment Complete!**
