import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:onis_viewer/core/dicom/image_region.dart';
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
      final status = _bindings.dicomLoadFile(_handle, pathPtr, outId);
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

  /// [tagKey] is `(group << 16) | element`, same encoding as internal DCMTK tag int.
  /// [vr] is the DICOM value representation ASCII (e.g. `UI`, `CS`).
  String dicomGetStringElement(int dicomId, int tagKey, String vr) {
    _ensureOpen();
    final vrPtr = vr.toNativeUtf8();
    const maxLen = 65536;
    final out = calloc<ffi.Uint8>(maxLen);
    final written = calloc<ffi.Uint32>();
    try {
      final status = _bindings.dicomGetStringElement(
        _handle,
        dicomId,
        tagKey,
        vrPtr,
        out,
        maxLen,
        written,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomGetStringElement failed: ${_readLastError()}',
        );
      }
      final n = written.value;
      if (n == 0) {
        return '';
      }
      return utf8.decode(out.asTypedList(n));
    } finally {
      calloc.free(vrPtr);
      calloc.free(out);
      calloc.free(written);
    }
  }

  /// Fills [ImageRegion] from native `dicom_dcmtk_base::get_regions`.
  List<ImageRegion> dicomGetRegions(int dicomId) {
    _ensureOpen();
    final countPtr = calloc<ffi.Int32>();
    const cap = 64;
    var buf = calloc<OnisBackendDicomRegion>(cap);
    try {
      var status = _bindings.dicomGetRegions(
        _handle,
        dicomId,
        buf,
        cap,
        countPtr,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomGetRegions failed: ${_readLastError()}',
        );
      }
      var total = countPtr.value;
      if (total > cap) {
        calloc.free(buf);
        buf = calloc<OnisBackendDicomRegion>(total);
        status = _bindings.dicomGetRegions(
          _handle,
          dicomId,
          buf,
          total,
          countPtr,
        );
        if (status != OnisBackendStatus.ok) {
          throw StateError(
            'Backend dicomGetRegions failed: ${_readLastError()}',
          );
        }
        total = countPtr.value;
      }

      final out = <ImageRegion>[];
      for (var i = 0; i < total; i++) {
        final native = buf.elementAt(i).ref;
        final r = ImageRegion();
        r.spatialFormat = native.spatial_format;
        r.dataType = native.data_type;
        r.originalSpacing[0] = native.original_spacing_x;
        r.originalSpacing[1] = native.original_spacing_y;
        r.originalUnit[0] = native.original_unit_x;
        r.originalUnit[1] = native.original_unit_y;
        r.calibratedSpacing[0] = native.calibrated_spacing_x;
        r.calibratedSpacing[1] = native.calibrated_spacing_y;
        r.calibratedUnit[0] = native.calibrated_unit_x;
        r.calibratedUnit[1] = native.calibrated_unit_y;
        r.x0 = native.x0;
        r.x1 = native.x1;
        r.y0 = native.y0;
        r.y1 = native.y1;
        out.add(r);
      }
      return out;
    } finally {
      calloc.free(buf);
      calloc.free(countPtr);
    }
  }

  /// Creates a native [onis::dicom_frame] for [dicomId] / [frameIndex]. Returns
  /// an opaque frame id; call [dicomReleaseFrame] when done.
  int dicomCreateFrame(int dicomId, int frameIndex) {
    _ensureOpen();
    final outId = calloc<ffi.Int32>();
    try {
      final status = _bindings.dicomFrameCreate(
        _handle,
        dicomId,
        frameIndex,
        outId,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomFrameCreate failed: ${_readLastError()}',
        );
      }
      return outId.value;
    } finally {
      calloc.free(outId);
    }
  }

  void dicomReleaseFrame(int frameId) {
    _ensureOpen();
    final status = _bindings.dicomFrameRelease(_handle, frameId);
    if (status != OnisBackendStatus.ok) {
      throw StateError(
        'Backend dicomFrameRelease failed: ${_readLastError()}',
      );
    }
  }

  (int width, int height) dicomFrameGetDimensions(int frameId) {
    _ensureOpen();
    final outW = calloc<ffi.Int32>();
    final outH = calloc<ffi.Int32>();
    try {
      final status = _bindings.dicomFrameGetDimensions(
        _handle,
        frameId,
        outW,
        outH,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomFrameGetDimensions failed: ${_readLastError()}',
        );
      }
      return (outW.value, outH.value);
    } finally {
      calloc.free(outW);
      calloc.free(outH);
    }
  }

  bool dicomFrameIsMonochrome(int frameId) {
    _ensureOpen();
    final out = calloc<ffi.Int32>();
    try {
      final status = _bindings.dicomFrameIsMonochrome(
        _handle,
        frameId,
        out,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomFrameIsMonochrome failed: ${_readLastError()}',
        );
      }
      return out.value != 0;
    } finally {
      calloc.free(out);
    }
  }

  int dicomFrameGetBitsPerPixel(int frameId) {
    _ensureOpen();
    final out = calloc<ffi.Int32>();
    try {
      final status = _bindings.dicomFrameGetBitsPerPixel(
        _handle,
        frameId,
        out,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomFrameGetBitsPerPixel failed: ${_readLastError()}',
        );
      }
      return out.value;
    } finally {
      calloc.free(out);
    }
  }

  /// Full copy of native intermediate pixels (`get_intermediate_pixel_data`).
  Uint8List dicomFrameCopyIntermediatePixelData(int frameId) {
    _ensureOpen();
    final sizeOut = calloc<ffi.Uint32>();
    try {
      var status = _bindings.dicomFrameGetIntermediatePixelData(
        _handle,
        frameId,
        ffi.nullptr,
        0,
        sizeOut,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomFrameGetIntermediatePixelData (size) failed: ${_readLastError()}',
        );
      }
      final n = sizeOut.value;
      if (n == 0) {
        return Uint8List(0);
      }
      final buf = calloc<ffi.Uint8>(n);
      try {
        status = _bindings.dicomFrameGetIntermediatePixelData(
          _handle,
          frameId,
          buf,
          n,
          sizeOut,
        );
        if (status != OnisBackendStatus.ok) {
          throw StateError(
            'Backend dicomFrameGetIntermediatePixelData (copy) failed: ${_readLastError()}',
          );
        }
        return Uint8List.fromList(buf.asTypedList(n));
      } finally {
        calloc.free(buf);
      }
    } finally {
      calloc.free(sizeOut);
    }
  }

  ({int bits, bool isSigned}) dicomFrameGetRepresentation(int frameId) {
    _ensureOpen();
    final outBits = calloc<ffi.Int32>();
    final outSigned = calloc<ffi.Int32>();
    try {
      final status = _bindings.dicomFrameGetRepresentation(
        _handle,
        frameId,
        outBits,
        outSigned,
      );
      if (status != OnisBackendStatus.ok) {
        throw StateError(
          'Backend dicomFrameGetRepresentation failed: ${_readLastError()}',
        );
      }
      return (bits: outBits.value, isSigned: outSigned.value != 0);
    } finally {
      calloc.free(outBits);
      calloc.free(outSigned);
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
