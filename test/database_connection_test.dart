import 'dart:io';
import 'package:mysql1/mysql1.dart';
import '../lib/core/database/database_config.dart';

void main() async {
  print('🔄 Testing TruckMitr Database Connection...\n');
  
  // Print configuration
  print('📋 Database Configuration:');
  print('   Host: ${DatabaseConfig.host}');
  print('   Port: ${DatabaseConfig.port}');
  print('   Database: ${DatabaseConfig.database}');
  print('   Username: ${DatabaseConfig.username}');
  print('   Password: ${DatabaseConfig.password.isEmpty ? "(empty)" : "***"}');
  print('');
  
  MySqlConnection? connection;
  
  try {
    // Test 1: Basic Connection
    print('🔌 Test 1: Basic Database Connection');
    connection = await _connectToDatabase();
    
    if (connection != null) {
      print('   ✅ SUCCESS: Database connected successfully!');
    } else {
      print('   ❌ FAILED: Could not connect to database');
      _printTroubleshootingSteps();
      exit(1);
    }
    
    // Test 2: Database Info
    print('\n📊 Test 2: Database Information');
    await _printDatabaseInfo(connection);
    
    // Test 3: Table Structure Check
    print('\n🗂️  Test 3: Checking Required Tables');
    await _checkTables(connection);
    
    // Test 4: Sample Data Check
    print('\n📋 Test 4: Checking Sample Data');
    await _checkSampleData(connection);
    
    // Test 5: Authentication Test
    print('\n🔐 Test 5: Authentication Test');
    await _testAuthentication(connection);
    
    print('\n🎉 All tests completed successfully!');
    print('✅ Database is properly connected to the backend.');
    
  } catch (e) {
    print('❌ ERROR: ${e.toString()}');
    _printTroubleshootingSteps();
    exit(1);
  } finally {
    // Clean up connection
    if (connection != null) {
      try {
        await connection.close();
        print('\n🔌 Database connection closed.');
      } catch (e) {
        print('Warning: Error closing connection: $e');
      }
    }
  }
  
  exit(0);
}

Future<MySqlConnection?> _connectToDatabase() async {
  try {
    final settings = ConnectionSettings(
      host: DatabaseConfig.host,
      port: DatabaseConfig.port,
      user: DatabaseConfig.username,
      password: DatabaseConfig.password,
      db: DatabaseConfig.database,
      timeout: DatabaseConfig.connectionTimeout,
    );

    final connection = await MySqlConnection.connect(settings);
    
    // Test with a simple query
    final result = await connection.query('SELECT 1 as test');
    print('   Test query result: ${result.first['test']}');
    
    return connection;
  } catch (e) {
    print('   Connection error: ${e.toString()}');
    return null;
  }
}

Future<void> _printDatabaseInfo(MySqlConnection connection) async {
  try {
    // Get database version
    final versionResult = await connection.query('SELECT VERSION() as version');
    print('   MySQL Version: ${versionResult.first['version']}');
    
    // Get table count
    final tableResult = await connection.query('SHOW TABLES');
    print('   Number of tables: ${tableResult.length}');
    
  } catch (e) {
    print('   ❌ Error getting database info: ${e.toString()}');
  }
}

Future<void> _checkTables(MySqlConnection connection) async {
  try {
    final requiredTables = ['admins', 'users', 'callback_requests', 'call_logs'];
    
    for (String table in requiredTables) {
      try {
        final result = await connection.query('SELECT COUNT(*) as count FROM $table');
        final count = result.first['count'];
        print('   ✅ Table "$table": $count records');
      } catch (e) {
        print('   ❌ Table "$table": Missing or inaccessible');
        throw Exception('Required table "$table" not found');
      }
    }
  } catch (e) {
    print('   ❌ Table check failed: ${e.toString()}');
    rethrow;
  }
}

