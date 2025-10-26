# TruckMitr Admin Panel - Complete Setup Guide

## 🚀 Features

### Complete Management System
- **Dashboard**: Real-time statistics, charts, and KPIs
- **Telecaller Management**: Add, edit, delete telecallers with performance metrics
- **Manager Management**: Manage team leaders and their teams
- **Lead Management**: Assign/reassign leads, bulk operations, filtering
- **Call Monitoring**: Real-time call tracking with detailed logs
- **Analytics**: Comprehensive reports with charts and insights

### UI/UX Features
- Modern, responsive design with Tailwind CSS
- Real-time data updates (auto-refresh)
- Interactive charts (Recharts)
- Smooth animations and transitions
- Mobile-friendly interface
- Dark mode ready

## 📦 Installation

### 1. Dependencies Already Installed
```bash
npm install axios recharts lucide-react react-router-dom @tanstack/react-query date-fns
```

### 2. Install Tailwind CSS
```bash
npm install -D tailwindcss postcss autoprefixer
```

### 3. Start Development Server
```bash
npm run dev
```

The admin panel will be available at: http://localhost:5173

## 🔧 Configuration

### API Configuration
Update `src/config/api.js` with your backend URL:

```javascript
export const API_BASE_URL = 'http://localhost/tmemployeeapp/api';
```

For production:
```javascript
export const API_BASE_URL = 'https://yourdomain.com/api';
```

## 🔐 Default Login Credentials

```
Username: admin
Password: admin123
```

**Important**: Change these credentials in production!

## 📁 Project Structure

```
admin-panel/
├── src/
│   ├── components/
│   │   ├── Layout.jsx              # Main layout with sidebar
│   │   ├── ProtectedRoute.jsx      # Route protection
│   │   ├── TelecallerModal.jsx     # Add/Edit telecaller
│   │   ├── ManagerModal.jsx        # Add/Edit manager
│   │   └── AssignLeadsModal.jsx    # Assign leads to telecaller
│   ├── pages/
│   │   ├── Login.jsx               # Login page
│   │   ├── Dashboard.jsx           # Main dashboard
│   │   ├── Telecallers.jsx         # Telecaller management
│   │   ├── Managers.jsx            # Manager management
│   │   ├── Leads.jsx               # Lead management
│   │   ├── CallMonitoring.jsx      # Call tracking
│   │   └── Analytics.jsx           # Reports & analytics
│   ├── context/
│   │   └── AuthContext.jsx         # Authentication context
│   ├── config/
│   │   └── api.js                  # API configuration
│   ├── App.jsx                     # Main app component
│   └── main.jsx                    # Entry point
├── public/
└── package.json
```

## 🎨 Key Features Breakdown

### 1. Dashboard
- Live statistics cards
- Call trends chart (7 days)
- Call status distribution (pie chart)
- Top performers (bar chart)
- Recent activity feed
- Auto-refresh every 30 seconds

### 2. Telecaller Management
- Grid view with cards
- Search functionality
- Add/Edit/Delete operations
- Performance metrics per telecaller
- Status management (active/inactive)

### 3. Manager Management
- Manager cards with team info
- Team size and performance metrics
- CRUD operations
- Team performance tracking

### 4. Lead Management
- Searchable table view
- Status filtering
- Bulk selection
- Assign/Reassign to telecallers
- Last contact tracking
- Status badges

### 5. Call Monitoring
- Real-time call logs
- Date filtering (today, yesterday, week, month)
- Call statistics
- Status color coding
- Duration tracking
- Telecaller identification

### 6. Analytics
- Revenue tracking
- Conversion rate metrics
- Performance trends (30 days)
- Telecaller comparison charts
- KPI cards with growth indicators

## 🔌 Backend APIs Required

The following PHP APIs are created in the `api/` folder:

1. `auth_api.php` - Authentication
2. `dashboard_stats_api.php` - Dashboard statistics
3. `admin_telecallers_api.php` - Telecaller CRUD
4. `admin_managers_api.php` - Manager CRUD
5. `admin_leads_api.php` - Lead listing
6. `admin_assign_leads_api.php` - Lead assignment
7. `call_monitoring_api.php` - Call logs
8. `admin_analytics_api.php` - Analytics data

## 🚀 Deployment

### Development
```bash
npm run dev
```

### Production Build
```bash
npm run build
```

The build files will be in the `dist/` folder. Upload to your web server.

### Environment Variables
Create `.env` file:
```
VITE_API_URL=https://yourdomain.com/api
```

## 🎯 Usage Guide

### Adding a Telecaller
1. Go to Telecallers page
2. Click "Add Telecaller"
3. Fill in details (name, email, phone, password, location)
4. Click "Save"

### Assigning Leads
1. Go to Leads page
2. Select leads using checkboxes
3. Click "Assign" button
4. Choose telecaller from dropdown
5. Confirm assignment

### Monitoring Calls
1. Go to Call Monitoring
2. Select date filter
3. View real-time call logs
4. Check statistics

### Viewing Analytics
1. Go to Analytics page
2. View KPIs and charts
3. Compare telecaller performance
4. Track trends

## 🔒 Security Features

- JWT-based authentication (ready for implementation)
- Protected routes
- Input validation
- SQL injection prevention
- XSS protection
- CORS configuration

## 📱 Responsive Design

- Desktop: Full sidebar navigation
- Tablet: Collapsible sidebar
- Mobile: Hamburger menu
- Touch-friendly buttons
- Optimized charts for small screens

## 🎨 Customization

### Colors
Edit `tailwind.config.js`:
```javascript
theme: {
  extend: {
    colors: {
      primary: { ... }
    }
  }
}
```

### Branding
Update logo in `src/components/Layout.jsx`

## 🐛 Troubleshooting

### API Connection Issues
- Check `src/config/api.js` URL
- Verify CORS headers in PHP
- Check browser console for errors

### Build Errors
```bash
npm install
npm run build
```

### Styling Issues
```bash
npm install -D tailwindcss postcss autoprefixer
```

## 📞 Support

For issues or questions, check:
- Browser console for errors
- Network tab for API responses
- PHP error logs

## 🎉 You're All Set!

Your admin panel is ready to use. Access it at http://localhost:5173 and start managing your TruckMitr system!
