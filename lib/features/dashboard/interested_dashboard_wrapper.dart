import 'package:flutter/material.dart';
import '../dashboard/dynamic_dashboard_screen.dart';

/// Simple wrapper that directly shows the Dynamic Dashboard
/// Authentication is handled at login, so no need to check again
class InterestedDashboardWrapper extends StatelessWidget {
  const InterestedDashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly show the Dynamic Dashboard
    // User is already authenticated via Phase 1 login
    // Phase 2 auto-login happens in background at login time
    return const DynamicDashboardScreen();
  }
}
