import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// TaskSuite Authentication Service
/// Handles authentication with the TaskSuite HRMS backend
class TaskSuiteAuthService {
  static const String _tokenKey = 'tasksuite_token';
  static const String _userKey = 'tasksuite_user';
  static const String _emailKey = 'tasksuite_email';

  static TaskSuiteAuthService? _instance;
  static TaskSuiteAuthService get instance {
    _instance ??= TaskSuiteAuthService._();
    return _instance!;
  }

  TaskSuiteAuthService._();

  String? _token;
  Map<String, dynamic>? _user;

  /// Get stored token
  String? get token => _token;

  /// Get stored user
  Map<String, dynamic>? get user => _user;

  /// Check if authenticated with TaskSuite
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Initialize - restore from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _user = json.decode(userJson);
      } catch (e) {
        print('⚠️ Error parsing TaskSuite user: $e');
      }
    }
    print('🔐 TaskSuite token available: ${_token != null}');
  }

  /// Login to TaskSuite
  Future<TaskSuiteLoginResult> login(String email, String password) async {
    try {
      print('🔐 TaskSuite: Attempting login...');
      print('📧 Email: $email');
      print('🔗 URL: ${ApiConstants.login}');

      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password_hash': password}),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['token'] != null) {
          _token = data['token'];
          _user = data['user'];

          // Save to storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          await prefs.setString(_emailKey, email);
          if (_user != null) {
            await prefs.setString(_userKey, json.encode(_user));
          }

          print('✅ TaskSuite login successful!');
          print('👤 User: ${_user?['name']}');
          return TaskSuiteLoginResult.success(_user!, _token!);
        } else {
          return TaskSuiteLoginResult.failure(
            data['message'] ?? 'Login failed',
          );
        }
      } else {
        final data = json.decode(response.body);
        return TaskSuiteLoginResult.failure(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ TaskSuite login error: $e');
      return TaskSuiteLoginResult.failure('Connection error: $e');
    }
  }

  /// Get token for API calls
  Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  /// Get stored email
  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_emailKey);
    print('🔓 TaskSuite logged out');
  }

  /// Clear token (for re-authentication)
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

/// Result of TaskSuite login attempt
class TaskSuiteLoginResult {
  final bool success;
  final Map<String, dynamic>? user;
  final String? token;
  final String? error;

  TaskSuiteLoginResult._({
    required this.success,
    this.user,
    this.token,
    this.error,
  });

  factory TaskSuiteLoginResult.success(
    Map<String, dynamic> user,
    String token,
  ) {
    return TaskSuiteLoginResult._(success: true, user: user, token: token);
  }

  factory TaskSuiteLoginResult.failure(String error) {
    return TaskSuiteLoginResult._(success: false, error: error);
  }
}
