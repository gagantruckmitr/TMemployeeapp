# Job Applicants Match Making Filter

## Feature Overview
When a telecaller marks a driver as "Match Making Done" (from the **Connected** section in the feedback modal) for any job, that driver will automatically disappear from ALL job applicant lists across the system. 

**To make the driver reappear:** The telecaller must submit feedback from the **Connected section only** (like Interview Done, Not Selected, Not Interested, etc.). Feedback from other sections (Not Connected, Call Back Later) will NOT make the driver reappear.

**Important:** 
- The "Match Making Done" option only appears in the "1. Connected" section of the call feedback modal
- Only feedback from the "Connected" section can change the driver's visibility across jobs
- Feedback from "Not Connected" or "Call Back Later" sections does not affect the match-making status

## Implementation Details

### Backend Changes (API)
**File:** `api/phase2_job_applicants_api.php`

Added a filter condition to exclude drivers with global "Matchmaking Done" status:
```sql
WHERE a.job_id = $numericJobId
AND gms.global_match_status IS NULL
```

### How It Works

1. **Global Match Status Detection**
   - The `gms` (global match status) subquery checks the most recent **Connected section** feedback for each driver across ALL jobs
   - Only feedback from the Connected section is considered (Interview Done, Not Selected, Not Interested, Interview Fixed, Ready for Interview, Will Confirm Later, Match Making Done)
   - If the most recent Connected feedback is "Match Making Done", the driver gets a global match status

2. **Filtering Logic**
   - Drivers with `gms.global_match_status = 'Matchmaking Done'` are excluded from job applicant lists
   - Only drivers with `gms.global_match_status IS NULL` are shown

3. **Reappearing Logic - Connected Section Only**
   - When a telecaller submits new feedback from the **Connected section** (other than "Match Making Done"), it becomes the most recent Connected feedback
   - The global match status check will no longer find "Matchmaking Done" as the latest Connected feedback
   - The driver automatically reappears in all job applicant lists

4. **Other Sections Don't Affect Visibility**
   - Feedback from "Not Connected" section (Ringing, Call Busy, Switched Off, etc.) does NOT change the match-making status
   - Feedback from "Call Back Later" section (Busy Right Now, Call Tomorrow Morning, etc.) does NOT change the match-making status
   - Only Connected section feedback can make a hidden driver reappear

## User Flow

### Scenario 1: Driver Gets Match Made
1. Telecaller calls driver for Job A
2. Call connects successfully
3. Telecaller selects "Connected" status in the feedback modal
4. From the Connected section, telecaller selects "Match Making Done"
5. Telecaller submits the feedback
6. Driver disappears from Job A applicants list
7. Driver also disappears from Job B, Job C, and all other job applicant lists

### Scenario 2: Feedback Changed (Connected Section)
1. Driver was previously marked as "Match Making Done"
2. Telecaller calls the same driver again (can find via search)
3. Telecaller selects "Connected" status
4. Telecaller submits new feedback: "Not Interested" (or any other Connected status)
5. Driver reappears in ALL job applicant lists where they had applied

### Scenario 3: Feedback from Other Sections (Driver Remains Hidden)
1. Driver was previously marked as "Match Making Done" (from Connected section)
2. Telecaller calls the same driver again
3. Telecaller selects "Not Connected" status (e.g., "Ringing", "Call Busy")
4. Telecaller submits the feedback
5. Driver remains HIDDEN from all job applicant lists
6. **Why?** Because "Match Making Done" is still the most recent **Connected section** feedback
7. Feedback from "Not Connected", "Call Back Later", or "Match Status" sections does NOT override the Connected section status

### Scenario 4: Incorrect Match Making
1. Telecaller accidentally marked driver as "Match Making Done"
2. Telecaller can immediately call the driver again
3. Submit any other feedback from the **Connected section** (Interview Done, Not Selected, etc.)
4. Driver will reappear in all job lists

## Database Structure

The system uses the `call_logs_match_making` table to track:
- `unique_id_driver`: Driver's unique ID
- `match_status`: The feedback status (e.g., "Matchmaking Done")
- `created_at`: Timestamp of the feedback
- `job_id`: The job for which feedback was given

The global status is determined by the most recent `match_status` across all jobs for a driver.

## Benefits

1. **Prevents Duplicate Placements**: Once a driver is matched, they won't appear in other job lists
2. **Flexibility**: Telecallers can correct mistakes by submitting new feedback
3. **Automatic Sync**: No manual intervention needed - the system automatically updates all job lists
4. **Real-time Updates**: Changes are reflected immediately when the job applicants list is refreshed

## Testing

To test this feature:

1. **Test Match Making (Driver Hides)**:
   - Find a driver who applied to multiple jobs
   - Call the driver from any job
   - Select "Connected" section
   - Submit feedback: "Match Making Done"
   - Verify the driver disappears from all job applicant lists

2. **Test Other Sections Don't Unhide**:
   - Find the same driver (use global search)
   - Call the driver again
   - Select "Not Connected" section
   - Submit feedback: "Ringing" or "Call Busy"
   - Verify the driver REMAINS HIDDEN from all job applicant lists
   - Try "Call Back Later" section feedback → Driver still hidden
   - Try "Match Status" → Driver still hidden

3. **Test Reappearing (Connected Section Only)**:
   - Find the same driver (use global search)
   - Call the driver again
   - Select "Connected" section
   - Submit different feedback: "Not Interested" or "Interview Done"
   - Verify the driver NOW REAPPEARS in all job applicant lists

## Notes

- The "Match Making Done" option only appears in the **"1. Connected"** section of the feedback modal
- This ensures the option is only used when the telecaller has successfully connected with the driver
- The filter only applies to the "Match Making Done" status (case-insensitive: "Matchmaking Done" or "Match Making Done")
- Other feedback statuses (Interview Done, Not Selected, etc.) do not affect visibility across jobs
- The system always uses the most recent feedback to determine global status
- Drivers can still be found using the global search feature even when hidden from job lists
- If a driver is marked as "Match Making Done" within 5 minutes, updating the feedback will modify the same record; after 5 minutes, a new record is created

## Feedback Modal Structure

The call feedback modal has 4 sections:

1. **Connected** (Green) - Contains:
   - Interview Done
   - Not Selected
   - Not Interested
   - Interview Fixed
   - Ready for Interview
   - Will Confirm Later
   - **Match Making Done** ← This triggers the global filter

2. **Not Connected** (Orange) - Contains:
   - Ringing
   - Call Busy
   - Switched Off
   - Not Reachable
   - Disconnected

3. **Call Back Later** (Blue) - Contains:
   - Busy Right Now
   - Call Tomorrow Morning
   - Call in Evening
   - Call After 2 Days

4. **Match Status** - Optional additional status:
   - Selected
   - Not Selected
   - Pending
