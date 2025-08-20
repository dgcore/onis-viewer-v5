import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../api/request/async_request.dart';

/// Site-specific HTTP implementation of the AsyncRequest interface
class SiteAsyncRequest implements AsyncRequest {
  /// The base URL for the HTTP requests
  final String baseUrl;

  /// HTTP client for making requests
  final http.Client _client;

  /// Current request in progress (if any)
  http.Request? _currentRequest;

  /// Stream controller for request cancellation
  StreamController<bool>? _cancellationController;

  /// Constructor
  ///
  /// [baseUrl] - The base URL for the HTTP requests
  SiteAsyncRequest({required this.baseUrl}) : _client = http.Client();

  @override
  Future<void> send(RequestType type, [Map<String, dynamic>? data]) async {
    // Cancel any existing request
    await cancel();

    // Create cancellation controller for this request
    _cancellationController = StreamController<bool>();

    try {
      // Build the request URL based on the request type
      final url = _buildUrl(type);

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
        return;
      }

      // Handle the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success - you might want to handle the response data here
        final responseBody = await response.stream.bytesToString();
        print('Request successful: ${response.statusCode} - $responseBody');
      } else {
        // Error
        throw HttpRequestException(
          'HTTP request failed with status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is HttpRequestException) {
        rethrow;
      }
      throw HttpRequestException('HTTP request failed: $e', 0);
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
}

/// Exception thrown when HTTP requests fail
class HttpRequestException implements Exception {
  final String message;
  final int statusCode;

  HttpRequestException(this.message, this.statusCode);

  @override
  String toString() => 'HttpRequestException: $message (Status: $statusCode)';
}
