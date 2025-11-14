import 'package:flutter/material.dart';
import '../core/utils/screenshot_helper.dart';
import '../core/theme/app_theme.dart';

class ScreenshotButton extends StatelessWidget {
  final VoidCallback? onScreenshotTaken;
  final IconData icon;
  final String tooltip;
  final bool showLabel;

  const ScreenshotButton({
    super.key,
    this.onScreenshotTaken,
    this.icon = Icons.camera_alt,
    this.tooltip = 'Take Screenshot',
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return showLabel
        ? ElevatedButton.icon(
            onPressed: () => _takeScreenshot(context),
            icon: Icon(icon),
            label: const Text('Screenshot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
            ),
          )
        : FloatingActionButton(
            onPressed: () => _takeScreenshot(context),
            tooltip: tooltip,
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(icon, color: AppTheme.white),
          );
  }

  Future<void> _takeScreenshot(BuildContext context) async {
    await ScreenshotHelper.quickScreenshot(context);
    onScreenshotTaken?.call();
  }
}

class ScreenshotFab extends StatelessWidget {
  final VoidCallback? onScreenshotTaken;

  const ScreenshotFab({
    super.key,
    this.onScreenshotTaken,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        await ScreenshotHelper.quickScreenshot(context);
        onScreenshotTaken?.call();
      },
      tooltip: 'Take Screenshot',
      backgroundColor: AppTheme.primaryBlue,
      child: Icon(Icons.camera_alt, color: AppTheme.white),
    );
  }
}