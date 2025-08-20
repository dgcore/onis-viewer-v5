/// Enumeration of request types supported by the async request system
enum RequestType {
  /// Find studies in the database
  findStudies,

  /// Import data or studies
  import,

  /// Export data or studies
  export,

  /// User authentication/login
  login,

  /// User logout/disconnect
  logout,

  /// Get study details
  getStudy,

  /// Get series details
  getSeries,

  /// Get image data
  getImage,

  /// Search for sources
  searchSources,

  /// Connect to a source
  connect,

  /// Disconnect from a source
  disconnect,

  /// Get user information
  getUserInfo,

  /// Update user settings
  updateSettings,
}

/// Interface for asynchronous request responses
abstract class AsyncResponse {
  /// Whether the request was successful
  bool get isSuccess;

  /// Status code (if applicable)
  int? get statusCode;

  /// Response data as a JSON structure
  Map<String, dynamic>? get data;

  /// Error message if the request failed
  String? get errorMessage;

  /// Additional metadata about the response
  Map<String, dynamic>? get metadata;
}

/// Interface for asynchronous requests that can be sent and cancelled
abstract class AsyncRequest {
  /// Send the request with the provided JSON data
  ///
  /// [type] - The type of request to send
  /// [data] - The JSON structure containing the request data
  /// Returns a Future that completes with the response when the request is finished
  Future<AsyncResponse> send(RequestType type, [Map<String, dynamic>? data]);

  /// Cancel the current request if it's in progress
  ///
  /// Returns a Future that completes when the cancellation is finished
  Future<void> cancel();
}
