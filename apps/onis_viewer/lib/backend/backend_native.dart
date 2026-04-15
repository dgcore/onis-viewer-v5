import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'ffi_bindings.dart';

class OnisBackendNative {
  OnisBackendNative._(this._bindings, this._handle);

  final OnisBackendBindings _bindings;
  ffi.Pointer<OnisBackendHandle> _handle;

  bool get isClosed => _handle == ffi.nullptr;

  static OnisBackendNative create({ffi.DynamicLibrary? library}) {
    final lib = library ?? _openDynamicLibrary();
    final bindings = OnisBackendBindings(lib);
    final handle = bindings.create();
    if (handle == ffi.nullptr) {
      throw StateError('Failed to create backend native handle.');
    }
    return OnisBackendNative._(bindings, handle);
  }

  int version() => _bindings.version();

  int ping(int value) {
    _ensureOpen();
    final out = calloc<ffi.Int32>();
    try {
      final status = _bindings.ping(_handle, value, out);
      if (status != OnisBackendStatus.ok) {
        throw StateError('Backend ping failed: ${_readLastError()}');
      }
      return out.value;
    } finally {
      calloc.free(out);
    }
  }

  int instanceId() {
    _ensureOpen();
    final id = _bindings.instanceId(_handle);
    if (id < 0) {
      throw StateError('Backend instanceId failed: ${_readLastError()}');
    }
    return id;
  }

  void close() {
    if (isClosed) {
      return;
    }
    _bindings.destroy(_handle);
    _handle = ffi.nullptr;
  }

  void _ensureOpen() {
    if (isClosed) {
      throw StateError('Backend native handle is already closed.');
    }
  }

  String _readLastError() {
    final ptr = _bindings.getLastError();
    if (ptr == ffi.nullptr) {
      return 'Unknown backend error.';
    }
    return ptr.toDartString();
  }

  static ffi.DynamicLibrary _openDynamicLibrary() {
    final String fileName;
    if (Platform.isMacOS) {
      fileName = 'libonis_backend.dylib';
    } else if (Platform.isLinux) {
      fileName = 'libonis_backend.so';
    } else if (Platform.isWindows) {
      fileName = 'onis_backend.dll';
    } else {
      throw UnsupportedError('Unsupported platform for native backend.');
    }

    final candidates = <String>[
      if ((Platform.environment['ONIS_BACKEND_LIB_PATH'] ?? '').isNotEmpty)
        Platform.environment['ONIS_BACKEND_LIB_PATH']!,
      fileName,
      p.join(Directory.current.path, fileName),
      // Bundle-relative candidates (macOS app sandbox / Flutter desktop run).
      p.join(p.dirname(Platform.resolvedExecutable), fileName),
      p.join(
        p.dirname(Platform.resolvedExecutable),
        '..',
        'Frameworks',
        fileName,
      ),
      p.join(
        p.dirname(Platform.script.toFilePath()),
        fileName,
      ),
    ];

    void addAncestorCandidates(String startPath, int maxDepth) {
      var cursor = p.normalize(startPath);
      for (int i = 0; i < maxDepth; i++) {
        candidates.add(p.join(cursor, 'native', 'backend', 'build', fileName));
        candidates.add(
          p.join(cursor, 'apps', 'onis_viewer', 'native', 'backend', 'build', fileName),
        );
        final parent = p.dirname(cursor);
        if (parent == cursor) {
          break;
        }
        cursor = parent;
      }
    }

    addAncestorCandidates(Directory.current.path, 12);
    addAncestorCandidates(p.dirname(Platform.resolvedExecutable), 12);
    addAncestorCandidates(p.dirname(Platform.script.toFilePath()), 12);

    final uniqueCandidates = <String>[];
    for (final candidate in candidates) {
      if (!uniqueCandidates.contains(candidate)) {
        uniqueCandidates.add(candidate);
      }
    }

    Object? lastError;
    for (final candidate in uniqueCandidates) {
      try {
        return ffi.DynamicLibrary.open(candidate);
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError(
      'Unable to load native backend library ($fileName).\n'
      'You can force a path using ONIS_BACKEND_LIB_PATH.\n'
      'Tried:\n- ${uniqueCandidates.join('\n- ')}\n'
      'Last error: $lastError',
    );
  }
}
