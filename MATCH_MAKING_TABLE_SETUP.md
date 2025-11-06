# Match Making Table Setup

## Overview
Created a new `match_making` table in the `truckmitr` database to track driver-transporter matches made by telecallers.

## Table Structure

### Table Name: `match_making`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | INT(11) | NO | PRI | AUTO_INCREMENT | Primary key |
| caller_id | INT(11) | NO | MUL | - | Telecaller ID who made the match |
| tele_caller_name | VARCHAR(255) | NO | - | - | Name of the telecaller |
| unique_id_transporter | VARCHAR(50) | NO | MUL | - | Transporter unique ID (TMID) |
| unique_id_driver | VARCHAR(50) | NO | MUL | - | Driver unique ID (TMID) |
| transporter_name | VARCHAR(255) | NO | - | - | Name of the transporter |
| driver_name | VARCHAR(255) | NO | - | - | Name of the driver |
| application_id | VARCHAR(100) | YES | MUL | NULL | Application/Job application ID |
| job_id | VARCHAR(100) | YES | MUL | NULL | Job posting ID |
| feed_back | TEXT | YES | - | NULL | Feedback about the match |
| created_at | TIMESTAMP | NO | MUL | CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | NO | - | CURRENT_TIMESTAMP | Record update timestamp |

## Indexes

The table includes the following indexes for optimal query performance:

1. **PRIMARY KEY**: `id`
2. **idx_caller_id**: Index on `caller_id` - Fast lookup by telecaller
3. **idx_transporter**: Index on `unique_id_transporter` - Fast lookup by transporter
4. **idx_driver**: Index on `unique_id_driver` - Fast lookup by driver
5. **idx_application**: Index on `application_id` - Fast lookup by application
6. **idx_job**: Index on `job_id` - Fast lookup by job
7. **idx_created_at**: Index on `created_at` - Fast date-based queries

## Installation Methods

### Method 1: Using PHP Script (Recommended)

1. Navigate to the API endpoint in your browser:
   ```
   https://truckmitr.com/truckmitr-app/api/create_match_making_table.php
   ```

2. Or use curl:
   ```bash
   curl https://truckmitr.com/truckmitr-app/api/create_match_making_table.php
   ```

3. Expected response:
   ```json
   {
     "success": true,
     "message": "match_making table created successfully!",
     "table_structure": [...],
     "table_info": {...}
   }
   ```

### Method 2: Using SQL File

1. Connect to MySQL:
   ```bash
   mysql -u username -p truckmitr
   ```

2. Run the SQL file:
   ```bash
   mysql -u username -p truckmitr < api/create_match_making_table.sql
   ```

3. Or execute directly:
   ```sql
   source api/create_match_making_table.sql;
   ```

### Method 3: Direct SQL Execution

Execute this SQL in your MySQL client:

