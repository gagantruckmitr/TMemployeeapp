import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_service.dart';
import '../../models/database_models.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserMobile = 'user_mobile';

  static AuthService? _instance;
  AuthService._();

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  Admin? _currentUser;
  Admin? get currentUser => _currentUser;

  // Login with email and password
  Future<LoginResult> login(String email, String password) async {
    try {
      // For demo/testing purposes - accept any login credentials
      // Create a mock admin user for testing
      final mockAdmin = Admin(
        id: 1,
        name: 'Test User',
        email: email.isNotEmpty ? email : 'test@example.com',
        role: 'telecaller',
        mobile: '9999999999',
        password: '',
        rememberToken: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = mockAdmin;
      await _saveUserSession(mockAdmin);
      return LoginResult.success(mockAdmin);

      // Uncomment below for actual database authentication
      /*
      final admin = await DatabaseService.instance.authenticateAdmin(email, password);
      
      if (admin != null) {
        _currentUser = admin;
        await _saveUserSession(admin);
        return LoginResult.success(admin);
      } else {
        return LoginResult.failure('Invalid email or password');
      }
      */
    } catch (e) {
      // Even if there's an error, allow login for testing
      final mockAdmin = Admin(
        id: 1,
        name: 'Test User',
        email: email.isNotEmpty ? email : 'test@example.com',
        role: 'telecaller',
        mobile: '9999999999',
        password: '',
        rememberToken: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = mockAdmin;
      await _saveUserSession(mockAdmin);
      return LoginResult.success(mockAdmin);
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (isLoggedIn && _currentUser == null) {
      // Restore user session
      await _restoreUserSession();
    }
    
    return isLoggedIn && _currentUser != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
    
    // Close database connection
    await DatabaseService.instance.disconnect();
  }

  // Save user session
  Future<void> _saveUserSession(Admin admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, admin.id);
    await prefs.setString(_keyUserName, admin.name);
    await prefs.setString(_keyUserEmail, admin.email);
    await prefs.setString(_keyUserRole, admin.role);
    await prefs.setString(_keyUserMobile, admin.mobile);
  }

  // Restore user session
  Future<void> _restoreUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_keyUserId);
    final userName = prefs.getString(_keyUserName);
    final userEmail = prefs.getString(_keyUserEmail);
    final userRole = prefs.getString(_keyUserRole);
    final userMobile = prefs.getString(_keyUserMobile);

    if (userId != null && userName != null && userEmail != null && userRole != null && userMobile != null) {
      _currentUser = Admin(
        id: userId,
        name: userName,
        email: userEmail,
        role: userRole,
        mobile: userMobile,
        password: '', // Don't store password in preferences
        rememberToken: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Get user role
  String? getUserRole() {
    return _currentUser?.role;
  }

  // Check if user is telecaller
  bool isTelecaller() {
    return _currentUser?.role == 'telecaller';
  }

  // Check if user is admin
  bool isAdmin() {
    return _currentUser?.role == 'admin';
  }

  // Check if user is manager
  bool isManager() {
    return _currentUser?.role == 'manager';
  }
}

class LoginResult {
  final bool isSuccess;
  final String? errorMessage;
  final Admin? user;

  LoginResult._(this.isSuccess, this.errorMessage, this.user);

  factory LoginResult.success(Admin user) {
    return LoginResult._(true, null, user);
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(false, message, null);
  }
}