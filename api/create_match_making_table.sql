-- Create match_making table for tracking driver-transporter matches
-- Database: truckmitr

CREATE TABLE IF NOT EXISTS `match_making` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `caller_id` INT(11) NOT NULL COMMENT 'Telecaller ID who made the match',
  `tele_caller_name` VARCHAR(255) NOT NULL COMMENT 'Name of the telecaller',
  `unique_id_transporter` VARCHAR(50) NOT NULL COMMENT 'Transporter unique ID (TMID)',
  `unique_id_driver` VARCHAR(50) NOT NULL COMMENT 'Driver unique ID (TMID)',
  `transporter_name` VARCHAR(255) NOT NULL COMMENT 'Name of the transporter',
  `driver_name` VARCHAR(255) NOT NULL COMMENT 'Name of the driver',
  `application_id` VARCHAR(100) NULL COMMENT 'Application/Job application ID',
  `job_id` VARCHAR(100) NULL COMMENT 'Job posting ID',
  `feed_back` TEXT NULL COMMENT 'Feedback about the match',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',
  PRIMARY KEY (`id`),
  INDEX `idx_caller_id` (`caller_id`),
  INDEX `idx_transporter` (`unique_id_transporter`),
  INDEX `idx_driver` (`unique_id_driver`),
  INDEX `idx_application` (`application_id`),
  INDEX `idx_job` (`job_id`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tracks driver-transporter matchmaking by telecallers';

-- Show table structure
DESCRIBE match_making;

-- Show success message
SELECT 'match_making table created successfully!' AS message;
