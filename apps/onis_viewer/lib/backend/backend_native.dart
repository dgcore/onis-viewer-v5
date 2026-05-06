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

  /// Loads a DICOM Part 10 file from disk. Returns an opaque session id, or
  /// throws on failure.
  int dicomLoadFile(String utf8Path) {
    _ensureOpen();
    final pathPtr = utf8Path.toNativeUtf8();
    final outId = calloc<ffi.Int32>();
    try {
      final status =
          _bindings.dicomLoadFile(_handle, pathPtr, outId);
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomLoadFile failed: ${_readLastError()}',
        );
      }
      return outId.value;
    } finally {
      calloc.free(pathPtr);
      calloc.free(outId);
    }
  }

  void dicomRelease(int id) {
    _ensureOpen();
    final status = _bindings.dicomRelease(_handle, id);
    if (status != OnisBackendStatus.ok) {
      throw StateError(
        'Backend dicomRelease failed: ${_readLastError()}',
      );
    }
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

    bool looksLikeOnisRepoRoot(String dir) =>
        File(p.join(dir, 'CMakeLists.txt')).existsSync() &&
        File(p.join(dir, 'apps', 'onis_viewer', 'pubspec.yaml')).existsSync();

    String? walkFindRepoRoot(String startPath, int maxDepth) {
      var cursor = p.normalize(startPath);
      for (var i = 0; i < maxDepth; i++) {
        if (looksLikeOnisRepoRoot(cursor)) {
          return cursor;
        }
        final parent = p.dirname(cursor);
        if (parent == cursor) {
          return null;
        }
        cursor = parent;
      }
      return null;
    }

    /// Prefer explicit paths; never rely on a bare library name (dyld/cwd can
    /// resolve an outdated stub, e.g. under apps/onis_viewer/).
    final candidates = <String>[];
    final seen = <String>{};
    void addCandidate(String path) {
      final normalized = p.normalize(path);
      if (seen.add(normalized)) {
        candidates.add(normalized);
      }
    }

    final envPath = Platform.environment['ONIS_BACKEND_LIB_PATH'];
    if (envPath != null && envPath.isNotEmpty) {
      addCandidate(envPath);
    }

    final starts = <String>[
      Directory.current.path,
      p.dirname(Platform.resolvedExecutable),
      p.dirname(Platform.script.toFilePath()),
    ];
    final repoRoots = <String>{};
    for (final start in starts) {
      final root = walkFindRepoRoot(start, 28);
      if (root != null) {
        repoRoots.add(p.normalize(root));
      }
    }
    for (final root in repoRoots) {
      addCandidate(p.join(root, 'build', 'lib', fileName));
    }

    void addAncestorCandidates(String startPath, int maxDepth) {
      var cursor = p.normalize(startPath);
      for (var i = 0; i < maxDepth; i++) {
        addCandidate(p.join(cursor, 'build', 'lib', fileName));
        addCandidate(
          p.join(cursor, 'native', 'backend', 'build', 'lib', fileName),
        );
        addCandidate(
          p.join(
            cursor,
            'apps',
            'onis_viewer',
            'native',
            'backend',
            'build',
            'lib',
            fileName,
          ),
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

    addCandidate(p.join(Directory.current.path, 'build', 'lib', fileName));
    addCandidate(p.join(p.dirname(Platform.resolvedExecutable), fileName));
    addCandidate(
      p.join(
        p.dirname(Platform.resolvedExecutable),
        '..',
        'Frameworks',
        fileName,
      ),
    );
    addCandidate(p.join(p.dirname(Platform.script.toFilePath()), fileName));

    final uniqueCandidates = candidates;

    Object? lastError;
    for (final candidate in uniqueCandidates) {
      try {
        final lib = ffi.DynamicLibrary.open(candidate);
        if (!onisBackendLibraryHasDicomExports(lib)) {
          lastError = StateError(
            'Loaded $candidate but it is missing DICOM exports (rebuild the '
            'full onis_backend from the ONIS5 repo root, or set '
            'ONIS_BACKEND_LIB_PATH to a current libonis_backend.dylib).',
          );
          continue;
        }
        return lib;
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError(
      'Unable to load a DCMTK-enabled native backend ($fileName).\n'
      'Build from the repo root (CMake target onis_backend), copy the dylib '
      'next to the app or under build/lib, or set ONIS_BACKEND_LIB_PATH.\n'
      'You can force a path using ONIS_BACKEND_LIB_PATH.\n'
      'Tried:\n- ${uniqueCandidates.join('\n- ')}\n'
      'Last error: $lastError',
    );
  }
}
