<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TruckMitr API - Testing & Setup Tools</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            color: white;
            margin-bottom: 40px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        
        .header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.3);
        }
        
        .card h2 {
            color: #4f46e5;
            margin-bottom: 15px;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card p {
            color: #6b7280;
            margin-bottom: 20px;
            line-height: 1.6;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }
        
        .btn:hover {
            transform: scale(1.05);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        }
        
        .btn-warning {
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        }
        
        .btn-danger {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
        }
        
        .status {
            background: #f3f4f6;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .status-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #e5e7eb;
        }
        
        .status-item:last-child {
            border-bottom: none;
        }
        
        .badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.875rem;
            font-weight: 600;
        }
        
        .badge-success {
            background: #d1fae5;
            color: #065f46;
        }
        
        .badge-warning {
            background: #fef3c7;
            color: #92400e;
        }
        
        .badge-error {
            background: #fee2e2;
            color: #991b1b;
        }
        
        .icon {
            font-size: 1.5rem;
        }
        
        .footer {
            text-align: center;
            color: white;
            margin-top: 40px;
            opacity: 0.8;
        }
        
        .docs-section {
            background: white;
            border-radius: 12px;
            padding: 25px;
            margin-top: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        
        .docs-section h3 {
            color: #1f2937;
            margin-bottom: 15px;
        }
        
        .docs-section ul {
            list-style: none;
            padding: 0;
        }
        
        .docs-section li {
            padding: 10px 0;
            border-bottom: 1px solid #e5e7eb;
        }
        
        .docs-section li:last-child {
            border-bottom: none;
        }
        
        .docs-section a {
            color: #4f46e5;
            text-decoration: none;
            font-weight: 500;
        }
        
        .docs-section a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚛 TruckMitr API</h1>
            <p>Testing & Setup Tools Dashboard</p>
        </div>
        
        <?php
        // Quick system check
        $host = '127.0.0.1';
        $dbname = 'truckmitr';
        $username = 'truckmitr';
        $password = '825Redp&4';
        
        $dbConnected = false;
        $telecallerCount = 0;
        $driverCount = 0;
        $callLogCount = 0;
        
        try {
            $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $dbConnected = true;
            
            $stmt = $pdo->query("SELECT COUNT(*) FROM admins WHERE role = 'telecaller'");
            $telecallerCount = $stmt->fetchColumn();
            
            $stmt = $pdo->query("SELECT COUNT(*) FROM users WHERE role = 'driver'");
            $driverCount = $stmt->fetchColumn();
            
            $stmt = $pdo->query("SELECT COUNT(*) FROM call_logs");
            $callLogCount = $stmt->fetchColumn();
        } catch(Exception $e) {
            $dbConnected = false;
        }
        ?>
        
        <div class="status">
            <h3 style="margin-bottom: 15px; color: #1f2937;">System Status</h3>
            <div class="status-item">
                <span>Database Connection</span>
                <span class="badge <?php echo $dbConnected ? 'badge-success' : 'badge-error'; ?>">
                    <?php echo $dbConnected ? '✓ Connected' : '✗ Failed'; ?>
                </span>
            </div>
            <?php if ($dbConnected): ?>
            <div class="status-item">
                <span>Telecallers</span>
                <span class="badge <?php echo $telecallerCount > 0 ? 'badge-success' : 'badge-warning'; ?>">
                    <?php echo $telecallerCount; ?>
                </span>
            </div>
            <div class="status-item">
                <span>Drivers</span>
                <span class="badge <?php echo $driverCount > 0 ? 'badge-success' : 'badge-warning'; ?>">
                    <?php echo $driverCount; ?>
                </span>
            </div>
            <div class="status-item">
                <span>Call Logs</span>
                <span class="badge <?php echo $callLogCount > 0 ? 'badge-success' : 'badge-warning'; ?>">
                    <?php echo $callLogCount; ?>
                </span>
            </div>
            <?php endif; ?>
        </div>
        
        <div class="grid">
            <!-- Quick Setup -->
            <div class="card">
                <h2><span class="icon">🚀</span> Quick Setup</h2>
                <p>Automated setup wizard that creates tables, adds sample data, and tests all components.</p>
                <a href="quick_setup.php" class="btn">Run Quick Setup</a>
            </div>
            
            <!-- Comprehensive Test -->
            <div class="card">
                <h2><span class="icon">🔍</span> System Test</h2>
                <p>Complete system health check. Tests database, APIs, configuration, and shows detailed status.</p>
                <a href="comprehensive_test.php" class="btn btn-secondary">Run Full Test</a>
            </div>
            
            <!-- IVR Test -->
            <div class="card">
                <h2><span class="icon">📞</span> IVR Test</h2>
                <p>Test MyOperator IVR integration, check configuration, and verify call functionality.</p>
                <a href="test_ivr_complete.php" class="btn btn-warning">Test IVR</a>
            </div>
            
            <!-- Dashboard Debug -->
            <div class="card">
                <h2><span class="icon">📊</span> Dashboard Debug</h2>
                <p>Debug dashboard data issues. Shows call logs, counts, and status breakdowns.</p>
                <a href="test_dashboard_debug.php?caller_id=1" class="btn">Debug Dashboard</a>
            </div>
            
            <!-- Seed Test Data -->
            <div class="card">
                <h2><span class="icon">🌱</span> Add Sample Data</h2>
                <p>Add sample call logs for testing. Creates realistic data for today's date.</p>
                <a href="seed_test_data.php" class="btn btn-secondary">Add Sample Data</a>
            </div>
            
            <!-- Connection Test -->
            <div class="card">
                <h2><span class="icon">🔌</span> Connection Test</h2>
                <p>Basic connectivity test. Verifies database connection and API accessibility.</p>
                <a href="test_connection.php" class="btn">Test Connection</a>
            </div>
        </div>
        
        <div class="grid">
            <!-- Dashboard API -->
            <div class="card">
                <h2><span class="icon">📈</span> Dashboard API</h2>
                <p>View raw dashboard statistics API response for debugging.</p>
                <a href="dashboard_stats_api.php?caller_id=1" class="btn">View API</a>
            </div>
            
            <!-- Fresh Leads API -->
            <div class="card">
                <h2><span class="icon">👥</span> Fresh Leads API</h2>
                <p>View uncalled drivers (fresh leads) API response.</p>
                <a href="fresh_leads_api.php?action=fresh_leads&caller_id=1&limit=5" class="btn">View API</a>
            </div>
            
            <!-- Auth API -->
            <div class="card">
                <h2><span class="icon">🔐</span> Auth API</h2>
                <p>Test authentication API endpoint.</p>
                <a href="auth_api.php" class="btn">View API</a>
            </div>
        </div>
        
        <div class="docs-section">
            <h3>📚 Documentation</h3>
            <ul>
                <li>
                    <a href="../QUICK_FIX_INSTRUCTIONS.txt" target="_blank">
                        Quick Fix Instructions - Step-by-step guide to fix common issues
                    </a>
                </li>
                <li>
                    <a href="../TROUBLESHOOTING_GUIDE.md" target="_blank">
                        Troubleshooting Guide - Comprehensive problem-solving guide
                    </a>
                </li>
                <li>
                    <a href="../PLESK_DEPLOYMENT_GUIDE.md" target="_blank">
                        Plesk Deployment Guide - Complete deployment instructions
                    </a>
                </li>
                <li>
                    <a href="../FIXES_APPLIED.md" target="_blank">
                        Fixes Applied - Summary of all fixes and improvements
                    </a>
                </li>
            </ul>
        </div>
        
        <div class="docs-section">
            <h3>⚡ Quick Actions</h3>
            <p style="margin-bottom: 15px;">Common tasks and their solutions:</p>
            <ul>
                <li><strong>Dashboard shows zeros?</strong> → Run <a href="seed_test_data.php">Add Sample Data</a></li>
                <li><strong>IVR not working?</strong> → Run <a href="test_ivr_complete.php">IVR Test</a> and follow instructions</li>
                <li><strong>API not reachable?</strong> → Run <a href="test_connection.php">Connection Test</a></li>
                <li><strong>First time setup?</strong> → Run <a href="quick_setup.php">Quick Setup</a></li>
                <li><strong>Something broken?</strong> → Run <a href="comprehensive_test.php">System Test</a></li>
            </ul>
        </div>
        
        <div class="footer">
            <p>TruckMitr API v1.0 | Testing & Setup Tools</p>
            <p style="margin-top: 10px; font-size: 0.9rem;">
                For support, run the comprehensive test and share the results
            </p>
        </div>
    </div>
</body>
</html>
