"""
Centralized error handling for API and application errors
"""

import 'package:flutter/material.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
  }) : super(message: message, code: code ?? 'NETWORK_ERROR');
}

class ApiException extends AppException {
  final int statusCode;
  final Map<String, dynamic>? details;

  ApiException({
    required String message,
    required this.statusCode,
    String? code,
    this.details,
  }) : super(message: message, code: code ?? 'API_ERROR_$statusCode');
}

class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  ValidationException({
    required String message,
    this.fieldErrors,
  }) : super(message: message, code: 'VALIDATION_ERROR');
}

class TimeoutException extends AppException {
  TimeoutException({String message = 'Request timeout. Please try again.'})
      : super(message: message, code: 'TIMEOUT_ERROR');
}

class UnauthorizedException extends AppException {
  UnauthorizedException({String message = 'Unauthorized. Please login again.'})
      : super(message: message, code: 'UNAUTHORIZED');
}

class ForbiddenException extends AppException {
  ForbiddenException({String message = 'You do not have permission to access this resource.'})
      : super(message: message, code: 'FORBIDDEN');
}

class NotFoundException extends AppException {
  NotFoundException({String message = 'Resource not found.'})
      : super(message: message, code: 'NOT_FOUND');
}

class ServerException extends AppException {
  ServerException({String message = 'Server error. Please try again later.'})
      : super(message: message, code: 'SERVER_ERROR');
}

class ErrorHandler {
  /// Handle exceptions and return user-friendly error message
  static String getErrorMessage(dynamic exception) {
    if (exception is AppException) {
      return exception.message;
    } else if (exception is TimeoutException) {
      return 'Connection timeout. Please check your internet and try again.';
    } else if (exception is UnauthorizedException) {
      return 'Your session has expired. Please login again.';
    } else if (exception is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (exception is ApiException) {
      return exception.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get error code from exception
  static String? getErrorCode(dynamic exception) {
    if (exception is AppException) {
      return exception.code;
    }
    return null;
  }

  /// Check if exception is unauthorized
  static bool isUnauthorized(dynamic exception) {
    return exception is UnauthorizedException || 
           (exception is ApiException && exception.statusCode == 401);
  }

  /// Check if exception is network-related
  static bool isNetworkError(dynamic exception) {
    return exception is NetworkException || exception is TimeoutException;
  }

  /// Log error for debugging
  static void logError(dynamic exception, StackTrace? stackTrace) {
    print('[ERROR] ${exception.toString()}');
    if (stackTrace != null) {
      print('[STACK_TRACE] $stackTrace');
    }
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    dynamic exception, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = getErrorMessage(exception);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic exception, {
    String title = 'Error',
  }) {
    final message = getErrorMessage(exception);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Parse API error response
  static String parseApiError(Map<String, dynamic> response) {
    if (response.containsKey('message')) {
      return response['message'] ?? 'An error occurred';
    }
    if (response.containsKey('error')) {
      return response['error'] ?? 'An error occurred';
    }
    return 'An unexpected error occurred';
  }
}
