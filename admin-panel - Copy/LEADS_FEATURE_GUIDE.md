# Leads Management Feature - Complete Guide

## Overview
The Leads Management page is a comprehensive, modern interface for managing all leads in the TruckMitr system. It provides powerful filtering, search, assignment, and analytics capabilities.

## Features

### 1. **Dashboard Statistics**
- **Total Leads**: Overview of all leads in the system
- **Interested Leads**: Leads showing interest
- **Callbacks**: Leads scheduled for callback
- **Fresh Leads**: New, uncontacted leads
- **Assigned/Unassigned**: Assignment status tracking
- **Not Interested**: Leads marked as not interested
- **No Response**: Leads with no response

### 2. **Advanced Filtering & Search**
- **Search**: Real-time search by driver name or phone number
- **Status Filter**: Filter by lead status (fresh, interested, callback, etc.)
- **View Modes**: Toggle between Table View and Card View

### 3. **Bulk Operations**
- **Select All**: Quickly select all filtered leads
- **Individual Selection**: Select specific leads
- **Bulk Assignment**: Assign multiple leads to telecallers at once

### 4. **Lead Information Display**
Each lead shows:
- Driver name and ID
- Phone number
- Current status with color-coded badges
- Assigned telecaller
- Call statistics (total calls, connected calls)
- Success rate percentage
- Last contact date/time
- Engagement score

### 5. **Two View Modes**

#### Table View
- Compact, data-dense display
- Sortable columns
- Quick actions
- Ideal for bulk operations

#### Card View
- Visual, card-based layout
- Better for detailed review
- Shows success rate prominently
- Mobile-friendly design

### 6. **Lead Detail Modal**
Click "View Details" on any lead to see:
- Complete contact information
- Assignment details with reassign option
- Comprehensive call statistics
- Timeline of interactions
- Quick action buttons

### 7. **Export Functionality**
- Export filtered leads to CSV
- Includes all lead data
- Timestamped filename
- One-click download

### 8. **Real-time Updates**
- Auto-refresh every 30 seconds
- Manual refresh button
- Loading states and animations
- Error handling with retry

## API Enhancements

### Enhanced Data Points
The `admin_leads_api.php` now provides:

```json
{
  "id": 123,
  "driver_name": "John Doe",
  "phone": "9876543210",
  "status": "interested",
  "assigned_to": "Telecaller Name",
  "assigned_to_id": 5,
  "assigned_to_email": "telecaller@example.com",
  "last_contact": "Oct 26, 2025 14:30",
  "first_contact": "Oct 20, 2025 10:15",
  "total_calls": 5,
  "connected_calls": 3,
  "interested_calls": 2,
  "callback_calls": 1,
  "not_interested_calls": 0,
  "no_response_calls": 1,
  "avg_call_duration": 45.5,
  "success_rate": 60.0,
  "engagement_score": 85
}
```

### Summary Statistics
API response includes summary:
```json
{
  "summary": {
    "total_leads": 150,
    "total_calls": 450,
    "total_connected": 280,
    "by_status": {
      "fresh": 30,
      "interested": 45,
      "callback": 25,
      "not_interested": 20,
      "no_response": 15,
      "connected": 15
    },
    "assigned": 120,
    "unassigned": 30
  }
}
```

## Status Color Coding

- **Fresh**: Blue - New leads
- **Interested**: Green - Positive response
- **Callback**: Yellow - Scheduled for follow-up
- **Not Interested**: Red - Declined
- **No Response**: Gray - No answer
- **Connected**: Emerald - Successfully connected

## Engagement Score Algorithm

The engagement score (0-100) is calculated based on:
- **Call Attempts** (up to 50 points): 10 points per call, max 50
- **Connected Calls** (up to 50 points): 15 points per connected call
- **Status Bonus**:
  - Interested: +30 points
  - Connected: +25 points
  - Callback: +20 points
  - Fresh: +10 points
  - No Response: +5 points
  - Not Interested: 0 points

## Usage Guide

### Assigning Leads
1. Select one or more leads using checkboxes
2. Click "Assign (X)" button in the header
3. Choose a telecaller from the dropdown
4. Click "Assign" to confirm

### Viewing Lead Details
1. Click "View Details" button on any lead
2. Review complete information
3. Use "Reassign" button to change assignment
4. Click "Close" or outside modal to dismiss

### Exporting Data
1. Apply desired filters
2. Click "Export" button
3. CSV file downloads automatically
4. Open in Excel or Google Sheets

### Searching & Filtering
1. Use search box for name/phone lookup
2. Select status from dropdown
3. Results update in real-time
4. Switch between table/card view as needed

## Technical Details

### Dependencies
- React 18+
- TanStack Query (React Query)
- Axios
- Lucide React (icons)
- Tailwind CSS

### Performance
- Optimized with useMemo for filtering
- Debounced search (instant feedback)
- Lazy loading for large datasets
- Efficient re-rendering

### Responsive Design
- Mobile-first approach
- Breakpoints: sm, md, lg, xl
- Touch-friendly interactions
- Adaptive layouts

## Testing

Test the API:
```bash
# Open in browser
http://localhost/api/test_leads_enhanced.php
```

Test the frontend:
```bash
# Navigate to admin panel
http://localhost:3000/leads
```

## Troubleshooting

### No Leads Showing
- Check database connection
- Verify call_logs table has data
- Check status filter setting

### Assignment Not Working
- Verify admin_assign_leads_api.php exists
- Check telecaller list is loading
- Review browser console for errors

### Slow Performance
- Reduce LIMIT in SQL query
- Add database indexes
- Enable query caching

## Future Enhancements

Potential additions:
- Advanced filters (date range, telecaller)
- Lead scoring and prioritization
- Bulk status updates
- Lead notes and comments
- Activity timeline
- Email/SMS integration
- Lead import/export
- Custom fields
- Tags and categories

## Support

For issues or questions:
1. Check browser console for errors
2. Review API response in Network tab
3. Test API endpoint directly
4. Check database connectivity
5. Verify user permissions

---

**Last Updated**: October 26, 2025
**Version**: 2.0
**Status**: Production Ready ✓
