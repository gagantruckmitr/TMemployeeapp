# 📞 Complete TeleCMI Call Flow

## Overview
This document explains the complete flow of a TeleCMI call from initiation to feedback submission, showing exactly when each field in the `call_logs` table gets filled.

---

## 🔄 Call Flow Stages

### Stage 1: Call Initiation (Automatic)
**When:** User taps "TeleCMI IVR" button in the app

**API Called:** `POST /api/telecmi_production_api.php?action=click_to_call`

**Fields Filled Automatically:**
```sql
-- Core Identification
caller_id = 3                          -- Pooja's ID
tc_for = 'TeleCMI'                     -- Call provider
user_id = 7541                         -- Driver's ID
driver_name = 'Shahidul islam'         -- Driver's name

-- Call Status (Initial)
call_status = 'pending'                -- Initial status
feedback = NULL                        -- ⏳ Will be filled by user
remarks = NULL                         -- ⏳ Will be filled by user
notes = NULL                           -- ⏳ Will be filled by user
call_duration = 0                      -- ⏳ Will be updated later

-- Phone Numbers
caller_number = '+917678361210'        -- Pooja's phone
user_number = '+916000193973'          -- Driver's phone

-- Timestamps (Initial)
call_time = NOW()                      -- Current timestamp
created_at = NOW()                     -- Record creation time
updated_at = NOW()                     -- Last update time
call_initiated_at = NOW()              -- When call was initiated
call_start_time = NOW()                -- Call start time
call_completed_at = NULL               -- ⏳ Will be filled when call ends
call_end_time = NULL                   -- ⏳ Will be filled when call ends

-- TeleCMI Data
reference_id = 'telecmi_xxxxx'         -- Unique call ID
api_response = {...}                   -- TeleCMI API response JSON
webhook_data = NULL                    -- ⏳ Will be filled by webhooks
recording_url = NULL                   -- ⏳ Will be filled by TeleCMI

-- Other Data
ip_address = '122.161.49.29'          -- Caller's IP
manual_call_recording_url = NULL       -- Not used for TeleCMI
myoperator_unique_id = NULL            -- Not used for TeleCMI
```

**What Happens:**
1. ✅ App sends driver details to API
2. ✅ API validates Pooja's authorization
3. ✅ API checks driver exists
4. ✅ API calls TeleCMI to initiate call
5. ✅ Call logged to database with initial data
6. ✅ Success response sent to app
7. ✅ App shows "Call in Progress" dialog

---

### Stage 2: Call in Progress (Automatic via Webhooks)
**When:** TeleCMI sends webhook notifications

**API Called:** `POST /api/telecmi_production_api.php?action=webhook`

**Fields Updated by Webhooks:**

#### When Call Starts (call.initiated):
```sql
call_status = 'pending'                -- Call is ringing
call_start_time = NOW()                -- Updated to actual start time
webhook_data = {...}                   -- Webhook payload stored
updated_at = NOW()                     -- Updated
```

#### When Call is Answered (call.answered):
```sql
call_status = 'connected'              -- Call is connected
webhook_data = {...}                   -- Webhook payload stored
updated_at = NOW()                     -- Updated
```

#### When Call Ends (call.ended):
```sql
call_status = 'completed'              -- Call ended (or 'failed')
call_duration = 120                    -- Duration from TeleCMI
call_end_time = NOW()                  -- When call ended
call_completed_at = NOW()              -- When call completed
recording_url = 'https://...'          -- Recording URL (if available)
webhook_data = {...}                   -- Webhook payload stored
updated_at = NOW()                     -- Updated
```

**What Happens:**
1. ✅ Pooja's phone rings
2. ✅ She answers
3. ✅ Connected to driver
4. ✅ They talk
5. ✅ Call ends
6. ✅ TeleCMI sends webhooks
7. ✅ Database updated automatically

---

### Stage 3: Feedback Submission (Manual by User)
**When:** User submits feedback via feedback modal in the app

**API Called:** `POST /api/telecmi_production_api.php?action=update_feedback`

**Fields Filled by User (via Feedback Modal):**
```sql
-- User Input Fields (Filled Manually)
call_status = 'completed'              -- ✍️ User confirms status
feedback = 'Interested'                -- ✍️ User selects feedback
remarks = 'Driver wants more details'  -- ✍️ User types remarks
notes = 'Follow up next week'          -- ✍️ User adds notes (optional)

-- Timestamps Updated
call_completed_at = NOW()              -- Confirmed completion time
call_end_time = NOW()                  -- Confirmed end time
updated_at = NOW()                     -- Last update
```

**Request Body:**
```json
{
  "reference_id": "telecmi_xxxxx",
  "status": "completed",
  "feedback": "Interested",
  "remarks": "Driver wants more details about the job",
  "notes": "Follow up next week",
  "call_duration": 120
}
```

**What Happens:**
1. ✅ User sees feedback modal
2. ✍️ User selects call status
3. ✍️ User chooses feedback option
4. ✍️ User types remarks
5. ✍️ User adds notes (optional)
6. ✅ User taps Submit
7. ✅ App sends feedback to API
8. ✅ Database updated with user input
9. ✅ Driver removed from fresh leads

---

## 📊 Field Filling Summary

