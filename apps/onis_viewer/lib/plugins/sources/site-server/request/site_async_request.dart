import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  /// Stream controller for request cancellation
  //StreamController<bool>? _cancellationController;

  /// Flag to track if cancellation was requested
  bool _isCancelled = false;

  /// Completer to track when the send operation completes
  Completer<void>? _sendCompleter;

  /// HTTP client for making requests
  final http.Client _client;

  /// Current HTTP request being processed
  http.Request? _currentRequest;

  /// Constructor
  ///
  /// [baseUrl] - The base URL for the HTTP requests
  /// [requestType] - The type of request to make
  /// [data] - The JSON data for the request
  SiteAsyncRequest({
    required this.baseUrl,
    required this.requestType,
    this.data,
  }) : _client = http.Client() {
    debugPrint('SiteAsyncRequest created with baseUrl: $baseUrl');
  }

  @override
  Future<AsyncResponse> send() async {
    debugPrint(
        'SiteAsyncRequest.send() started for request type: $requestType');

    // Cancel any existing request
    await cancel();

    // Create completer to track completion
    _sendCompleter = Completer<void>();

    // Reset cancellation flag
    _isCancelled = false;

    // Create cancellation controller for this request
    /*_cancellationController = StreamController<bool>();

    // Listen to cancellation events
    StreamSubscription<bool>? cancellationSubscription;
    cancellationSubscription =
        _cancellationController!.stream.listen((cancelled) {
      if (cancelled) {
        debugPrint('SiteAsyncRequest.send() - cancellation signal received');
        _isCancelled = true;
      }
    });*/

    try {
      debugPrint('SiteAsyncRequest.send() - building URL');
      // Build the request URL based on the request type
      final url = _buildUrl(requestType);

      debugPrint('SiteAsyncRequest.send() - creating HTTP request');
      // Create the HTTP request
      _currentRequest = http.Request('POST', Uri.parse(url));
      _currentRequest!.headers['Content-Type'] = 'application/json';

      // Add request data if provided
      if (data != null) {
        _currentRequest!.body = jsonEncode(data);
      }

      debugPrint('SiteAsyncRequest.send() - starting 10 second delay');
      //await Future.delayed(const Duration(seconds: 10));
      debugPrint('SiteAsyncRequest.send() - 10 second delay completed');

      // Check if cancelled during the delay
      /*if (_isCancelled) {
        debugPrint(
            'SiteAsyncRequest.send() - request was cancelled during delay');
        return _createCancelledResponse();
      }*/

      debugPrint(
          'SiteAsyncRequest.send() - sending HTTP request to: ${_currentRequest!.url}');
      debugPrint(
          'SiteAsyncRequest.send() - request headers: ${_currentRequest!.headers}');
      debugPrint(
          'SiteAsyncRequest.send() - request body: ${_currentRequest!.body}');
      // Send the request
      final response = await _client.send(_currentRequest!);

      // Check if request was cancelled
      if (_isCancelled) {
        debugPrint(
            'SiteAsyncRequest.send() - request was cancelled after HTTP send');
        return _createCancelledResponse();
      }

      // Handle the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success - parse the response data
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody) as Map<String, dynamic>?;

        debugPrint('SiteAsyncRequest.send() - returning success response');
        return _createSuccessResponse(response.statusCode, responseData);
      } else {
        // Error
        final responseBody = await response.stream.bytesToString();
        debugPrint('SiteAsyncRequest.send() - returning error response');
        return _createErrorResponse(response.statusCode, responseBody);
      }
    } catch (e) {
      debugPrint('SiteAsyncRequest.send() - caught exception: $e');
      if (e is HttpRequestException) {
        return _createErrorResponse(e.statusCode, e.message);
      }
      return _createErrorResponse(0, 'HTTP request failed: $e');
    } finally {
      debugPrint('SiteAsyncRequest.send() - finally block executing');

      // Cancel the cancellation subscription
      //await cancellationSubscription.cancel();

      _currentRequest = null;

      // Close the cancellation controller
      /*if (_cancellationController != null &&
          !_cancellationController!.isClosed) {
        _cancellationController!.close();
      }
      _cancellationController = null;*/

      // Complete the send operation
      if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
        _sendCompleter!.complete();
      }

      debugPrint('SiteAsyncRequest.send() - finally block completed');
    }
  }

  @override
  Future<void> cancel() async {
    debugPrint('SiteAsyncRequest.cancel() called');

    // Set cancellation flag
    _isCancelled = true;

    if (_currentRequest != null) {
      _currentRequest = null;

      // Add cancellation signal and close
      /*if (_cancellationController != null &&
          !_cancellationController!.isClosed) {
        _cancellationController!.add(true);
        await _cancellationController!.close();
        debugPrint('SiteAsyncRequest.cancel() - cancellation signal sent');
      }
      _cancellationController = null;*/

      // Wait for the send operation to complete
      if (_sendCompleter != null && !_sendCompleter!.isCompleted) {
        debugPrint(
            'SiteAsyncRequest.cancel() - waiting for send operation to complete');
        await _sendCompleter!.future;
        debugPrint('SiteAsyncRequest.cancel() - send operation completed');
      }
    }
  }

  /// Build the URL for the given request type
  String _buildUrl(RequestType type) {
    switch (type) {
      case RequestType.findStudies:
        return '$baseUrl/studies/find';
      case RequestType.import:
        return '$baseUrl/api/import';
      case RequestType.export:
        return '$baseUrl/api/export';
      case RequestType.login:
        return '$baseUrl/accounts/authenticate';
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
