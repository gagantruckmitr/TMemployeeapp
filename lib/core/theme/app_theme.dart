import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Brand Colors - Blue & Purple Theme
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color accentBlue = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color darkBlue = Color(0xFF1E1B4B);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0F172A);
  static const Color gray = Color(0xFF64748B);
  static const Color lightBlue = Color(0xFFDDD6FE);

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x20FFFFFF),
      Color(0x10FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onboardingGradient = LinearGradient(
    colors: [darkBlue, primaryBlue, primaryPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0x15FFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: white,
      );

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: black,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: black,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: black,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: gray,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: gray,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        color: gray,
      );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: black,
      );

  // Additional colors for better compatibility
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  
  // Primary color getter for backward compatibility
  static Color get primaryColor => primaryBlue;
  
  // Additional color getters for backward compatibility
  static Color get accentColor => accentPurple;
  static Color get textPrimary => black;
  static Color get textSecondary => gray;

  // Theme Data
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: white,
            elevation: 8,
            shadowColor: primaryBlue.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: white.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentPurple, width: 2),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: black,
          ),
        ),
      );

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Modern Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.08),
          blurRadius: 25,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
        BoxShadow(
          color: primaryPurple.withValues(alpha: 0.05),
          blurRadius: 50,
          offset: const Offset(0, 20),
          spreadRadius: -10,
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: black.withValues(alpha: 0.1),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
      ];
}