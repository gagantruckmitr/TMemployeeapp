-- ============================================
-- TeleCMI Production: Call Logs Table Setup
-- ============================================
-- Run this SQL to ensure your call_logs table is production-ready
-- ============================================

-- Create call_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS `call_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reference_id` varchar(255) DEFAULT NULL COMMENT 'TeleCMI call ID or unique reference',
  `caller_id` int(11) DEFAULT NULL COMMENT 'User ID who made the call (3 for Pooja)',
  `driver_id` varchar(50) DEFAULT NULL COMMENT 'Driver ID from admin table',
  `driver_mobile` varchar(20) DEFAULT NULL COMMENT 'Driver phone number',
  `driver_name` varchar(255) DEFAULT NULL COMMENT 'Driver name',
  `driver_tmid` varchar(50) DEFAULT NULL COMMENT 'Driver TMID',
  `call_type` enum('ivr','manual') DEFAULT 'manual' COMMENT 'IVR or Manual call',
  `status` varchar(50) DEFAULT 'initiated' COMMENT 'Call status: initiated, ringing, connected, completed, failed',
  `provider` enum('telecmi','manual','myoperator') DEFAULT 'manual' COMMENT 'Call provider',
  `telecmi_user_id` varchar(100) DEFAULT NULL COMMENT 'TeleCMI user ID (5003_33336628)',
  `feedback` text DEFAULT NULL COMMENT 'Call feedback: Interested, Not Interested, etc.',
  `remarks` text DEFAULT NULL COMMENT 'Additional remarks or notes',
  `call_duration` int(11) DEFAULT 0 COMMENT 'Call duration in seconds',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When call was initiated',
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp() COMMENT 'Last update time',
  PRIMARY KEY (`id`),
  KEY `idx_reference_id` (`reference_id`),
  KEY `idx_caller_id` (`caller_id`),
  KEY `idx_driver_id` (`driver_id`),
  KEY `idx_provider` (`provider`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Call logs for TeleCMI and manual calls';

-- Add missing columns if table already exists
ALTER TABLE `call_logs` 
ADD COLUMN IF NOT EXISTS `driver_name` varchar(255) DEFAULT NULL COMMENT 'Driver name' AFTER `driver_mobile`,
ADD COLUMN IF NOT EXISTS `driver_tmid` varchar(50) DEFAULT NULL COMMENT 'Driver TMID' AFTER `driver_name`,
ADD COLUMN IF NOT EXISTS `telecmi_user_id` varchar(100) DEFAULT NULL COMMENT 'TeleCMI user ID' AFTER `provider`;

-- Update provider enum to include telecmi if not present
ALTER TABLE `call_logs` 
MODIFY COLUMN `provider` enum('telecmi','manual','myoperator') DEFAULT 'manual' COMMENT 'Call provider';

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS `idx_reference_id` ON `call_logs` (`reference_id`);
CREATE INDEX IF NOT EXISTS `idx_caller_id` ON `call_logs` (`caller_id`);
CREATE INDEX IF NOT EXISTS `idx_driver_id` ON `call_logs` (`driver_id`);
CREATE INDEX IF NOT EXISTS `idx_provider` ON `call_logs` (`provider`);
CREATE INDEX IF NOT EXISTS `idx_created_at` ON `call_logs` (`created_at`);
CREATE INDEX IF NOT EXISTS `idx_status` ON `call_logs` (`status`);

-- ============================================
-- Verification Queries
-- ============================================

-- Check table structure
DESCRIBE call_logs;

-- Check existing data
SELECT COUNT(*) as total_calls, provider, status 
FROM call_logs 
GROUP BY provider, status;

-- Check Pooja's TeleCMI calls
SELECT * FROM call_logs 
WHERE caller_id = 3 AND provider = 'telecmi' 
ORDER BY created_at DESC 
LIMIT 10;

-- ============================================
-- Sample Data (Optional - for testing)
-- ============================================

-- Uncomment to insert sample data
/*
INSERT INTO call_logs (
  reference_id, caller_id, driver_id, driver_mobile, driver_name, driver_tmid,
  call_type, status, provider, telecmi_user_id, feedback, remarks, call_duration, created_at
) VALUES (
  'telecmi_sample_001', 3, 'test_driver_1', '919876543210', 'Test Driver', 'TM123456',
  'ivr', 'completed', 'telecmi', '5003_33336628', 'Interested', 'Test call', 120, NOW()
);
*/

-- ============================================
-- Cleanup Old Data (Optional)
-- ============================================

-- Uncomment to delete old test data
/*
DELETE FROM call_logs WHERE driver_id LIKE 'test_%';
*/

-- ============================================
-- Success Message
-- ============================================
SELECT '✅ Call logs table is ready for production!' as status;
