import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/services/phase2_auth_service.dart';
import 'features/auth/phase2_login_screen.dart';
import 'features/main_container.dart';

void main() {
  runApp(const Phase2App());
}

class Phase2App extends StatelessWidget {
  const Phase2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruckMitr Match Making',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await Phase2AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return _isLoggedIn ? const MainContainer() : const Phase2LoginScreen();
  }
}
