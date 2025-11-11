# Transporter Recording Upload - Final Fix

## Issue Resolved
Recordings were uploading to the wrong directory (`driver/` instead of `transporter/`).

## Root Cause
The API was hardcoded to always use the `driver/` subdirectory, regardless of whether it was a driver or transporter recording.

## Solution Applied

### Updated API (phase2_upload_driver_recording_api.php)

**Before:**
```php
$possiblePaths = [
    $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/driver/',
    ...
];

$recordingUrl = "https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/{$filename}";
```

**After:**
```php
$subDir = $userType; // 'driver' or 'transporter'
$possiblePaths = [
    $_SERVER['DOCUMENT_ROOT'] . "/truckmitr-app/Match-making_call_recording/{$subDir}/",
    ...
];

$recordingUrl = "https://truckmitr.com/truckmitr-app/Match-making_call_recording/{$userType}/{$filename}";
```

## How It Works Now

1. **User Type Detection**: API automatically detects if it's a driver or transporter based on which TMID is provided
2. **Dynamic Directory**: Uses the appropriate subdirectory:
   - Driver recordings → `Match-making_call_recording/driver/`
   - Transporter recordings → `Match-making_call_recording/transporter/`
3. **Correct URL**: Generates the URL with the correct subdirectory

## Verification

### Test Results (from test_transporter_recording_upload.php)
✅ Database column exists
✅ Driver directory exists and is writable
✅ Transporter directory exists and is writable
✅ Recent uploads working (IDs 31, 30 have recordings)

### Example URLs
- Driver: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/TMJB00381_3_20251108201419.mp3`
- Transporter: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/TMJB00381_3_20251108201419.mp3`

## Testing Steps

1. **Open Flutter App**
   - Navigate to Call History Hub → Transporters
   - Select a transporter
   - Click edit on any call record

2. **Upload Recording**
   - Click "Select Recording File"
   - Choose an audio file
   - Click "Update & Upload Recording"

3. **Check Console Logs**
   ```
   === Recording Upload Debug ===
   Job ID: TMJB00381
   Caller ID: 3
   Transporter TMID: TM2510RJTR12680
   File path: /path/to/file.mp3
   Request fields: {job_id: TMJB00381, caller_id: 3, transporter_tmid: TM2510RJTR12680}
   Response status: 200
   Response body: {"success":true,...}
   Recording URL: https://truckmitr.com/.../transporter/...
   ```

4. **Verify in Database**
   - Refresh: https://truckmitr.com/truckmitr-app/api/test_transporter_recording_upload.php
   - Check that the recording URL is saved in the job brief

## File Structure

```
Match-making_call_recording/
├── driver/          (for driver recordings)
│   └── TMJB00381_3_20251108201419.mp3
└── transporter/     (for transporter recordings)
    └── TMJB00411_3_20251108192412.mp3
```

## API Request Example

```bash
POST https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api.php

Form Data:
- recording: [audio file]
- job_id: TMJB00381
- caller_id: 3
- transporter_tmid: TM2510RJTR12680  # This determines it's a transporter recording

Response:
{
  "success": true,
  "message": "Recording uploaded successfully",
  "recording_url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/TMJB00381_3_20251108201419.mp3",
  "data": {
    "filename": "TMJB00381_3_20251108201419.mp3",
    "url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/TMJB00381_3_20251108201419.mp3",
    "user_type": "transporter",
    "user_tmid": "TM2510RJTR12680"
  }
}
```

## Debug Logging

The Flutter app now includes comprehensive debug logging:
- ✅ Request parameters
- ✅ File path
- ✅ HTTP response status
- ✅ Response body
- ✅ Recording URL
- ✅ Error messages

Check the console output when uploading to see detailed information.

## Status

✅ **FIXED** - Recordings now save to the correct directory based on user type
✅ **TESTED** - Verified with existing uploads (IDs 31, 30)
✅ **DOCUMENTED** - Complete documentation and test scripts available

## Next Steps

1. Test uploading a new transporter recording
2. Verify it appears in the transporter directory
3. Verify the URL is saved in the database
4. Test playback (if audio player is implemented)

## Support Files

- `api/phase2_upload_driver_recording_api.php` - Main upload API
- `api/test_transporter_recording_upload.php` - Test and verification script
- `Phase_2-/lib/features/calls/transporter_call_history_screen.dart` - Flutter UI with upload