### Automatic Fields (Filled by System):
| Field | When Filled | Source |
|-------|-------------|--------|
| `caller_id` | Call initiation | System (Pooja's ID) |
| `tc_for` | Call initiation | System ('TeleCMI') |
| `user_id` | Call initiation | System (Driver ID) |
| `driver_name` | Call initiation | Database (users table) |
| `caller_number` | Call initiation | Database (admins table) |
| `user_number` | Call initiation | Database (users table) |
| `reference_id` | Call initiation | System (generated) |
| `api_response` | Call initiation | TeleCMI API response |
| `ip_address` | Call initiation | Server ($_SERVER) |
| `call_time` | Call initiation | System (NOW()) |
| `created_at` | Call initiation | System (NOW()) |
| `call_initiated_at` | Call initiation | System (NOW()) |
| `call_start_time` | Call initiation | System (NOW()) |
| `webhook_data` | During call | TeleCMI webhooks |
| `call_duration` | Call end | TeleCMI webhook |
| `recording_url` | Call end | TeleCMI webhook |
| `call_end_time` | Call end | TeleCMI webhook |
| `call_completed_at` | Call end | TeleCMI webhook |

### Manual Fields (Filled by User via Feedback Modal):
| Field | When Filled | Source |
|-------|-------------|--------|
| `call_status` | ✍️ Feedback submission | User selection |
| `feedback` | ✍️ Feedback submission | User selection |
| `remarks` | ✍️ Feedback submission | User input |
| `notes` | ✍️ Feedback submission | User input (optional) |

### Updated Fields:
| Field | When Updated | Source |
|-------|--------------|--------|
| `updated_at` | Every update | System (NOW()) |
| `call_status` | Multiple times | System → User |
| `call_duration` | Webhook → Feedback | TeleCMI → User |

---

## 🎯 Complete Example

### Initial Insert (Call Initiation):
```sql
INSERT INTO call_logs (
  caller_id, tc_for, user_id, driver_name,
  call_status, feedback, remarks, notes,
  call_duration, caller_number, user_number,
  call_time, reference_id, api_response,
  created_at, updated_at, call_initiated_at,
  ip_address, call_start_time
) VALUES (
  3, 'TeleCMI', 7541, 'Shahidul islam',
  'pending', NULL, NULL, NULL,
  0, '+917678361210', '+916000193973',
  NOW(), 'telecmi_xxxxx', '{"type":"telecmi"...}',
  NOW(), NOW(), NOW(),
  '122.161.49.29', NOW()
);
```

### Webhook Update (Call Connected):
```sql
UPDATE call_logs 
SET call_status = 'connected',
    webhook_data = '{"event":"call.answered"...}',
    updated_at = NOW()
WHERE reference_id = 'telecmi_xxxxx';
```

### Webhook Update (Call Ended):
```sql
UPDATE call_logs 
SET call_status = 'completed',
    call_duration = 120,
    call_end_time = NOW(),
    call_completed_at = NOW(),
    recording_url = 'https://recordings.telecmi.com/...',
    webhook_data = '{"event":"call.ended"...}',
    updated_at = NOW()
WHERE reference_id = 'telecmi_xxxxx';
```

### User Feedback Update:
```sql
UPDATE call_logs 
SET call_status = 'completed',
    feedback = 'Interested',
    remarks = 'Driver wants more details about the job',
    notes = 'Follow up next week',
    call_duration = 120,
    call_completed_at = NOW(),
    call_end_time = NOW(),
    updated_at = NOW()
WHERE reference_id = 'telecmi_xxxxx';
```

---

## 📱 Flutter App Integration

### Feedback Modal Fields:

```dart
// Call Status (Required)
enum CallStatus {
  pending,
  connected,
  not_connected,
  busy,
  no_answer,
  callback,
  callback_later,
  not_reachable,
  not_interested,
  invalid,
  completed,
  failed,
  cancelled
}

// Feedback (Required)
String feedback = 'Interested'; // or 'Not Interested', 'Didn't Pick', etc.

// Remarks (Optional)
String remarks = 'Driver wants more details about the job';

// Notes (Optional)
String notes = 'Follow up next week';

// Call Duration (Automatic from TeleCMI)
int callDuration = 120; // seconds
```

### API Call from Flutter:
```dart
final result = await ApiService.updateCallFeedback(
  referenceId: callId,
  callStatus: 'completed',
  feedback: 'Interested',
  remarks: 'Driver wants more details',
  callDuration: 120,
);
```

---

## ✅ Summary

### Automatic (System Fills):
- ✅ All identification fields (IDs, names, numbers)
- ✅ All timestamps (created, initiated, start, end)
- ✅ TeleCMI data (reference_id, api_response, webhook_data)
- ✅ Technical data (IP address, recording URL)
- ✅ Initial call status ('pending')

### Manual (User Fills via Feedback Modal):
- ✍️ **call_status** - Final status after call
- ✍️ **feedback** - User's feedback selection
- ✍️ **remarks** - User's comments/notes
- ✍️ **notes** - Additional notes (optional)

### Hybrid (System then User):
- 🔄 **call_duration** - From TeleCMI webhook, confirmed by user
- 🔄 **call_status** - Starts as 'pending', updated by webhooks, finalized by user

---

**This ensures a complete audit trail of the call with both automatic system data and manual user feedback!** 🎉
