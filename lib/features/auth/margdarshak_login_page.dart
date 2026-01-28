import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/app_router.dart';
import '../../core/services/real_auth_service.dart';

class MargdarshakLoginPage extends StatefulWidget {
  const MargdarshakLoginPage({super.key});

  @override
  State<MargdarshakLoginPage> createState() => _MargdarshakLoginPageState();
}

class _MargdarshakLoginPageState extends State<MargdarshakLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  // Classic Professional Theme
  static const Color _primaryColor = Color(0xFF1565C0); // Classic Blue
  static const Color _backgroundColor = Colors.white;
  static const Color _textColor = Color(0xFF333333);
  static const Color _borderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await RealAuthService.instance.getSavedCredentials();
    if (credentials['mobile'] != null && credentials['password'] != null) {
      if (mounted) {
        setState(() {
          _mobileController.text = credentials['mobile']!;
          _passwordController.text = credentials['password']!;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Standard clean UI
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  const Center(
                    child: Icon(
                      Icons.account_circle, // Standard profile icon
                      size: 80,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header text
                  const Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 48),

                  // Mobile Input
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: const Icon(
                        Icons.phone_android,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length != 10) return 'Invalid mobile number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Remember Me & Forgot Password
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: _primaryColor,
                        onChanged: (val) =>
                            setState(() => _rememberMe = val ?? false),
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: _primaryColor),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Back to Role Selection
                  TextButton(
                    onPressed: () => context.go(AppRouter.roleSelection),
                    child: const Text(
                      'Back to Role Selection',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  // Simple Demo Link
                  const SizedBox(height: 20),
                  Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _mobileController.text = '1234567890';
                          _passwordController.text = 'demo123';
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Use Demo Account',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final mobile = _mobileController.text.trim();
      final password = _passwordController.text;

      final result = await RealAuthService.instance.login(mobile, password);

      if (result.isSuccess && result.user != null) {
        final user = result.user!;

        if (user.role != 'margdarshak' && user.role != 'field_agent') {
          await RealAuthService.instance.logout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Access denied. Margdarshak only.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        if (_rememberMe) {
          await RealAuthService.instance.saveCredentials(mobile, password);
        }

        if (mounted) {
          context.go(AppRouter.margdarshakDashboard);
        }
      } else {
        // Demo fallback
        if (mobile == '1234567890' && password == 'demo123') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_id', 'demo_margdarshak');
          await prefs.setString('user_name', 'Demo Margdarshak');
          await prefs.setString('user_email', 'demo@margdarshak.com');
          await prefs.setString('user_role', 'margdarshak');
          await prefs.setString('user_mobile', mobile);
          await prefs.setString('auth_token', 'demo_token');
          await RealAuthService.instance.isLoggedIn();

          if (_rememberMe) {
            await RealAuthService.instance.saveCredentials(mobile, password);
          }

          if (mounted) {
            context.go(AppRouter.margdarshakDashboard);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Invalid credentials'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
