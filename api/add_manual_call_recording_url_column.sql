-- Add manual_call_recording_url column to call_logs table
-- This column stores URLs of manually uploaded call recordings

ALTER TABLE call_logs 
ADD COLUMN IF NOT EXISTS manual_call_recording_url VARCHAR(500) NULL 
AFTER recording_url
COMMENT 'URL of manually uploaded call recording';

-- Add index for faster queries
CREATE INDEX idx_manual_recording_url ON call_logs(manual_call_recording_url);

-- Show the updated table structure
DESCRIBE call_logs;
