import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../models/phase2_user_model.dart';
import 'api_service.dart';
import 'smart_calling_service.dart';
import 'session_manager.dart';

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
  static const String _keySavedMobile = 'saved_mobile';
  static const String _keySavedPassword = 'saved_password';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmployeeDetails = 'employee_details';

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
      final uri = Uri.parse('https://truckmitr.com/api/telehead/login');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'mobile': mobile, 'password': password}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // New API uses 'status' instead of 'success' and 'data' instead of 'user'
        if (data['status'] == true) {
          final userData = data['data'];

          // Parse employee details if available
          EmployeeDetails? employeeDetails;
          if (userData['employee_details'] != null) {
            employeeDetails = EmployeeDetails.fromJson(
              userData['employee_details'],
            );
          }

          final user = UserProfile(
            id: userData['id']?.toString() ?? '',
            role: userData['role'] ?? '',
            name: userData['name'] ?? '',
            mobile: userData['mobile'] ?? '',
            email: employeeDetails?.email ?? userData['email'] ?? '',
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            employeeDetails: employeeDetails,
          );
          final token = data['token'];

          _currentUser = user;
          await _saveUserSession(user, token);

          // CRITICAL: Set caller ID for API calls immediately after login
          ApiService.setCallerId(user.id);

          // Sync user data to Phase2AuthService format for IVR compatibility
          await _syncToPhase2Auth(user);

          // Reset session timer on successful login
          await SessionManager.instance.resetSession();

          // Update telecaller status to online if role is telecaller
          if (user.role == 'telecaller') {
            await _updateTelecallerStatus(user.id, 'online');
            await _recordLogin(user.id);
          }

          return LoginResult.success(user);
        } else {
          return LoginResult.failure(data['message'] ?? 'Login failed');
        }
      } else {
        final data = json.decode(response.body);
        return LoginResult.failure(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      return LoginResult.failure('Connection error: $e');
    }
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String mobile) async {
    try {
      final uri = Uri.parse(
        'https://truckmitr.com/api/telehead/forgot-password',
      );

      print('🔵 Requesting OTP for mobile: $mobile');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'mobile': mobile}),
          )
          .timeout(timeout);

      print('🔵 Forgot Password Response: ${response.body}');

      final data = json.decode(response.body);
      // Ensure we return a consistent format
      if (response.statusCode == 200) {
        return {
          'success':
              true, // The API might return 'status' or 'success', adjust based on actual response if needed. Assuming standard pattern.
          ...data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
          ...data,
        };
      }
    } catch (e) {
      print('❌ Forgot Password Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String mobile,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final uri = Uri.parse(
        'https://truckmitr.com/api/telehead/reset-password',
      );

      print('🔵 Resetting password for mobile: $mobile with token: $token');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'mobile': mobile,
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(timeout);

      print('🔵 Reset Password Response: ${response.body}');

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset password',
          ...data,
        };
      }
    } catch (e) {
      print('❌ Reset Password Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get user profile from API
  Future<UserProfileWithStats?> getProfile() async {
    if (_currentUser == null) return null;

    try {
      final uri = Uri.parse('$baseUrl/auth_api.php').replace(
        queryParameters: {'action': 'profile', 'user_id': _currentUser!.id},
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
      final uri = Uri.parse(
        '$baseUrl/auth_api.php',
      ).replace(queryParameters: {'action': 'update_profile'});

      final body = <String, dynamic>{'user_id': _currentUser!.id};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (mobile != null) body['mobile'] = mobile;

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(timeout);

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

    // Check session validity (DISABLED)
    /*
    if (isLoggedIn && _currentUser != null) {
      final isSessionValid = await SessionManager.instance.isSessionValid();
      if (!isSessionValid) {
        print('Session expired due to inactivity - logging out');
        await logout(keepCredentials: true);
        return false;
      }
    }
    */

    return isLoggedIn && _currentUser != null;
  }

  // Logout
  Future<void> logout({bool keepCredentials = true}) async {
    // Save credentials before clearing if needed
    Map<String, String?>? savedCreds;
    if (keepCredentials) {
      savedCreds = await getSavedCredentials();
    }

    try {
      // Update telecaller status to offline if role is telecaller
      if (_currentUser?.role == 'telecaller') {
        await _updateTelecallerStatus(_currentUser!.id, 'offline');
        await _recordLogout(_currentUser!.id);
      }

      // Call logout API
      final uri = Uri.parse(
        '$baseUrl/auth_api.php',
      ).replace(queryParameters: {'action': 'logout'});
      await http.get(uri).timeout(timeout);
    } catch (e) {
      print('Logout API call failed: $e');
    }

    // Clear session manager
    await SessionManager.instance.clearSession();

    // CRITICAL: Clear API caller ID and cached data
    ApiService.setCallerId('');
    SmartCallingService.instance.clearCache();

    // Clear local session
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentUser = null;

    // Restore saved credentials if needed
    if (keepCredentials && savedCreds != null) {
      final mobile = savedCreds['mobile'];
      final password = savedCreds['password'];
      if (mobile != null && password != null) {
        await saveCredentials(mobile, password);
      }
    }
  }

  // Update telecaller status
  Future<void> _updateTelecallerStatus(
    String telecallerId,
    String status,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/manager_dashboard_api.php',
      ).replace(queryParameters: {'action': 'update_telecaller_status'});

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'telecaller_id': int.parse(telecallerId),
              'status': status,
            }),
          )
          .timeout(timeout);

      print('✅ Telecaller status updated to: $status');
    } catch (e) {
      print('❌ Failed to update telecaller status: $e');
    }
  }

  // Record login time
  Future<void> _recordLogin(String telecallerId) async {
    try {
      final uri = Uri.parse('$baseUrl/live_status_api.php?action=login');

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(timeout);

      print('✅ Login time recorded');
    } catch (e) {
      print('❌ Failed to record login: $e');
    }
  }

  // Record logout time
  Future<void> _recordLogout(String telecallerId) async {
    try {
      final uri = Uri.parse('$baseUrl/live_status_api.php?action=logout');

      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telecaller_id': int.parse(telecallerId)}),
          )
          .timeout(timeout);

      print('✅ Logout time recorded');
    } catch (e) {
      print('❌ Failed to record logout: $e');
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

    // Save employee details as JSON
    if (user.employeeDetails != null) {
      await prefs.setString(
        _keyEmployeeDetails,
        json.encode(user.employeeDetails!.toJson()),
      );
    }

    print(
      '💾 Saved user session - ID: ${user.id}, Name: ${user.name}, Role: ${user.role}',
    );
    print(
      '💾 Saved token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
    );
  }

  // Sync user data to Phase2AuthService format for IVR compatibility
  Future<void> _syncToPhase2Auth(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phase2User = Phase2User(
        id: int.tryParse(user.id) ?? 0,
        name: user.name,
        mobile: user.mobile,
        email: user.email,
        role: user.role,
        tcFor: '', // Not available in RealAuthService
        createdAt: DateTime.now().toIso8601String(),
      );

      // Save to Phase2AuthService keys
      await prefs.setString('phase2_user', json.encode(phase2User.toJson()));
      await prefs.setBool('phase2_is_logged_in', true);

      print('✅ User data synced to Phase2AuthService for IVR compatibility');
    } catch (e) {
      print('⚠️ Failed to sync user to Phase2AuthService: $e');
      // Don't fail login if sync fails
    }
  }

  // Save credentials for auto-fill
  Future<void> saveCredentials(String mobile, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedMobile, mobile);
    await prefs.setString(_keySavedPassword, password);
    await prefs.setBool(_keyRememberMe, true);
  }

  // Get saved credentials
  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

    if (rememberMe) {
      return {
        'mobile': prefs.getString(_keySavedMobile),
        'password': prefs.getString(_keySavedPassword),
      };
    }

    return {'mobile': null, 'password': null};
  }

  // Clear saved credentials
  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedMobile);
    await prefs.remove(_keySavedPassword);
    await prefs.setBool(_keyRememberMe, false);
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
    final employeeDetailsJson = prefs.getString(_keyEmployeeDetails);

    if (userId != null &&
        userName != null &&
        userEmail != null &&
        userRole != null &&
        userMobile != null) {
      // Restore employee details if available
      EmployeeDetails? employeeDetails;
      if (employeeDetailsJson != null) {
        try {
          employeeDetails = EmployeeDetails.fromJson(
            json.decode(employeeDetailsJson),
          );
        } catch (e) {
          print('⚠️ Failed to restore employee details: $e');
        }
      }

      _currentUser = UserProfile(
        id: userId,
        name: userName,
        email: userEmail,
        role: userRole,
        mobile: userMobile,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        employeeDetails: employeeDetails,
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
    final token = prefs.getString(_keyAuthToken);
    if (token != null) {
      print(
        '🔑 Retrieved token from storage: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
      );
    } else {
      print('⚠️ No token found in storage');
    }
    return token;
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
  final EmployeeDetails? employeeDetails;

  UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.mobile,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.employeeDetails,
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
      employeeDetails: json['employee_details'] != null
          ? EmployeeDetails.fromJson(json['employee_details'])
          : null,
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
      'employee_details': employeeDetails?.toJson(),
    };
  }

  // Helper to get full photo URL
  String? get photoUrl {
    if (employeeDetails?.photoPath != null &&
        employeeDetails!.photoPath!.isNotEmpty) {
      return 'https://truckmitr.com/storage/app/public/${employeeDetails!.photoPath}';
    }
    return null;
  }
}

