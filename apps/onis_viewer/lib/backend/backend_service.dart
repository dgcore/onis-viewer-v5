import 'backend_native.dart';

/// High-level backend API used by viewer/business layers.
class OnisBackendService {
  OnisBackendService({OnisBackendNative? native})
      : _native = native ?? OnisBackendNative.create();

  final OnisBackendNative _native;

  int get backendVersion => _native.version();
  int get backendInstanceId => _native.instanceId();

  /// Smoke-test style call to validate Dart <-> native plumbing.
  int ping(int value) => _native.ping(value);

  void dispose() => _native.close();
}
