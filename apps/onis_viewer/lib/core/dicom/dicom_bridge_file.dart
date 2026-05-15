import 'dart:io';

import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/core/dicom/image_region.dart';

/// Native DICOM session opened in the C++ backend (`loadDicomFile` / `releaseDicom`).
///
/// This does **not** replace [DicomFile], which holds Dart-side tag maps and decoded
/// pixels. Use [DicomBridgeFile] when the dataset lives only in the backend until FFI
/// exposes tag/frame APIs.
///
/// Loads and releases go through [OVApi.backend] (single process-wide backend).
///
/// Frame extraction: [DicomBridgeFileFrameFactory.extractFrame] in
/// `dicom_bridge_frame.dart` (extension, avoids an import cycle with
/// [DicomBridgeFrame]). Extract hydrates native frame metadata (resolution, bits,
/// photometric, palettes, min/max) before pixels are read.
class DicomBridgeFile {
  DicomBridgeFile._(this._backendId, {String? unlinkPathAfterRelease})
      : _unlinkPathAfterRelease = unlinkPathAfterRelease;

  final int _backendId;
  /// When set (e.g. stream download temp file), deleted in [dispose] after
  /// [releaseDicom] so native code keeps a valid on-disk file until the session ends.
  final String? _unlinkPathAfterRelease;
  bool _released = false;

  /// Opaque id passed to the native layer (`onis_backend_dicom_*`).
  int get backendId => _backendId;

  bool get isReleased => _released;

  /// `tagGgEe` like `0008:0018`; [vr] is the DICOM VR (`UI`, `CS`, …).
  String readStringElement(String tagGgEe, String vr) {
    final tag = parseDicomTagKey(tagGgEe);
    return OVApi().backend.dicomGetStringElement(backendId, tag, vr);
  }

  /// Regions from [dicom_dcmtk_base::get_regions] (pixel spacing and/or ultrasound).
  List<ImageRegion> readRegions() {
    return OVApi().backend.dicomGetRegions(backendId);
  }

  /// Packs `GGGG:EEEE` into the same `int32` layout as the native DCMTK helpers.
  static int parseDicomTagKey(String tagGgEe) {
    final parts = tagGgEe.split(':');
    if (parts.length != 2) {
      return 0;
    }
    final g = int.parse(parts[0], radix: 16);
    final e = int.parse(parts[1], radix: 16);
    return ((g & 0xFFFF) << 16) | (e & 0xFFFF);
  }

  /// Opens a Part 10 file on disk. Returns `null` if loading fails (missing path,
  /// unreadable file, invalid DICOM, backend error).
  ///
  /// For failures that must propagate (e.g. logging), use [loadFromPathOrThrow].
  static DicomBridgeFile? loadFromPath(String utf8Path) {
    try {
      final id = OVApi().backend.loadDicomFile(utf8Path);
      return DicomBridgeFile._(id);
    } catch (_) {
      return null;
    }
  }

  /// Same as [loadFromPath] but throws (typically [StateError]) when the backend
  /// rejects the file; does not return `null`.
  static DicomBridgeFile loadFromPathOrThrow(String utf8Path) {
    final id = OVApi().backend.loadDicomFile(utf8Path);
    return DicomBridgeFile._(id);
  }

  /// Takes ownership of an id already returned by [OVApi.backend.loadDicomFile].
  /// The previous holder must not call [releaseDicom] for that id.
  ///
  /// [unlinkPathAfterRelease]: if the dataset was loaded from a scratch path
  /// (e.g. HTTP stream temp file), pass it here so it is removed only after
  /// [dispose] releases the native handle. Do not delete that file yourself.
  factory DicomBridgeFile.adopt(int backendId, {String? unlinkPathAfterRelease}) =>
      DicomBridgeFile._(backendId, unlinkPathAfterRelease: unlinkPathAfterRelease);

  /// Releases the native dataset. Safe to call more than once.
  void dispose() {
    if (_released) {
      return;
    }
    _released = true;
    OVApi().backend.releaseDicom(_backendId);
    final p = _unlinkPathAfterRelease;
    if (p != null) {
      try {
        File(p).deleteSync();
      } catch (_) {}
    }
  }
}