// Employee Details Model
class EmployeeDetails {
  final int? id;
  final String? empId;
  final String? fullName;
  final String? guardianName;
  final String? dob;
  final String? gender;
  final String? mobile;
  final String? email;
  final String? photoPath;
  final String? currentAddress;
  final String? permanentAddress;
  final String? city;
  final String? state;
  final String? pin;
  final String? department;
  final String? designation;
  final String? doj;
  final String? workLocation;
  final String? employmentType;
  final String? reportingManager;
  final String? ctc;
  final String? pan;
  final String? aadhaar;
  final String? highestQualification;
  final String? emergencyName;
  final String? emergencyRelation;
  final String? emergencyPhone;
  final String? status;
  final String? basicSalary;
  final String? grossSalary;

  EmployeeDetails({
    this.id,
    this.empId,
    this.fullName,
    this.guardianName,
    this.dob,
    this.gender,
    this.mobile,
    this.email,
    this.photoPath,
    this.currentAddress,
    this.permanentAddress,
    this.city,
    this.state,
    this.pin,
    this.department,
    this.designation,
    this.doj,
    this.workLocation,
    this.employmentType,
    this.reportingManager,
    this.ctc,
    this.pan,
    this.aadhaar,
    this.highestQualification,
    this.emergencyName,
    this.emergencyRelation,
    this.emergencyPhone,
    this.status,
    this.basicSalary,
    this.grossSalary,
  });

