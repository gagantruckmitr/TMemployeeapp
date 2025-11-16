# Transporter Smart Calling Implementation

## Overview
Complete implementation of transporter welcome calls in the Smart Calling feature with toggle functionality between drivers and transporters.

## Features Implemented

### 1. **Toggle Interface**
- Modern toggle button to switch between Drivers and Transporters
- Separate data loading and management for each type
- Smooth animations and transitions

### 2. **Transporter Data Models**
**File:** `lib/models/smart_calling_models.dart`

Added:
- `TransporterConnectedFeedback` enum with welcome call options:
  - Callback Later
  - Agree for Subscription
  - Agree for Subscription (Tomorrow)
  - Job Details received
  - Not a Transporter
  - Driver, but registered as Transporter

- `TransporterContact` model (similar to DriverContact)
- Updated `CallFeedback` to support transporter feedback

### 3. **UI Components**

#### Transporter Feedback Modal
**File:** `lib/features/telecaller/widgets/transporter_feedback_modal.dart`
- Dedicated feedback modal for transporter welcome calls
- Connected/Not Connected status options
- Transporter-specific feedback choices
- Optional remarks field
- Same professional UI as driver feedback

#### Transporter Contact Card
**File:** `lib/features/telecaller/widgets/transporter_contact_card.dart`
- Contact card UI for transporters
- Profile completion ring
- Company/transport name display
- Same call button functionality as drivers

### 4. **Smart Calling Page Updates**
**File:** `lib/features/telecaller/smart_calling_page.dart`

Added:
- Toggle section between Drivers and Transporters
- Separate state management for both types
- Transporter call methods:
  - `_startTransporterCall()` - Initiates calls
  - `_handleEasyGoTransporterIVR()` - EasyGo IVR integration
  - `_handleClick2CallTransporterIVR()` - Click2Call IVR integration
  - `_handleManualTransporterCall()` - Manual dialer
  - `_updateTransporterStatus()` - Updates feedback
- Dynamic contact list rendering based on toggle

### 5. **Backend API**

#### Transporter Leads API
**File:** `api/transporter_leads_api.php`

Production-ready API with:
- **GET** `/transporter_leads_api.php?action=transporter_leads`
  - Fetches uncalled transporters assigned to telecaller
  - Parameters: `caller_id`, `limit`
  - Returns: Array of transporter contacts

- **GET** `/transporter_leads_api.php?action=transporter_leads&status={status}`
  - Fetches transporters by call status
  - Parameters: `caller_id`, `status`, `limit`
  - Statuses: connected, callback, callback_later, not_reachable, not_interested, invalid

- **POST** `/transporter_leads_api.php?action=mark_called`
  - Logs a call to transporter
  - Body: `transporter_id`, `caller_id`, `status`, `feedback`, `remarks`
  - Creates entry in `call_logs` table with `call_type='welcome_call'`

Features:
- Profile completion calculation for transporters
- Image URL construction
- Subscription status mapping
- Call logs table auto-creation
- Error handling and logging
- Caching support

#### Test File
**File:** `api/test_transporter_leads.php`
- Interactive HTML test interface
- Test all API endpoints
- View request/response data

### 6. **Service Layer**

#### API Service
**File:** `lib/core/services/api_service.dart`

Added methods:
- `getTransporters()` - Fetch transporter leads
- `getTransportersByStatus()` - Fetch by call status
- `updateTransporterCallStatus()` - Update call feedback
- `_mapJsonToTransporterContact()` - JSON to model mapping

#### Smart Calling Service
**File:** `lib/core/services/smart_calling_service.dart`

Added:
- `getTransporters()` - With caching
- `updateTransporterCallStatus()` - Status updates
- `refreshTransporters()` - Force refresh
- Separate cache management for transporters

## Database Schema

### call_logs Table
The API uses the existing `call_logs` table with these key fields for transporters:
- `transporter_id` - Transporter user ID
- `transporter_tm_id` - Transporter TM ID
- `transporter_name` - Transporter name
- `transporter_mobile` - Transporter phone
- `call_type` - Set to 'welcome_call' for transporters
- `call_status` - Call outcome
- `feedback` - Feedback text
- `remarks` - Additional notes

## Call Flow

### 1. Transporter Selection
```
User opens Smart Calling → Toggles to "Transporters" → Sees assigned transporters

Filtering Logic:
✅ Include: Transporters with role = 'transporter'
✅ Include: Transporters NOT in jobs table (no jobs yet)
✅ Include: Transporters NOT called by any telecaller
✅ Include: Assigned via round-robin to current telecaller
❌ Exclude: Transporters with existing jobs
❌ Exclude: Transporters already called
```

### 2. Initiate Call
```
User clicks call button → Selects call type (Manual/EasyGo IVR/Click2Call) → Call initiated
```

### 3. Call Feedback
```
Call ends → Feedback modal appears → User selects:
- Connected:
  - Callback Later
  - Agree for Subscription
  - Agree for Subscription (Tomorrow)
  - Job Details received
  - Not a Transporter
  - Driver, but registered as Transporter
- Not Connected:
  - Ringing / Call Busy
  - Switched Off / Not Reachable
```

### 4. Save Feedback
```
User submits → API logs call → Transporter removed from list → Success message
```

## API Integration

### Fetch Transporters
```dart
final transporters = await SmartCallingService.instance.getTransporters(
  limit: 50,
  forceRefresh: false,
);
```

