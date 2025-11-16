/// Utility functions for masking phone numbers for privacy
class PhoneMaskingUtils {
  /// Masks a phone number for display while maintaining privacy
  /// 
  /// Examples:
  /// - 9876543210 -> 98****3210
  /// - +919876543210 -> +91 98****3210
  /// - 1234567890 -> 12****7890
  /// 
  /// Shows first 2 and last 4 digits, masks the middle digits
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    
    // Remove all non-digit characters for processing
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If less than 6 digits, mask all but last 2
    if (digitsOnly.length <= 6) {
      if (digitsOnly.length <= 2) return phoneNumber;
      final lastTwo = digitsOnly.substring(digitsOnly.length - 2);
      return '${'*' * (digitsOnly.length - 2)}$lastTwo';
    }
    
    // Standard masking: show first 2 and last 4 digits
    final firstTwo = digitsOnly.substring(0, 2);
    final lastFour = digitsOnly.substring(digitsOnly.length - 4);
    final middleCount = digitsOnly.length - 6;
    
    // Check if original had country code prefix
    if (phoneNumber.startsWith('+')) {
      return '+$firstTwo ${'*' * middleCount}$lastFour';
    }
    
    return '$firstTwo${'*' * middleCount}$lastFour';
  }
  
  /// Alternative masking: shows only last 4 digits
  /// Example: 9876543210 -> ******3210
  static String maskPhoneNumberStrict(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length <= 4) return phoneNumber;
    
    final lastFour = digitsOnly.substring(digitsOnly.length - 4);
    final maskedCount = digitsOnly.length - 4;
    
    return '${'*' * maskedCount}$lastFour';
  }
  
  /// Checks if a phone number is already masked
  static bool isMasked(String phoneNumber) {
    return phoneNumber.contains('*');
  }
}
