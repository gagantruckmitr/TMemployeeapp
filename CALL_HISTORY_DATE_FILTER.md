# Call History Date Filter Implementation

## Overview
Added date filtering functionality to the Call History screen, allowing telecallers to filter call logs by specific date ranges.

## Features Added

### 1. Date Range Filter Options
- **All Time**: Shows all call history (default)
- **Today**: Shows only today's calls
- **Yesterday**: Shows only yesterday's calls
- **Last 7 Days**: Shows calls from the past 7 days
- **Last 30 Days**: Shows calls from the past 30 days
- **Custom Range**: Opens a date range picker to select any custom date range

### 2. UI Components
- **Separate Date Filter Icon**: Calendar icon button in the header next to the main filter icon
- **Visual Indicator**: Purple dot appears on the calendar icon when a date filter is active
- **Dedicated Bottom Sheet**: Separate modal for date filtering with purple theme
- **Current Selection Display**: Shows the currently selected date range prominently
- **Custom Date Range Picker**: Calendar UI for selecting custom date ranges
- **Quick Filter Chips**: Easy-to-tap buttons for common date ranges

### 3. Backend Support
- Updated `call_history_api.php` to accept `date_from` and `date_to` parameters
- Date filtering uses the actual call time (call_initiated_at, call_time, or Created_at)
- Efficient SQL queries with proper date comparison

## Files Modified

### Frontend (Flutter)
1. **lib/features/telecaller/screens/call_history_screen.dart**
   - Added date range state variables
   - Added date range filter UI in bottom sheet
   - Implemented date range calculation logic
   - Added custom date picker dialog
   - Updated API calls to include date parameters

2. **lib/core/services/api_service.dart**
   - Added `dateFrom` and `dateTo` parameters to `getCallHistory` method
   - Added DateFormat import for date formatting
   - Format dates as 'yyyy-MM-dd' for API

3. **lib/core/services/smart_calling_service.dart**
   - Added `dateFrom` and `dateTo` parameters to `getCallHistory` method
   - Pass date parameters to ApiService

### Backend (PHP)
1. **api/call_history_api.php**
   - Added `date_from` and `date_to` query parameters
   - Added SQL date filtering in both main query and count query
   - Uses DATE() function for proper date comparison

## Usage

### For Telecallers
1. Open Call History screen
2. Tap the **calendar icon** (📅) in the header (next to the filter icon)
3. Select a predefined range (Today, Yesterday, Last 7 Days, etc.) or choose "Custom Range"
4. For custom range, select start and end dates from the calendar picker
5. Tap "Apply Date Filter" to see filtered results
6. A purple dot appears on the calendar icon when a date filter is active
7. Date filter works independently from other filters (status, feedback, remarks)

### API Usage
```
GET /api/call_history_api.php?action=call_history&caller_id=1&date_from=2024-12-01&date_to=2024-12-08
```

## Technical Details

### Date Calculation Logic
- **Today**: Start and end date = current date
- **Yesterday**: Start and end date = current date - 1 day
- **Last 7 Days**: Start = current date - 6 days, End = current date
- **Last 30 Days**: Start = current date - 29 days, End = current date
- **Custom**: User-selected start and end dates

### SQL Query
```sql
WHERE DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at)) >= ?
  AND DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at)) <= ?
```

## Benefits
- **Quick Access**: Dedicated calendar icon for instant date filtering
- **Visual Feedback**: Purple indicator shows when date filter is active
- **Better Organization**: Easily find calls from specific time periods
- **Improved Performance**: Reduce data load by filtering by date
- **Pattern Analysis**: Analyze daily/weekly/monthly call patterns
- **Flexible Range**: Custom date picker for detailed analysis
- **Independent Filtering**: Works alongside other filters without interference

## UI/UX Highlights
- **Separate Icon**: Date filter has its own calendar icon, not buried in the main filter
- **Purple Theme**: Distinct purple color scheme differentiates date filtering from other filters
- **Active Indicator**: Small purple dot on calendar icon when date filter is applied
- **Current Selection**: Prominently displays the selected date range in the bottom sheet
- **Quick Filters**: One-tap access to common date ranges (Today, Last 7 Days, etc.)
- **Clean Layout**: Dedicated bottom sheet keeps the UI organized and focused

## Testing
- Test all predefined date ranges (Today, Yesterday, Last 7 Days, Last 30 Days)
- Test custom date range picker with various date combinations
- Verify API returns correct filtered data for each date range
- Check that date filter works in combination with status/feedback/remarks filters
- Ensure date filter persists during refresh
- Verify purple indicator appears/disappears correctly
- Test that "All Time" removes the date filter
