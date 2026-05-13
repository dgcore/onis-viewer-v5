import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

final class OnisBackendHandle extends ffi.Opaque {}

/// Must match [OnisBackendDicomRegion] in `onis_backend.h`.
final class OnisBackendDicomRegion extends ffi.Struct {
  @ffi.Int32()
  external int spatial_format;

  @ffi.Int32()
  external int data_type;

  @ffi.Double()
  external double original_spacing_x;

  @ffi.Double()
  external double original_spacing_y;

  @ffi.Int32()
  external int original_unit_x;

  @ffi.Int32()
  external int original_unit_y;

  @ffi.Double()
  external double calibrated_spacing_x;

  @ffi.Double()
  external double calibrated_spacing_y;

  @ffi.Int32()
  external int calibrated_unit_x;

  @ffi.Int32()
  external int calibrated_unit_y;

  @ffi.Int32()
  external int x0;

  @ffi.Int32()
  external int x1;

  @ffi.Int32()
  external int y0;

  @ffi.Int32()
  external int y1;
}

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

typedef _DicomGetStringElementNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Uint32,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Uint8>,
  ffi.Uint32,
  ffi.Pointer<ffi.Uint32>,
);
typedef _DicomGetStringElementDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  int,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Uint8>,
  int,
  ffi.Pointer<ffi.Uint32>,
);

typedef _DicomGetRegionsNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<OnisBackendDicomRegion>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomGetRegionsDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<OnisBackendDicomRegion>,
  int,
  ffi.Pointer<ffi.Int32>,
);

typedef _DicomFrameCreateNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomFrameCreateDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  int,
  ffi.Pointer<ffi.Int32>,
);

typedef _DicomFrameReleaseNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
);
typedef _DicomFrameReleaseDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
);

typedef _DicomFrameGetDimensionsNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomFrameGetDimensionsDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);

typedef _DicomFrameIsMonochromeNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomFrameIsMonochromeDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Int32>,
);

typedef _DicomFrameGetBitsPerPixelNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomFrameGetBitsPerPixelDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Int32>,
);

typedef _DicomFrameGetIntermediatePixelDataNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Uint8>,
  ffi.Uint32,
  ffi.Pointer<ffi.Uint32>,
);
typedef _DicomFrameGetIntermediatePixelDataDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Uint8>,
  int,
  ffi.Pointer<ffi.Uint32>,
);

typedef _DicomFrameGetRepresentationNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);
typedef _DicomFrameGetRepresentationDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);

