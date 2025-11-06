# Phase 2 API Upload Instructions

## Files to Upload to Server

Upload these files to `D:\tmemployeeapp\api\` on your server:

1. **api/phase2_jobs_api.php** - Fetches jobs from database
2. **api/phase2_dashboard_stats_api.php** - Fetches dashboard statistics
3. **api/phase2_recent_activities_api.php** - Fetches recent activities
4. **api/test_phase2_api.php** - Test file to verify APIs work

## Testing the APIs

### Step 1: Test Database Connection
Visit: `https://truckmitr.com/truckmitr-app/api/test_phase2_api.php`

This will show you:
- Database connection status
- Jobs table structure
- Sample data
- Query tests

### Step 2: Test Dashboard Stats API
Visit: `https://truckmitr.com/truckmitr-app/api/phase2_dashboard_stats_api.php`

Expected response:
```json
{
  "success": true,
  "message": "Dashboard stats fetched successfully",
  "data": {
    "totalJobs": 156,
    "approvedJobs": 89,
    "pendingJobs": 42,
    "inactiveJobs": 18,
    "expiredJobs": 7,
    "activeTransporters": 89,
    "driversApplied": 324,
    "totalMatches": 267,
    "totalCalls": 1842
  }
}
```

### Step 3: Test Jobs API
Visit: `https://truckmitr.com/truckmitr-app/api/phase2_jobs_api.php`

With filters:
- All jobs: `?filter=all`
- Approved: `?filter=approved`
- Pending: `?filter=pending`
- Active: `?filter=active`
- Inactive: `?filter=inactive`
- Expired: `?filter=expired`

### Step 4: Test Recent Activities API
Visit: `https://truckmitr.com/truckmitr-app/api/phase2_recent_activities_api.php?limit=10`

## Database Column Mapping

The APIs use these database columns:

### Jobs Table
- `status` = 1 means **approved**, 0 means **pending**
- `active_status` = 1 means **active**, 0 means **inactive**
- `Application_Deadline` - for checking expired jobs
- `job_id` - unique job identifier
- `job_location` - job location
- `vehicle_type` - type of vehicle required
- `Salary_Range` - salary range
- `Required_Experience` - required experience

### Transporters Table
- `transporter_id` - unique transporter ID
- `name` - transporter name
- `phone` - transporter phone
- `city` - transporter city

### Lead Assignment Table
- `lead_assignment_new` - tracks driver applications
- `job_id` - links to jobs table
- `driver_id` - links to drivers table
- `status` - application status

## Troubleshooting

If you get HTTP 500 error:
1. Check if `config.php` exists in the api folder
2. Verify database credentials in `config.php`
3. Check PHP error logs
4. Run `test_phase2_api.php` to see detailed error messages

If no data is returned:
1. Check if jobs table has data
2. Verify column names match (use test_phase2_api.php)
3. Check if transporters table exists and has data

## Flutter App Configuration

The Flutter app is configured to use:
- Base URL: `http://192.168.29.149/api` (local)
- Production URL: Update in `Phase_2-/lib/core/services/phase2_api_service.dart`

Change the baseUrl to:
```dart
static const String baseUrl = 'https://truckmitr.com/truckmitr-app/api';
```
