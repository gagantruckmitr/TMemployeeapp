/// App Exception Classes for Professional Error Handling
/// Categorizes errors like Amazon/Flipkart for user-friendly display

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? technicalDetails;
  final String userMessage;
  final AppExceptionType type;
  final bool isRetryable;

  const AppException({
    required this.message,
    required this.userMessage,
    required this.type,
    this.technicalDetails,
    this.isRetryable = true,
  });

  @override
  String toString() => message;
}

/// Types of exceptions for different UI treatments
enum AppExceptionType {
  network,
  server,
  auth,
  notFound,
  validation,
  permission,
  timeout,
  maintenance,
  unknown,
}

/// Network connectivity exception
class NetworkException extends AppException {
  const NetworkException({String? technicalDetails})
    : super(
        message: 'No internet connection',
        userMessage: 'Please check your internet connection and try again.',
        type: AppExceptionType.network,
        technicalDetails: technicalDetails,
        isRetryable: true,
      );
}

/// Server error exception (500, 502, 503, etc.)
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({this.statusCode, String? technicalDetails})
    : super(
        message: 'Server error',
        userMessage:
            'We\'re experiencing technical difficulties. Please try again in a few moments.',
        type: AppExceptionType.server,
        technicalDetails: technicalDetails,
        isRetryable: true,
      );
}

/// Authentication expired or invalid
class AuthException extends AppException {
  const AuthException({String? technicalDetails})
    : super(
        message: 'Authentication error',
        userMessage: 'Your session has expired. Please login again.',
        type: AppExceptionType.auth,
        technicalDetails: technicalDetails,
        isRetryable: false,
      );
}

/// Resource not found (404)
class NotFoundException extends AppException {
  const NotFoundException({String? technicalDetails, String? customMessage})
    : super(
        message: 'Not found',
        userMessage:
            customMessage ?? 'The requested information is not available.',
        type: AppExceptionType.notFound,
        technicalDetails: technicalDetails,
        isRetryable: false,
      );
}

/// Validation error (400, 422)
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    String? technicalDetails,
    this.errors,
    String? customMessage,
  }) : super(
         message: 'Validation error',
         userMessage: customMessage ?? 'Please check your input and try again.',
         type: AppExceptionType.validation,
         technicalDetails: technicalDetails,
         isRetryable: false,
       );
}

/// Permission denied (403)
class PermissionException extends AppException {
  const PermissionException({String? technicalDetails})
    : super(
        message: 'Permission denied',
        userMessage: 'You don\'t have permission to access this feature.',
        type: AppExceptionType.permission,
        technicalDetails: technicalDetails,
        isRetryable: false,
      );
}

/// Request timeout
class TimeoutException extends AppException {
  const TimeoutException({String? technicalDetails})
    : super(
        message: 'Request timeout',
        userMessage: 'The connection is taking too long. Please try again.',
        type: AppExceptionType.timeout,
        technicalDetails: technicalDetails,
        isRetryable: true,
      );
}

/// Server maintenance
class MaintenanceException extends AppException {
  final DateTime? expectedEndTime;

  const MaintenanceException({String? technicalDetails, this.expectedEndTime})
    : super(
        message: 'Server maintenance',
        userMessage:
            'We\'re currently performing maintenance. Please try again shortly.',
        type: AppExceptionType.maintenance,
        technicalDetails: technicalDetails,
        isRetryable: true,
      );
}

/// Unknown/Generic exception
class UnknownException extends AppException {
  const UnknownException({String? technicalDetails})
    : super(
        message: 'Unknown error',
        userMessage: 'Something went wrong. Please try again.',
        type: AppExceptionType.unknown,
        technicalDetails: technicalDetails,
        isRetryable: true,
      );
}

/// Exception parser to convert raw errors to AppException
class ExceptionParser {
  /// Parse any error into an AppException
  static AppException parse(dynamic error) {
    if (error is AppException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (_isNetworkError(errorString)) {
      return NetworkException(technicalDetails: error.toString());
    }

    // Timeout errors
    if (_isTimeoutError(errorString)) {
      return TimeoutException(technicalDetails: error.toString());
    }

    // Authentication errors
    if (_isAuthError(errorString)) {
      return AuthException(technicalDetails: error.toString());
    }

    // Permission errors
    if (_isPermissionError(errorString)) {
      return PermissionException(technicalDetails: error.toString());
    }

    // Not found errors
    if (_isNotFoundError(errorString)) {
      return NotFoundException(technicalDetails: error.toString());
    }

    // Server errors
    if (_isServerError(errorString)) {
      return ServerException(technicalDetails: error.toString());
    }

    // Validation errors
    if (_isValidationError(errorString)) {
      return ValidationException(technicalDetails: error.toString());
    }

    // Maintenance
    if (_isMaintenanceError(errorString)) {
      return MaintenanceException(technicalDetails: error.toString());
    }

    // Default to unknown
    return UnknownException(technicalDetails: error.toString());
  }

  static bool _isNetworkError(String error) {
    return error.contains('socketexception') ||
        error.contains('failed host lookup') ||
        error.contains('network is unreachable') ||
        error.contains('no address associated') ||
        error.contains('os error: no address') ||
        error.contains('clientexception') ||
        error.contains('connection refused') ||
        error.contains('connection closed') ||
        error.contains('connection reset') ||
        error.contains('no internet') ||
        error.contains('handshake') ||
        error.contains('unable to connect');
  }

  static bool _isTimeoutError(String error) {
    return error.contains('timeout') ||
        error.contains('timed out') ||
        error.contains('time out');
  }

  static bool _isAuthError(String error) {
    return error.contains('unauthorized') ||
        error.contains('401') ||
        error.contains('authentication') ||
        error.contains('token expired') ||
        error.contains('invalid token') ||
        error.contains('session expired') ||
        error.contains('login again');
  }

  static bool _isPermissionError(String error) {
    return error.contains('forbidden') ||
        error.contains('403') ||
        error.contains('permission denied') ||
        error.contains('access denied');
  }

  static bool _isNotFoundError(String error) {
    return error.contains('not found') ||
        error.contains('404') ||
        error.contains('does not exist');
  }

  static bool _isServerError(String error) {
    return error.contains('500') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('internal server') ||
        error.contains('server error') ||
        error.contains('database') ||
        error.contains('sql') ||
        error.contains('query error');
  }

  static bool _isValidationError(String error) {
    return error.contains('validation') ||
        error.contains('invalid') ||
        error.contains('400') ||
        error.contains('422') ||
        error.contains('bad request');
  }

  static bool _isMaintenanceError(String error) {
    return error.contains('maintenance') ||
        error.contains('under construction') ||
        error.contains('temporarily unavailable');
  }
}
