import 'database_service.dart';
import 'database_config.dart';

class DatabaseSetup {
  static Future<bool> testConnection() async {
    try {
      final db = DatabaseService.instance;
      final conn = await db.connection;
      
      // Test query
      final result = await conn.query('SELECT 1 as test');
      
      print('Database connection successful!');
      print('Test query result: ${result.first['test']}');
      
      return true;
    } catch (e) {
      print('Database connection failed: $e');
      return false;
    }
  }

  static Future<void> printDatabaseInfo() async {
    try {
      final db = DatabaseService.instance;
      final conn = await db.connection;
      
      // Get database version
      final versionResult = await conn.query('SELECT VERSION() as version');
      print('MySQL Version: ${versionResult.first['version']}');
      
      // Get table count
      final tableResult = await conn.query('SHOW TABLES');
      print('Number of tables: ${tableResult.length}');
      
      // Get admin count
      final adminResult = await conn.query('SELECT COUNT(*) as count FROM admins');
      print('Number of admins: ${adminResult.first['count']}');
      
      // Get user count
      final userResult = await conn.query('SELECT COUNT(*) as count FROM users');
      print('Number of users: ${userResult.first['count']}');
      
      // Get callback requests count
      final callbackResult = await conn.query('SELECT COUNT(*) as count FROM callback_requests');
      print('Number of callback requests: ${callbackResult.first['count']}');
      
    } catch (e) {
      print('Error getting database info: $e');
    }
  }

  static void printConnectionInstructions() {
    print('''
=== Database Setup Instructions ===

1. Make sure MySQL/MariaDB is running on your system
2. Create a database named 'truckmitr'
3. Import the SQL file: assets/database/truckmitr (1).sql
4. Update database credentials in lib/core/database/database_config.dart:
   - host: ${DatabaseConfig.host}
   - port: ${DatabaseConfig.port}
   - username: ${DatabaseConfig.username}
   - password: ${DatabaseConfig.password}
   - database: ${DatabaseConfig.database}

5. Test credentials from existing admins table:
   - Email: admin@gmail.com, Password: (check database for hashed password)
   - Email: puja@gmail.com (telecaller)
   - Email: tanisha@gmail.com (telecaller)

Note: The app uses hashed passwords. For testing, you may need to:
1. Create a new admin with a known password, or
2. Update the password field with a plain text password temporarily
3. Modify the authentication logic in auth_service.dart for plain text comparison

=== Quick MySQL Commands ===
mysql -u root -p
CREATE DATABASE truckmitr;
USE truckmitr;
SOURCE path/to/truckmitr.sql;

=== Test Connection ===
Call DatabaseSetup.testConnection() in your app to verify the connection.
''');
  }
}