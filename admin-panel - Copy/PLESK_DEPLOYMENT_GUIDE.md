# Admin Panel Plesk Deployment Guide

## 🎯 Overview
Deploy the React admin panel on Plesk alongside your existing API.

## 📋 Prerequisites
- Plesk hosting account
- Node.js enabled on Plesk
- Your domain: `yourdomain.com`
- API already deployed at: `yourdomain.com/api`

## 🏗️ Deployment Structure

```
yourdomain.com/
├── api/                    # Your existing API (already deployed)
├── admin/                  # Admin panel (new)
│   ├── index.html
│   ├── assets/
│   └── ...
└── httpdocs/              # Root directory
```

## 📦 Step 1: Build the Admin Panel

### On Your Local Machine:

1. **Navigate to admin-panel folder**
   ```bash
   cd admin-panel
   ```

2. **Update API URL for production**
   Edit `src/config/api.js`:
   ```javascript
   export const API_BASE_URL = 'https://yourdomain.com/api';
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Build for production**
   ```bash
   npm run build
   ```

5. **Build output will be in `dist/` folder**

## 📤 Step 2: Upload to Plesk

### Option A: Using Plesk File Manager

1. **Login to Plesk**
   - Go to your Plesk control panel
   - Select your domain

2. **Navigate to File Manager**
   - Click "Files" → "File Manager"
   - Go to `httpdocs/` directory

3. **Create admin folder**
   - Click "Create Directory"
   - Name it: `admin`

4. **Upload build files**
   - Enter the `admin/` folder
   - Upload all files from your local `dist/` folder
   - This includes:
     - `index.html`
     - `assets/` folder
     - `vite.svg`

### Option B: Using FTP

1. **Connect via FTP**
   - Host: `yourdomain.com`
   - Username: Your Plesk FTP username
   - Password: Your Plesk FTP password

2. **Navigate to httpdocs/admin/**

3. **Upload all files from dist/ folder**

## 🔧 Step 3: Configure Plesk

### 1. Set up .htaccess for React Router

Create `.htaccess` in `httpdocs/admin/`:

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /admin/
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /admin/index.html [L]
</IfModule>
```

### 2. Enable CORS (if needed)

Add to your API's `.htaccess` in `httpdocs/api/`:

```apache
Header set Access-Control-Allow-Origin "*"
Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
Header set Access-Control-Allow-Headers "Content-Type, Authorization"
```

## 🌐 Step 4: Access Your Admin Panel

Your admin panel will be available at:
```
https://yourdomain.com/admin
```

## ✅ Step 5: Verify Deployment

1. **Open admin panel**
   ```
   https://yourdomain.com/admin
   ```

2. **Check login page loads**

3. **Test login**
   - Username: `admin@truckmitr.com`
   - Password: Your admin password

4. **Verify API connection**
   - Dashboard should load data
   - Check browser console for errors

## 🔒 Step 6: Security Setup

### 1. Password Protect Admin Directory (Optional)

In Plesk:
1. Go to "Password-Protected Directories"
2. Select `/admin` directory
3. Enable protection
4. Create username/password

### 2. SSL Certificate

Ensure SSL is enabled:
1. Go to "SSL/TLS Certificates"
2. Install Let's Encrypt certificate
3. Force HTTPS redirect

## 🚀 Quick Deployment Script

Create `deploy-admin.sh`:

```bash
#!/bin/bash

echo "🏗️  Building Admin Panel..."
cd admin-panel
npm install
npm run build

echo "📦 Creating deployment package..."
cd dist
zip -r ../../admin-panel-deploy.zip .
cd ../..

echo "✅ Deployment package ready: admin-panel-deploy.zip"
echo "📤 Upload this file to Plesk and extract in httpdocs/admin/"
```

Make it executable:
```bash
chmod +x deploy-admin.sh
```

Run it:
```bash
./deploy-admin.sh
```

## 📁 Final Directory Structure on Plesk

```
httpdocs/
├── admin/
│   ├── index.html
│   ├── assets/
│   │   ├── index-[hash].js
│   │   ├── index-[hash].css
│   │   └── ...
│   ├── vite.svg
│   └── .htaccess
├── api/
│   ├── auth_api.php
│   ├── admin_leads_api.php
│   ├── config.php
│   └── ...
└── index.html (your main site, if any)
```

## 🔍 Troubleshooting

### Issue: Blank page after deployment
**Solution:**
1. Check browser console for errors
2. Verify API_BASE_URL in config
3. Check .htaccess is uploaded
4. Clear browser cache

### Issue: API calls failing
**Solution:**
1. Check CORS headers in API
2. Verify API URL is correct
3. Check SSL certificate
4. Test API directly: `https://yourdomain.com/api/auth_api.php`

### Issue: 404 on page refresh
**Solution:**
1. Verify .htaccess is in admin folder
2. Check mod_rewrite is enabled in Plesk
3. Verify RewriteBase is correct

### Issue: Assets not loading
**Solution:**
1. Check file permissions (644 for files, 755 for folders)
2. Verify all files uploaded correctly
3. Check browser network tab for 404s

## 📊 Performance Optimization

### 1. Enable Gzip Compression

Add to `.htaccess`:
```apache
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
</IfModule>
```

### 2. Enable Browser Caching

Add to `.htaccess`:
```apache
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/gif "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
</IfModule>
```

## 🔄 Update Process

When you make changes:

1. **Build locally**
   ```bash
   cd admin-panel
   npm run build
   ```

2. **Upload new files**
   - Delete old files in `httpdocs/admin/assets/`
   - Upload new files from `dist/`
   - Keep `.htaccess`

3. **Clear cache**
   - Clear browser cache
   - Or add version query: `?v=2`

## 📝 Environment-Specific Config

### Development
```javascript
// src/config/api.js
export const API_BASE_URL = 'http://localhost/api';
```

### Production
```javascript
// src/config/api.js
export const API_BASE_URL = 'https://yourdomain.com/api';
```

## ✨ Post-Deployment Checklist

- [ ] Admin panel loads at `https://yourdomain.com/admin`
- [ ] Login page displays correctly
- [ ] Can login with admin credentials
- [ ] Dashboard loads with data
- [ ] All pages accessible (Leads, Telecallers, etc.)
- [ ] API calls working
- [ ] No console errors
- [ ] SSL certificate active
- [ ] Mobile responsive
- [ ] Fast loading times

## 🎉 Success!

Your admin panel is now live at:
```
https://yourdomain.com/admin
```

Login and start managing your TruckMitr system!

---

**Need Help?**
- Check browser console for errors
- Test API endpoints directly
- Verify file permissions
- Check Plesk error logs
