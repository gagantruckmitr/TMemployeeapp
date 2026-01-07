import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/exceptions/app_exceptions.dart';
import 'error_widgets.dart';

/// Professional Error Handler - Amazon/Flipkart Style
/// Never shows raw technical errors to users
class ErrorHandler {
  /// Show user-friendly error message as a premium snackbar
  /// Automatically converts technical errors to user-friendly messages
  static void showError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    final exception = ExceptionParser.parse(error);
    final message = customMessage ?? exception.userMessage;

    PremiumSnackbar.showError(
      context,
      message,
      onRetry: exception.isRetryable ? onRetry : null,
    );
  }

  /// Show error as a beautiful bottom sheet (for important errors)
  static Future<void> showErrorSheet(
    BuildContext context,
    dynamic error, {
    String? customTitle,
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) async {
    final exception = ExceptionParser.parse(error);

    await ErrorBottomSheet.show(
      context,
      exception: exception,
      customTitle: customTitle,
      customMessage: customMessage,
      onRetry: onRetry,
      onClose: onClose,
    );
  }

  /// Show success message with premium snackbar
  static void showSuccess(BuildContext context, String message) {
    PremiumSnackbar.showSuccess(context, message);
  }

  /// Show info message with premium snackbar
  static void showInfo(BuildContext context, String message) {
    PremiumSnackbar.showInfo(context, message);
  }

  /// Show warning message with premium snackbar
  static void showWarning(BuildContext context, String message) {
    PremiumSnackbar.showWarning(context, message);
  }

  /// Get an inline error widget for embedding in screens
  static Widget getInlineError(
    dynamic error, {
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    final exception = ExceptionParser.parse(error);
    return InlineErrorWidget.fromException(
      exception,
      onRetry: onRetry,
      compact: compact,
    );
  }

  /// Get a full screen error widget
  static Widget getFullScreenError(
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
    String? customTitle,
    String? customMessage,
  }) {
    final exception = ExceptionParser.parse(error);
    return FullScreenErrorWidget(
      exception: exception,
      onRetry: onRetry,
      onGoBack: onGoBack,
      customTitle: customTitle,
      customMessage: customMessage,
    );
  }

  /// Handle network errors specifically
  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    showErrorSheet(context, const NetworkException(), onRetry: onRetry);
  }

  /// Handle server errors specifically
  static void showServerError(BuildContext context, {VoidCallback? onRetry}) {
    showErrorSheet(context, const ServerException(), onRetry: onRetry);
  }

  /// Handle timeout errors specifically
  static void showTimeoutError(BuildContext context, {VoidCallback? onRetry}) {
    showError(context, const TimeoutException(), onRetry: onRetry);
  }

  /// Handle auth errors - typically requires re-login
  static void showAuthError(BuildContext context, {VoidCallback? onLogin}) {
    showErrorSheet(
      context,
      const AuthException(),
      onRetry: onLogin,
      customTitle: 'Session Expired',
      customMessage:
          'Your session has expired for security. Please login again to continue.',
    );
  }

  /// Convert technical errors to user-friendly messages (legacy support)
  static String getUserFriendlyMessage(dynamic error) {
    final exception = ExceptionParser.parse(error);
    return exception.userMessage;
  }

  /// Check if an error is retryable
  static bool isRetryable(dynamic error) {
    final exception = ExceptionParser.parse(error);
    return exception.isRetryable;
  }

  /// Get exception type for custom handling
  static AppExceptionType getErrorType(dynamic error) {
    final exception = ExceptionParser.parse(error);
    return exception.type;
  }
}

/// Error screen widget for full-page errors (legacy support + enhanced)
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final dynamic error;

  const ErrorScreen({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
    this.onGoBack,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    // If error is provided, use the new FullScreenErrorWidget
    if (error != null) {
      final exception = ExceptionParser.parse(error);
      return FullScreenErrorWidget(
        exception: exception,
        onRetry: onRetry,
        onGoBack: onGoBack,
      );
    }

    // Legacy behavior for backward compatibility
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern error illustration
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B6B).withOpacity(0.15),
                        const Color(0xFFFF6B6B).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 40,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Oops!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (onGoBack != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onGoBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state widget for when there's no data
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF667EEA)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget with shimmer effect
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
