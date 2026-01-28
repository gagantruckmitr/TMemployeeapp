import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/session_manager.dart';
import 'core/services/real_auth_service.dart';
import 'core/services/phase2_auth_service.dart';
import 'firebase_options.dart'; // Assuming firebase_options.dart will be generated or handled

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
