import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'smart_calling_service.dart';

class RealAuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  static Duration get timeout => ApiConfig.timeout;
  
  // SharedPreferences keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserMobile = 'user_mobile';
  static const String _keyAuthToken = 'auth_token';

  static RealAuthService? _instance;
  RealAuthService._();

  static RealAuthService get instance {
    _instance ??= RealAuthService._();
    return _instance!;
  }

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  // Login with mobile and password
  Future<LoginResult> login(String mobile, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/auth_api.php').replace(
        queryParameters: {'action': 'login'},
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mobile': mobile,
          'password': password,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final user = UserProfile.fromJson(data['user']);
          final token = data['token'];
          
          _currentUser = user;
          await _saveUserSession(user, token);
          
          // Update telecaller status to online if role is telecaller
          if (user.role == 'telecaller') {
            await _updateTelecallerStatus(user.id, 'online');
          }
          
          return LoginResult.success(user);
        } else {
          return LoginResult.failure(data['error'] ?? 'Login failed');
        }
      } else {
        final data = json.decode(response.body);
        return LoginResult.failure(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      return LoginResult.failure('Connection error: $e');
    }
  }

  // Get user profile from API
  Future<UserProfileWithStats?> getProfile() async {
    if (_currentUser == null) return null;

    try {
      final uri = Uri.parse('$baseUrl/auth_api.php').replace(
        queryParameters: {
          'action': 'profile',
          'user_id': _currentUser!.id,
        },
      );

      final response = await http.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserProfileWithStats.fromJson(data);
        }
      }
    } catch (e) {
      print('Failed to fetch profile: $e');
    }
    return null;
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? mobile,
  }) async {
    if (_currentUser == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/auth_api.php').replace(
        queryParameters: {'action': 'update_profile'},
      );

      final body = <String, dynamic>{
        'user_id': _currentUser!.id,
      };
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (mobile != null) body['mobile'] = mobile;

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update local user data
          _currentUser = UserProfile(
            id: _currentUser!.id,
            role: _currentUser!.role,
            name: name ?? _currentUser!.name,
            mobile: mobile ?? _currentUser!.mobile,
            email: email ?? _currentUser!.email,
            createdAt: _currentUser!.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
          await _updateUserSession(_currentUser!);
          return true;
        }
      }
    } catch (e) {
      print('Failed to update profile: $e');
    }
    return false;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (isLoggedIn && _currentUser == null) {
      await _restoreUserSession();
    }
    
    return isLoggedIn && _currentUser != null;
  }

  // Logout
  Future<void> logout() async {
    try {
      // Update telecaller status to offline if role is telecaller
      if (_currentUser?.role == 'telecaller') {
        await _updateTelecallerStatus(_currentUser!.id, 'offline');
      }
      
      // Call logout API
      final uri = Uri.parse('$baseUrl/auth_api.php').replace(
        queryParameters: {'action': 'logout'},
      );
      await http.get(uri).timeout(timeout);
    } catch (e) {
      print('Logout API call failed: $e');
    }

    // CRITICAL: Clear API caller ID and cached data
    ApiService.setCallerId('');
    SmartCallingService.instance.clearCache();
    
    // Clear local session
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;
  }
  
  // Update telecaller status
  Future<void> _updateTelecallerStatus(String telecallerId, String status) async {
    try {
      final uri = Uri.parse('$baseUrl/manager_dashboard_api.php').replace(
        queryParameters: {'action': 'update_telecaller_status'},
      );
      
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'telecaller_id': int.parse(telecallerId),
          'status': status,
        }),
      ).timeout(timeout);
      
      print('✅ Telecaller status updated to: $status');
    } catch (e) {
      print('❌ Failed to update telecaller status: $e');
    }
  }

  // Save user session
  Future<void> _saveUserSession(UserProfile user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserEmail, user.email);
    await prefs.setString(_keyUserRole, user.role);
    await prefs.setString(_keyUserMobile, user.mobile);
    await prefs.setString(_keyAuthToken, token);
  }

  // Update user session
  Future<void> _updateUserSession(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserEmail, user.email);
    await prefs.setString(_keyUserMobile, user.mobile);
  }

  // Restore user session
  Future<void> _restoreUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final userName = prefs.getString(_keyUserName);
    final userEmail = prefs.getString(_keyUserEmail);
    final userRole = prefs.getString(_keyUserRole);
    final userMobile = prefs.getString(_keyUserMobile);

    if (userId != null && userName != null && userEmail != null && 
        userRole != null && userMobile != null) {
      _currentUser = UserProfile(
        id: userId,
        name: userName,
        email: userEmail,
        role: userRole,
        mobile: userMobile,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      // CRITICAL FIX: Set caller ID for API calls when session is restored
      // This ensures each telecaller gets their own leads
      _setCallerIdForApiCalls(userId);
    }
  }
  
  // Set caller ID for API calls
  void _setCallerIdForApiCalls(String userId) {
    try {
      ApiService.setCallerId(userId);
      print('✅ Caller ID set to: $userId for API calls');
    } catch (e) {
      print('❌ Failed to set caller ID: $e');
    }
  }

  // Get auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  // Role checks
  bool isTelecaller() => _currentUser?.role == 'telecaller';
  bool isAdmin() => _currentUser?.role == 'admin';
  bool isManager() => _currentUser?.role == 'manager';
}

// User Profile Model
class UserProfile {
  final String id;
  final String role;
  final String name;
  final String mobile;
  final String email;
  final String createdAt;
  final String updatedAt;

  UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.mobile,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'mobile': mobile,
      'email': email,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// User Profile with Stats
class UserProfileWithStats {
  final UserProfile user;
  final UserStats stats;

  UserProfileWithStats({
    required this.user,
    required this.stats,
  });

  factory UserProfileWithStats.fromJson(Map<String, dynamic> json) {
    return UserProfileWithStats(
      user: UserProfile.fromJson(json['user']),
      stats: UserStats.fromJson(json['stats']),
    );
  }
}

// User Stats Model
class UserStats {
  final int totalCalls;
  final int connectedCalls;
  final int pendingCalls;
  final int callbacksScheduled;

  UserStats({
    required this.totalCalls,
    required this.connectedCalls,
    required this.pendingCalls,
    required this.callbacksScheduled,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalCalls: json['totalCalls'] ?? 0,
      connectedCalls: json['connectedCalls'] ?? 0,
      pendingCalls: json['pendingCalls'] ?? 0,
      callbacksScheduled: json['callbacksScheduled'] ?? 0,
    );
  }

  double get successRate {
    if (totalCalls == 0) return 0.0;
    return (connectedCalls / totalCalls) * 100;
  }
}

// Login Result
class LoginResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserProfile? user;

  LoginResult._(this.isSuccess, this.errorMessage, this.user);

  factory LoginResult.success(UserProfile user) {
    return LoginResult._(true, null, user);
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(false, message, null);
  }
}
