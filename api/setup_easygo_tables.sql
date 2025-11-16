-- EasyGo IVR Database Tables Setup

-- Table for storing EasyGo API tokens
CREATE TABLE IF NOT EXISTS `easygo_tokens` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `token` TEXT NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for logging EasyGo call attempts
CREATE TABLE IF NOT EXISTS `easygo_call_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `reference_id` VARCHAR(100) NOT NULL,
  `telecaller_phone` VARCHAR(20) NOT NULL,
  `client_phone` VARCHAR(20) NOT NULL,
  `status` ENUM('initiated', 'connected', 'failed', 'completed') DEFAULT 'initiated',
  `api_response` TEXT,
  `call_duration` INT DEFAULT NULL COMMENT 'Duration in seconds',
  `feedback` TEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_reference_id` (`reference_id`),
  INDEX `idx_telecaller_phone` (`telecaller_phone`),
  INDEX `idx_client_phone` (`client_phone`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert initial token (will be replaced by generated token)
INSERT INTO `easygo_tokens` (`token`, `expires_at`) 
VALUES (
  'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjaWQiOiI1MTEiLCJ1c2VyX2lkIjoiMTI4OSIsInVzZXJfbG9naW4iOiJhZG1pbkB0cnVja21pdHIuY29tIiwia3ljIjoiMSIsImV4cCI6MTc2MzQ4MDI5NywiY2xpZW50aXAiOm51bGwsImlwIjoiNDkuMzYuMTQ0LjI0MyIsImlzYWRtaW4iOiIxIiwiZGlyZWN0RGlhbCI6IjEiLCJzZXJ2ZXIiOm51bGx9.9sLOjmgP0D0cmPLe54C8ha8HcNnmwSn6QP3EEGXn5FY',
  FROM_UNIXTIME(1763480297)
)
ON DUPLICATE KEY UPDATE 
  token = VALUES(token),
  expires_at = VALUES(expires_at);
