# XAMPP Setup Instructions for Admin Panel

## Step 1: Install XAMPP

1. Download XAMPP from: https://www.apachefriends.org/download.html
2. Install to default location: `C:\xampp`
3. During installation, select:
   - ✅ Apache
   - ✅ MySQL
   - ✅ PHP
   - ✅ phpMyAdmin

## Step 2: Copy Project Files

### Option A: Create Symbolic Link (Recommended)
Open PowerShell as Administrator and run:
```powershell
New-Item -ItemType SymbolicLink -Path "C:\xampp\htdocs\tmemployeeapp" -Target "D:\tmemployeeapp"
```

### Option B: Copy Files
Copy your entire project folder to:
```
C:\xampp\htdocs\tmemployeeapp
```

## Step 3: Start XAMPP

1. Open **XAMPP Control Panel** (as Administrator)
2. Click **Start** next to Apache
3. Click **Start** next to MySQL
4. Both should show green "Running" status

## Step 4: Setup Database

1. Open browser and go to: http://localhost/phpmyadmin
2. Click "Import" tab
3. Choose your database SQL file
4. Click "Go"

Or create database manually:
```sql
CREATE DATABASE truckmitr;
```

## Step 5: Update Database Config

Edit: `D:\tmemployeeapp\api\config.php`

```php
<?php
$host = 'localhost';
$dbname = 'truckmitr';  // Your database name
$username = 'root';      // Default XAMPP username
$password = '';          // Default XAMPP password (empty)

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}
?>
```

## Step 6: Create Admin User

1. Go to: http://localhost/phpmyadmin
2. Select your database
3. Click "SQL" tab
4. Run this query:

```sql
INSERT INTO users (name, email, phone, password, role, status) 
VALUES (
    'Admin User', 
    'admin@truckmitra.com', 
    '9999999999', 
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 
    'admin', 
    'active'
);
```

## Step 7: Access Admin Panel

### Test Setup:
```
http://localhost/tmemployeeapp/admin/test_setup.php
```

### Login Page:
```
http://localhost/tmemployeeapp/admin/login.php
```

### Login Credentials:
- **Email**: admin@truckmitra.com
- **Password**: password

## Step 8: Access Dashboard

After login:
```
http://localhost/tmemployeeapp/admin/index.php
```

---

## 🔧 Troubleshooting

### Apache won't start - Port 80 in use
1. Open XAMPP Control Panel
2. Click "Config" next to Apache
3. Select "httpd.conf"
4. Find: `Listen 80`
5. Change to: `Listen 8080`
6. Save and restart Apache
7. Access via: http://localhost:8080/tmemployeeapp/admin/

### MySQL won't start - Port 3306 in use
1. Click "Config" next to MySQL
2. Select "my.ini"
3. Find: `port=3306`
4. Change to: `port=3307`
5. Update `api/config.php`:
```php
$pdo = new PDO("mysql:host=$host;port=3307;dbname=$dbname", $username, $password);
```

### "Access Denied" Error
- Make sure you're running XAMPP Control Panel as Administrator
- Check Windows Firewall isn't blocking Apache

### Database Connection Failed
1. Verify MySQL is running (green in XAMPP)
2. Check database name in `api/config.php`
3. Verify database exists in phpMyAdmin

### Blank Page / White Screen
1. Enable error display in `api/config.php`:
```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
```
2. Check Apache error logs: `C:\xampp\apache\logs\error.log`

---

## 📱 Quick Access URLs

After XAMPP is running:

| Service | URL |
|---------|-----|
| Admin Panel Test | http://localhost/tmemployeeapp/admin/test_setup.php |
| Admin Login | http://localhost/tmemployeeapp/admin/login.php |
| Admin Dashboard | http://localhost/tmemployeeapp/admin/index.php |
| phpMyAdmin | http://localhost/phpmyadmin |
| API Test | http://localhost/tmemployeeapp/api/test_connection.php |

---

## ✅ Verification Checklist

- [ ] XAMPP installed
- [ ] Apache running (green)
- [ ] MySQL running (green)
- [ ] Database created
- [ ] Database config updated
- [ ] Admin user created
- [ ] Can access test_setup.php
- [ ] Can login to admin panel
- [ ] Dashboard loads correctly

---

## 🎯 Next Steps After Setup

1. Change default admin password
2. Add telecallers
3. Import leads
4. Configure MyOperator settings
5. Test call logging

---

**Need Help?** Check the error logs:
- Apache: `C:\xampp\apache\logs\error.log`
- PHP: `C:\xampp\php\logs\php_error_log`
- MySQL: `C:\xampp\mysql\data\mysql_error.log`
