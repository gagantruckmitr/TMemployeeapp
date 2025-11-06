# Job Assignment Round-Robin System

## Overview
Automatic round-robin assignment system for distributing job leads equally among 4 telecallers (IDs: 3, 4, 9, 11).

## Telecaller IDs
- **ID 3** - Telecaller 1
- **ID 4** - Telecaller 2  
- **ID 9** - Telecaller 3
- **ID 11** - Telecaller 4

## How It Works

### Round-Robin Algorithm
Jobs are assigned in rotation:
1. First job → Telecaller 3
2. Second job → Telecaller 4
3. Third job → Telecaller 9
4. Fourth job → Telecaller 11
5. Fifth job → Telecaller 3 (cycle repeats)

This ensures equal distribution of leads.

## Scripts Created

### 1. Bulk Assignment Script
**File:** `api/assign_jobs_round_robin.php`

**Purpose:** Assigns ALL currently unassigned jobs in round-robin order

**Usage:**
```bash
# Run once to assign all existing unassigned jobs
curl http://your-domain.com/api/assign_jobs_round_robin.php
```

**What it does:**
- Finds all jobs where `assigned_to` is NULL or 0
- Assigns them to telecallers 3, 4, 9, 11 in rotation
- Uses database transaction for safety
- Returns assignment summary

**Response Example:**
```json
{
  "success": true,
  "message": "Successfully assigned 186 jobs in round-robin fashion",
  "total_unassigned": 186,
  "assigned_count": 186,
  "telecaller_ids": [3, 4, 9, 11],
  "summary": [
    {"assigned_to": 3, "count": 47},
    {"assigned_to": 4, "count": 47},
    {"assigned_to": 9, "count": 46},
    {"assigned_to": 11, "count": 46}
  ]
}
```

---

### 2. Auto-Assignment Script
**File:** `api/auto_assign_new_jobs.php`

**Purpose:** Assigns a single new job to the next telecaller in rotation

**Usage:**
```bash
# Assign a specific job
curl -X POST http://your-domain.com/api/auto_assign_new_jobs.php \
  -d "job_id=228"
```

**Parameters:**
- `job_id` (required) - The database ID of the job to assign

**What it does:**
- Checks if job exists and is unassigned
- Calculates next telecaller based on total assigned jobs
- Assigns job to next telecaller in rotation
- Maintains round-robin balance

**When to use:**
- Call this API when a new job is created
- Can be integrated into job creation workflow
- Ensures new jobs are automatically assigned

---

### 3. Test/Verification Script
**File:** `api/test_job_assignments.php`

**Purpose:** Verifies assignment distribution and balance

**Usage:**
```bash
# Check current assignment status
curl http://your-domain.com/api/test_job_assignments.php
```

**What it shows:**
- Total jobs count
- Unassigned jobs count
- Distribution per telecaller
- Recent assignments
- Balance status
- Recommendations

**Response Example:**
```json
{
  "success": true,
  "summary": {
    "total_jobs": 186,
    "unassigned_jobs": 0,
    "assigned_jobs": 186,
    "is_balanced": true,
    "max_difference": 1
  },
  "distribution": [
    {"assigned_to": 3, "count": 47},
    {"assigned_to": 4, "count": 47},
    {"assigned_to": 9, "count": 46},
    {"assigned_to": 11, "count": 46}
  ],
  "recommendation": "All jobs are assigned!"
}
```

---

## Implementation Steps

### Step 1: Test Current State
```bash
# Check how many jobs need assignment
curl http://your-domain.com/api/test_job_assignments.php
```

### Step 2: Assign Existing Jobs
```bash
# Assign all unassigned jobs
curl http://your-domain.com/api/assign_jobs_round_robin.php
```

### Step 3: Verify Assignment
```bash
# Verify distribution is balanced
curl http://your-domain.com/api/test_job_assignments.php
```

### Step 4: Integrate Auto-Assignment (Optional)
For new jobs, call the auto-assignment API:
```php
// When creating a new job
$newJobId = 228; // ID of newly created job
$assignUrl = "http://your-domain.com/api/auto_assign_new_jobs.php";
$ch = curl_init($assignUrl);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, "job_id=$newJobId");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);
```

---

## Database Schema

### Jobs Table
The `assigned_to` column stores the telecaller ID:

```sql
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS assigned_to INT(11) DEFAULT NULL,
ADD INDEX idx_assigned_to (assigned_to);
```

**Values:**
- `NULL` or `0` = Unassigned
- `3, 4, 9, 11` = Assigned to specific telecaller

---

## API Integration

### Fetch Jobs for Specific Telecaller
Update your jobs API to filter by `assigned_to`:

```php
// In phase2_jobs_api.php
$callerId = $_GET['caller_id']; // From logged-in user

$query = "SELECT * FROM jobs 
          WHERE assigned_to = $callerId 
          ORDER BY created_at DESC";
```

### Dashboard Stats
Show assigned job count per telecaller:

```php
$statsQuery = "SELECT 
                 assigned_to,
                 COUNT(*) as total_jobs,
                 SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_jobs
               FROM jobs 
               WHERE assigned_to IN (3, 4, 9, 11)
               GROUP BY assigned_to";
```

---

## Monitoring & Maintenance

### Check Balance Regularly
```bash
# Run daily to ensure balance
curl http://your-domain.com/api/test_job_assignments.php
```

### Re-balance if Needed
If distribution becomes unbalanced:
1. Check for manually assigned jobs
2. Run bulk assignment for new unassigned jobs
3. Consider reassignment if severely imbalanced

### Add New Telecallers
To add more telecallers to rotation:
1. Update `$telecallerIds` array in all scripts
2. Run bulk assignment to redistribute

---

## Troubleshooting

### Problem: Jobs not assigned
**Solution:** Run `assign_jobs_round_robin.php`

### Problem: Unbalanced distribution
**Check:**
- Are jobs being manually assigned?
- Are some telecallers being skipped?
- Run test script to see actual distribution

### Problem: New jobs not auto-assigned
**Solution:** Integrate `auto_assign_new_jobs.php` into job creation workflow

---

## Benefits

✅ **Equal Distribution** - Each telecaller gets fair share of leads
✅ **Automatic** - No manual assignment needed
✅ **Scalable** - Easy to add more telecallers
✅ **Balanced** - Maintains even distribution
✅ **Transparent** - Easy to verify and monitor

---

## Next Steps

1. ✅ Run test script to see current state
2. ✅ Run bulk assignment for existing jobs
3. ✅ Verify balanced distribution
4. ⏳ Integrate auto-assignment for new jobs
5. ⏳ Update job fetch APIs to filter by `assigned_to`
6. ⏳ Add assignment info to dashboard

---

## Support

If you need to:
- Change telecaller IDs
- Add more telecallers
- Modify assignment logic
- Reset assignments

Just update the `$telecallerIds` array in the scripts and re-run the bulk assignment.
