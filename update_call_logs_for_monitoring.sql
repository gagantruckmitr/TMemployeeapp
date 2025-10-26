-- Add columns for MyOperator call monitoring
ALTER TABLE call_logs 
ADD COLUMN IF NOT EXISTS call_start_time DATETIME NULL AFTER call_duration,
ADD COLUMN IF NOT EXISTS call_end_time DATETIME NULL AFTER call_start_time,
ADD COLUMN IF NOT EXISTS recording_url VARCHAR(500) NULL AFTER call_end_time,
ADD COLUMN IF NOT EXISTS myoperator_unique_id VARCHAR(100) NULL AFTER recording_url,
ADD COLUMN IF NOT EXISTS webhook_data TEXT NULL AFTER myoperator_unique_id;

-- Add index for faster lookups
ALTER TABLE call_logs 
ADD INDEX idx_myoperator_unique_id (myoperator_unique_id),
ADD INDEX idx_reference_id (reference_id);
