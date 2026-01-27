import 'package:flutter/material.dart';

class AppColors {
  // New Color Palette - Professional Blue Theme
  static const Color primaryBlue = Color(0xFF1565C0); // Deep Blue #1565C0
  static const Color lightBlue = Color(0xFF42A5F5); // Light Blue #42A5F5
  static const Color veryLightBlue = Color(0xFFE3F2FD); // Very light blue #E3F2FD
  static const Color accentBlue = Color(0xFF1976D2); // Accent Blue #1976D2
  
  // Primary colors
  static const Color primary = primaryBlue;
  static const Color accent = accentBlue;
  static const Color background = Color(0xFFF5F7FA);
  static const Color secondary = lightBlue;
  
  // Legacy support (keeping old names for backward compatibility)
  static const Color lightBeige = veryLightBlue;
  static const Color mediumBeige = lightBlue;
  static const Color darkBeige = primaryBlue;
  static const Color rosyBeige = primaryBlue;
  static const Color primaryPink = primaryBlue; // Map pink to blue
  static const Color lightPink = lightBlue;
  static const Color veryLightPink = veryLightBlue;
  static const Color peachAccent = accentBlue;
  
  // Legacy support
  static const Color darkGray = Color(0xFF2C3E50);
  static const Color softGray = Color(0xFF95A5A6);
  static const Color offWhite = veryLightBlue;
  static const Color slateBlue = primaryBlue;
  static const Color brown = primaryBlue;
  static const Color orange = accentBlue;
  static const Color cream = veryLightBlue;
  static const Color darkBrown = Color(0xFF0D47A1);
  static const Color lightTeal = lightBlue;
  static const Color mediumTeal = primaryBlue;
  static const Color darkTeal = Color(0xFF0D47A1);
  static const Color veryDarkTeal = Color(0xFF01579B);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
  static const Color online = Color(0xFF4CAF50);
  static const Color busy = Color(0xFFFF9800);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color onBreak = Color(0xFF2196F3);
  
  // Glassmorphism
  static Color get glassBackground => Colors.white.withValues(alpha: 0.7);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.2);
  
  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primary.withValues(alpha: 0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentGradient => LinearGradient(
    colors: [accent, accent.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE0E0E0),
      Color(0xFFF5F5F5),
      Color(0xFFE0E0E0),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
  );
  
  // Shadow colors
  static Color get shadowLight => Colors.black.withValues(alpha: 0.05);
  static Color get shadowMedium => Colors.black.withValues(alpha: 0.1);
  static Color get shadowDark => Colors.black.withValues(alpha: 0.2);
}
