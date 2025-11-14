import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'core/services/phase2_auth_service.dart';
import 'core/services/real_auth_service.dart';
import 'features/auth/unified_login_screen.dart';
import 'features/main_container.dart';
import 'features/telecaller/navigation_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const TMEmployeeApp());
}

class TMEmployeeApp extends StatelessWidget {
  const TMEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruckMitr Employee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
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
  Widget? _homeScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Check both auth systems
    final phase2LoggedIn = await Phase2AuthService.isLoggedIn();
    final tmConnectLoggedIn = await RealAuthService.instance.isLoggedIn();

    Widget home;
    if (phase2LoggedIn) {
      home = const MainContainer(); // Match Making app
    } else if (tmConnectLoggedIn) {
      home = const NavigationContainer(); // TMConnect app
    } else {
      home = const UnifiedLoginScreen(); // Show login with toggle
    }

    setState(() {
      _homeScreen = home;
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

    return _homeScreen ?? const UnifiedLoginScreen();
  }
}
