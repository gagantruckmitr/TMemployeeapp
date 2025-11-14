import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Color getters for backward compatibility
  static const Color primaryBlue = AppColors.primaryBlue;
  static const Color accentOrange = AppColors.accent;
  static const Color accentPurple = AppColors.accent;
  static const Color accentBlue = AppColors.accentBlue;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color gray = AppColors.softGray;
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color primaryColor = AppColors.primary;
  static const Color accentColor = AppColors.accent;
  static const Color textPrimary = AppColors.darkGray;
  static const Color textSecondary = AppColors.softGray;
  static const Color primaryPurple = AppColors.primary;
  
  // Gradient getters
  static LinearGradient get primaryGradient => AppColors.primaryGradient;
  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Colors.white, AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shadow getters
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Border radius getters
  static const double radiusMedium = 12.0;
  
  // Text style getters for backward compatibility
  static TextStyle get headingLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGray,
  );
  
  static TextStyle get headingMedium => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
  );
  
  static TextStyle get headlineSmall => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
  );
  
  static TextStyle get titleMedium => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    color: AppColors.darkGray,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    color: AppColors.softGray,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    color: AppColors.softGray,
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
