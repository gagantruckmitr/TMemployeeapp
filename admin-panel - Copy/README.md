# 🎯 TruckMitr Admin Panel

A modern, feature-rich admin panel built with React + Vite for managing the TruckMitr telecalling system.

## ✨ Features

### 📊 Dashboard
- Real-time statistics and KPIs
- Interactive charts (Line, Bar, Pie)
- Live activity feed
- Auto-refresh every 30 seconds

### 👥 Telecaller Management
- Add, edit, delete telecallers
- Performance metrics per telecaller
- Search and filter functionality
- Status management (active/inactive)

### 👔 Manager Management
- Manage team leaders
- View team size and performance
- CRUD operations

### 📞 Leads Management
- Comprehensive lead listing
- Multi-select bulk assignment
- Filter by status
- Search by name/phone
- Reassign leads to telecallers

### 📱 Call Monitoring
- Real-time call logs
- Date-based filtering
- Call statistics
- Status tracking
- Auto-refresh every 10 seconds

### 📈 Analytics & Reports
- Revenue tracking
- Conversion rate metrics
- 30-day performance trends
- Telecaller comparison charts

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## 🔐 Default Login

- Username: `admin`
- Password: `admin123`

## 🛠️ Tech Stack

- **React 18** - UI library
- **Vite** - Build tool
- **TailwindCSS** - Styling
- **React Router** - Navigation
- **TanStack Query** - Data fetching
- **Recharts** - Charts
- **Axios** - HTTP client
- **Lucide React** - Icons

## 📁 Project Structure

```
admin-panel/
├── src/
│   ├── components/      # Reusable components
│   │   ├── Layout.jsx
│   │   ├── ProtectedRoute.jsx
│   │   ├── TelecallerModal.jsx
│   │   ├── ManagerModal.jsx
│   │   └── AssignLeadsModal.jsx
│   ├── pages/          # Page components
│   │   ├── Dashboard.jsx
│   │   ├── Telecallers.jsx
│   │   ├── Managers.jsx
│   │   ├── Leads.jsx
│   │   ├── CallMonitoring.jsx
│   │   ├── Analytics.jsx
│   │   └── Login.jsx
│   ├── context/        # React context
│   │   └── AuthContext.jsx
│   ├── config/         # Configuration
│   │   └── api.js
│   ├── App.jsx
│   ├── main.jsx
│   └── index.css
├── public/
├── package.json
└── vite.config.js
```

## 🔌 API Integration

The panel connects to PHP backend APIs:

```javascript
// Update in src/config/api.js
export const API_BASE_URL = 'http://localhost/tmemployeeapp/api';
```

### Required APIs

- `auth_api.php` - Authentication
- `dashboard_stats_api.php` - Dashboard data
- `admin_telecallers_api.php` - Telecaller CRUD
- `admin_managers_api.php` - Manager CRUD
- `admin_leads_api.php` - Lead listing
- `admin_assign_leads_api.php` - Lead assignment
- `call_monitoring_api.php` - Call logs
- `admin_analytics_api.php` - Analytics data

## 🎨 Customization

### Colors

Update `tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      primary: {
        500: '#6366f1', // Change primary color
      },
    },
  },
}
```

### Branding

Update logo in `src/components/Layout.jsx` and `src/pages/Login.jsx`

## 📱 Responsive Design

The admin panel is fully responsive:
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

## 🔒 Security

- Protected routes with authentication
- JWT token support (optional)
- CORS enabled
- Input validation
- XSS protection

## 🚀 Deployment

### Build

```bash
npm run build
```

### Deploy

1. Upload `dist/` folder to your web server
2. Configure web server to serve `index.html` for all routes
3. Update `API_BASE_URL` for production

### Apache .htaccess

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

## 📊 Performance

- Code splitting
- Lazy loading
- Optimized bundle size
- Fast refresh in development
- Production optimizations

## 🐛 Troubleshooting

### API Connection Issues

1. Check XAMPP/Apache is running
2. Verify `api/config.php` database settings
3. Enable CORS in PHP
4. Check API endpoints are accessible

### Build Errors

```bash
# Clear cache
rm -rf node_modules
npm install

# Clear Vite cache
rm -rf .vite
```

## 📝 License

MIT

## 👨‍💻 Support

For issues or questions, contact the development team.

---

**Built with ❤️ for TruckMitr**
