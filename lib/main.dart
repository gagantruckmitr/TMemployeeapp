import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/session_manager.dart';
import 'core/services/real_auth_service.dart';
import 'core/services/phase2_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize session manager with auto-logout on expiration
  await SessionManager.instance.initialize(
    onExpired: () async {
      // Logout user when session expires
      final isRealAuthLoggedIn = await RealAuthService.instance.isLoggedIn();
      final isPhase2LoggedIn = await Phase2AuthService.isLoggedIn();

      if (isRealAuthLoggedIn) {
        await RealAuthService.instance.logout(keepCredentials: true);
      }

      if (isPhase2LoggedIn) {
        await Phase2AuthService.logout();
      }
    },
  );

  // Wrap the app in ProviderScope for Riverpod support
  runApp(const ProviderScope(child: TMEmployeeApp()));
}
