import 'dart:typed_data';

import 'package:onis_viewer/core/dicom/image_region.dart';

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

  /// Loads a DICOM Part 10 file from disk via DCMTK; returns a backend-held id.
  int loadDicomFile(String utf8Path) => _native.dicomLoadFile(utf8Path);

  void releaseDicom(int id) => _native.dicomRelease(id);

  /// See [OnisBackendNative.dicomGetStringElement].
  String dicomGetStringElement(int dicomId, int tagKey, String vr) =>
      _native.dicomGetStringElement(dicomId, tagKey, vr);

  List<ImageRegion> dicomGetRegions(int dicomId) =>
      _native.dicomGetRegions(dicomId);

  int dicomCreateFrame(int dicomId, int frameIndex) =>
      _native.dicomCreateFrame(dicomId, frameIndex);

  void dicomReleaseFrame(int frameId) => _native.dicomReleaseFrame(frameId);

  (int width, int height) dicomFrameGetDimensions(int frameId) =>
      _native.dicomFrameGetDimensions(frameId);

  bool dicomFrameIsMonochrome(int frameId) =>
      _native.dicomFrameIsMonochrome(frameId);

  int dicomFrameGetBitsPerPixel(int frameId) =>
      _native.dicomFrameGetBitsPerPixel(frameId);

  Uint8List dicomFrameCopyIntermediatePixelData(int frameId) =>
      _native.dicomFrameCopyIntermediatePixelData(frameId);

  ({int bits, bool isSigned}) dicomFrameGetRepresentation(int frameId) =>
      _native.dicomFrameGetRepresentation(frameId);

  void dispose() => _native.close();
}
