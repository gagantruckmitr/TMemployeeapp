# TruckMitr Admin Panel - Setup Guide

## 🚀 Quick Start

The admin panel is now ready! Here's what you have:

### Features Implemented

✅ **Dashboard** - Real-time stats, charts, and activity monitoring
✅ **Telecaller Management** - Add, edit, delete telecallers with performance metrics
✅ **Manager Management** - Manage team leaders and their teams
✅ **Leads Management** - View, filter, and reassign leads to telecallers
✅ **Call Monitoring** - Real-time call tracking with detailed logs
✅ **Analytics** - Comprehensive reports with charts and trends

### Tech Stack

- React 18 + Vite
- TailwindCSS for styling
- React Router for navigation
- TanStack Query for data fetching
- Recharts for data visualization
- Axios for API calls

### Running the Admin Panel

```bash
cd admin-panel
npm run dev
```

The panel will be available at: http://localhost:5173

### Default Login Credentials

- **Username:** admin
- **Password:** admin123

(Update these in your database)

### API Configuration

The admin panel connects to your PHP backend at:
`http://localhost/tmemployeeapp/api`

Update this in `admin-panel/src/config/api.js` if needed.

### Backend APIs Created

All PHP APIs are in the `/api` folder:

- `admin_telecallers_api.php` - CRUD for telecallers
- `admin_managers_api.php` - CRUD for managers
- `admin_leads_api.php` - Lead listing and filtering
- `admin_assign_leads_api.php` - Reassign leads
- `admin_analytics_api.php` - Analytics data
- `call_monitoring_api.php` - Call logs and monitoring
- `dashboard_stats_api.php` - Dashboard statistics

### Database Requirements

Make sure your database has these tables:
- `users` (with role: admin, manager, telecaller)
- `drivers` (leads)
- `call_logs`

### Features Overview

#### 1. Dashboard
- Live statistics cards
- Call trends chart (7 days)
- Call status distribution pie chart
- Top performers bar chart
- Recent activity feed
- Auto-refreshes every 30 seconds

#### 2. Telecallers Page
- Grid view of all telecallers
- Search functionality
- Add/Edit/Delete operations
- Performance metrics per telecaller
- Status management (active/inactive)

#### 3. Managers Page
- Manager cards with team info
- Team size and performance metrics
- Add/Edit/Delete managers
- Search and filter

#### 4. Leads Management
- Comprehensive lead table
- Multi-select for bulk assignment
- Filter by status (fresh, interested, callback, etc.)
- Search by name or phone
- Reassign leads to telecallers
- Last contact tracking

#### 5. Call Monitoring
- Real-time call logs
- Filter by date (today, yesterday, week, month)
- Call statistics cards
- Detailed call information
- Status tracking
- Auto-refreshes every 10 seconds

#### 6. Analytics
- Revenue tracking
- Conversion rate metrics
- Performance trends (30 days)
- Telecaller comparison charts
- Average call duration

### UI/UX Features

- Modern gradient design
- Responsive layout (mobile, tablet, desktop)
- Smooth animations and transitions
- Loading states
- Error handling
- Toast notifications
- Modal dialogs
- Real-time updates

### Next Steps

1. **Test the APIs** - Make sure your PHP backend is running
2. **Update credentials** - Change default admin password
3. **Customize branding** - Update colors in tailwind.config.js
4. **Add more features** - Extend as needed

### Troubleshooting

If you see API errors:
1. Check that XAMPP/Apache is running
2. Verify database connection in `api/config.php`
3. Check CORS headers are enabled
4. Ensure all API files are in the `/api` folder

### Production Deployment

1. Build the admin panel:
```bash
npm run build
```

2. Deploy the `dist` folder to your web server
3. Update API_BASE_URL in production
4. Enable authentication and security measures

---

**Admin Panel is ready to use! 🎉**

Access it at http://localhost:5173 and start managing your TruckMitr system.