/// Returns true if [lib] exports the DCMTK DICOM entry points (not an older
/// stub dylib). Tries both Apple symbol spellings.
bool onisBackendLibraryHasDicomExports(ffi.DynamicLibrary lib) {
  bool tryLookup(void Function() primary, void Function()? underscore) {
    try {
      primary();
      return true;
    } catch (_) {
      if (underscore != null && (Platform.isMacOS || Platform.isIOS)) {
        try {
          underscore();
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  final hasLoad = tryLookup(
    () => lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
      'onis_backend_dicom_load_file',
    ),
    () => lib.lookupFunction<_DicomLoadFileNative, _DicomLoadFileDart>(
      '_onis_backend_dicom_load_file',
    ),
  );
  if (!hasLoad) return false;

  final hasString = tryLookup(
    () => lib.lookupFunction<_DicomGetStringElementNative,
        _DicomGetStringElementDart>(
      'onis_backend_dicom_get_string_element',
    ),
    () => lib.lookupFunction<_DicomGetStringElementNative,
        _DicomGetStringElementDart>(
      '_onis_backend_dicom_get_string_element',
    ),
  );
  if (!hasString) return false;

  final hasRegions = tryLookup(
    () => lib.lookupFunction<_DicomGetRegionsNative, _DicomGetRegionsDart>(
      'onis_backend_dicom_get_regions',
    ),
    () => lib.lookupFunction<_DicomGetRegionsNative, _DicomGetRegionsDart>(
      '_onis_backend_dicom_get_regions',
    ),
  );
  if (!hasRegions) return false;

  final hasFrameCreate = tryLookup(
    () => lib.lookupFunction<_DicomFrameCreateNative, _DicomFrameCreateDart>(
      'onis_backend_dicom_frame_create',
    ),
    () => lib.lookupFunction<_DicomFrameCreateNative, _DicomFrameCreateDart>(
      '_onis_backend_dicom_frame_create',
    ),
  );
  if (!hasFrameCreate) return false;

  final hasFrameRelease = tryLookup(
    () => lib.lookupFunction<_DicomFrameReleaseNative, _DicomFrameReleaseDart>(
      'onis_backend_dicom_frame_release',
    ),
    () => lib.lookupFunction<_DicomFrameReleaseNative, _DicomFrameReleaseDart>(
      '_onis_backend_dicom_frame_release',
    ),
  );
  if (!hasFrameRelease) return false;

  final hasFrameGetDims = tryLookup(
    () => lib.lookupFunction<_DicomFrameGetDimensionsNative,
        _DicomFrameGetDimensionsDart>(
      'onis_backend_dicom_frame_get_dimensions',
    ),
    () => lib.lookupFunction<_DicomFrameGetDimensionsNative,
        _DicomFrameGetDimensionsDart>(
      '_onis_backend_dicom_frame_get_dimensions',
    ),
  );
  if (!hasFrameGetDims) return false;

  final hasFrameMono = tryLookup(
    () => lib.lookupFunction<_DicomFrameIsMonochromeNative,
        _DicomFrameIsMonochromeDart>(
      'onis_backend_dicom_frame_is_monochrome',
    ),
    () => lib.lookupFunction<_DicomFrameIsMonochromeNative,
        _DicomFrameIsMonochromeDart>(
      '_onis_backend_dicom_frame_is_monochrome',
    ),
  );
  if (!hasFrameMono) return false;

  final hasFrameBits = tryLookup(
    () => lib.lookupFunction<_DicomFrameGetBitsPerPixelNative,
        _DicomFrameGetBitsPerPixelDart>(
      'onis_backend_dicom_frame_get_bits_per_pixel',
    ),
    () => lib.lookupFunction<_DicomFrameGetBitsPerPixelNative,
        _DicomFrameGetBitsPerPixelDart>(
      '_onis_backend_dicom_frame_get_bits_per_pixel',
    ),
  );
  if (!hasFrameBits) return false;

  final hasFrameInter = tryLookup(
    () => lib.lookupFunction<_DicomFrameGetIntermediatePixelDataNative,
        _DicomFrameGetIntermediatePixelDataDart>(
      'onis_backend_dicom_frame_get_intermediate_pixel_data',
    ),
    () => lib.lookupFunction<_DicomFrameGetIntermediatePixelDataNative,
        _DicomFrameGetIntermediatePixelDataDart>(
      '_onis_backend_dicom_frame_get_intermediate_pixel_data',
    ),
  );
  if (!hasFrameInter) return false;

  final hasFrameRepr = tryLookup(
    () => lib.lookupFunction<_DicomFrameGetRepresentationNative,
        _DicomFrameGetRepresentationDart>(
      'onis_backend_dicom_frame_get_representation',
    ),
    () => lib.lookupFunction<_DicomFrameGetRepresentationNative,
        _DicomFrameGetRepresentationDart>(
      '_onis_backend_dicom_frame_get_representation',
    ),
  );
  return hasFrameRepr;
}

_DicomGetStringElementDart _lookupDicomGetStringElement(
    ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomGetStringElementNative,
        _DicomGetStringElementDart>(
      'onis_backend_dicom_get_string_element',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomGetStringElementNative,
          _DicomGetStringElementDart>(
        '_onis_backend_dicom_get_string_element',
      );
    }
    rethrow;
  }
}

_DicomGetRegionsDart _lookupDicomGetRegions(ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomGetRegionsNative, _DicomGetRegionsDart>(
      'onis_backend_dicom_get_regions',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomGetRegionsNative, _DicomGetRegionsDart>(
        '_onis_backend_dicom_get_regions',
      );
    }
    rethrow;
  }
}

_DicomFrameCreateDart _lookupDicomFrameCreate(ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameCreateNative, _DicomFrameCreateDart>(
      'onis_backend_dicom_frame_create',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameCreateNative, _DicomFrameCreateDart>(
        '_onis_backend_dicom_frame_create',
      );
    }
    rethrow;
  }
}

_DicomFrameReleaseDart _lookupDicomFrameRelease(ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameReleaseNative, _DicomFrameReleaseDart>(
      'onis_backend_dicom_frame_release',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameReleaseNative, _DicomFrameReleaseDart>(
        '_onis_backend_dicom_frame_release',
      );
    }
    rethrow;
  }
}

