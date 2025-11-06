import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/phase2_user_model.dart';

class Phase2AuthService {
  static const String baseUrl = 'https://truckmitr.com/truckmitr-app/api';
  static const String _userKey = 'phase2_user';
  static const String _isLoggedInKey = 'phase2_is_logged_in';

  // Login
  static Future<Phase2User> login(String mobile, String password) async {
    try {
      print('Attempting login to: $baseUrl/phase2_auth_api.php');
      print('Mobile: $mobile');
      
      final response = await http.post(
        Uri.parse('$baseUrl/phase2_auth_api.php'),
        body: {
          'action': 'login',
          'mobile': mobile,
          'password': password,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet connection');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final user = Phase2User.fromJson(data['data']);
          await _saveUser(user);
          return user;
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Save user to local storage
  static Future<void> _saveUser(Phase2User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get current user
  static Future<Phase2User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return Phase2User.fromJson(json.decode(userJson));
    }
    return null;
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Get user ID for call logs
  static Future<int> getUserId() async {
    final user = await getCurrentUser();
    return user?.id ?? 0;
  }
}
