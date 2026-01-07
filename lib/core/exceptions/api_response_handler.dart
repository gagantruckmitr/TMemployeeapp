import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_exceptions.dart';

/// API Response Handler - Converts HTTP responses to AppExceptions
/// Use this in all API service classes for consistent error handling
class ApiResponseHandler {
  /// Handle HTTP response and throw appropriate AppException if error
  static void handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        // Success - no action needed
        return;
      case 400:
        throw ValidationException(
          technicalDetails: 'HTTP 400: ${response.body}',
          customMessage:
              _extractMessage(response.body) ??
              'Invalid request. Please check your input.',
        );
      case 401:
        throw AuthException(technicalDetails: 'HTTP 401: ${response.body}');
      case 403:
        throw PermissionException(
          technicalDetails: 'HTTP 403: ${response.body}',
        );
      case 404:
        throw NotFoundException(
          technicalDetails: 'HTTP 404: ${response.body}',
          customMessage:
              _extractMessage(response.body) ??
              'The requested resource was not found.',
        );
      case 422:
        throw ValidationException(
          technicalDetails: 'HTTP 422: ${response.body}',
          customMessage:
              _extractMessage(response.body) ??
              'Invalid data. Please check your input.',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException(
          statusCode: response.statusCode,
          technicalDetails: 'HTTP ${response.statusCode}: ${response.body}',
        );
      default:
        if (response.statusCode >= 500) {
          throw ServerException(
            statusCode: response.statusCode,
            technicalDetails: 'HTTP ${response.statusCode}: ${response.body}',
          );
        }
        throw UnknownException(
          technicalDetails: 'HTTP ${response.statusCode}: ${response.body}',
        );
    }
  }

  /// Wrap an async API call with proper exception handling
  static Future<T> safeCall<T>(
    Future<T> Function() apiCall, {
    String? errorContext,
  }) async {
    try {
      return await apiCall();
    } on SocketException catch (e) {
      print(
        '❌ Network error${errorContext != null ? ' ($errorContext)' : ''}: $e',
      );
      throw NetworkException(technicalDetails: e.toString());
    } on TimeoutException catch (e) {
      print('❌ Timeout${errorContext != null ? ' ($errorContext)' : ''}: $e');
      throw TimeoutException(technicalDetails: e.toString());
    } on http.ClientException catch (e) {
      print(
        '❌ Client error${errorContext != null ? ' ($errorContext)' : ''}: $e',
      );
      throw NetworkException(technicalDetails: e.toString());
    } on AppException {
      rethrow;
    } catch (e) {
      print('❌ Error${errorContext != null ? ' ($errorContext)' : ''}: $e');
      throw ExceptionParser.parse(e);
    }
  }

  /// Extract error message from JSON response body
  static String? _extractMessage(String body) {
    try {
      final Map<String, dynamic> data = _parseJson(body);
      return data['message'] as String? ??
          data['error'] as String? ??
          data['errors']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Safe JSON parsing
  static Map<String, dynamic> _parseJson(String body) {
    try {
      final decoded = Uri.decodeComponent(body);
      return Map<String, dynamic>.from(
        (decoded.startsWith('{') ? decoded : body) as Map,
      );
    } catch (_) {
      return {};
    }
  }
}

/// Extension on http.Response for easier error handling
extension ResponseExtension on http.Response {
  /// Check if response is successful (2xx)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Throw appropriate AppException if response is not successful
  void throwIfError() {
    if (!isSuccess) {
      ApiResponseHandler.handleResponse(this);
    }
  }

  /// Get the response body as a Map, or throw an appropriate exception
  Map<String, dynamic> get jsonBody {
    throwIfError();
    try {
      return Map<String, dynamic>.from(
        Uri.decodeComponent(body).startsWith('{')
            ? json.decode(Uri.decodeComponent(body))
            : json.decode(body),
      );
    } catch (e) {
      throw UnknownException(
        technicalDetails: 'Failed to parse response: $body',
      );
    }
  }

  /// Get the response body as a List, or throw an appropriate exception
  List<dynamic> get jsonList {
    throwIfError();
    try {
      return List<dynamic>.from(json.decode(body));
    } catch (e) {
      throw UnknownException(
        technicalDetails: 'Failed to parse response: $body',
      );
    }
  }
}
