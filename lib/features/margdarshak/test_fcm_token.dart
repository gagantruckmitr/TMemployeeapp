// Quick test script to get FCM token
// You can call this from anywhere in your app for testing

import 'package:flutter/foundation.dart';
import 'services/notification_service.dart';
import 'utils/fcm_token_helper.dart';

/// Quick function to test FCM token retrieval
/// Call this from initState() or any button press for testing
Future<void> testFCMToken() async {
  if (kDebugMode) {
    print('\n🔥 Testing FCM Token Retrieval...\n');
    
    // Method 1: Direct service call
    final token1 = await MargdarshakNotificationService.instance.getFCMToken();
    print('Method 1 - Direct service: ${token1 != null ? "✅ Success" : "❌ Failed"}');
    
    // Method 2: Using helper
    final token2 = await FCMTokenHelper.getTokenForTesting();
    print('Method 2 - Helper: ${token2 != null ? "✅ Success" : "❌ Failed"}');
    
    // Method 3: Copy to clipboard
    final token3 = await FCMTokenHelper.getTokenAndCopyToClipboard();
    print('Method 3 - Copy to clipboard: ${token3 != null ? "✅ Success" : "❌ Failed"}');
    
    print('\n🎯 Use any of the tokens above for notification testing!\n');
  }
}

/// Add this to any widget's build method for a quick test button
/// Example: ElevatedButton(onPressed: testFCMToken, child: Text('Test FCM'))