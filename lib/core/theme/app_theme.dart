import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Color getters for backward compatibility with Phase 2
  static Color get primaryBlue => AppColors.primary;
  static Color get primaryColor => AppColors.primary;
  static Color get accentPurple => AppColors.accent;
  static Color get accentColor => AppColors.accent;
  static Color get accentOrange => const Color(0xFFFF6B35);
  static Color get accentBlue => const Color(0xFF4A90E2);
  static Color get primaryPurple => AppColors.accent;
  static Color get lightPurple => const Color(0xFFF3E8FF);
  static Color get darkGray => AppColors.darkGray;
  static Color get gray => AppColors.softGray;
  static Color get softGray => AppColors.softGray;
  static Color get lightGray => const Color(0xFFF5F5F5);
  static Color get white => Colors.white;
  static Color get black => Colors.black;
  static Color get success => const Color(0xFF10B981);
  static Color get error => const Color(0xFFEF4444);
  static Color get warning => const Color(0xFFF59E0B);
  static Color get textPrimary => AppColors.darkGray;
  static Color get textSecondary => AppColors.softGray;
  
  // Gradient getters
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Color(0xFFF8F9FD), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shadow getters
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Border radius getters
  static double get radiusSmall => 8.0;
  static double get radiusMedium => 12.0;
  static double get radiusLarge => 16.0;
  
  // Text style getters for backward compatibility
  static TextStyle get headingLarge => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGray,
  );
  
  static TextStyle get headingMedium => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
  );
  
  static TextStyle get titleMedium => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
  );
  
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    color: AppColors.darkGray,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    color: AppColors.softGray,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    color: AppColors.softGray,
  );
  
  static TextStyle get headlineSmall => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: Colors.red.shade400,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkGray),
        titleTextStyle: TextStyle(
          color: AppColors.darkGray,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGray,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGray,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGray,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.darkGray,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.softGray,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
      ),
    );
  }
}
