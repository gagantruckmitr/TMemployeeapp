-- Add caller_id column to job_brief_table
ALTER TABLE `job_brief_table` 
ADD COLUMN `caller_id` int(11) DEFAULT NULL COMMENT 'Telecaller ID who made the call' AFTER `job_id`,
ADD KEY `caller_id` (`caller_id`);
