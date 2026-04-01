import 'dart:typed_data';

import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/onis_exception.dart';

enum EncodedFormat {
  unknown, // 0
  raw, // 1
  j2k, // 2
  png // 3
}

extension EncodedFormatExtension on EncodedFormat {
  int get toInt {
    switch (this) {
      case EncodedFormat.unknown:
        return 0;
      case EncodedFormat.raw:
        return 1;
      case EncodedFormat.j2k:
        return 2;
      case EncodedFormat.png:
        return 3;
    }
  }

  static EncodedFormat fromInt(int value) {
    switch (value) {
      case 0:
        return EncodedFormat.unknown;
      case 1:
        return EncodedFormat.raw;
      case 2:
        return EncodedFormat.j2k;
      case 3:
        return EncodedFormat.png;
      default:
        return EncodedFormat.unknown;
    }
  }
}

class IntermediatePixelData {
  int currentRes = -1;
  int resIndex = -1;
  int resCount = 0;
  dynamic encodedData;
  EncodedFormat encodedDataFormat = EncodedFormat.unknown;
  int decodingError = 0;
  Uint8List? intermediatePixelData;
  int width = 0;
  int height = 0;
  double finalMinValue = 0;
  double finalMaxValue = 0;
  int bits = 8;
  bool isSigned = false;
  int rgbOrder = 0;

  List<double> getMinMaxValues(
      int bits, bool isSigned, double slope, double intercept) {
    final bytes = intermediatePixelData;
    if (bytes == null || encodedDataFormat != EncodedFormat.raw) {
      return [finalMinValue, finalMaxValue];
    }

    if (bytes.isEmpty) {
      return [finalMinValue, finalMaxValue];
    }

    if (bits <= 8) {
      return isSigned
          ? _getMinMaxInt8(bytes, slope, intercept)
          : _getMinMaxUint8(bytes, slope, intercept);
    }

    if (bits <= 16) {
      if (bytes.lengthInBytes % 2 != 0) {
        throw OnisException(OnisErrorCodes.internal,
            'intermediatePixelData size is not divisible by 2');
      }
      return isSigned
          ? _getMinMaxInt16(bytes, slope, intercept)
          : _getMinMaxUint16(bytes, slope, intercept);
    }

    if (bits <= 32) {
      if (bytes.lengthInBytes % 4 != 0) {
        throw OnisException(OnisErrorCodes.internal,
            'intermediatePixelData size is not divisible by 4');
      }
      return isSigned
          ? _getMinMaxInt32(bytes, slope, intercept)
          : _getMinMaxUint32(bytes, slope, intercept);
    }

    return [finalMinValue, finalMaxValue];
  }

  List<double> _getMinMaxInt8(Uint8List bytes, double slope, double intercept) {
    final values = Int8List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );

    double first = values[0] * slope + intercept;
    double minValue = first;
    double maxValue = first;

    for (int i = 1; i < values.length; ++i) {
      final double v = values[i] * slope + intercept;
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    return [minValue, maxValue];
  }

  List<double> _getMinMaxUint8(
      Uint8List bytes, double slope, double intercept) {
    final values = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );

    double first = values[0] * slope + intercept;
    double minValue = first;
    double maxValue = first;

    for (int i = 1; i < values.length; ++i) {
      final double v = values[i] * slope + intercept;
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    return [minValue, maxValue];
  }

  List<double> _getMinMaxInt16(
      Uint8List bytes, double slope, double intercept) {
    final values = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 2,
    );

    double first = values[0] * slope + intercept;
    double minValue = first;
    double maxValue = first;

    for (int i = 1; i < values.length; ++i) {
      final double v = values[i] * slope + intercept;
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    return [minValue, maxValue];
  }

  List<double> _getMinMaxUint16(
      Uint8List bytes, double slope, double intercept) {
    final values = Uint16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 2,
    );

    double first = values[0] * slope + intercept;
    double minValue = first;
    double maxValue = first;

    for (int i = 1; i < values.length; ++i) {
      final double v = values[i] * slope + intercept;
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    return [minValue, maxValue];
  }

  List<double> _getMinMaxInt32(
      Uint8List bytes, double slope, double intercept) {
    final values = Int32List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 4,
    );

    double first = values[0] * slope + intercept;
    double minValue = first;
    double maxValue = first;

    for (int i = 1; i < values.length; ++i) {
      final double v = values[i] * slope + intercept;
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    return [minValue, maxValue];
  }

  List<double> _getMinMaxUint32(
      Uint8List bytes, double slope, double intercept) {
    final values = Uint32List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 4,
    );

    double first = values[0] * slope + intercept;
    double minValue = first;
    double maxValue = first;

    for (int i = 1; i < values.length; ++i) {
      final double v = values[i] * slope + intercept;
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    return [minValue, maxValue];
  }
}
