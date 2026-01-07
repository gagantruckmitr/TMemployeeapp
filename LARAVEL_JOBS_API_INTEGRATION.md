# Laravel Jobs API Integration Complete

## Overview
Successfully integrated the live Laravel API endpoint for fetching job postings in the Dynamic Jobs Screen.

## API Endpoint
- **URL**: `https://truckmitr.com/api/telehead/agent-jobs/{assigned_to}`
- **Method**: GET
- **Authentication**: Bearer Token (from login)
- **Response Format**: JSON array of job objects

## API Response Structure
```json
{
  "id": 260,
  "transporter_id": 5562,
  "job_id": "TMJB00260",
  "assigned_to": 3,
  "job_title": "Heavy truck driver",
  "job_location": "Madhya Pradesh",
  "Required_Experience": "1-5",
  "Salary_Range": "5000-10000",
  "Type_of_License": "LMV",
  "Preferred_Skills": "[\"Fuel Tanker\"]",
  "Application_Deadline": "2025-09-03 00:00:00",
  "Job_Management": "10",
  "Job_Description": "Need 10 truck drivers",
  "vehicle_type": "Heavy Commercial Vehicles",
  "status": "1",
  "active_inactive": 1,
  "consent_visible_driver": 0,
  "closed_job": null,
  "Created_at": "2025-09-03 00:13:05",
  "Updated_at": "2025-11-04 10:11:13",
  "number_of_drivers_required": 1,
  "remarks": null,
  "transporter_name": "Rohit swami",
  "transporter_unique_id": "TM2509ARTR05562",
  "transporter_image": null
}
```

## Field Mappings

### Status Fields
- **status**: `"1"` = Approved, `"0"` = Not Approved
- **active_inactive**: `1` = Active, `0` = Pending/Inactive
- **closed_job**: `1` or non-null = Closed, `null` or `0` = Open

### Date Fields
- **Created_at**: Job posting date (e.g., "2025-09-03 00:13:05")
- **Application_Deadline**: Deadline for applications (e.g., "2025-09-03 00:00:00")
- **Expiry Calculation**: Automatically calculated by comparing `Application_Deadline` with current date

### Job Details
- **job_id**: Unique job identifier (e.g., "TMJB00260")
- **job_title**: Job position title
- **job_location**: Location/state for the job
- **Job_Description**: Detailed job description
- **vehicle_type**: Type of vehicle required
- **Type_of_License**: Required license type
- **Required_Experience**: Experience range (e.g., "1-5")
- **Salary_Range**: Salary range (e.g., "5000-10000")
- **number_of_drivers_required**: Number of drivers needed

### Transporter Details
- **transporter_id**: Transporter's user ID
- **transporter_name**: Transporter's name
- **transporter_unique_id**: Transporter's TMID
- **transporter_image**: Profile image URL (nullable)

## Changes Made

### 1. Phase2ApiService (`lib/core/services/phase2_api_service.dart`)

#### Updated `fetchJobs()` method:
- Changed from PHP API to Laravel API endpoint
- Added Bearer token authentication
- Implemented client-side filtering for different job statuses
- Added proper error handling and logging

#### Updated `searchJobs()` method:
- Now fetches all jobs and filters locally
- Searches across multiple fields: jobId, TMID, name, location, title, vehicle type

### 2. JobModel (`lib/models/job_model.dart`)

#### Added `fromLaravelJson()` factory method:
- Parses Laravel API response format
- Maps Laravel field names to app field names
- Handles status conversions:
  - `status` → `isApproved`
  - `active_inactive` → `isActive`
  - `closed_job` → `isClosed`
- Calculates expiry based on `Application_Deadline`
- Handles nullable fields gracefully

### 3. Dynamic Jobs Screen (`lib/features/jobs/dynamic_jobs_screen.dart`)
- No changes needed - already uses `Phase2ApiService.fetchJobs()`
- Automatically benefits from the new Laravel API integration

## Filter Logic

The app supports 7 filter types:

1. **All**: Shows all jobs
2. **Approved**: `status == 1`
3. **Active**: `active_inactive == 1` AND not expired
4. **Pending**: `status == 0`
5. **Inactive**: `active_inactive == 0`
6. **Expired**: Current date > `Application_Deadline`
7. **Closed**: `closed_job != null`

## Job Card Display

The Modern Job Card displays:
- ✅ Job ID (e.g., TMJB00260)
- ✅ Job Title
- ✅ Transporter Name & TMID
- ✅ Approval Status Badge (Approved/Pending)
- ✅ Active Status Badge (Active/Inactive)
- ✅ Expired Badge (if deadline passed)
- ✅ Closed Badge (if job is closed)
- ✅ Posted Date (from Created_at)
- ✅ Deadline Date (from Application_Deadline)
- ✅ Job Location
- ✅ Vehicle Type
- ✅ License Type
- ✅ Salary Range
- ✅ Experience Required
- ✅ Drivers Required Count
- ✅ Assignment Status (Assigned to You / Assigned to another telecaller)

## Testing

To test the integration:

1. **Login** with valid credentials to get Bearer token
2. **Navigate** to Job Postings screen
3. **Verify** jobs are loaded from Laravel API
4. **Test filters**: All, Approved, Active, Pending, Inactive, Expired, Closed
5. **Test search**: Search by Job ID, TMID, Name, Location
6. **Check badges**: Verify status badges display correctly
7. **Check expiry**: Verify expired jobs show red badge
8. **Check assignment**: Verify "Assigned to You" vs "Assigned to another telecaller"

## API Requirements

- ✅ Bearer token authentication
- ✅ User must be logged in
- ✅ API returns jobs assigned to the logged-in telecaller
- ✅ Response is a JSON array of job objects

## Error Handling

- Network errors are caught and displayed
- Invalid tokens show authentication error
- Empty results show "No jobs found"
- Parse errors are logged and handled gracefully

## Future Enhancements

1. Add dedicated search API endpoint for better performance
2. Add pagination for large job lists
3. Add pull-to-refresh functionality
4. Cache jobs locally for offline access
5. Add real-time updates via WebSocket
6. Add job count by status in filter tabs

## Notes

- The Laravel API doesn't provide some fields (city, state, profile completion, applicants count)
- These fields are set to default values in `fromLaravelJson()`
- Search is currently client-side - consider server-side search for large datasets
- All date parsing handles multiple formats gracefully
