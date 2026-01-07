# Jobs Screen Fixes Complete

## Issues Fixed

### 1. TMID and Name Not Visible
- Enhanced field mapping with multiple fallbacks
- Added support for: transporter_name, transporterName
- Added support for: transporter_unique_id, transporterTmid, transporter_tmid
- Default value "Unknown Transporter" if missing

### 2. Fresh Jobs at the Top
- Added sorting by Created_at date (newest first)
- Applied to all filter views
- Sorting happens after filtering

### 3. No Expired Jobs in Pending Section
- Updated pending filter to exclude expired jobs
- Expired jobs only in "Expired" and "All" filters

## Filter Behavior

- **All**: All jobs, sorted newest first
- **Approved**: status=1, sorted newest first
- **Active**: active_inactive=1 AND not expired, sorted newest first
- **Pending**: status=0 AND not expired, sorted newest first
- **Inactive**: active_inactive=0, sorted newest first
- **Expired**: deadline passed, sorted newest first
- **Closed**: closed_job=1, sorted newest first

## Files Modified

1. lib/core/services/phase2_api_service.dart
2. lib/models/job_model.dart
