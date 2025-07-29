import 'dart:ffi';
import 'dart:io';

typedef TestConnectionNative = Int32 Function();
typedef TestConnectionDart = int Function();

class OnisFFI {
  static final DynamicLibrary _lib = _loadLibrary();

  static DynamicLibrary _loadLibrary() {
    if (Platform.isMacOS) {
      return DynamicLibrary.open('libonis_core.dylib');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('libonis_core.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libonis_core.so');
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static final TestConnectionDart _testConnection =
      _lib.lookupFunction<TestConnectionNative, TestConnectionDart>(
          'test_connection');

  Future<String> testConnection() async {
    try {
      final result = _testConnection();
      return result == 0 ? 'Connected successfully' : 'Connection failed';
    } catch (e) {
      return 'FFI Error: $e';
    }
  }
}
