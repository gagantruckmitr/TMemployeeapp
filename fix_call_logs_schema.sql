-- Fix call_logs table schema
-- Run this in phpMyAdmin or MySQL command line

USE truckmitr;

-- Backup existing data (if any)
DROP TABLE IF EXISTS call_logs_backup;
CREATE TABLE call_logs_backup AS SELECT * FROM call_logs;

-- Drop old table
DROP TABLE IF EXISTS call_logs;

-- Create new table with correct schema
CREATE TABLE `call_logs` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `job_id` varchar(255) DEFAULT NULL COMMENT 'Job reference (optional)',
  `job_name` varchar(255) DEFAULT NULL,
  `caller_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Telecaller user ID',
  `user_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Driver user ID',
  `caller_number` varchar(20) DEFAULT NULL,
  `user_number` varchar(20) NOT NULL,
  `transporter_id` bigint(20) UNSIGNED DEFAULT NULL,
  `transporter_tm_id` varchar(255) DEFAULT NULL,
  `transporter_name` varchar(255) DEFAULT NULL,
  `transporter_mobile` varchar(20) DEFAULT NULL,
  `driver_id` bigint(20) UNSIGNED DEFAULT NULL,
  `driver_tm_id` varchar(255) DEFAULT NULL,
  `driver_name` varchar(255) DEFAULT NULL,
  `driver_mobile` varchar(20) DEFAULT NULL,
  `call_status` enum('pending','connected','callback','callback_later','not_reachable','not_interested','invalid','completed','failed','cancelled') DEFAULT 'pending',
  `call_type` varchar(50) DEFAULT 'telecaller',
  `call_count` int(11) DEFAULT 1,
  `call_initiated_by` varchar(50) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `reference_id` varchar(100) DEFAULT NULL COMMENT 'MyOperator reference ID',
  `api_response` text DEFAULT NULL COMMENT 'MyOperator API response',
  `call_duration` int(11) DEFAULT 0 COMMENT 'Call duration in seconds',
  `call_time` timestamp NULL DEFAULT NULL,
  `call_initiated_at` timestamp NULL DEFAULT NULL,
  `call_completed_at` timestamp NULL DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_caller_id` (`caller_id`),
  KEY `idx_caller_user` (`caller_id`, `user_id`),
  KEY `idx_reference_id` (`reference_id`),
  KEY `idx_call_status` (`call_status`),
  KEY `idx_call_time` (`call_time`),
  KEY `idx_job_id` (`job_id`),
  KEY `idx_driver_id` (`driver_id`),
  KEY `idx_transporter_id` (`transporter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Restore data from backup (if compatible columns exist)
INSERT INTO call_logs 
(id, caller_id, user_id, caller_number, user_number, call_status, 
 feedback, remarks, reference_id, api_response, call_time, created_at, updated_at)
SELECT 
    id, 
    caller_id, 
    user_id, 
    COALESCE(caller_number, ''),
    user_number, 
    COALESCE(call_status, 'pending'),
    feedback, 
    remarks, 
    reference_id, 
    api_response, 
    call_time, 
    created_at, 
    updated_at
FROM call_logs_backup;

-- Verify the fix
SELECT 'Table recreated successfully!' as Status;
SELECT COUNT(*) as RecordsRestored FROM call_logs;

-- Optional: Drop backup table after verification
-- DROP TABLE call_logs_backup;
