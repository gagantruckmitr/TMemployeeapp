import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../models/margdarshak_user_model.dart';

/// Margdarshak Authentication Service
/// Handles login, logout, and session management for field agents
class MargdarshakAuthService {
  static const String _tokenKey = 'margdarshak_token';
  static const String _userKey = 'margdarshak_user';
  static const Duration _timeout = Duration(seconds: 30);

  // Singleton pattern
  static final MargdarshakAuthService _instance =
      MargdarshakAuthService._internal();
  factory MargdarshakAuthService() => _instance;
  MargdarshakAuthService._internal();

  MargdarshakUser? _currentUser;
  String? _authToken;

  // Getters
  MargdarshakUser? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _currentUser != null && _authToken != null;

  /// Login with mobile and password
  Future<MargdarshakLoginResponse> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/login');

      print('🔵 Margdarshak Login Request:');
      print('   URL: $url');
      print('   Mobile: $mobile');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'mobile': mobile,
              'password': password,
            }),
          )
          .timeout(_timeout);

      print('🔵 Margdarshak Login Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loginResponse = MargdarshakLoginResponse.fromJson(data);

        if (loginResponse.isSuccess) {
          // Save user and token
          _currentUser = loginResponse.user;
          _authToken = loginResponse.token;

          // Persist to SharedPreferences
          await _saveSession();

          print('✅ Margdarshak login successful');
          print('   User: ${_currentUser?.name}');
          print('   Employee ID: ${_currentUser?.employeeId}');
          print('   State: ${_currentUser?.stateName}');
        }

        return loginResponse;
      } else {
        return MargdarshakLoginResponse(
          status: false,
          message: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Margdarshak login error: $e');
      return MargdarshakLoginResponse(
        status: false,
        message: 'Connection error: $e',
      );
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_authToken != null) {
      await prefs.setString(_tokenKey, _authToken!);
    }

    if (_currentUser != null) {
      await prefs.setString(_userKey, json.encode(_currentUser!.toJson()));
    }

    // Also save to common keys for compatibility
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('role', 'field_agent');
    await prefs.setString('user_id', _currentUser?.id.toString() ?? '');
    await prefs.setString('user_name', _currentUser?.name ?? '');
    await prefs.setString('user_mobile', _currentUser?.mobile ?? '');
    await prefs.setString('auth_token', _authToken ?? '');
  }

  /// Load session from SharedPreferences
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        _authToken = token;
        _currentUser = MargdarshakUser.fromJson(json.decode(userJson));

        print('✅ Margdarshak session loaded');
        print('   User: ${_currentUser?.name}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Failed to load session: $e');
      return false;
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear margdarshak-specific keys
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    // Clear common keys
    await prefs.remove('is_logged_in');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('auth_token');

    _currentUser = null;
    _authToken = null;

    print('✅ Margdarshak logged out');
  }

  /// Get headers with authentication token
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
}
