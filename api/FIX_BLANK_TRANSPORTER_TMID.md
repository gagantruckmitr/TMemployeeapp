# Fix: Blank unique_id_transporter Field

## Problem
The `unique_id_transporter` field in `call_logs_match_making` table is blank/NULL.

## Most Likely Cause
The `jobs` table doesn't have `transporter_id` set for the jobs.

## Quick Test
Run this URL to check:
```
https://truckmitr.com/truckmitr-app/api/test_jobs_transporter.php
```

This will show if jobs have transporter_id set or not.

## Quick Fix
If jobs are missing transporter_id, update them:

```sql
-- Check which jobs are missing transporter_id
SELECT id, job_id, job_title, transporter_id 
FROM jobs 
WHERE transporter_id IS NULL OR transporter_id = 0
LIMIT 20;

-- Update jobs with transporter_id (if you know the transporter)
UPDATE jobs 
SET transporter_id = (SELECT id FROM users WHERE unique_id = 'TM250UHPDR12962' LIMIT 1)
WHERE job_id = 'TMJB00437';
```

## Then Fix Call Logs
After jobs have correct transporter_id:

```sql
UPDATE call_logs_match_making clm
INNER JOIN jobs j ON clm.job_id = j.job_id
INNER JOIN users u ON j.transporter_id = u.id
SET clm.unique_id_transporter = u.unique_id,
    clm.transporter_name = u.name
WHERE (clm.unique_id_transporter IS NULL OR clm.unique_id_transporter = '')
AND clm.job_id IS NOT NULL AND clm.job_id != '';
```

Or use the cleanup tool:
```
https://truckmitr.com/truckmitr-app/api/admin_cleanup_call_logs.html
```
