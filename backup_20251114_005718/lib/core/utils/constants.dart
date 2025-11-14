class AppConstants {
  // App Info
  static const String appName = 'TruckMitr Employee';
  static const String companyName = 'TruckMitr';
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double paddingExtraLarge = 40.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Onboarding Content
  static const List<OnboardingContent> onboardingPages = [
    OnboardingContent(
      title: 'Welcome to TruckMitr',
      subtitle: 'Your smart logistics companion for efficient fleet management',
      lottieAsset: 'assets/lottie/truck_animation.json',
    ),
    OnboardingContent(
      title: 'Smart Calling Made Easy',
      subtitle: 'Connect with drivers and clients seamlessly with our intelligent calling system',
      lottieAsset: 'assets/lottie/call_animation.json',
    ),
    OnboardingContent(
      title: 'Track Your Performance',
      subtitle: 'Monitor your progress with real-time analytics and performance insights',
      lottieAsset: 'assets/lottie/analytics_animation.json',
    ),
  ];
  
  // Dummy KPI Data
  static const List<KPIData> kpiData = [
    KPIData(title: 'Calls Made', value: '127', icon: '📞', color: 0xFF4CAF50),
    KPIData(title: 'Connected', value: '89', icon: '✅', color: 0xFF2196F3),
    KPIData(title: 'Pending', value: '23', icon: '⏳', color: 0xFFFF9800),
    KPIData(title: 'Follow-ups', value: '15', icon: '🔄', color: 0xFF9C27B0),
  ];
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String lottieAsset;
  
  const OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.lottieAsset,
  });
}

class KPIData {
  final String title;
  final String value;
  final String icon;
  final int color;
  
  const KPIData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}