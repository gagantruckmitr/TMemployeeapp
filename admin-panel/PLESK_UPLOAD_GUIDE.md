# 🚀 Upload Admin Panel to Plesk - Direct Method

## ✅ Files Already Extracted!

Good news! Despite the warning, your files were extracted successfully:
- ✅ index.html
- ✅ assets/index-Bje56sYy.js
- ✅ assets/index-w0-429K9.css
- ✅ .htaccess
- ✅ vite.svg

## 🌐 Access Your Admin Panel

Your admin panel is now live at:
```
https://truckmitr.com/theemolyeeAdmin
```

## 🔧 Quick Test

1. Open: `https://truckmitr.com/theemolyeeAdmin`
2. You should see the login page
3. Login with your admin credentials
4. Check if dashboard loads

## ⚠️ If You See Issues

### Issue: Blank Page
**Fix:**
1. Check if `.htaccess` file is there
2. Update API URL in your build

### Issue: API Not Working
**Fix:**
Update `admin-panel/src/config/api.js` before building:
```javascript
export const API_BASE_URL = 'https://truckmitr.com/api';
```

Then rebuild:
```bash
npm run build
```

## 📤 Better Upload Method (For Future Updates)

### Method 1: Direct FTP Upload (Recommended)

1. **Use FileZilla or WinSCP**
   - Host: `truckmitr.com`
   - Username: Your FTP username
   - Password: Your FTP password
   - Port: 21

2. **Navigate to:**
   ```
   /httpdocs/theemolyeeAdmin/
   ```

3. **Upload files from `dist/` folder:**
   - Drag and drop all files
   - Overwrite existing files
   - No zip needed!

### Method 2: Plesk File Manager (One by One)

1. Login to Plesk
2. File Manager → `httpdocs/theemolyeeAdmin/`
3. Click "Upload Files"
4. Select files from `dist/` folder
5. Upload one by one or in batches

## 🔄 Update Process

When you make changes:

1. **Update API URL (if needed)**
   ```javascript
   // admin-panel/src/config/api.js
   export const API_BASE_URL = 'https://truckmitr.com/api';
   ```

2. **Build**
   ```bash
   cd admin-panel
   npm run build
   ```

3. **Upload via FTP**
   - Connect to FTP
   - Go to `/httpdocs/theemolyeeAdmin/`
   - Delete old `assets/` folder
   - Upload new files from `dist/`

4. **Clear browser cache**
   - Hard refresh: Ctrl+Shift+R

## 📁 Current Structure on Server

```
/httpdocs/
├── theemolyeeAdmin/          # Your admin panel
│   ├── index.html
│   ├── assets/
│   │   ├── index-Bje56sYy.js
│   │   └── index-w0-429K9.css
│   ├── .htaccess
│   └── vite.svg
├── api/                      # Your API
│   ├── auth_api.php
│   ├── admin_leads_api.php
│   └── ...
└── ...
```

## ✨ Verify Deployment

### 1. Check Files
In Plesk File Manager, verify these files exist:
- `/httpdocs/theemolyeeAdmin/index.html`
- `/httpdocs/theemolyeeAdmin/assets/index-Bje56sYy.js`
- `/httpdocs/theemolyeeAdmin/assets/index-w0-429K9.css`
- `/httpdocs/theemolyeeAdmin/.htaccess`

### 2. Test URL
Open: `https://truckmitr.com/theemolyeeAdmin`

### 3. Check Console
Press F12 → Console tab
- Should see no errors
- API calls should work

### 4. Test Login
- Email: `admin@truckmitr.com`
- Password: Your password
- Should redirect to dashboard

## 🎯 Success Checklist

- [ ] Admin panel loads at `/theemolyeeAdmin`
- [ ] Login page displays correctly
- [ ] Can login successfully
- [ ] Dashboard shows data
- [ ] All pages work (Leads, Telecallers, etc.)
- [ ] No console errors
- [ ] API calls working
- [ ] Mobile responsive

## 🔒 Security Tips

1. **Enable HTTPS** (if not already)
   - Plesk → SSL/TLS Certificates
   - Install Let's Encrypt
   - Force HTTPS redirect

2. **Password Protect** (optional)
   - Plesk → Password-Protected Directories
   - Select `/theemolyeeAdmin`
   - Add extra layer of security

3. **Regular Backups**
   - Plesk → Backup Manager
   - Schedule automatic backups

## 📞 Need Help?

If you see any issues:
1. Check browser console (F12)
2. Verify all files uploaded
3. Check file permissions (644 for files, 755 for folders)
4. Test API directly: `https://truckmitr.com/api/auth_api.php`

---

**Your admin panel is ready!** 🎉

Access it at: `https://truckmitr.com/theemolyeeAdmin`
