import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

final class OnisBackendHandle extends ffi.Opaque {}

abstract final class OnisBackendStatus {
  static const int ok = 0;
  static const int error = 1;
  static const int invalidArgument = 2;
}

typedef _VersionNative = ffi.Int32 Function();
typedef _VersionDart = int Function();

typedef _CreateNative = ffi.Pointer<OnisBackendHandle> Function();
typedef _CreateDart = ffi.Pointer<OnisBackendHandle> Function();

typedef _DestroyNative = ffi.Void Function(ffi.Pointer<OnisBackendHandle>);
typedef _DestroyDart = void Function(ffi.Pointer<OnisBackendHandle>);

typedef _PingNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
);
typedef _PingDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Int32>,
);

typedef _GetLastErrorNative = ffi.Pointer<Utf8> Function();
typedef _GetLastErrorDart = ffi.Pointer<Utf8> Function();

typedef _InstanceIdNative = ffi.Int32 Function(ffi.Pointer<OnisBackendHandle>);
typedef _InstanceIdDart = int Function(ffi.Pointer<OnisBackendHandle>);

typedef _DicomLoadFileNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomLoadFileDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Int32>,
);

typedef _DicomReleaseNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
);
typedef _DicomReleaseDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
);

/// Returns true if [lib] exports the DCMTK DICOM entry points (not an older
/// stub dylib). Tries both Apple symbol spellings.
bool onisBackendLibraryHasDicomExports(ffi.DynamicLibrary lib) {
  try {
    lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
      'onis_backend_dicom_load_file',
    );
    return true;
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      try {
        lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
          '_onis_backend_dicom_load_file',
        );
        return true;
      } catch (_) {}
    }
    return false;
  }
}

class _DicomExportNames {
  const _DicomExportNames(this.loadFile, this.release);
  final String loadFile;
  final String release;
}

/// Whether the linker used leading underscores for DICOM exports on this dylib.
_DicomExportNames _dicomExportNames(ffi.DynamicLibrary lib) {
  try {
    lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
      'onis_backend_dicom_load_file',
    );
    lib.lookupFunction<_DicomReleaseNative, _DicomReleaseDart>(
      'onis_backend_dicom_release',
    );
    return const _DicomExportNames(
      'onis_backend_dicom_load_file',
      'onis_backend_dicom_release',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
        '_onis_backend_dicom_load_file',
      );
      lib.lookupFunction<_DicomReleaseNative, _DicomReleaseDart>(
        '_onis_backend_dicom_release',
      );
      return const _DicomExportNames(
        '_onis_backend_dicom_load_file',
        '_onis_backend_dicom_release',
      );
    }
    rethrow;
  }
}

class OnisBackendBindings {
  factory OnisBackendBindings(ffi.DynamicLibrary lib) {
    final dicom = _dicomExportNames(lib);
    return OnisBackendBindings._(
      lib,
      dicomLoadFileName: dicom.loadFile,
      dicomReleaseName: dicom.release,
    );
  }

  OnisBackendBindings._(
    ffi.DynamicLibrary lib, {
    required String dicomLoadFileName,
    required String dicomReleaseName,
  })  : version = lib.lookupFunction<_VersionNative, _VersionDart>(
          'onis_backend_version',
        ),
        create = lib.lookupFunction<_CreateNative, _CreateDart>(
          'onis_backend_create',
        ),
        destroy = lib.lookupFunction<_DestroyNative, _DestroyDart>(
          'onis_backend_destroy',
        ),
        ping = lib.lookupFunction<_PingNative, _PingDart>(
          'onis_backend_ping',
        ),
        instanceId = lib.lookupFunction<_InstanceIdNative, _InstanceIdDart>(
          'onis_backend_instance_id',
        ),
        getLastError =
            lib.lookupFunction<_GetLastErrorNative, _GetLastErrorDart>(
          'onis_backend_get_last_error',
        ),
        dicomLoadFile =
            lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
          dicomLoadFileName,
        ),
        dicomRelease =
            lib.lookupFunction<_DicomReleaseNative, _DicomReleaseDart>(
          dicomReleaseName,
        );

  final _VersionDart version;
  final _CreateDart create;
  final _DestroyDart destroy;
  final _PingDart ping;
  final _InstanceIdDart instanceId;
  final _GetLastErrorDart getLastError;
  final _DicomLoadFileDart dicomLoadFile;
  final _DicomReleaseDart dicomRelease;
}
