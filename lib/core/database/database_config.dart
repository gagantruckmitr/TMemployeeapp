class DatabaseConfig {
  static const String host = '127.0.0.1'; // Use IP instead of localhost
  static const int port = 3306;
  static const String database = 'truckmitr';
  static const String username = 'root';
  static const String password = ''; // Change this if phpMyAdmin requires password
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration queryTimeout = Duration(seconds: 15);
  
  // Connection string for MySQL
  static String get connectionString => 
      'mysql://$username:$password@$host:$port/$database';
}