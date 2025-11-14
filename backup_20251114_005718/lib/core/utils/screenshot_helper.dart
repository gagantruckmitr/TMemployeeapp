import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenshotHelper {
  static final ScreenshotController _screenshotController = ScreenshotController();
  
  static ScreenshotController get controller => _screenshotController;

  /// Request storage permission for saving screenshots
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  /// Capture screenshot of a widget
  static Future<Uint8List?> captureWidget(Widget widget) async {
    try {
      return await _screenshotController.captureFromWidget(
        widget,
        delay: const Duration(milliseconds: 100),
      );
    } catch (e) {
      debugPrint('Error capturing widget screenshot: $e');
      return null;
    }
  }

  /// Capture screenshot and save to gallery/documents
  static Future<String?> captureAndSave({
    String? fileName,
    bool saveToGallery = true,
  }) async {
    try {
      // Request permission first
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Capture screenshot
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = fileName ?? 'screenshot_$timestamp.png';

      // Get save directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Create Pictures directory if it doesn't exist
          final picturesDir = Directory('${directory.path}/Pictures');
          if (!await picturesDir.exists()) {
            await picturesDir.create(recursive: true);
          }
          directory = picturesDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Save file
      final file = File('${directory.path}/$finalFileName');
      await file.writeAsBytes(imageBytes);

      return file.path;
    } catch (e) {
      debugPrint('Error saving screenshot: $e');
      return null;
    }
  }

  /// Show screenshot preview dialog
  static void showScreenshotPreview(
    BuildContext context,
    Uint8List imageBytes, {
    VoidCallback? onSave,
    VoidCallback? onShare,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Screenshot Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 400,
                maxWidth: 300,
              ),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (onSave != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSave();
                      },
                      child: const Text('Save'),
                    ),
                  if (onShare != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onShare();
                      },
                      child: const Text('Share'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick screenshot with feedback
  static Future<void> quickScreenshot(BuildContext context) async {
    if (!context.mounted) return;
    
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taking screenshot...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Capture and save
      final filePath = await captureAndSave();
      
      if (!context.mounted) return;
      
      if (filePath != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot saved to: ${filePath.split('/').last}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // You could implement opening the file here
                debugPrint('Screenshot saved at: $filePath');
              },
            ),
          ),
        );
      } else {
        throw Exception('Failed to save screenshot');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}