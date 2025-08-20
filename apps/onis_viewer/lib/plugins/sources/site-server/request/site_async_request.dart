import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../api/request/async_request.dart';

/// Site-specific HTTP implementation of the AsyncRequest interface
class SiteAsyncRequest implements AsyncRequest {
  /// The base URL for the HTTP requests
  final String baseUrl;

  /// The type of request
  @override
  final RequestType requestType;

  /// The JSON data for the request
  @override
  final Map<String, dynamic>? data;

  /// HTTP client for making requests
  final http.Client _client;

  /// Current request in progress (if any)
  http.Request? _currentRequest;

  /// Stream controller for request cancellation
  StreamController<bool>? _cancellationController;

  /// Constructor
  ///
  /// [baseUrl] - The base URL for the HTTP requests
  /// [requestType] - The type of request to make
  /// [data] - The JSON data for the request
  SiteAsyncRequest({
    required this.baseUrl,
    required this.requestType,
    this.data,
  }) : _client = http.Client();

  @override
  Future<AsyncResponse> send() async {
    // Cancel any existing request
    await cancel();

    // Create cancellation controller for this request
    _cancellationController = StreamController<bool>();

    try {
      // Build the request URL based on the request type
      final url = _buildUrl(requestType);

      // Create the HTTP request
      _currentRequest = http.Request('POST', Uri.parse(url));
      _currentRequest!.headers['Content-Type'] = 'application/json';

      // Add request data if provided
      if (data != null) {
        _currentRequest!.body = jsonEncode(data);
      }

      // Send the request
      final response = await _client.send(_currentRequest!);

      // Check if request was cancelled
      if (_cancellationController!.isClosed) {
        return _createCancelledResponse();
      }

      // Handle the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success - parse the response data
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody) as Map<String, dynamic>?;

        return _createSuccessResponse(response.statusCode, responseData);
      } else {
        // Error
        final responseBody = await response.stream.bytesToString();
        return _createErrorResponse(response.statusCode, responseBody);
      }
    } catch (e) {
      if (e is HttpRequestException) {
        return _createErrorResponse(e.statusCode, e.message);
      }
      return _createErrorResponse(0, 'HTTP request failed: $e');
    } finally {
      _currentRequest = null;
      await _cancellationController?.close();
      _cancellationController = null;
    }
  }

  @override
  Future<void> cancel() async {
    if (_currentRequest != null) {
      _currentRequest = null;
      _cancellationController?.add(true);
      await _cancellationController?.close();
      _cancellationController = null;
    }
  }

  /// Build the URL for the given request type
  String _buildUrl(RequestType type) {
    switch (type) {
      case RequestType.findStudies:
        return '$baseUrl/api/studies/find';
      case RequestType.import:
        return '$baseUrl/api/import';
      case RequestType.export:
        return '$baseUrl/api/export';
      case RequestType.login:
        return '$baseUrl/api/auth/login';
      case RequestType.logout:
        return '$baseUrl/api/auth/logout';
      case RequestType.getStudy:
        return '$baseUrl/api/studies';
      case RequestType.getSeries:
        return '$baseUrl/api/series';
      case RequestType.getImage:
        return '$baseUrl/api/images';
      case RequestType.searchSources:
        return '$baseUrl/api/sources/search';
      case RequestType.connect:
        return '$baseUrl/api/sources/connect';
      case RequestType.disconnect:
        return '$baseUrl/api/sources/disconnect';
      case RequestType.getUserInfo:
        return '$baseUrl/api/user/info';
      case RequestType.updateSettings:
        return '$baseUrl/api/user/settings';
    }
  }

  /// Dispose of resources
  void dispose() {
    cancel();
    _client.close();
  }

  /// Create a success response
  AsyncResponse _createSuccessResponse(
      int statusCode, Map<String, dynamic>? data) {
    return _SiteAsyncResponse(
      isSuccess: true,
      statusCode: statusCode,
      data: data,
      errorMessage: null,
      metadata: null,
    );
  }

  /// Create an error response
  AsyncResponse _createErrorResponse(int statusCode, String errorMessage) {
    return _SiteAsyncResponse(
      isSuccess: false,
      statusCode: statusCode,
      data: null,
      errorMessage: errorMessage,
      metadata: null,
    );
  }

  /// Create a cancelled response
  AsyncResponse _createCancelledResponse() {
    return _SiteAsyncResponse(
      isSuccess: false,
      statusCode: null,
      data: null,
      errorMessage: 'Request was cancelled',
      metadata: null,
    );
  }
}

/// Implementation of AsyncResponse for SiteAsyncRequest
class _SiteAsyncResponse implements AsyncResponse {
  @override
  final bool isSuccess;

  @override
  final int? statusCode;

  @override
  final Map<String, dynamic>? data;

  @override
  final String? errorMessage;

  @override
  final Map<String, dynamic>? metadata;

  _SiteAsyncResponse({
    required this.isSuccess,
    required this.statusCode,
    required this.data,
    required this.errorMessage,
    required this.metadata,
  });
}

/// Exception thrown when HTTP requests fail
class HttpRequestException implements Exception {
  final String message;
  final int statusCode;

  HttpRequestException(this.message, this.statusCode);

  @override
  String toString() => 'HttpRequestException: $message (Status: $statusCode)';
}