Future<void> _checkSampleData(MySqlConnection connection) async {
  try {
    // Check admins
    final adminResult = await connection.query('SELECT COUNT(*) as count FROM admins');
    final adminCount = adminResult.first['count'];
    print('   📊 Admins: $adminCount');
    
    if (adminCount == 0) {
      print('   ⚠️  WARNING: No admin users found. You need to add test data.');
    }
    
    // Check users
    final userResult = await connection.query('SELECT COUNT(*) as count FROM users');
    final userCount = userResult.first['count'];
    print('   📊 Users: $userCount');
    
    // Check drivers specifically
    final driverResult = await connection.query('SELECT COUNT(*) as count FROM users WHERE role = "driver"');
    final driverCount = driverResult.first['count'];
    print('   📊 Drivers: $driverCount');
    
    // Check transporters specifically
    final transporterResult = await connection.query('SELECT COUNT(*) as count FROM users WHERE role = "transporter"');
    final transporterCount = transporterResult.first['count'];
    print('   📊 Transporters: $transporterCount');
    
    // Check callback requests
    final callbackResult = await connection.query('SELECT COUNT(*) as count FROM callback_requests');
    final callbackCount = callbackResult.first['count'];
    print('   📊 Callback Requests: $callbackCount');
    
  } catch (e) {
    print('   ❌ Sample data check failed: ${e.toString()}');
    rethrow;
  }
}

Future<void> _testAuthentication(MySqlConnection connection) async {
  try {
    // Test with common admin credentials
    final testCredentials = [
      {'email': 'admin@gmail.com', 'password': 'admin123'},
      {'email': 'admin@test.com', 'password': 'admin123'},
      {'email': 'puja@gmail.com', 'password': 'puja123'},
      {'email': 'telecaller@test.com', 'password': 'tele123'},
    ];
    
    bool foundValidAdmin = false;
    
    for (var cred in testCredentials) {
      try {
        final result = await connection.query(
          'SELECT * FROM admins WHERE email = ? AND password = ?',
          [cred['email'], cred['password']]
        );
        
        if (result.isNotEmpty) {
          final admin = result.first;
          print('   ✅ Login SUCCESS: ${admin['name']} (${admin['role']}) - ${cred['email']}');
          foundValidAdmin = true;
          break;
        }
      } catch (e) {
        // Continue to next credential
      }
    }
    
    if (!foundValidAdmin) {
      print('   ⚠️  WARNING: No valid admin credentials found.');
      print('   💡 You need to add test admin data. Run this SQL in phpMyAdmin:');
      print('   INSERT INTO admins (role, name, email, password, created_at, updated_at) VALUES ("admin", "Test Admin", "admin@test.com", "admin123", NOW(), NOW());');
    }
    
  } catch (e) {
    print('   ❌ Authentication test failed: ${e.toString()}');
    rethrow;
  }
}

void _printTroubleshootingSteps() {
  print('\n🔧 TROUBLESHOOTING STEPS:');
  print('');
  print('1. ✅ Check XAMPP Status:');
  print('   - Open XAMPP Control Panel');
  print('   - Ensure MySQL service is RUNNING (green)');
  print('   - If not running, click "Start" next to MySQL');
  print('');
  print('2. ✅ Check Database Exists:');
  print('   - Open phpMyAdmin: http://localhost/phpmyadmin');
  print('   - Look for "truckmitr" database in left sidebar');
  print('   - If missing, create it and import your SQL file');
  print('');
  print('3. ✅ Check Database Configuration:');
  print('   - File: lib/core/database/database_config.dart');
  print('   - Host should be: localhost or 127.0.0.1');
  print('   - Port should be: 3306');
  print('   - Username should be: root');
  print('   - Password should be: (empty for XAMPP default)');
  print('');
  print('4. ✅ Import Database:');
  print('   - In phpMyAdmin, select "truckmitr" database');
  print('   - Click "Import" tab');
  print('   - Choose file: assets/database/truckmitr (1).sql');
  print('   - Click "Go" to import');
  print('');
  print('5. ✅ Add Test Data:');
  print('   - In phpMyAdmin, go to SQL tab');
  print('   - Run the contents of: database_test_data.sql');
  print('');
  print('6. ✅ Check Firewall/Antivirus:');
  print('   - Temporarily disable firewall/antivirus');
  print('   - Some security software blocks database connections');
  print('');
  print('Need help? Check the detailed guides:');
  print('📖 SETUP.md - Complete setup instructions');
  print('📖 DATABASE_CONNECTION_GUIDE.md - Step-by-step connection guide');
}