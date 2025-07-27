import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

// Définition des types de fonctions C
typedef OnisGetVersionFunc = ffi.Pointer<ffi.Char> Function();
typedef OnisAddFunc = ffi.Int32 Function(ffi.Int32, ffi.Int32);
typedef OnisGetNameFunc = ffi.Pointer<ffi.Char> Function();

// Définition des types de fonctions Dart
typedef OnisGetVersion = ffi.Pointer<ffi.Char> Function();
typedef OnisAdd = int Function(int, int);
typedef OnisGetName = ffi.Pointer<ffi.Char> Function();

class OnisCore {
  static ffi.DynamicLibrary? _lib;

  // Fonctions FFI
  static late final OnisGetVersion _onisGetVersion;
  static late final OnisAdd _onisAdd;
  static late final OnisGetName _onisGetName;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    // Charger la bibliothèque dynamique selon la plateforme
    if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open('onis_core.dll');
    } else if (Platform.isMacOS) {
      _lib = ffi.DynamicLibrary.open('libonis_core.dylib');
    } else if (Platform.isLinux) {
      _lib = ffi.DynamicLibrary.open('libonis_core.so');
    } else {
      throw UnsupportedError('Plateforme non supportée pour FFI');
    }

    // Obtenir les références aux fonctions
    _onisGetVersion = _lib!
        .lookupFunction<OnisGetVersionFunc, OnisGetVersion>('onis_get_version');
    _onisAdd = _lib!.lookupFunction<OnisAddFunc, OnisAdd>('onis_add');
    _onisGetName =
        _lib!.lookupFunction<OnisGetNameFunc, OnisGetName>('onis_get_name');

    _initialized = true;
  }

  // Méthodes publiques pour appeler les fonctions C++
  static String getVersion() {
    if (!_initialized) initialize();
    final ptr = _onisGetVersion();
    // Conversion simple de pointeur vers string
    return _ptrToString(ptr);
  }

  static int add(int a, int b) {
    if (!_initialized) initialize();
    return _onisAdd(a, b);
  }

  static String getName() {
    if (!_initialized) initialize();
    final ptr = _onisGetName();
    return _ptrToString(ptr);
  }

  // Méthode utilitaire pour convertir un pointeur vers string
  static String _ptrToString(ffi.Pointer<ffi.Char> ptr) {
    final buffer = <int>[];
    int i = 0;
    while (ptr[i] != 0) {
      buffer.add(ptr[i]);
      i++;
    }
    return String.fromCharCodes(buffer);
  }
}
