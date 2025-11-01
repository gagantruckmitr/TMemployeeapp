# Manual Call Recording Column Update - Summary

## What Changed?

The call recording upload feature now stores URLs in a **separate column** called `manual_call_recording_url` instead of `recording_url`.

## Why the Change?

To maintain **clear separation** between:
- **Automatic IVR recordings** → stored in `recording_url`
- **Manual user uploads** → stored in `manual_call_recording_url`

This prevents conflicts and provides better data organization.

---

## Updated Files

### 1. `api/upload_recording_api.php`
**Changes**:
- Column name changed from `recording_url` to `manual_call_recording_url`
- Auto-creates the new column if it doesn't exist
- Updates the correct column when uploading

### 2. `api/add_manual_call_recording_url_column.sql` (NEW)
**Purpose**: SQL migration file to manually add the column if needed

### 3. `CALL_RECORDING_UPLOAD_COMPLETE.md`
**Changes**: Updated documentation to reflect new column name

### 4. `RECORDING_COLUMNS_EXPLAINED.md` (NEW)
**Purpose**: Comprehensive guide explaining both recording columns

---

## Database Changes

### New Column
```sql
ALTER TABLE call_logs 
ADD COLUMN manual_call_recording_url VARCHAR(500) NULL 
AFTER recording_url
COMMENT 'URL of manually uploaded call recording';
```

### Column Structure
```
call_logs table:
├── recording_url              (IVR/MyOperator automatic recordings)
└── manual_call_recording_url  (User uploaded recordings)
```

---

## How It Works Now

### Upload Flow
1. User uploads recording via app
2. File saved to: `/voice-recording/TMID_CallerID_DateTime.ext`
3. URL generated: `https://truckmitr.com/truckmitr-app/voice-recording/TMID_CallerID_DateTime.ext`
4. **Database updated**: `call_logs.manual_call_recording_url = [URL]`
5. Success response returned

### Example
```
File: TM123456_5_20241101143025.mp3
URL: https://truckmitr.com/truckmitr-app/voice-recording/TM123456_5_20241101143025.mp3
Database: call_logs.manual_call_recording_url = [URL]
```

---

## Migration Steps

### Automatic (Recommended)
The API automatically creates the column on first upload. No action needed!

### Manual (Optional)
If you want to add the column immediately:

```bash
# Option 1: Run SQL file
mysql -u username -p database_name < api/add_manual_call_recording_url_column.sql

# Option 2: Run SQL command directly
mysql -u username -p database_name -e "ALTER TABLE call_logs ADD COLUMN manual_call_recording_url VARCHAR(500) NULL AFTER recording_url;"
```

---

## Testing

### Test the Upload
1. Open the app
2. Make a call
3. Open call feedback modal
4. Upload a recording
5. Submit feedback
6. Check database: `SELECT manual_call_recording_url FROM call_logs WHERE id = [call_log_id];`

### Expected Result
```sql
-- Before upload
manual_call_recording_url: NULL

-- After upload
manual_call_recording_url: https://truckmitr.com/truckmitr-app/voice-recording/TM123456_5_20241101143025.mp3
```

---

## Benefits

✅ **Clear Separation**: IVR vs Manual recordings in different columns  
✅ **No Conflicts**: Both can exist for the same call  
✅ **Better Tracking**: Easy to identify recording source  
✅ **Backward Compatible**: Existing `recording_url` data unchanged  
✅ **Auto-Migration**: Column created automatically if missing  

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Column Name** | recording_url | manual_call_recording_url |
| **Purpose** | Mixed (IVR + Manual) | Manual uploads only |
| **IVR Recordings** | recording_url | recording_url (unchanged) |
| **Manual Uploads** | recording_url | manual_call_recording_url |
| **Conflicts** | Possible | None |

The change is **complete and ready to use**! 🎉