  factory EmployeeDetails.fromJson(Map<String, dynamic> json) {
    return EmployeeDetails(
      id: json['id'],
      empId: json['emp_id'],
      fullName: json['full_name'],
      guardianName: json['guardian_name'],
      dob: json['dob'],
      gender: json['gender'],
      mobile: json['mobile'],
      email: json['email'],
      photoPath: json['photo_path'],
      currentAddress: json['current_address'],
      permanentAddress: json['permanent_address'],
      city: json['city'],
      state: json['state'],
      pin: json['pin'],
      department: json['department'],
      designation: json['designation'],
      doj: json['doj'],
      workLocation: json['work_location'],
      employmentType: json['employment_type'],
      reportingManager: json['reporting_manager'],
      ctc: json['ctc']?.toString(),
      pan: json['pan'],
      aadhaar: json['aadhaar'],
      highestQualification: json['highest_qualification'],
      emergencyName: json['emergency_name'],
      emergencyRelation: json['emergency_relation'],
      emergencyPhone: json['emergency_phone'],
      status: json['status'],
      basicSalary: json['basic_salary']?.toString(),
      grossSalary: json['gross_salary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emp_id': empId,
      'full_name': fullName,
      'guardian_name': guardianName,
      'dob': dob,
      'gender': gender,
      'mobile': mobile,
      'email': email,
      'photo_path': photoPath,
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
      'city': city,
      'state': state,
      'pin': pin,
      'department': department,
      'designation': designation,
      'doj': doj,
      'work_location': workLocation,
      'employment_type': employmentType,
      'reporting_manager': reportingManager,
      'ctc': ctc,
      'pan': pan,
      'aadhaar': aadhaar,
      'highest_qualification': highestQualification,
      'emergency_name': emergencyName,
      'emergency_relation': emergencyRelation,
      'emergency_phone': emergencyPhone,
      'status': status,
      'basic_salary': basicSalary,
      'gross_salary': grossSalary,
    };
  }

  // Helper to get full photo URL
  String? get photoUrl {
    if (photoPath != null && photoPath!.isNotEmpty) {
      return 'https://truckmitr.com/storage/app/public/$photoPath';
    }
    return null;
  }
}

// User Profile with Stats
class UserProfileWithStats {
  final UserProfile user;
  final UserStats stats;

  UserProfileWithStats({required this.user, required this.stats});

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
