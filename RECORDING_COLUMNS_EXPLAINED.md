# Call Recording Columns in call_logs Table

## Overview
The `call_logs` table now has two separate columns for storing call recording URLs, each serving a different purpose.

## Column Structure

### 1. `recording_url` (VARCHAR 500)
**Purpose**: Stores URLs of automatic call recordings from IVR/MyOperator system

**Source**: 
- Automatically populated by MyOperator webhook
- Set when IVR calls are made through the system
- Managed by the telephony provider

**Example**:
```
https://myoperator.com/recordings/call_12345.mp3
```

**Use Case**:
- IVR calls initiated through MyOperator
- Automatic call recording by telephony system
- System-generated recordings

---

### 2. `manual_call_recording_url` (VARCHAR 500)
**Purpose**: Stores URLs of manually uploaded call recordings via the mobile app

**Source**:
- Uploaded by telecallers through the app
- User-initiated file upload
- Managed by upload_recording_api.php

**Example**:
```
https://truckmitr.com/truckmitr-app/voice-recording/TM123456_5_20241101143025.mp3
```

**Use Case**:
- Manual calls made directly from phone dialer
- Calls recorded on telecaller's device
- User uploads recording after call completion

---

## Why Two Columns?

### Separation of Concerns
1. **Different Sources**: IVR system vs Manual upload
2. **Different Workflows**: Automatic vs User-initiated
3. **Different Locations**: External provider vs Internal server
4. **Different Formats**: Provider format vs Standardized format

### Benefits
- ✅ Clear distinction between automatic and manual recordings
- ✅ Both recording types can coexist for the same call
- ✅ Easy to query and filter by recording source
- ✅ No data conflicts or overwrites
- ✅ Better audit trail and tracking

---

## Database Schema

```sql
CREATE TABLE call_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT,
    caller_id INT,
    call_time DATETIME,
    duration INT,
    status VARCHAR(50),
    feedback TEXT,
    remarks TEXT,
    reference_id VARCHAR(100),
    api_response TEXT,
    
    -- IVR/MyOperator automatic recording
    recording_url VARCHAR(500) NULL 
        COMMENT 'URL of automatic IVR call recording',
    
    -- Manually uploaded recording
    manual_call_recording_url VARCHAR(500) NULL 
        COMMENT 'URL of manually uploaded call recording',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## Usage Examples

### Query calls with IVR recordings
```sql
SELECT * FROM call_logs 
WHERE recording_url IS NOT NULL;
```

### Query calls with manual recordings
```sql
SELECT * FROM call_logs 
WHERE manual_call_recording_url IS NOT NULL;
```

### Query calls with any recording
```sql
SELECT * FROM call_logs 
WHERE recording_url IS NOT NULL 
   OR manual_call_recording_url IS NOT NULL;
```

### Query calls with both recordings
```sql
SELECT * FROM call_logs 
WHERE recording_url IS NOT NULL 
  AND manual_call_recording_url IS NOT NULL;
```

---

## API Integration

### Automatic Recording (IVR)
- **Populated by**: MyOperator webhook (`api/myoperator_webhook.php`)
- **Column**: `recording_url`
- **Trigger**: Automatic after IVR call completion

### Manual Recording Upload
- **Populated by**: Upload API (`api/upload_recording_api.php`)
- **Column**: `manual_call_recording_url`
- **Trigger**: User uploads file through app

---

## Migration

To add the new column to existing database:

```sql
-- Run this SQL command
ALTER TABLE call_logs 
ADD COLUMN IF NOT EXISTS manual_call_recording_url VARCHAR(500) NULL 
AFTER recording_url
COMMENT 'URL of manually uploaded call recording';

-- Add index for performance
CREATE INDEX idx_manual_recording_url 
ON call_logs(manual_call_recording_url);
```

Or use the provided migration file:
```bash
mysql -u username -p database_name < api/add_manual_call_recording_url_column.sql
```

---

## Summary

| Feature | recording_url | manual_call_recording_url |
|---------|--------------|---------------------------|
| **Source** | IVR/MyOperator | User Upload |
| **Automatic** | Yes | No |
| **Location** | External Provider | Internal Server |
| **Format** | Provider-specific | TMID_CallerID_DateTime |
| **Populated By** | Webhook | Upload API |
| **User Control** | No | Yes |

Both columns work independently and can coexist, providing complete recording coverage for all call types.
