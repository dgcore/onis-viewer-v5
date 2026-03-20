//region spatial format:
class OsRsf {
  static const int none = 0x00;
  static const int twoDim = 0x01;
  static const int mmode = 0x02;
  static const int spectral = 0x03;
  static const int waveForm = 0x04;
  static const int graphics = 0x05;
}

// region data type:
class OsRdt {
  static const int none = 0x00;
  static const int tissue = 0x01;
  static const int colorFlow = 0x02;
  static const int pwSpectralDoppler = 0x03;
  static const int cwSpectralDoppler = 0x04;
  static const int dopplerMeanTrace = 0x05;
  static const int dopplerModeTrace = 0x06;
  static const int dopplerMaxTrace = 0x07;
  static const int volumeTrace = 0x08;
  static const int dvolumePerDt = 0x09;
  static const int ecgTrace = 0xA0;
  static const int pulseTrace = 0xB0;
  static const int phonocardiogramTrace = 0xC0;
  static const int grayBar = 0xD0;
  static const int colorBar = 0xE0;
  static const int integratedBackscatter = 0xF0;
  static const int areaTrace = 0x10;
  static const int dareaPerDt = 0x11;
}

//unit types:
class OsUnit {
  static const int invalid = 0xFFFFFF;
  static const int none = 0x00;
  static const int percent = 0x01;
  static const int decibel = 0x02;
  static const int cm = 0x03;
  static const int second = 0x04;
  static const int hertz = 0x05;
  static const int decibelPerSecond = 0x06;
  static const int cmPerSecond = 0x07;
  static const int cm2 = 0x08;
  static const int cm2PerSecond = 0x09;
  static const int cm3 = 0x0A;
  static const int cm3PerSecond = 0x0B;
  static const int degree = 0x0C;
}

class ImageRegion {
  int spatialFormat = OsRsf.twoDim;
  int dataType = OsRdt.none;
  List<double> originalSpacing = [1.0, 1.0];
  List<int> originalUnit = [OsUnit.none, OsUnit.none];
  List<double> calibratedSpacing = [1.0, 1.0];
  List<int> calibratedUnit = [OsUnit.none, OsUnit.none];
  int x0 = 0;
  int x1 = 0;
  int y0 = 0;
  int y1 = 0;

  bool isEqual(ImageRegion other) {
    if (identical(this, other)) return true;

    if (spatialFormat != other.spatialFormat) return false;
    if (dataType != other.dataType) return false;

    if (originalSpacing[0] != other.originalSpacing[0]) return false;
    if (originalSpacing[1] != other.originalSpacing[1]) return false;

    if (originalUnit[0] != other.originalUnit[0]) return false;
    if (originalUnit[1] != other.originalUnit[1]) return false;

    if (calibratedSpacing[0] != other.calibratedSpacing[0]) return false;
    if (calibratedSpacing[1] != other.calibratedSpacing[1]) return false;

    if (calibratedUnit[0] != other.calibratedUnit[0]) return false;
    if (calibratedUnit[1] != other.calibratedUnit[1]) return false;

    if (x0 != other.x0) return false;
    if (x1 != other.x1) return false;
    if (y0 != other.y0) return false;
    if (y1 != other.y1) return false;

    return true;
  }

  ImageRegion clone() {
    final copy = ImageRegion();
    copy.originalSpacing[0] = originalSpacing[0];
    copy.originalSpacing[1] = originalSpacing[1];
    copy.originalUnit[0] = originalUnit[0];
    copy.originalUnit[1] = originalUnit[1];
    copy.calibratedSpacing[0] = calibratedSpacing[0];
    copy.calibratedSpacing[1] = calibratedSpacing[1];
    copy.calibratedUnit[0] = calibratedUnit[0];
    copy.calibratedUnit[1] = calibratedUnit[1];
    copy.x0 = x0;
    copy.x1 = x1;
    copy.y0 = y0;
    copy.y1 = y1;
    copy.spatialFormat = spatialFormat;
    copy.dataType = dataType;
    return copy;
  }
}

class ImageRegionInfo {
  List<int> dimensions = [0, 0];
  List<ImageRegion> regions = [];

  ImageRegionInfo clone() {
    ImageRegionInfo copy = ImageRegionInfo();
    copy.dimensions[0] = dimensions[0];
    copy.dimensions[1] = dimensions[1];
    for (int i = 0; i < regions.length; i++) {
      ImageRegion rg = regions[i].clone();
      copy.regions.add(rg);
    }
    return copy;
  }
}
