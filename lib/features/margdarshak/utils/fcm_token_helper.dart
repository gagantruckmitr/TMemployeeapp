import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class FCMTokenHelper {
  /// Get FCM token and print it to console for testing
  static Future<String?> getTokenForTesting() async {
    try {
      final token = await MargdarshakNotificationService.instance.getFCMToken();
      
      if (token != null && kDebugMode) {
        print('\n' + '=' * 50);
        print('FCM TOKEN FOR NOTIFICATION TESTING');
        print('=' * 50);
        print(token);
        print('=' * 50 + '\n');
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Get FCM token and copy to clipboard
  static Future<String?> getTokenAndCopyToClipboard() async {
    try {
      final token = await getTokenForTesting();
      
      if (token != null) {
        await Clipboard.setData(ClipboardData(text: token));
        if (kDebugMode) {
          print('FCM Token copied to clipboard!');
        }
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error copying FCM token to clipboard: $e');
      }
      return null;
    }
  }

  /// Show FCM token in a dialog (for testing purposes)
  static Future<void> showTokenDialog(BuildContext context) async {
    final token = await getTokenForTesting();
    
    if (token != null && context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('FCM Token'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Copy this token for notification testing:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    token,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: token));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copied to clipboard!')),
                  );
                },
                child: const Text('Copy & Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }
}