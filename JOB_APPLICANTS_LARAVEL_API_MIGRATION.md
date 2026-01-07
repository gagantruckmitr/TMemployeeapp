# Job Applicants Laravel API Migration

## Summary
Successfully migrated the Job Applicants screen to use the new Laravel API endpoint instead of the old PHP API.

## Changes Made

### 1. Updated API Endpoint
**File:** `lib/core/services/phase2_api_service.dart`

**Method:** `fetchJobApplicants(String jobId)`

**Old Endpoint:**
```
$baseUrl/phase2_job_applicants_api.php?job_id={jobId}
```

**New Endpoint:**
```
http://truckmitr.com/api/telehead/jobs/{jobId}/applicants
```

### 2. API Response Mapping

The Laravel API returns a different structure than the old PHP API:

**Laravel API Response:**
```json
{
  "job_id": "567",
  "total_applicants": 12,
  "applicants": [
    {
      "driver_id": 17094,
      "driver_unique_id": "TM2511RJDR16936",
      "driver_name": "भगवान सिंह",
      "mobile": "9610303638",
      "state_name": "Rajasthan",
      "vehicle_type": "Container Trucks\n",
      "Driving_Experience": "1",
      "Type_of_License": "HPMV/HTV",
      "applied_at": "2025-12-18 16:17:19",
      "job_created_at": "2025-12-16 19:35:35",
      "job_updated_at": "2025-12-17 06:26:42",
      "profile_completion": 100,
      "subscription": {
        "start_at": "2025-11-16 08:36:35",
        "amount": "49.00"
      }
    }
  ]
}
```

### 3. Field Mapping

The following transformations are applied to map Laravel API fields to the `DriverApplicant` model:

| Laravel API Field | DriverApplicant Field | Notes |
|-------------------|----------------------|-------|
| `driver_id` | `driverId` | Direct mapping |
| `driver_unique_id` | `driverTmid` | Direct mapping |
| `driver_name` | `name` | Direct mapping |
| `mobile` | `mobile` | Direct mapping |
| `state_name` | `state` | Direct mapping |
| `vehicle_type` | `vehicleType` | Direct mapping |
| `Driving_Experience` | `drivingExperience` | Converted to string |
| `Type_of_License` | `licenseType` | Direct mapping |
| `applied_at` | `appliedAt` | Direct mapping |
| `job_created_at` | `createdAt` | Direct mapping |
| `job_updated_at` | `updatedAt` | Direct mapping |
| `profile_completion` | `profileCompletion` | Direct mapping |
| `subscription.start_at` | `subscriptionStartDate` | Nested field |
| `subscription.amount` | `subscriptionAmount` | Nested field, converted to string |
| `subscription` (exists) | `subscriptionStatus` | Set to 'active' if exists, 'inactive' otherwise |

### 4. Missing Fields

The following fields are not provided by the Laravel API and are set to default values:

- `jobTitle` → Empty string
- `contractorId` → 0
- `transporterTmid` → Empty string
- `transporterName` → Empty string
- `email` → Empty string
- `city` → Empty string (not directly provided)
- `gender` → null
- `profileImage` → null
- `licenseNumber` → Empty string
- `preferredLocation` → Empty string
- `aadharNumber` → Empty string
- `panNumber` → Empty string
- `gstNumber` → Empty string
- `status` → 'active'
- `subscriptionEndDate` → null
- `callFeedback` → null
- `matchStatus` → null
- `matchMakerName` → null
- `feedbackNotes` → null
- `otherAppliedJobs` → null

## Testing

To test the changes:

1. Navigate to the Jobs screen
2. Select any job with applicants
3. Verify that the applicants list loads correctly
4. Check that all displayed information is accurate:
   - Driver name
   - Mobile number
   - State
   - Vehicle type
   - Driving experience
   - License type
   - Applied date/time
   - Profile completion percentage
   - Subscription information

## Notes

- The Laravel API does not provide `city` information separately, only `state_name`
- Profile images are not included in the current Laravel API response
- Call feedback and match status will need to be fetched separately if needed
- The `job_id` from the response is used to populate the `jobId` field in the model

## Backward Compatibility

The changes maintain full compatibility with the existing `DriverApplicant` model and the Job Applicants screen UI. No changes were required to the screen itself.

## Additional Fixes

Fixed syntax errors in `phase2_api_service.dart`:
- Added missing commas after `'driverMobile'` and `'transporterMobile'` fields in two locations (lines 491-492 and 644-645)
