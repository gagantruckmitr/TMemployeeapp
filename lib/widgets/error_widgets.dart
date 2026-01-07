import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/exceptions/app_exceptions.dart';

/// Premium Error Bottom Sheet - Similar to Amazon/Flipkart error screens
class ErrorBottomSheet extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final String? customTitle;
  final String? customMessage;

  const ErrorBottomSheet({
    super.key,
    required this.exception,
    this.onRetry,
    this.onClose,
    this.customTitle,
    this.customMessage,
  });

  /// Show the error bottom sheet
  static Future<void> show(
    BuildContext context, {
    required AppException exception,
    VoidCallback? onRetry,
    VoidCallback? onClose,
    String? customTitle,
    String? customMessage,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => ErrorBottomSheet(
        exception: exception,
        onRetry: onRetry,
        onClose: onClose,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Error Icon with animation
              _buildErrorIcon(),
              const SizedBox(height: 20),

              // Title
              Text(
                customTitle ?? _getTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                customMessage ?? exception.userMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  if (onClose != null || !exception.isRetryable)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onClose?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A2E),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if ((onClose != null || !exception.isRetryable) &&
                      exception.isRetryable &&
                      onRetry != null)
                    const SizedBox(width: 16),
                  if (exception.isRetryable && onRetry != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRetry?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getButtonColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getRetryIcon(), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _getRetryButtonText(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        shape: BoxShape.circle,
      ),
      child: Icon(_getIcon(), size: 40, color: _getIconColor()),
    );
  }

  IconData _getIcon() {
    switch (exception.type) {
      case AppExceptionType.network:
        return Icons.wifi_off_rounded;
      case AppExceptionType.server:
        return Icons.cloud_off_rounded;
      case AppExceptionType.auth:
        return Icons.lock_outline_rounded;
      case AppExceptionType.notFound:
        return Icons.search_off_rounded;
      case AppExceptionType.validation:
        return Icons.error_outline_rounded;
      case AppExceptionType.permission:
        return Icons.block_rounded;
      case AppExceptionType.timeout:
        return Icons.timer_off_rounded;
      case AppExceptionType.maintenance:
        return Icons.build_rounded;
      case AppExceptionType.unknown:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getIconColor() {
    switch (exception.type) {
      case AppExceptionType.network:
        return const Color(0xFFFF6B6B);
      case AppExceptionType.server:
        return const Color(0xFFFF8C42);
      case AppExceptionType.auth:
        return const Color(0xFF6C5CE7);
      case AppExceptionType.notFound:
        return const Color(0xFF74B9FF);
      case AppExceptionType.validation:
        return const Color(0xFFFFBE76);
      case AppExceptionType.permission:
        return const Color(0xFFE84393);
      case AppExceptionType.timeout:
        return const Color(0xFFFD79A8);
      case AppExceptionType.maintenance:
        return const Color(0xFF00CEC9);
      case AppExceptionType.unknown:
        return const Color(0xFFFF7675);
    }
  }

  Color _getIconBackgroundColor() {
    return _getIconColor().withOpacity(0.12);
  }

  Color _getButtonColor() {
    switch (exception.type) {
      case AppExceptionType.network:
        return const Color(0xFF667EEA);
      case AppExceptionType.server:
        return const Color(0xFFFF8C42);
      case AppExceptionType.auth:
        return const Color(0xFF6C5CE7);
      case AppExceptionType.timeout:
        return const Color(0xFF667EEA);
      case AppExceptionType.maintenance:
        return const Color(0xFF00CEC9);
      default:
        return const Color(0xFF667EEA);
    }
  }

  String _getTitle() {
    switch (exception.type) {
      case AppExceptionType.network:
        return 'No Internet Connection';
      case AppExceptionType.server:
        return 'Oops! Something Went Wrong';
      case AppExceptionType.auth:
        return 'Session Expired';
      case AppExceptionType.notFound:
        return 'Not Found';
      case AppExceptionType.validation:
        return 'Invalid Input';
      case AppExceptionType.permission:
        return 'Access Denied';
      case AppExceptionType.timeout:
        return 'Connection Timeout';
      case AppExceptionType.maintenance:
        return 'Under Maintenance';
      case AppExceptionType.unknown:
        return 'Something Went Wrong';
    }
  }

  IconData _getRetryIcon() {
    switch (exception.type) {
      case AppExceptionType.auth:
        return Icons.login_rounded;
      default:
        return Icons.refresh_rounded;
    }
  }

  String _getRetryButtonText() {
    switch (exception.type) {
      case AppExceptionType.auth:
        return 'Login Again';
      case AppExceptionType.network:
        return 'Try Again';
      default:
        return 'Retry';
    }
  }
}

/// Inline Error Widget - For use within screens
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;
  final AppExceptionType? type;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
    this.type,
  });

  factory InlineErrorWidget.fromException(
    AppException exception, {
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    return InlineErrorWidget(
      message: exception.userMessage,
      onRetry: exception.isRetryable ? onRetry : null,
      compact: compact,
      type: exception.type,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactError();
    }
    return _buildFullError();
  }

  Widget _buildCompactError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0E0)),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: const Color(0xFFFF6B6B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFD63031), fontSize: 14),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullError() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), size: 40, color: _getIconColor()),
          ),
          const SizedBox(height: 24),
          Text(
            _getTitle(),
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
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
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
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case AppExceptionType.network:
        return Icons.wifi_off_rounded;
      case AppExceptionType.server:
        return Icons.cloud_off_rounded;
      case AppExceptionType.auth:
        return Icons.lock_outline_rounded;
      case AppExceptionType.notFound:
        return Icons.search_off_rounded;
      case AppExceptionType.timeout:
        return Icons.timer_off_rounded;
      case AppExceptionType.maintenance:
        return Icons.build_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case AppExceptionType.network:
        return const Color(0xFFFF6B6B);
      case AppExceptionType.server:
        return const Color(0xFFFF8C42);
      case AppExceptionType.timeout:
        return const Color(0xFFFD79A8);
      default:
        return const Color(0xFFFF7675);
    }
  }

  Color _getIconBackgroundColor() {
    return _getIconColor().withOpacity(0.12);
  }

  String _getTitle() {
    switch (type) {
      case AppExceptionType.network:
        return 'No Internet Connection';
      case AppExceptionType.server:
        return 'Server Error';
      case AppExceptionType.timeout:
        return 'Connection Timeout';
      default:
        return 'Something Went Wrong';
    }
  }
}