### Update Transporter Status
```dart
final success = await SmartCallingService.instance.updateTransporterCallStatus(
  transporterId: '123',
  status: CallStatus.connected,
  feedback: 'Agree for Subscription',
  remarks: 'Interested in premium plan',
);
```

## Testing

### 1. Test API Endpoints
Open in browser:
```
http://your-domain.com/api/test_transporter_leads.php
```

### 2. Test in App
1. Login as telecaller
2. Navigate to Smart Calling
3. Toggle to "Transporters"
4. Verify transporters load
5. Make a test call
6. Submit feedback
7. Verify transporter is removed from list

### 3. Verify Database
```sql
-- Check call logs
SELECT * FROM call_logs 
WHERE call_type = 'welcome_call' 
AND transporter_id IS NOT NULL 
ORDER BY created_at DESC 
LIMIT 10;
```

## Configuration

### Automatic Round-Robin Assignment
The system now automatically assigns transporters to telecallers using **round-robin distribution**:

- **No manual assignment needed** - The API automatically distributes transporters
- **Fair distribution** - Each telecaller gets an equal share
- **Smart filtering** - Only includes transporters who:
  1. Have role = 'transporter'
  2. Do NOT have any jobs (not in jobs.transporter_id)
  3. Have NOT been called yet (not in call_logs)

### Assignment Logic
```
Transporter 1 → Telecaller 1
Transporter 2 → Telecaller 2
Transporter 3 → Telecaller 3
Transporter 4 → Telecaller 1 (round-robin repeats)
Transporter 5 → Telecaller 2
...and so on
```

### Check Assignment Distribution
Use the debug script to verify assignment:
```
http://your-domain.com/api/debug_transporter_assignment.php
```

Or use the test page:
```
http://your-domain.com/api/test_transporter_assignment.html
```

### Manual Assignment (Optional)
If you need to manually assign specific transporters:
```sql
UPDATE users 
SET assigned_to = {telecaller_user_id} 
WHERE role = 'transporter' 
AND id IN (1, 2, 3);
```

Note: Manual assignment via `assigned_to` field is now **ignored** by the API in favor of automatic round-robin distribution.

## Feedback Options Mapping

### Connected Status
| Display Text | Database Value |
|-------------|----------------|
| Callback Later | Connected: Callback Later |
| Agree for Subscription | Connected: Agree for Subscription |
| Agree for Subscription (Tomorrow) | Connected: Agree for Subscription (Tomorrow) |
| Job Details received | Connected: Job Details received |
| Not a Transporter | Connected: Not a Transporter |
| Driver, but registered as Transporter | Connected: Driver, but registered as Transporter |

### Not Connected Status
| Display Text | Database Value |
|-------------|----------------|
| Ringing / Call Busy | Not Connected: Ringing / Call Busy |
| Switched Off / Not Reachable | Not Connected: Switched Off / Not Reachable |

## Performance Optimizations

1. **Caching**: 5-minute cache for transporter data
2. **Pagination**: Limit parameter for API calls
3. **Lazy Loading**: Data loaded only when transporter toggle is active
4. **Efficient Queries**: Indexed database queries
5. **Profile Completion**: Calculated on-demand

## Security Features

1. **Caller ID Validation**: All requests require valid telecaller ID
2. **Assignment Check**: Only assigned transporters are shown
3. **SQL Injection Prevention**: Prepared statements
4. **CORS Headers**: Configured for app access
5. **Error Logging**: Server-side error tracking

## Troubleshooting

### No Transporters Showing
1. Check if transporters are assigned to telecaller
2. Verify `assigned_to` field in database
3. Check API response in test file
4. Verify telecaller ID is correct

### Call Not Logging
1. Check `call_logs` table exists
2. Verify API endpoint is accessible
3. Check network logs in app
4. Verify transporter ID is valid

### Feedback Not Saving
1. Check API response for errors
2. Verify call_logs table structure
3. Check database permissions
4. Review server error logs

## Future Enhancements

1. **Analytics Dashboard**: Track transporter call metrics
2. **Bulk Assignment**: Assign multiple transporters at once
3. **Call Recording**: Upload and link recordings
4. **Follow-up Reminders**: Automated callback scheduling
5. **Performance Reports**: Telecaller performance tracking

## Files Modified/Created

### Created Files
- `lib/features/telecaller/widgets/transporter_feedback_modal.dart`
- `lib/features/telecaller/widgets/transporter_contact_card.dart`
- `api/transporter_leads_api.php`
- `api/test_transporter_leads.php`
- `TRANSPORTER_SMART_CALLING_IMPLEMENTATION.md`

### Modified Files
- `lib/models/smart_calling_models.dart`
- `lib/features/telecaller/smart_calling_page.dart`
- `lib/core/services/smart_calling_service.dart`
- `lib/core/services/api_service.dart`

## Deployment Checklist

- [ ] Deploy `transporter_leads_api.php` to server
- [ ] Test API endpoints using test file
- [ ] Verify database connection
- [ ] Assign transporters to telecallers
- [ ] Test in development environment
- [ ] Test call flow end-to-end
- [ ] Verify feedback saves correctly
- [ ] Test with multiple telecallers
- [ ] Monitor error logs
- [ ] Deploy to production

## Support

For issues or questions:
1. Check error logs in `api/transporter_leads_api.php`
2. Test API using `test_transporter_leads.php`
3. Verify database queries
4. Check app network logs
5. Review this documentation

---

**Version:** 1.0  
**Last Updated:** November 22, 2025  
**Status:** Production Ready ✅