```sql
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
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_caller_id` (`caller_id`),
  INDEX `idx_transporter` (`unique_id_transporter`),
  INDEX `idx_driver` (`unique_id_driver`),
  INDEX `idx_application` (`application_id`),
  INDEX `idx_job` (`job_id`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Usage Examples

### Insert a Match Record

```sql
INSERT INTO match_making (
  caller_id,
  tele_caller_name,
  unique_id_transporter,
  unique_id_driver,
  transporter_name,
  driver_name,
  application_id,
  job_id,
  feed_back
) VALUES (
  5,
  'John Doe',
  'TM123456',
  'TM789012',
  'ABC Transport',
  'Rajesh Kumar',
  'APP001',
  'JOB001',
  'Good match, driver has experience with similar routes'
);
```

### Query Matches by Telecaller

```sql
SELECT * FROM match_making 
WHERE caller_id = 5 
ORDER BY created_at DESC;
```

### Query Matches by Transporter

```sql
SELECT * FROM match_making 
WHERE unique_id_transporter = 'TM123456' 
ORDER BY created_at DESC;
```

### Query Matches by Driver

```sql
SELECT * FROM match_making 
WHERE unique_id_driver = 'TM789012' 
ORDER BY created_at DESC;
```

### Get Match Statistics

```sql
-- Total matches by telecaller
SELECT 
  caller_id,
  tele_caller_name,
  COUNT(*) as total_matches
FROM match_making
GROUP BY caller_id, tele_caller_name
ORDER BY total_matches DESC;

-- Matches per day
SELECT 
  DATE(created_at) as match_date,
  COUNT(*) as matches_count
FROM match_making
GROUP BY DATE(created_at)
ORDER BY match_date DESC;

-- Recent matches
SELECT * FROM match_making
ORDER BY created_at DESC
LIMIT 10;
```

### Update Feedback

```sql
UPDATE match_making 
SET feed_back = 'Driver accepted the job offer'
WHERE id = 1;
```

## API Integration Example

### Create Match Endpoint

```php
<?php
// api/match_making_api.php
require_once 'config.php';

$pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);

$data = json_decode(file_get_contents('php://input'), true);

$stmt = $pdo->prepare("
  INSERT INTO match_making (
    caller_id,
    tele_caller_name,
    unique_id_transporter,
    unique_id_driver,
    transporter_name,
    driver_name,
    application_id,
    job_id,
    feed_back
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$stmt->execute([
  $data['caller_id'],
  $data['tele_caller_name'],
  $data['unique_id_transporter'],
  $data['unique_id_driver'],
  $data['transporter_name'],
  $data['driver_name'],
  $data['application_id'] ?? null,
  $data['job_id'] ?? null,
  $data['feed_back'] ?? null
]);

echo json_encode([
  'success' => true,
  'match_id' => $pdo->lastInsertId()
]);
?>
```

## Verification

After creating the table, verify it exists:

```sql
-- Check if table exists
SHOW TABLES LIKE 'match_making';

-- View table structure
DESCRIBE match_making;

-- View table indexes
SHOW INDEX FROM match_making;

-- Check table status
SHOW TABLE STATUS LIKE 'match_making';
```

## Features

✅ **Auto-incrementing ID**: Unique identifier for each match  
✅ **Telecaller Tracking**: Records who made the match  
✅ **Dual Timestamps**: Tracks creation and updates  
✅ **Indexed Columns**: Fast queries on key fields  
✅ **Flexible Feedback**: Text field for detailed notes  
✅ **Optional Fields**: Application and job IDs are nullable  
✅ **UTF-8 Support**: Handles international characters  

## Use Cases

1. **Match Tracking**: Record when telecallers connect drivers with transporters
2. **Performance Metrics**: Track how many matches each telecaller makes
3. **Success Rate**: Monitor which matches lead to successful placements
4. **Feedback Collection**: Store notes about match quality and outcomes
5. **Reporting**: Generate reports on matchmaking activity
6. **Audit Trail**: Maintain history of all matches made

## Best Practices

1. **Always include feedback**: Helps improve future matching
2. **Use unique IDs**: Reference TMIDs for data integrity
3. **Update feedback**: Add notes as match progresses
4. **Regular cleanup**: Archive old records periodically
5. **Monitor performance**: Use indexes for fast queries

## Troubleshooting

### Table Already Exists
If you see "Table already exists" error, the table is already created. You can:
- Drop and recreate: `DROP TABLE match_making;` then run create script
- Or just use the existing table

### Permission Denied
Ensure your MySQL user has CREATE TABLE privileges:
```sql
GRANT CREATE ON truckmitr.* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;
```

### Character Set Issues
If you see encoding issues, ensure your connection uses UTF-8:
```php
$pdo = new PDO("mysql:host=HOST;dbname=DB;charset=utf8mb4", USER, PASS);
```

## Summary

The `match_making` table is now ready to track driver-transporter matches in your TruckMitr employee app. It includes all necessary fields for comprehensive matchmaking tracking and reporting.

**Files Created**:
- `api/create_match_making_table.sql` - SQL script
- `api/create_match_making_table.php` - PHP execution script
- `MATCH_MAKING_TABLE_SETUP.md` - This documentation

**Status**: ✅ Ready to Use!