/// Premium Snackbar for quick error notifications
class PremiumSnackbar {
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF39C12),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3498DB),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Full Screen Error Widget - For critical errors
class FullScreenErrorWidget extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final String? customTitle;
  final String? customMessage;

  const FullScreenErrorWidget({
    super.key,
    required this.exception,
    this.onRetry,
    this.onGoBack,
    this.customTitle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated illustration
              _buildIllustration(),
              const SizedBox(height: 40),

              // Title
              Text(
                customTitle ?? _getTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                customMessage ?? exception.userMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Action buttons
              if (exception.isRetryable && onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          exception.type == AppExceptionType.auth
                              ? Icons.login_rounded
                              : Icons.refresh_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          exception.type == AppExceptionType.auth
                              ? 'Login Again'
                              : 'Try Again',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (onGoBack != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onGoBack,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getIconColor().withOpacity(0.15),
            _getIconColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _getIconColor().withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(), size: 50, color: _getIconColor()),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (exception.type) {
      case AppExceptionType.network:
        return Icons.wifi_off_rounded;
      case AppExceptionType.server:
        return Icons.cloud_off_rounded;
      case AppExceptionType.auth:
        return Icons.lock_outline_rounded;
      case AppExceptionType.notFound:
        return Icons.search_off_rounded;
      case AppExceptionType.validation:
        return Icons.error_outline_rounded;
      case AppExceptionType.permission:
        return Icons.block_rounded;
      case AppExceptionType.timeout:
        return Icons.timer_off_rounded;
      case AppExceptionType.maintenance:
        return Icons.build_rounded;
      case AppExceptionType.unknown:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getIconColor() {
    switch (exception.type) {
      case AppExceptionType.network:
        return const Color(0xFFFF6B6B);
      case AppExceptionType.server:
        return const Color(0xFFFF8C42);
      case AppExceptionType.auth:
        return const Color(0xFF6C5CE7);
      case AppExceptionType.notFound:
        return const Color(0xFF74B9FF);
      case AppExceptionType.validation:
        return const Color(0xFFFFBE76);
      case AppExceptionType.permission:
        return const Color(0xFFE84393);
      case AppExceptionType.timeout:
        return const Color(0xFFFD79A8);
      case AppExceptionType.maintenance:
        return const Color(0xFF00CEC9);
      case AppExceptionType.unknown:
        return const Color(0xFFFF7675);
    }
  }

  String _getTitle() {
    switch (exception.type) {
      case AppExceptionType.network:
        return 'No Internet Connection';
      case AppExceptionType.server:
        return 'Oops! Something Went Wrong';
      case AppExceptionType.auth:
        return 'Session Expired';
      case AppExceptionType.notFound:
        return 'Not Found';
      case AppExceptionType.validation:
        return 'Invalid Input';
      case AppExceptionType.permission:
        return 'Access Denied';
      case AppExceptionType.timeout:
        return 'Connection Timeout';
      case AppExceptionType.maintenance:
        return 'Under Maintenance';
      case AppExceptionType.unknown:
        return 'Something Went Wrong';
    }
  }
}