_DicomFrameGetDimensionsDart _lookupDicomFrameGetDimensions(
    ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameGetDimensionsNative,
        _DicomFrameGetDimensionsDart>(
      'onis_backend_dicom_frame_get_dimensions',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameGetDimensionsNative,
          _DicomFrameGetDimensionsDart>(
        '_onis_backend_dicom_frame_get_dimensions',
      );
    }
    rethrow;
  }
}

_DicomFrameIsMonochromeDart _lookupDicomFrameIsMonochrome(
    ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameIsMonochromeNative,
        _DicomFrameIsMonochromeDart>(
      'onis_backend_dicom_frame_is_monochrome',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameIsMonochromeNative,
          _DicomFrameIsMonochromeDart>(
        '_onis_backend_dicom_frame_is_monochrome',
      );
    }
    rethrow;
  }
}

_DicomFrameGetBitsPerPixelDart _lookupDicomFrameGetBitsPerPixel(
    ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameGetBitsPerPixelNative,
        _DicomFrameGetBitsPerPixelDart>(
      'onis_backend_dicom_frame_get_bits_per_pixel',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameGetBitsPerPixelNative,
          _DicomFrameGetBitsPerPixelDart>(
        '_onis_backend_dicom_frame_get_bits_per_pixel',
      );
    }
    rethrow;
  }
}

_DicomFrameGetIntermediatePixelDataDart _lookupDicomFrameGetIntermediatePixelData(
    ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameGetIntermediatePixelDataNative,
        _DicomFrameGetIntermediatePixelDataDart>(
      'onis_backend_dicom_frame_get_intermediate_pixel_data',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameGetIntermediatePixelDataNative,
          _DicomFrameGetIntermediatePixelDataDart>(
        '_onis_backend_dicom_frame_get_intermediate_pixel_data',
      );
    }
    rethrow;
  }
}

_DicomFrameGetRepresentationDart _lookupDicomFrameGetRepresentation(
    ffi.DynamicLibrary lib) {
  try {
    return lib.lookupFunction<_DicomFrameGetRepresentationNative,
        _DicomFrameGetRepresentationDart>(
      'onis_backend_dicom_frame_get_representation',
    );
  } catch (_) {
    if (Platform.isMacOS || Platform.isIOS) {
      return lib.lookupFunction<_DicomFrameGetRepresentationNative,
          _DicomFrameGetRepresentationDart>(
        '_onis_backend_dicom_frame_get_representation',
      );
    }
    rethrow;
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
        ),
        dicomGetStringElement = _lookupDicomGetStringElement(lib),
        dicomGetRegions = _lookupDicomGetRegions(lib),
        dicomFrameCreate = _lookupDicomFrameCreate(lib),
        dicomFrameRelease = _lookupDicomFrameRelease(lib),
        dicomFrameGetDimensions = _lookupDicomFrameGetDimensions(lib),
        dicomFrameIsMonochrome = _lookupDicomFrameIsMonochrome(lib),
        dicomFrameGetBitsPerPixel = _lookupDicomFrameGetBitsPerPixel(lib),
        dicomFrameGetIntermediatePixelData =
            _lookupDicomFrameGetIntermediatePixelData(lib),
        dicomFrameGetRepresentation = _lookupDicomFrameGetRepresentation(lib);

  final _VersionDart version;
  final _CreateDart create;
  final _DestroyDart destroy;
  final _PingDart ping;
  final _InstanceIdDart instanceId;
  final _GetLastErrorDart getLastError;
  final _DicomLoadFileDart dicomLoadFile;
  final _DicomReleaseDart dicomRelease;
  final _DicomGetStringElementDart dicomGetStringElement;
  final _DicomGetRegionsDart dicomGetRegions;
  final _DicomFrameCreateDart dicomFrameCreate;
  final _DicomFrameReleaseDart dicomFrameRelease;
  final _DicomFrameGetDimensionsDart dicomFrameGetDimensions;
  final _DicomFrameIsMonochromeDart dicomFrameIsMonochrome;
  final _DicomFrameGetBitsPerPixelDart dicomFrameGetBitsPerPixel;
  final _DicomFrameGetIntermediatePixelDataDart dicomFrameGetIntermediatePixelData;
  final _DicomFrameGetRepresentationDart dicomFrameGetRepresentation;
}
