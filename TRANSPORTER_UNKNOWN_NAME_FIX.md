# Transporter "Unknown" Name Fix

## Issue
Transporter cards in the call history are showing "Unknown" instead of actual transporter names.

## Root Cause
The issue is in the **database query** in `phase2_job_brief_api.php`. The original query was:
```sql
SELECT 
  unique_id as tmid,
  name,  -- This picks a random name when grouping
  ...
FROM job_brief_table
GROUP BY unique_id
```

When using `GROUP BY unique_id`, MySQL picks a random `name` value from the grouped records. If that record has an empty name, it shows as "Unknown".

## Solution

### Updated Query
The new query uses a LEFT JOIN with `transporter_table` and COALESCE to prioritize name sources:

```sql
SELECT 
  jb.unique_id as tmid,
  COALESCE(
    t.name,                    -- 1st priority: transporter_table.name
    t.company_name,            -- 2nd priority: transporter_table.company_name
    (SELECT name               -- 3rd priority: most recent non-empty name from job_brief
     FROM job_brief_table 
     WHERE unique_id = jb.unique_id 
     AND name IS NOT NULL 
     AND name != '' 
     AND name != 'null'
     ORDER BY created_at DESC 
     LIMIT 1),
    jb.unique_id              -- Last resort: use TMID
  ) as name,
  COALESCE(t.company_name, '') as company,
  ...
FROM job_brief_table jb
LEFT JOIN transporter_table t ON jb.unique_id = t.unique_id
GROUP BY jb.unique_id, t.name, t.company_name
```

## Name Priority Logic

1. **transporter_table.name** - Primary source (master data)
2. **transporter_table.company_name** - If name is empty
3. **Most recent job_brief name** - If transporter not in master table
4. **TMID** - Last resort fallback

## Testing

### Step 1: Run Test Script
```bash
https://truckmitr.com/truckmitr-app/api/test_transporter_names.php
```

This will show:
- Transporters in job_brief_table and their names
- Whether transporter_table exists
- Test results of the new query
- Recommendations

### Step 2: Check Results
The test script will identify:
- ✓ Transporters with proper names
- ❌ Transporters with empty names
- ⚠️ Transporters using TMID as fallback

### Step 3: Verify in App
1. Open the app
2. Navigate to Call History → Transporters
3. Check if names are now displayed correctly

## Additional Fixes

### If transporter_table doesn't exist

You need to identify the correct transporter master table. Common names:
- `transporter_table`
- `transporters`
- `transporter_master`
- `users` (with role filter)

Update the query to use the correct table name.

### Update Existing Records

If you want to populate empty names in job_brief_table:

```sql
UPDATE job_brief_table jb
LEFT JOIN transporter_table t ON jb.unique_id = t.unique_id
SET jb.name = COALESCE(t.name, t.company_name, jb.unique_id)
WHERE jb.name IS NULL OR jb.name = '' OR jb.name = 'null';
```

### Prevent Future Empty Names

Update the `saveJobBrief` function to fetch the name from transporter_table if not provided:

```php
// In saveJobBrief function
if (empty($name)) {
    // Try to fetch from transporter_table
    $nameQuery = "SELECT name, company_name FROM transporter_table WHERE unique_id = '$uniqueId' LIMIT 1";
    $nameResult = $conn->query($nameQuery);
    if ($nameResult && $nameResult->num_rows > 0) {
        $nameRow = $nameResult->fetch_assoc();
        $name = $nameRow['name'] ?? $nameRow['company_name'] ?? null;
    }
}
```

## Frontend Fallback

The frontend already has good fallback logic in `call_history_hub_screen.dart`:

```dart
String _getDisplayName(Map<String, dynamic> transporter) {
  final name = transporter['name']?.toString().trim();
  final company = transporter['company']?.toString().trim();
  final tmid = transporter['tmid']?.toString().trim();

  // Priority: name → company → Contact (TMID) → Unknown Contact
  if (name != null && name.isNotEmpty && name.toLowerCase() != 'null') {
    return name;
  }
  if (company != null && company.isNotEmpty && company.toLowerCase() != 'null') {
    return company;
  }
  if (tmid != null && tmid.isNotEmpty && tmid.toLowerCase() != 'null') {
    return 'Contact ($tmid)';
  }
  return 'Unknown Contact';
}
```

## Files Modified

1. **api/phase2_job_brief_api.php**
   - Updated `getTransportersList()` function
   - Added LEFT JOIN with transporter_table
   - Added COALESCE for name priority

2. **api/test_transporter_names.php** (new)
   - Debug script to identify name issues
   - Shows data from both tables
   - Tests the new query

## Verification Checklist

- [ ] Run test script to check database
- [ ] Verify transporter_table exists
- [ ] Check if names are populated in transporter_table
- [ ] Test the new query results
- [ ] Refresh app and check transporter list
- [ ] Verify names are displayed correctly
- [ ] Check that "Unknown" only appears for truly unknown transporters

## Expected Results

After the fix:
- ✅ Transporters with names in master table show correct names
- ✅ Transporters with company names show company names
- ✅ Transporters with job_brief names show those names
- ✅ Only truly unknown transporters show "Unknown" or "Contact (TMID)"

## Troubleshooting

### Still showing "Unknown"
1. Check if transporter_table exists
2. Verify the table name is correct
3. Check if unique_id matches between tables
4. Run the test script to see actual data

### Performance issues
If the query is slow:
1. Add index on `job_brief_table.unique_id`
2. Add index on `transporter_table.unique_id`
3. Consider caching the transporter list

### Names not updating
1. Clear app cache
2. Restart the app
3. Check API response in network tab
4. Verify the API is returning updated data

## Database Schema

### Required Tables

**job_brief_table**
```sql
- id (PRIMARY KEY)
- unique_id (transporter TMID)
- name (transporter name - may be empty)
- job_id
- created_at
- ... other fields
```

**transporter_table** (or equivalent)
```sql
- id (PRIMARY KEY)
- unique_id (transporter TMID)
- name (transporter name)
- company_name (company name)
- ... other fields
```

### Recommended Indexes
```sql
CREATE INDEX idx_job_brief_unique_id ON job_brief_table(unique_id);
CREATE INDEX idx_transporter_unique_id ON transporter_table(unique_id);
```

## Future Improvements

1. **Normalize Data**: Store only TMID in job_brief_table, fetch name from master table
2. **Caching**: Cache transporter names to reduce database queries
3. **Validation**: Require name when creating job brief
4. **Sync**: Periodically sync names from master table to job_brief_table
5. **Search**: Add search by TMID in addition to name
