import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  
  Responsive(this.context);
  
  // Screen dimensions
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
  
  // Screen type
  bool get isSmallScreen => width < 360;
  bool get isMediumScreen => width >= 360 && width < 600;
  bool get isLargeScreen => width >= 600;
  
  // Responsive values
  double wp(double percentage) => width * (percentage / 100);
  double hp(double percentage) => height * (percentage / 100);
  
  // Responsive padding
  double get paddingXS => wp(2);
  double get paddingS => wp(3);
  double get paddingM => wp(4);
  double get paddingL => wp(5);
  double get paddingXL => wp(6);
  
  // Responsive font sizes
  double get fontXS => wp(3);
  double get fontS => wp(3.5);
  double get fontM => wp(4);
  double get fontL => wp(4.5);
  double get fontXL => wp(5);
  double get fontXXL => wp(6);
  
  // Responsive icon sizes
  double get iconS => wp(5);
  double get iconM => wp(6);
  double get iconL => wp(8);
  double get iconXL => wp(10);
  
  // Responsive button sizes
  double get buttonHeight => hp(6);
  double get buttonHeightSmall => hp(5);
  double get buttonHeightLarge => hp(7);
  
  // Responsive card sizes
  double get cardPadding => wp(4);
  double get cardRadius => wp(3);
  
  // Get value based on screen size
  T valueWhen<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (width >= 1024 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }
}

// Extension for easy access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
