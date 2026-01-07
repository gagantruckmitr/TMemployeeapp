import 'package:flutter/material.dart';
import '../core/exceptions/app_exceptions.dart';
import 'error_handler.dart';
import 'error_widgets.dart';

/// A mixin that provides easy error handling for StatefulWidgets
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ErrorHandlingMixin<MyScreen> {
///   @override
///   Widget build(BuildContext context) {
///     return ...;
///   }
///
///   Future<void> loadData() async {
///     await safeApiCall(
///       () => MyApiService.fetchData(),
///       onSuccess: (data) => setState(() => _data = data),
///     );
///   }
/// }
/// ```
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AppException? _lastException;
  AppException? get lastException => _lastException;

  /// Execute an API call with automatic error handling
  Future<R?> safeApiCall<R>(
    Future<R> Function() apiCall, {
    void Function(R result)? onSuccess,
    void Function(AppException error)? onError,
    bool showLoadingState = true,
    bool showSnackbarOnError = true,
    bool showBottomSheetOnError = false,
  }) async {
    if (showLoadingState) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _lastException = null;
      });
    }

    try {
      final result = await apiCall();

      if (showLoadingState && mounted) {
        setState(() => _isLoading = false);
      }

      onSuccess?.call(result);
      return result;
    } catch (e) {
      final exception = ExceptionParser.parse(e);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = exception.userMessage;
          _lastException = exception;
        });

        if (showBottomSheetOnError) {
          ErrorHandler.showErrorSheet(
            context,
            exception,
            onRetry: () => safeApiCall(
              apiCall,
              onSuccess: onSuccess,
              onError: onError,
              showLoadingState: showLoadingState,
              showSnackbarOnError: showSnackbarOnError,
              showBottomSheetOnError: showBottomSheetOnError,
            ),
          );
        } else if (showSnackbarOnError) {
          ErrorHandler.showError(
            context,
            exception,
            onRetry: () => safeApiCall(
              apiCall,
              onSuccess: onSuccess,
              onError: onError,
              showLoadingState: showLoadingState,
              showSnackbarOnError: showSnackbarOnError,
              showBottomSheetOnError: showBottomSheetOnError,
            ),
          );
        }
      }

      onError?.call(exception);
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _lastException = null;
      });
    }
  }

  /// Get inline error widget if there's an error
  Widget? getInlineErrorWidget({VoidCallback? onRetry, bool compact = false}) {
    if (_lastException == null) return null;
    return InlineErrorWidget.fromException(
      _lastException!,
      onRetry: onRetry,
      compact: compact,
    );
  }

  /// Show error bottom sheet manually
  void showErrorSheet(dynamic error, {VoidCallback? onRetry}) {
    ErrorHandler.showErrorSheet(context, error, onRetry: onRetry);
  }

  /// Show error snackbar manually
  void showError(dynamic error, {VoidCallback? onRetry}) {
    ErrorHandler.showError(context, error, onRetry: onRetry);
  }

  /// Show success snackbar
  void showSuccess(String message) {
    ErrorHandler.showSuccess(context, message);
  }
}

/// A wrapper widget that handles loading, error, and empty states
class AsyncContentWrapper extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final AppException? exception;
  final bool isEmpty;
  final Widget child;
  final VoidCallback? onRetry;
  final String loadingMessage;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? customEmptyWidget;
  final Widget? customLoadingWidget;
  final bool showFullScreenError;

  const AsyncContentWrapper({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.exception,
    this.isEmpty = false,
    required this.child,
    this.onRetry,
    this.loadingMessage = 'Loading...',
    this.emptyTitle = 'No Data',
    this.emptyMessage = 'There\'s nothing to show here.',
    this.emptyIcon = Icons.inbox_rounded,
    this.customEmptyWidget,
    this.customLoadingWidget,
    this.showFullScreenError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return customLoadingWidget ?? LoadingStateWidget(message: loadingMessage);
    }

    // Error state
    if (errorMessage != null || exception != null) {
      if (showFullScreenError && exception != null) {
        return FullScreenErrorWidget(exception: exception!, onRetry: onRetry);
      }

      if (exception != null) {
        return Center(
          child: InlineErrorWidget.fromException(exception!, onRetry: onRetry),
        );
      }

      return Center(
        child: InlineErrorWidget(
          message: errorMessage ?? 'Something went wrong',
          onRetry: onRetry,
        ),
      );
    }

    // Empty state
    if (isEmpty) {
      return customEmptyWidget ??
          EmptyStateWidget(
            title: emptyTitle,
            message: emptyMessage,
            icon: emptyIcon,
            onAction: onRetry,
            actionLabel: onRetry != null ? 'Refresh' : null,
          );
    }

    // Content
    return child;
  }
}

/// Extension on Widget to easily wrap with error handling
extension ErrorHandlingExtension on Widget {
  /// Wrap this widget with async content wrapper
  Widget withAsyncState({
    required bool isLoading,
    String? errorMessage,
    AppException? exception,
    bool isEmpty = false,
    VoidCallback? onRetry,
    String loadingMessage = 'Loading...',
    String emptyTitle = 'No Data',
    String emptyMessage = 'There\'s nothing to show here.',
    IconData emptyIcon = Icons.inbox_rounded,
  }) {
    return AsyncContentWrapper(
      isLoading: isLoading,
      errorMessage: errorMessage,
      exception: exception,
      isEmpty: isEmpty,
      onRetry: onRetry,
      loadingMessage: loadingMessage,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      child: this,
    );
  }
}

/// Helper class for building FutureBuilder with proper error handling
class SafeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;
  final String loadingMessage;

  const SafeFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadingMessage = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              LoadingStateWidget(message: loadingMessage);
        }

        if (snapshot.hasError) {
          final exception = ExceptionParser.parse(snapshot.error);
          return errorBuilder?.call(context, snapshot.error!, () {
                // Force rebuild
                (context as Element).markNeedsBuild();
              }) ??
              InlineErrorWidget.fromException(exception);
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const EmptyStateWidget(
          title: 'No Data',
          message: 'There\'s nothing to show here.',
        );
      },
    );
  }
}
