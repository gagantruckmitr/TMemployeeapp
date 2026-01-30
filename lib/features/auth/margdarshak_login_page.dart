import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../margdarshak/services/margdarshak_auth_service.dart';

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

  final _authService = MargdarshakAuthService();

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    // Check if already logged in via MargdarshakAuthService
    final hasSession = await _authService.loadSession();
    if (hasSession && mounted) {
      // Already logged in, go to dashboard
      context.goNamed('margdarshak-dashboard');
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

                  // Demo credentials hint
                  const SizedBox(height: 20),
                  Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _mobileController.text = '6394752222';
                          _passwordController.text = '12345678';
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

      final result = await _authService.login(
        mobile: mobile,
        password: password,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${result.user?.name ?? 'Margdarshak'}!'),
              backgroundColor: Colors.green,
            ),
          );
          // Use pushReplacement to prevent going back to login
          context.goNamed('margdarshak-dashboard');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
