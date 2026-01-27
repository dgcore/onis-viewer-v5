/// Custom exception class for ONIS Viewer with error code and message
///
/// Usage examples:
/// ```dart
/// import 'package:onis_viewer/core/onis_exception.dart';
/// import 'package:onis_viewer/core/error_codes.dart';
///
/// // Basic usage with error code and message
/// throw OnisException(
///   OnisErrorCodes.notFound,
///   'User not found',
/// );
///
/// // With original error
/// try {
///   // some operation
/// } catch (e) {
///   throw OnisException(
///     OnisErrorCodes.internal,
///     'Failed to process request',
///     originalError: e,
///   );
/// }
///
/// // From server response
/// final response = {'code': 500, 'message': 'Invalid user'};
/// throw OnisException.fromResponse(response);
///
/// // Check error type
/// if (exception.isNetworkError) {
///   // Handle network error
/// }
/// ```
class OnisException implements Exception {
  /// Error code (e.g., EOS_* constants from the server)
  final int code;

  /// Human-readable error message
  final String message;

  /// Optional original error that caused this exception
  final dynamic originalError;

  /// Optional additional context data
  final Map<String, dynamic>? context;

  /// Creates an OnisException with an error code and message
  const OnisException(
    this.code,
    this.message, {
    this.originalError,
    this.context,
  });

  /// Creates an OnisException from a server error response
  /// Assumes the response has 'code' and 'message' fields
  factory OnisException.fromResponse(Map<String, dynamic> response) {
    final code = response['code'] as int? ?? 0;
    final message = response['message'] as String? ?? 'Unknown error';
    return OnisException(code, message, context: response);
  }

  /// Creates an OnisException from another exception
  factory OnisException.fromError(dynamic error, [int? code]) {
    if (error is OnisException) {
      return error;
    }
    return OnisException(
      code ?? 0,
      error.toString(),
      originalError: error,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('OnisException(code: $code, message: $message');
    if (originalError != null) {
      buffer.write(', originalError: $originalError');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write(', context: $context');
    }
    buffer.write(')');
    return buffer.toString();
  }

  /// Returns a user-friendly error message
  String get userMessage => message;

  /// Returns true if this is a specific error code
  bool isCode(int errorCode) => code == errorCode;

  /// Returns true if this is a network-related error
  bool get isNetworkError => code >= 17 && code <= 25; // EOS_NETWORK_* range

  /// Returns true if this is a database-related error
  bool get isDatabaseError => code >= 50 && code <= 58; // EOS_DB_* range

  /// Returns true if this is a file-related error
  bool get isFileError => code >= 524 && code <= 539; // EOS_FILE_* range

  /// Returns true if this is an authentication/authorization error
  bool get isAuthError =>
      code == 500 || code == 502 || code == 505 || code == 506 || code == 508;
}
