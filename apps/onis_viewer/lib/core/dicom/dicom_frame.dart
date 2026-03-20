import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onis_viewer/core/dicom/intermediate_pixel_data.dart';
import 'package:onis_viewer/core/dicom/raw_palette.dart';
import 'package:onis_viewer/core/models/database/color_lut.dart';
import 'package:onis_viewer/core/models/database/convolution_filter.dart';
import 'package:onis_viewer/core/models/database/opacity_table.dart';

enum PhotoType {
  mono1,
  mono2,
  rgb,
}

enum VoiLutFunction {
  linear,
  sigmoid,
}

class DicomFrame {
  late PhotoType _photo;
  int frameIndex;
  double rescaleSlope = 1.0;
  double intercept = 0.0;
  VoiLutFunction voiLutFunction = VoiLutFunction.linear;
  double _windowCenter = 128;
  double _windowWidth = 256;
  bool _windowLevelValid = false;
  double _originalWindowCenter = 128;
  double _originalWindowWidth = 256;

  WeakReference<ConvolutionFilter>? _wconvolutionFilter;
  WeakReference<OpacityTable>? _wopacityTable;
  WeakReference<ColorLut>? _wcolorLut;
  IntermediatePixelData? _data;
  double _minValue = 0;
  double _maxValue = 0;
  int _currentRes = -1;
  final List<DicomRawPalette?> _palette = [null, null, null];

  DicomFrame(
      {this.frameIndex = 0,
      required PhotoType photo,
      required IntermediatePixelData? data}) {
    _photo = photo;
    _data = data;
    if (_data != null) {
      _currentRes = _data!.currentRes;
    }
  }

  //-----------------------------------------------------------------------
  //palette
  //-----------------------------------------------------------------------
  void setPalette(int chanel, DicomRawPalette? palette) {
    if (identical(_palette[chanel], palette)) {
      _palette[chanel] = palette;
    }
  }

  DicomRawPalette? getPalette(int chanel) {
    return _palette[chanel];
  }

  //-----------------------------------------------------------------------
  //Intermediate pixel data
  //-----------------------------------------------------------------------

  get intermediatePixelData => _data;
  get currentRes => _currentRes;

  //-----------------------------------------------------------------------
  //properties
  //-----------------------------------------------------------------------

  get isMonochrome {
    if (_data == null) return false;
    return _photo == PhotoType.mono1 || _photo == PhotoType.mono2;
  }

  (int width, int height)? getDimensions() {
    if (_data != null) {
      return (_data!.width, _data!.height);
    }
    return null;
  }

  get photometricType => _photo;

  get havePalette => _palette[0] != null;

  //-----------------------------------------------------------------------
  //window level
  //-----------------------------------------------------------------------

  void setWindowLevel(double center, double width) {
    _windowCenter = center;
    _windowWidth = width;
    _windowLevelValid = true;
  }

  (double center, double width)? get windowLevel {
    if (_windowLevelValid) {
      return (_windowCenter, _windowWidth);
    }
    return null;
  }

  void setOriginalWindowLevel(double center, double width) {
    _originalWindowCenter = center;
    _originalWindowWidth = width;
  }

  (double center, double width) getOriginalWindowLevel() {
    return (_originalWindowCenter, _originalWindowWidth);
  }

  void interToDisplayWindowLevel(double center, double width) {
    double left = center - width * 0.5;
    double right = center + width * 0.5;
    left = left * rescaleSlope + intercept;
    right = right * rescaleSlope + intercept;
    center = (left + right) * 0.5;
    width = (right - left);
  }

  void displayToInterWindowLevel(double center, double width) {
    if (rescaleSlope != 0) {
      double left = center - width * 0.5;
      double right = center + width * 0.5;
      left = (left - intercept) / rescaleSlope;
      right = (right - intercept) / rescaleSlope;
      center = (left + right) * 0.5;
      width = (right - left);
    }
  }

  //-----------------------------------------------------------------------
  //overlays
  //-----------------------------------------------------------------------
  void showAllOverlays(bool show) {}

  void showOverlay(int index, bool show) {}

  bool isOverlayHidden(int index) {
    return false;
  }

  //-----------------------------------------------------------------------
  //min-max values
  //-----------------------------------------------------------------------

  (double minValue, double maxValue)? getMinMaxValues(bool intermediate) {
    IntermediatePixelData? inter = intermediatePixelData;
    if (inter == null) return null;
    if (intermediate) {
      return (_minValue, _maxValue);
    } else {
      return (
        _minValue * rescaleSlope + intercept,
        _maxValue * rescaleSlope + intercept
      );
    }
  }

  void setMinMaxValues(double minVal, double maxVal) {
    _minValue = minVal;
    _maxValue = maxVal;
  }

  //-----------------------------------------------------------------------
  //convolution filter
  //-----------------------------------------------------------------------

  set convolutionFilter(ConvolutionFilter? filter) {
    _wconvolutionFilter =
        filter == null ? null : WeakReference<ConvolutionFilter>(filter);
  }

  ConvolutionFilter? get convolutionFilter {
    return _wconvolutionFilter?.target;
  }

  //-----------------------------------------------------------------------
  //color lut
  //-----------------------------------------------------------------------

  set colorLut(ColorLut? colorLut) {
    _wcolorLut = colorLut == null ? null : WeakReference<ColorLut>(colorLut);
  }

  ColorLut? get colorLut {
    return _wcolorLut?.target;
  }

  //-----------------------------------------------------------------------
  //opacity table
  //-----------------------------------------------------------------------

  set opacityTable(OpacityTable? opacityTable) {
    _wopacityTable =
        opacityTable == null ? null : WeakReference<OpacityTable>(opacityTable);
  }

  OpacityTable? get opacityTable {
    return _wopacityTable?.target;
  }

  //-----------------------------------------------------------------------
  //extract bitmap
  //-----------------------------------------------------------------------

  bool createBitmap(
      {required int bits,
      required bool inverseColor,
      required Uint8List pixels,
      required int width,
      required int height}) {
    if (_data == null) return false;
    if (_data!.width != width || _data!.height != height) return false;
    if (_data!.intermediatePixelData == null) return false;
    calculatePixelData(
        bits: bits,
        inverseColor: inverseColor,
        pixels: pixels,
        width: width,
        height: height);
    return true;
  }

  void createWindowLevelLutForMonochrome(Uint8List lut,
      {required int bits, required bool isSigned, required bool inverse}) {
    if (bits != 8 && bits != 16 && bits != 32) return;
    //Calculate the Left and Right positions of the window level:
    double left, right;
    double center, width;
    final centerWidth = windowLevel;
    if (centerWidth == null) {
      // Normally, we should never come here.
      final minMax = getMinMaxValues(true);
      if (minMax != null) {
        width = minMax.$2 - minMax.$1;
        center = (minMax.$1 + minMax.$2) * 0.5;
      } else {
        if (bits == 32 || bits == 16) {
          width = 65536.0;
          center = isSigned ? 0.0 : 32768.0;
        } else {
          width = 256.0;
          center = isSigned ? 0.0 : 128.0;
        }
      }
    } else {
      // Adjust the values with the scale and intercept values.
      displayToInterWindowLevel(centerWidth.$1, centerWidth.$2);
      center = centerWidth.$1;
      width = centerWidth.$2;
    }
    if (width < 1.0) width = 1.0;
    left = center - width * 0.5;
    right = center + width * 0.5;

    double signedOffset;
    int maxBound;

    if (bits == 32) {
      signedOffset = 32768.0;
      maxBound = 65535;
    } else if (bits == 16) {
      signedOffset = 32768.0;
      maxBound = 65535;
    } else {
      signedOffset = 128.0;
      maxBound = 255;
    }

    if (isSigned) {
      left += signedOffset;
      right += signedOffset;
      center += signedOffset;
    }

    int minValue = math.max(0, left.floor());
    minValue = math.min(minValue, maxBound);
    int maxValue = math.min(maxBound, right.floor() + 1);
    maxValue = math.max(maxValue, 0);

    if (voiLutFunction == VoiLutFunction.sigmoid) {
      //SIGMOID TABLE:
      for (int i = 0; i <= maxBound; i++) {
        final double dval =
            255.0 / (1.0 + math.exp(-4.0 * (i - center) / width).toDouble());

        int ival = dval.floor();
        if (dval - dval.floor() >= 0.5) {
          ival++;
        }

        ival = math.min(ival, 255);
        ival = math.max(ival, 0);

        lut[i] = inverse ? (255 - ival) : ival;
      }
    } else {
      //LINEAR TABLE:
      final double factor = 255.0 / (right - left);

      if (inverse) {
        for (int i = 0; i < minValue; i++) {
          lut[i] = 255;
        }

        for (int i = minValue; i <= maxValue; i++) {
          final double dval = (i - left) * factor;
          int ival = dval.floor();

          ival = math.min(ival, 255);
          ival = math.max(ival, 0);

          lut[i] = 255 - ival;
        }

        for (int i = maxValue + 1; i <= maxBound; i++) {
          lut[i] = 0;
        }
      } else {
        for (int i = 0; i < minValue; i++) {
          lut[i] = 0;
        }

        for (int i = minValue; i <= maxValue; i++) {
          final double dval = (i - left) * factor;
          int ival = dval.floor();

          ival = math.min(ival, 255);
          ival = math.max(ival, 0);

          lut[i] = ival;
        }

        for (int i = maxValue + 1; i <= maxBound; i++) {
          lut[i] = 255;
        }
      }
    }
  }

  void createWindowLevelLutForRGBImage(
    Uint8List lut, {
    required bool inverse,
  }) {
    if (lut.length < 256) {
      throw ArgumentError('LUT must have at least 256 elements.');
    }

    final centerWidth = windowLevel;
    double center = 128.0;
    double width = 255.0;
    if (centerWidth != null) {
      center = centerWidth.$1;
      width = centerWidth.$2;
    }

    // If default → identity LUT
    if (center == 128.0 && width == 255.0) {
      if (inverse) {
        for (int i = 0; i < 256; i++) {
          lut[i] = 255 - i;
        }
      } else {
        for (int i = 0; i < 256; i++) {
          lut[i] = i;
        }
      }
      return;
    }

    // Convert to brightness / contrast
    double brightness = -(center - 128.0) / 128.0;
    brightness = brightness.clamp(-1.0, 1.0);

    double contrast = 255.0 - (width - 255.0);
    contrast /= 255.0;
    contrast = contrast.clamp(0.0, 3.0);

    final double trans = (1.0 - contrast) / 2.0;

    for (int i = 0; i < 256; i++) {
      double dval = (i / 255.0) * contrast + trans + brightness;
      dval *= 255.0;

      final f = dval.floor();
      int val = (dval - f >= 0.5) ? f + 1 : f;

      if (val < 0) {
        val = 0;
      } else if (val > 255) {
        val = 255;
      }

      lut[i] = inverse ? (255 - val) : val;
    }
  }

  void calculatePixelData(
      {required int bits,
      required bool inverseColor,
      required Uint8List pixels,
      required int width,
      required int height}) {
    if (_data?.intermediatePixelData == null) return;

    //True monochrome images:
    if (isMonochrome && !havePalette) {
      Uint8List? interData = _data!.intermediatePixelData;
      if (interData == null) return;
      int representation = _data!.bits;
      bool isSigned = _data!.isSigned;

      //Apply the convolution filter:
      final convFilter = convolutionFilter;

      if (convFilter != null &&
          _data!.bits > 0 &&
          (_data!.bits == 16 || _data!.bits == 8)) {
        //make sure that the size of the image is compatible with the filter dimension:
        int tmp = _data!.bits * convFilter.dimension;
        if (_data!.isSigned) tmp = -tmp;
        final compatible = (width < tmp || height < tmp) ? false : true;

        if (compatible) {
          //we have a convolution filter.
          //we will use a modified copy of up_Pixel that will take in account the convolution filter!
          final copy = Int32List(height * width);
          switch (tmp) {
            case 48:
              processConvolutionFilter3x3ForMonochrome(convFilter, width,
                  height, Uint16List.view(interData.buffer), copy);
              break;
            case -48:
              processConvolutionFilter3x3ForMonochrome(convFilter, width,
                  height, Int16List.view(interData.buffer), copy);
              break;
            case 80:
              processConvolutionFilter5x5ForMonochrome(convFilter, width,
                  height, Uint16List.view(interData.buffer), copy);
              break;
            case -80:
              processConvolutionFilter5x5ForMonochrome(convFilter, width,
                  height, Int16List.view(interData.buffer), copy);
              break;
            case 24:
              processConvolutionFilter3x3ForMonochrome(convFilter, width,
                  height, Uint8List.view(interData.buffer), copy);
              break;
            case -24:
              processConvolutionFilter3x3ForMonochrome(convFilter, width,
                  height, Int8List.view(interData.buffer), copy);
              break;
            case 40:
              processConvolutionFilter5x5ForMonochrome(convFilter, width,
                  height, Uint8List.view(interData.buffer), copy);
              break;
            case -40:
              processConvolutionFilter5x5ForMonochrome(convFilter, width,
                  height, Int8List.view(interData.buffer), copy);
              break;
            default:
              break;
          }
          interData = Uint8List.view(copy.buffer);
          representation = 32;
          isSigned = true;
        }
      }

      //Create our window level lut:
      final windowLevelLut = Uint8List(65536);
      bool inverseColor1 = _photo == PhotoType.mono1 ? true : false;
      if (inverseColor) inverseColor1 = !inverseColor1;
      createWindowLevelLutForMonochrome(windowLevelLut,
          bits: representation, isSigned: isSigned, inverse: inverseColor1);

      //Do we have an opacity table to apply?
      OpacityTable? opacity = opacityTable;

      //Do we have a color LUT to apply:
      ColorLut? color = colorLut;

      if (representation == 32) {
        if (isSigned) {
          if (color != null) {
            if (opacity != null) {
              _calculatePixelDataForSignedIntDataWithColorLutAndOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color,
                  table: opacity);
            } else {
              _calculatePixelDataForSignedIntDataWithColorLut(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color);
            }
          } else {
            if (opacity != null) {
              _calculatePixelDataForSignedIntDataWithOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  table: opacity);
            } else {
              _calculatePixelDataForSignedIntData(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut);
            }
          }
        } else {
          if (color != null) {
            if (opacity != null) {
              _calculatePixelDataForUnsignedIntDataWithColorLutAndOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color,
                  table: opacity);
            } else {
              _calculatePixelDataForUnsignedIntDataWithColorLut(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color);
            }
          } else {
            if (opacity != null) {
              _calculatePixelDataForUnsignedIntDataWithOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  table: opacity);
            } else {
              _calculatePixelDataForUnsignedIntData(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut);
            }
          }
        }
      } else if (representation == 16) {
        if (isSigned) {
          if (color != null) {
            if (opacity != null) {
              _calculatePixelDataForSignedShortDataWithColorLutAndOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color,
                  table: opacity);
            } else {
              _calculatePixelDataForSignedShortDataWithColorLut(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color);
            }
          } else {
            if (opacity != null) {
              _calculatePixelDataForSignedShortDataWithOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  table: opacity);
            } else {
              _calculatePixelDataForSignedShortData(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut);
            }
          }
        } else {
          if (color != null) {
            if (opacity != null) {
              _calculatePixelDataForUnsignedShortDataWithColorLutAndOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color,
                  table: opacity);
            } else {
              _calculatePixelDataForUnsignedShortDataWithColorLut(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color);
            }
          } else {
            if (opacity != null) {
              _calculatePixelDataForUnsignedShortDataWithOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  table: opacity);
            } else {
              _calculatePixelDataForUnsignedShortData(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut);
            }
          }
        }
      } else if (representation == 8) {
        if (isSigned) {
          if (color != null) {
            if (opacity != null) {
              _calculatePixelDataForSignedByteDataWithColorLutAndOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color,
                  table: opacity);
            } else {
              _calculatePixelDataForSignedByteDataWithColorLut(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color);
            }
          } else {
            if (opacity != null) {
              _calculatePixelDataForSignedByteDataWithOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  table: opacity);
            } else {
              _calculatePixelDataForSignedByteData(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut);
            }
          }
        } else {
          if (color != null) {
            if (opacity != null) {
              _calculatePixelDataForUnsignedByteDataWithColorLutAndOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color,
                  table: opacity);
            } else {
              _calculatePixelDataForUnsignedByteDataWithColorLut(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  colorLut: color);
            }
          } else {
            if (opacity != null) {
              _calculatePixelDataForUnsignedByteDataWithOpacityTable(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut,
                  table: opacity);
            } else {
              _calculatePixelDataForUnsignedByteData(
                  output: pixels,
                  width: width,
                  height: height,
                  pixels: interData,
                  windowLevelLut: windowLevelLut);
            }
          }
        }
      }
    } else {
      //Treat the rgb image here:
      int bitsPerPixels = 24;
      if (bitsPerPixels == 24 || bitsPerPixels == 32) {
        OpacityTable? opacity = opacityTable;
        ColorLut? color = colorLut;
        Uint8List windowLevelLut = Uint8List(256);
        createWindowLevelLutForRGBImage(
          windowLevelLut,
          inverse: inverseColor,
        );
        //Get the intermediate pixels:
        IntermediatePixelData? interData = intermediatePixelData;

        if (interData != null) {
          Uint8List? source = havePalette
              ? reconstructPaletteImage(interData)
              : interData.intermediatePixelData;
          int rgbOrder = havePalette ? 0 : interData.rgbOrder;
          if (source != null) {
            //Apply the convolution filter:
            ConvolutionFilter? convolution = convolutionFilter;

            if (convolution != null) {
              int filterDimension = convolutionFilter!.dimension;
              bool compatible =
                  (width < filterDimension || height < filterDimension)
                      ? false
                      : true;
              if (compatible) {
                Uint8List copy = Uint8List(height * width * 3);
                switch (filterDimension) {
                  case 3:
                    processConvolutionFilter3x3ForRGBData(
                        filter: convolution,
                        width: width,
                        height: height,
                        pixels: source,
                        rgbOrder: rgbOrder,
                        output: copy);
                    break;
                  case 5:
                    processConvolutionFilter5x5ForRGBData(
                        filter: convolution,
                        width: width,
                        height: height,
                        pixels: source,
                        rgbOrder: rgbOrder,
                        output: copy);
                    break;
                  default:
                    break;
                }
                source = copy;
              }
            }

            if (bitsPerPixels == 24) {
              if (color != null) {
                if (opacity != null) {
                  calculatePixelDataFor24BitsRGBDataWithColorLutAndOpacityTable(
                      outputBits: bits,
                      output: pixels,
                      width: width,
                      height: height,
                      pixels: source,
                      windowLevelLut: windowLevelLut,
                      table: opacity,
                      colorLut: color,
                      rgbOrder: rgbOrder);
                } else {
                  calculatePixelDataFor24BitsRGBDataWithColorLut(
                      outputBits: bitsPerPixels,
                      output: pixels,
                      width: width,
                      height: height,
                      pixels: source,
                      windowLevelLut: windowLevelLut,
                      colorLut: color,
                      rgbOrder: rgbOrder);
                }
              } else {
                if (opacity != null) {
                  calculatePixelDataFor24BitsRGBDataWithOpacityTable(
                      outputBits: bits,
                      output: pixels,
                      width: width,
                      height: height,
                      pixels: source,
                      windowLevelLut: windowLevelLut,
                      table: opacity,
                      rgbOrder: rgbOrder);
                } else {
                  calculatePixelDataFor24BitsRGBData(
                      outputBits: bits,
                      output: pixels,
                      width: width,
                      height: height,
                      pixels: source,
                      windowLevelLut: windowLevelLut,
                      rgbOrder: rgbOrder);
                }
              }
            }
          }
        }
      }
    }
  }

  Uint8List? reconstructPaletteImage(IntermediatePixelData interData) {
    if (interData.width <= 0 || interData.height <= 0) {
      return null;
    }

    final p0 = _palette[0];
    final p1 = _palette[1];
    final p2 = _palette[2];

    if (p0 == null || p1 == null || p2 == null) {
      return null;
    }
    if (p0.data == null || p1.data == null || p2.data == null) {
      return null;
    }
    if (interData.intermediatePixelData == null) {
      return null;
    }

    final int pixelCount = interData.width * interData.height;
    final Uint8List output = Uint8List(pixelCount * 3); // RGB

    final ByteBuffer redBuffer = p0.data!.buffer;
    final ByteBuffer greenBuffer = p1.data!.buffer;
    final ByteBuffer blueBuffer = p2.data!.buffer;

    if (interData.bits == 32) {
      return null;
    }

    if (interData.bits == 16) {
      if (p0.bits == 16 && p1.bits == 16 && p2.bits == 16) {
        final redPalette = Uint16List.view(redBuffer);
        final greenPalette = Uint16List.view(greenBuffer);
        final bluePalette = Uint16List.view(blueBuffer);

        if (interData.isSigned) {
          final pixels =
              Int16List.view(interData.intermediatePixelData!.buffer);
          if (pixels.length != pixelCount) {
            return null;
          }
          _fillPaletteRgb16Signed(
            pixels,
            output,
            p0,
            p1,
            p2,
            redPalette,
            greenPalette,
            bluePalette,
          );
          return output;
        } else {
          final pixels =
              Uint16List.view(interData.intermediatePixelData!.buffer);
          if (pixels.length != pixelCount) {
            return null;
          }
          _fillPaletteRgb16Unsigned(
            pixels,
            output,
            p0,
            p1,
            p2,
            redPalette,
            greenPalette,
            bluePalette,
          );
          return output;
        }
      }
      return null;
    }

    if (interData.bits == 8) {
      if (interData.isSigned) {
        final pixels = Int8List.view(interData.intermediatePixelData!.buffer);
        if (pixels.length != pixelCount) {
          return null;
        }

        if (p0.bits == 16 && p1.bits == 16 && p2.bits == 16) {
          _fillPaletteRgb8SignedWith16Palette(
            pixels,
            output,
            p0,
            p1,
            p2,
            Uint16List.view(redBuffer),
            Uint16List.view(greenBuffer),
            Uint16List.view(blueBuffer),
          );
        } else {
          _fillPaletteRgb8SignedWith8Palette(
            pixels,
            output,
            p0,
            p1,
            p2,
            Uint8List.view(redBuffer),
            Uint8List.view(greenBuffer),
            Uint8List.view(blueBuffer),
          );
        }
        return output;
      } else {
        final pixels = Uint8List.view(interData.intermediatePixelData!.buffer);
        if (pixels.length != pixelCount) {
          return null;
        }

        if (p0.bits == 16 && p1.bits == 16 && p2.bits == 16) {
          _fillPaletteRgb8UnsignedWith16Palette(
            pixels,
            output,
            p0,
            p1,
            p2,
            Uint16List.view(redBuffer),
            Uint16List.view(greenBuffer),
            Uint16List.view(blueBuffer),
          );
        } else {
          _fillPaletteRgb8UnsignedWith8Palette(
            pixels,
            output,
            p0,
            p1,
            p2,
            Uint8List.view(redBuffer),
            Uint8List.view(greenBuffer),
            Uint8List.view(blueBuffer),
          );
        }
        return output;
      }
    }

    return null;
  }

  int _paletteIndex(int pixelValue, DicomRawPalette palette) {
    if (pixelValue <= palette.value) {
      return 0;
    }
    if (pixelValue > palette.value + palette.count) {
      return palette.count - 1;
    }
    return pixelValue - palette.value;
  }

  void _fillPaletteRgb16Signed(
    Int16List pixels,
    Uint8List output,
    DicomRawPalette p0,
    DicomRawPalette p1,
    DicomRawPalette p2,
    Uint16List redPalette,
    Uint16List greenPalette,
    Uint16List bluePalette,
  ) {
    int offset = 0;
    for (int i = 0; i < pixels.length; i++) {
      final v = pixels[i];

      int index = _paletteIndex(v, p0);
      output[offset] = (redPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p1);
      output[offset + 1] = (greenPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p2);
      output[offset + 2] = (bluePalette[index] * 255) ~/ 65535;

      offset += 3;
    }
  }

  void _fillPaletteRgb16Unsigned(
    Uint16List pixels,
    Uint8List output,
    DicomRawPalette p0,
    DicomRawPalette p1,
    DicomRawPalette p2,
    Uint16List redPalette,
    Uint16List greenPalette,
    Uint16List bluePalette,
  ) {
    int offset = 0;
    for (int i = 0; i < pixels.length; i++) {
      final v = pixels[i];

      int index = _paletteIndex(v, p0);
      output[offset] = (redPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p1);
      output[offset + 1] = (greenPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p2);
      output[offset + 2] = (bluePalette[index] * 255) ~/ 65535;

      offset += 3;
    }
  }

  void _fillPaletteRgb8SignedWith16Palette(
    Int8List pixels,
    Uint8List output,
    DicomRawPalette p0,
    DicomRawPalette p1,
    DicomRawPalette p2,
    Uint16List redPalette,
    Uint16List greenPalette,
    Uint16List bluePalette,
  ) {
    int offset = 0;
    for (int i = 0; i < pixels.length; i++) {
      final v = pixels[i];

      int index = _paletteIndex(v, p0);
      output[offset] = (redPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p1);
      output[offset + 1] = (greenPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p2);
      output[offset + 2] = (bluePalette[index] * 255) ~/ 65535;

      offset += 3;
    }
  }

  void _fillPaletteRgb8UnsignedWith16Palette(
    Uint8List pixels,
    Uint8List output,
    DicomRawPalette p0,
    DicomRawPalette p1,
    DicomRawPalette p2,
    Uint16List redPalette,
    Uint16List greenPalette,
    Uint16List bluePalette,
  ) {
    int offset = 0;
    for (int i = 0; i < pixels.length; i++) {
      final v = pixels[i];

      int index = _paletteIndex(v, p0);
      output[offset] = (redPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p1);
      output[offset + 1] = (greenPalette[index] * 255) ~/ 65535;

      index = _paletteIndex(v, p2);
      output[offset + 2] = (bluePalette[index] * 255) ~/ 65535;

      offset += 3;
    }
  }

  void _fillPaletteRgb8SignedWith8Palette(
    Int8List pixels,
    Uint8List output,
    DicomRawPalette p0,
    DicomRawPalette p1,
    DicomRawPalette p2,
    Uint8List redPalette,
    Uint8List greenPalette,
    Uint8List bluePalette,
  ) {
    int offset = 0;
    for (int i = 0; i < pixels.length; i++) {
      final v = pixels[i];

      int index = _paletteIndex(v, p0);
      output[offset] = redPalette[index];

      index = _paletteIndex(v, p1);
      output[offset + 1] = greenPalette[index];

      index = _paletteIndex(v, p2);
      output[offset + 2] = bluePalette[index];

      offset += 3;
    }
  }

  void _fillPaletteRgb8UnsignedWith8Palette(
    Uint8List pixels,
    Uint8List output,
    DicomRawPalette p0,
    DicomRawPalette p1,
    DicomRawPalette p2,
    Uint8List redPalette,
    Uint8List greenPalette,
    Uint8List bluePalette,
  ) {
    int offset = 0;
    for (int i = 0; i < pixels.length; i++) {
      final v = pixels[i];

      int index = _paletteIndex(v, p0);
      output[offset] = redPalette[index];

      index = _paletteIndex(v, p1);
      output[offset + 1] = greenPalette[index];

      index = _paletteIndex(v, p2);
      output[offset + 2] = bluePalette[index];

      offset += 3;
    }
  }

  void _calculatePixelDataForUnsignedByteData(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut}) {
    Uint8List input = Uint8List.view(pixels.buffer);

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedByteData(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut}) {
    Int8List input = Int8List.view(pixels.buffer);

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i] + 128];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedShortData(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut}) {
    Uint16List input = Uint16List.view(pixels.buffer);

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void calculatePixelDataFor24BitsRGBData({
    required int outputBits,
    required Uint8List output,
    required int width,
    required int height,
    required Uint8List pixels,
    required Uint8List windowLevelLut,
    required int rgbOrder,
  }) {
    // Calculate the output stride.
    final int factor = (outputBits == 24) ? 3 : 4;
    int outputStride = width * factor;
    if (factor == 3) {
      outputStride += width % 4;
    }

    if (rgbOrder == 0) {
      // Interleaved RGBRGBRGB...
      if (outputBits == 32) {
        int inOffset = 0;
        int outOffset = 0;
        final int count = width * height;

        for (int i = 0; i < count; i++) {
          output[outOffset] = windowLevelLut[pixels[inOffset]];
          output[outOffset + 1] = windowLevelLut[pixels[inOffset + 1]];
          output[outOffset + 2] = windowLevelLut[pixels[inOffset + 2]];
          output[outOffset + 3] = 255;

          inOffset += 3;
          outOffset += 4;
        }
      }
    } else {
      // Planar R... G... B...
      final int sourceStride = width;

      if (outputBits == 32) {
        final int redOffset = 0;
        final int greenOffset = width * height;
        final int blueOffset = greenOffset * 2;

        for (int j = 0; j < height; j++) {
          int targetOffset = (height - j - 1) * outputStride;
          int pixFrom1 = redOffset + (height - j - 1) * sourceStride;
          int pixFrom2 = greenOffset + (height - j - 1) * sourceStride;
          int pixFrom3 = blueOffset + (height - j - 1) * sourceStride;

          for (int i = 0; i < width; i++) {
            output[targetOffset] = windowLevelLut[pixels[pixFrom1]];
            output[targetOffset + 1] = windowLevelLut[pixels[pixFrom2]];
            output[targetOffset + 2] = windowLevelLut[pixels[pixFrom3]];
            output[targetOffset + 3] = 255;

            targetOffset += 4;
            pixFrom1++;
            pixFrom2++;
            pixFrom3++;
          }
        }
      }
    }
  }

  void calculatePixelDataFor24BitsRGBDataWithColorLut({
    required int outputBits,
    required Uint8List output,
    required int width,
    required int height,
    required Uint8List pixels,
    required Uint8List windowLevelLut,
    required ColorLut colorLut,
    required int rgbOrder,
  }) {
    final int factor = (outputBits == 24) ? 3 : 4;
    int outputStride = width * factor;
    if (factor == 3) {
      outputStride += width % 4;
    }

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    if (rgbOrder == 0) {
      // Interleaved RGBRGBRGB...
      if (outputBits == 32) {
        int inOffset = 0;
        int outOffset = 0;
        final int count = width * height;

        for (int i = 0; i < count; i++) {
          output[outOffset] = red[windowLevelLut[pixels[inOffset]]];
          output[outOffset + 1] = green[windowLevelLut[pixels[inOffset + 1]]];
          output[outOffset + 2] = blue[windowLevelLut[pixels[inOffset + 2]]];
          output[outOffset + 3] = 255;

          inOffset += 3;
          outOffset += 4;
        }
      }
    } else {
      // Planar R... G... B...
      final int sourceStride = width;

      if (outputBits == 32) {
        final int redOffset = 0;
        final int greenOffset = width * height;
        final int blueOffset = greenOffset * 2;

        for (int j = 0; j < height; j++) {
          int targetOffset = (height - j - 1) * outputStride;
          int pixFrom1 = redOffset + (height - j - 1) * sourceStride;
          int pixFrom2 = greenOffset + (height - j - 1) * sourceStride;
          int pixFrom3 = blueOffset + (height - j - 1) * sourceStride;

          for (int i = 0; i < width; i++) {
            output[targetOffset] = red[windowLevelLut[pixels[pixFrom1]]];
            output[targetOffset + 1] = green[windowLevelLut[pixels[pixFrom2]]];
            output[targetOffset + 2] = blue[windowLevelLut[pixels[pixFrom3]]];
            output[targetOffset + 3] = 255;

            targetOffset += 4;
            pixFrom1++;
            pixFrom2++;
            pixFrom3++;
          }
        }
      }
    }
  }

  void calculatePixelDataFor24BitsRGBDataWithOpacityTable({
    required int outputBits,
    required Uint8List output,
    required int width,
    required int height,
    required Uint8List pixels,
    required Uint8List windowLevelLut,
    required OpacityTable table,
    required int rgbOrder,
  }) {
    final int factor = (outputBits == 24) ? 3 : 4;
    int outputStride = width * factor;
    if (factor == 3) {
      outputStride += width % 4;
    }

    final Uint8List? opacity = table.table;
    if (opacity == null) {
      return;
    }

    if (rgbOrder == 0) {
      // Interleaved RGBRGBRGB...
      if (outputBits == 32) {
        int inOffset = 0;
        int outOffset = 0;
        final int count = width * height;

        for (int i = 0; i < count; i++) {
          output[outOffset] = opacity[windowLevelLut[pixels[inOffset]]];
          output[outOffset + 1] = opacity[windowLevelLut[pixels[inOffset + 1]]];
          output[outOffset + 2] = opacity[windowLevelLut[pixels[inOffset + 2]]];
          output[outOffset + 3] = 255;

          inOffset += 3;
          outOffset += 4;
        }
      }
    } else {
      // Planar R... G... B...
      final int sourceStride = width;

      if (outputBits == 32) {
        final int redOffset = 0;
        final int greenOffset = width * height;
        final int blueOffset = greenOffset * 2;

        for (int j = 0; j < height; j++) {
          int targetOffset = (height - j - 1) * outputStride;
          int pixFrom1 = redOffset + (height - j - 1) * sourceStride;
          int pixFrom2 = greenOffset + (height - j - 1) * sourceStride;
          int pixFrom3 = blueOffset + (height - j - 1) * sourceStride;

          for (int i = 0; i < width; i++) {
            output[targetOffset] = opacity[windowLevelLut[pixels[pixFrom1]]];
            output[targetOffset + 1] =
                opacity[windowLevelLut[pixels[pixFrom2]]];
            output[targetOffset + 2] =
                opacity[windowLevelLut[pixels[pixFrom3]]];
            output[targetOffset + 3] = 255;

            targetOffset += 4;
            pixFrom1++;
            pixFrom2++;
            pixFrom3++;
          }
        }
      }
    }
  }

  void calculatePixelDataFor24BitsRGBDataWithColorLutAndOpacityTable({
    required int outputBits,
    required Uint8List output,
    required int width,
    required int height,
    required Uint8List pixels,
    required Uint8List windowLevelLut,
    required OpacityTable table,
    required ColorLut colorLut,
    required int rgbOrder,
  }) {
    final int factor = (outputBits == 24) ? 3 : 4;
    int outputStride = width * factor;
    if (factor == 3) {
      outputStride += width % 4;
    }

    final Uint8List? red = colorLut.getEntries(0);
    final Uint8List? green = colorLut.getEntries(1);
    final Uint8List? blue = colorLut.getEntries(2);
    final Uint8List? opacity = table.table;
    if (opacity == null || red == null || green == null || blue == null) {
      return;
    }

    if (rgbOrder == 0) {
      // Interleaved RGBRGBRGB...
      if (outputBits == 32) {
        int inOffset = 0;
        int outOffset = 0;
        final int count = width * height;

        for (int i = 0; i < count; i++) {
          output[outOffset] = red[opacity[windowLevelLut[pixels[inOffset]]]];
          output[outOffset + 1] =
              green[opacity[windowLevelLut[pixels[inOffset + 1]]]];
          output[outOffset + 2] =
              blue[opacity[windowLevelLut[pixels[inOffset + 2]]]];
          output[outOffset + 3] = 255;

          inOffset += 3;
          outOffset += 4;
        }
      }
    } else {
      // Planar R... G... B...
      final int sourceStride = width;

      if (outputBits == 32) {
        final int redOffset = 0;
        final int greenOffset = width * height;
        final int blueOffset = greenOffset * 2;

        for (int j = 0; j < height; j++) {
          int targetOffset = (height - j - 1) * outputStride;
          int pixFrom1 = redOffset + (height - j - 1) * sourceStride;
          int pixFrom2 = greenOffset + (height - j - 1) * sourceStride;
          int pixFrom3 = blueOffset + (height - j - 1) * sourceStride;

          for (int i = 0; i < width; i++) {
            output[targetOffset] =
                red[opacity[windowLevelLut[pixels[pixFrom1]]]];
            output[targetOffset + 1] =
                green[opacity[windowLevelLut[pixels[pixFrom2]]]];
            output[targetOffset + 2] =
                blue[opacity[windowLevelLut[pixels[pixFrom3]]]];
            output[targetOffset + 3] = 255;

            targetOffset += 4;
            pixFrom1++;
            pixFrom2++;
            pixFrom3++;
          }
        }
      }
    }
  }

  void _calculatePixelDataForUnsignedShortDataWithColorLut(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut}) {
    Uint16List input = Uint16List.view(pixels.buffer);
    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;
    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedByteDataWithColorLut(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut}) {
    Uint8List input = Uint8List.view(pixels.buffer);

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;
    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedByteDataWithColorLut(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut}) {
    Int8List input = Int8List.view(pixels.buffer);

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i] + 128];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedShortDataWithColorLut(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut}) {
    //Calculate the output stride:
    Int16List input = Int16List.view(pixels.buffer);

    //Get the color lut table:
    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i] + 32768];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedShortDataWithOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required OpacityTable table}) {
    Uint16List input = Uint16List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i]]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedByteDataWithOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required OpacityTable table}) {
    Uint8List input = Uint8List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i]]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedByteDataWithOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required OpacityTable table}) {
    Int8List input = Int8List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i] + 128]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedShortDataWithOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required OpacityTable table}) {
    Int16List input = Int16List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i] + 32768]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedShortDataWithColorLutAndOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut,
      required OpacityTable table}) {
    Uint16List input = Uint16List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i]]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedByteDataWithColorLutAndOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut,
      required OpacityTable table}) {
    Uint8List input = Uint8List.view(pixels.buffer);
    //Get the opacity table:

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i]]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedByteDataWithColorLutAndOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut,
      required OpacityTable table}) {
    Int8List input = Int8List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i] + 128]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedShortDataWithColorLutAndOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut,
      required OpacityTable table}) {
    Int16List input = Int16List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = opacity[windowLevelLut[input[i] + 32768]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedShortData(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut}) {
    Int16List input = Int16List.view(pixels.buffer);

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = windowLevelLut[input[i] + 32768];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedIntData(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut}) {
    Int32List input = Int32List.view(pixels.buffer);

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = input[i] + 32768;
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = windowLevelLut[val];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedIntData(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut}) {
    Uint32List input = Uint32List.view(pixels.buffer);

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = input[i];
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = windowLevelLut[val];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedIntDataWithOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required OpacityTable table}) {
    Int32List input = Int32List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = input[i] + 32768;
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = opacity[windowLevelLut[val]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedIntDataWithOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required OpacityTable table}) {
    Uint32List input = Uint32List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = input[i];
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = opacity[windowLevelLut[val]];
      output[index] = val;
      output[index + 1] = val;
      output[index + 2] = val;
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedIntDataWithColorLutAndOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut,
      required OpacityTable table}) {
    Int32List input = Int32List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = input[i] + 32768;
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = opacity[windowLevelLut[val]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedIntDataWithColorLutAndOpacityTable(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut,
      required OpacityTable table}) {
    Uint32List input = Uint32List.view(pixels.buffer);

    Uint8List? opacity = table.table;
    if (opacity == null) return;

    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }

    int val;
    int index = 0;

    for (int i = 0; i < input.length; i++) {
      val = input[i];
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = opacity[windowLevelLut[val]];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForSignedIntDataWithColorLut(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut}) {
    Int32List input = Int32List.view(pixels.buffer);
    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }
    int val;
    int index = 0;
    for (var i = 0; i < input.length; i++) {
      val = input[i] + 32768;
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = windowLevelLut[val];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }

  void _calculatePixelDataForUnsignedIntDataWithColorLut(
      {required Uint8List output,
      required int width,
      required int height,
      required Uint8List pixels,
      required Uint8List windowLevelLut,
      required ColorLut colorLut}) {
    Uint32List input = Uint32List.view(pixels.buffer);
    Uint8List? red = colorLut.getEntries(0);
    Uint8List? green = colorLut.getEntries(1);
    Uint8List? blue = colorLut.getEntries(2);
    if (red == null || green == null || blue == null) {
      return;
    }
    int val;
    int index = 0;
    for (var i = 0; i < input.length; i++) {
      val = input[i];
      if (val < 0) {
        val = 0;
      } else if (val > 65535) {
        val = 65535;
      }
      val = windowLevelLut[val];
      output[index] = red[val];
      output[index + 1] = green[val];
      output[index + 2] = blue[val];
      output[index + 3] = 255;
      index += 4;
    }
  }
}

void processConvolutionFilter3x3ForMonochrome(
  ConvolutionFilter filter,
  int width,
  int height,
  TypedData pixels,
  Int32List output,
) {
  if (pixels is Uint8List) {
    _processConvolutionFilter3x3ForMonochromeUint8(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }
  if (pixels is Int8List) {
    _processConvolutionFilter3x3ForMonochromeInt8(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }
  if (pixels is Uint16List) {
    _processConvolutionFilter3x3ForMonochromeUint16(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }
  if (pixels is Int16List) {
    _processConvolutionFilter3x3ForMonochromeInt16(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }

  throw UnsupportedError('Unsupported pixel type: ${pixels.runtimeType}');
}

void _processConvolutionFilter3x3ForMonochromeUint8(
  ConvolutionFilter filter,
  int width,
  int height,
  Uint8List pixels,
  Int32List output,
) {
  _processConvolutionFilter3x3ForMonochromeCore(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter3x3ForMonochromeInt8(
  ConvolutionFilter filter,
  int width,
  int height,
  Int8List pixels,
  Int32List output,
) {
  _processConvolutionFilter3x3ForMonochromeCore(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter3x3ForMonochromeUint16(
  ConvolutionFilter filter,
  int width,
  int height,
  Uint16List pixels,
  Int32List output,
) {
  _processConvolutionFilter3x3ForMonochromeCore(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter3x3ForMonochromeInt16(
  ConvolutionFilter filter,
  int width,
  int height,
  Int16List pixels,
  Int32List output,
) {
  _processConvolutionFilter3x3ForMonochromeCore(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter3x3ForMonochromeCore(
  ConvolutionFilter filter,
  int width,
  int height,
  int Function(int index) px,
  Int32List output,
) {
  final matrix = filter.matrix;
  if (matrix == null || matrix.length < 9) {
    return;
  }

  double normalization = filter.normalization;
  if (normalization == 0.0) {
    normalization = 1.0;
  }
  final double normalizationInv = 1.0 / normalization;

  final m0 = matrix[0];
  final m1 = matrix[1];
  final m2 = matrix[2];
  final m3 = matrix[3];
  final m4 = matrix[4];
  final m5 = matrix[5];
  final m6 = matrix[6];
  final m7 = matrix[7];
  final m8 = matrix[8];

  int roundFloor(double v) => v.floor();

  // Bottom line
  int outputIndex = (height - 1) * width;
  int sourcePosDown = (height - 1) * width;
  int sourcePos = (height - 1) * width;
  int sourcePosUp = (height - 2) * width;

  output[outputIndex] = roundFloor((px(sourcePosUp) * m0 +
          px(sourcePosUp) * m3 +
          px(sourcePosUp + 1) * m6 +
          px(sourcePos) * m1 +
          px(sourcePos) * m4 +
          px(sourcePos + 1) * m7 +
          px(sourcePosDown) * m2 +
          px(sourcePosDown) * m5 +
          px(sourcePosDown + 1) * m8) *
      normalizationInv);
  sourcePosUp++;
  sourcePos++;
  sourcePosDown++;
  outputIndex++;

  for (int i = 1; i < width - 1; i++) {
    output[outputIndex] = roundFloor((px(sourcePosUp - 1) * m0 +
            px(sourcePosUp) * m3 +
            px(sourcePosUp + 1) * m6 +
            px(sourcePos - 1) * m1 +
            px(sourcePos) * m4 +
            px(sourcePos + 1) * m7 +
            px(sourcePosDown - 1) * m2 +
            px(sourcePosDown) * m5 +
            px(sourcePosDown + 1) * m8) *
        normalizationInv);
    sourcePosUp++;
    sourcePos++;
    sourcePosDown++;
    outputIndex++;
  }

  output[outputIndex] = roundFloor((px(sourcePosUp - 1) * m0 +
          px(sourcePosUp) * m3 +
          px(sourcePosUp) * m6 +
          px(sourcePos - 1) * m1 +
          px(sourcePos) * m4 +
          px(sourcePos) * m7 +
          px(sourcePosDown - 1) * m2 +
          px(sourcePosDown) * m5 +
          px(sourcePosDown) * m8) *
      normalizationInv);

  // Middle lines
  for (int j = 1; j < height - 1; j++) {
    outputIndex = (height - j - 1) * width;
    sourcePosDown = (height - (j - 1) - 1) * width;
    sourcePos = (height - j - 1) * width;
    sourcePosUp = (height - (j + 1) - 1) * width;

    output[outputIndex] = roundFloor((px(sourcePosUp) * m0 +
            px(sourcePosUp) * m3 +
            px(sourcePosUp + 1) * m6 +
            px(sourcePos) * m1 +
            px(sourcePos) * m4 +
            px(sourcePos + 1) * m7 +
            px(sourcePosDown) * m2 +
            px(sourcePosDown) * m5 +
            px(sourcePosDown + 1) * m8) *
        normalizationInv);

    sourcePosUp++;
    sourcePos++;
    sourcePosDown++;
    outputIndex++;

    for (int i = 1; i < width - 1; i++) {
      output[outputIndex] = roundFloor((px(sourcePosUp - 1) * m0 +
              px(sourcePosUp) * m3 +
              px(sourcePosUp + 1) * m6 +
              px(sourcePos - 1) * m1 +
              px(sourcePos) * m4 +
              px(sourcePos + 1) * m7 +
              px(sourcePosDown - 1) * m2 +
              px(sourcePosDown) * m5 +
              px(sourcePosDown + 1) * m8) *
          normalizationInv);
      sourcePosUp++;
      sourcePos++;
      sourcePosDown++;
      outputIndex++;
    }

    output[outputIndex] = roundFloor((px(sourcePosUp - 1) * m0 +
            px(sourcePosUp) * m3 +
            px(sourcePosUp) * m6 +
            px(sourcePos - 1) * m1 +
            px(sourcePos) * m4 +
            px(sourcePos) * m7 +
            px(sourcePosDown - 1) * m2 +
            px(sourcePosDown) * m5 +
            px(sourcePosDown) * m8) *
        normalizationInv);
  }

  // Top line
  outputIndex = 0;
  sourcePosDown = width;
  sourcePos = 0;
  sourcePosUp = 0;

  output[outputIndex] = roundFloor((px(sourcePosUp) * m0 +
          px(sourcePosUp) * m3 +
          px(sourcePosUp + 1) * m6 +
          px(sourcePos) * m1 +
          px(sourcePos) * m4 +
          px(sourcePos + 1) * m7 +
          px(sourcePosDown) * m2 +
          px(sourcePosDown) * m5 +
          px(sourcePosDown + 1) * m8) *
      normalizationInv);
  sourcePosUp++;
  sourcePos++;
  sourcePosDown++;
  outputIndex++;

  for (int i = 1; i < width - 1; i++) {
    output[outputIndex] = roundFloor((px(sourcePosUp - 1) * m0 +
            px(sourcePosUp) * m3 +
            px(sourcePosUp + 1) * m6 +
            px(sourcePos - 1) * m1 +
            px(sourcePos) * m4 +
            px(sourcePos + 1) * m7 +
            px(sourcePosDown - 1) * m2 +
            px(sourcePosDown) * m5 +
            px(sourcePosDown + 1) * m8) *
        normalizationInv);
    sourcePosUp++;
    sourcePos++;
    sourcePosDown++;
    outputIndex++;
  }

  output[outputIndex] = roundFloor((px(sourcePosUp - 1) * m0 +
          px(sourcePosUp) * m3 +
          px(sourcePosUp) * m6 +
          px(sourcePos - 1) * m1 +
          px(sourcePos) * m4 +
          px(sourcePos) * m7 +
          px(sourcePosDown - 1) * m2 +
          px(sourcePosDown) * m5 +
          px(sourcePosDown) * m8) *
      normalizationInv);
}

void processConvolutionFilter5x5ForMonochrome(
  ConvolutionFilter filter,
  int width,
  int height,
  TypedData pixels,
  Int32List output,
) {
  if (pixels is Uint8List) {
    _processConvolutionFilter5x5ForMonochromeUint8(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }
  if (pixels is Int8List) {
    _processConvolutionFilter5x5ForMonochromeInt8(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }
  if (pixels is Uint16List) {
    _processConvolutionFilter5x5ForMonochromeUint16(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }
  if (pixels is Int16List) {
    _processConvolutionFilter5x5ForMonochromeInt16(
      filter,
      width,
      height,
      pixels,
      output,
    );
    return;
  }

  throw UnsupportedError('Unsupported pixel type: ${pixels.runtimeType}');
}

void _processConvolutionFilter5x5ForMonochromeUint8(
  ConvolutionFilter filter,
  int width,
  int height,
  Uint8List pixels,
  Int32List output,
) {
  _processConvolutionFilter5x5Core(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter5x5ForMonochromeInt8(
  ConvolutionFilter filter,
  int width,
  int height,
  Int8List pixels,
  Int32List output,
) {
  _processConvolutionFilter5x5Core(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter5x5ForMonochromeUint16(
  ConvolutionFilter filter,
  int width,
  int height,
  Uint16List pixels,
  Int32List output,
) {
  _processConvolutionFilter5x5Core(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter5x5ForMonochromeInt16(
  ConvolutionFilter filter,
  int width,
  int height,
  Int16List pixels,
  Int32List output,
) {
  _processConvolutionFilter5x5Core(
    filter,
    width,
    height,
    (int index) => pixels[index],
    output,
  );
}

void _processConvolutionFilter5x5Core(
  ConvolutionFilter filter,
  int width,
  int height,
  int Function(int index) px,
  Int32List output,
) {
  final matrix = filter.matrix;
  if (matrix == null || matrix.length < 25) {
    return;
  }

  double normalization = filter.normalization;
  if (normalization == 0.0) {
    normalization = 1.0;
  }
  final double normalizationInv = 1.0 / normalization;

  final m0 = matrix[0];
  final m1 = matrix[1];
  final m2 = matrix[2];
  final m3 = matrix[3];
  final m4 = matrix[4];
  final m5 = matrix[5];
  final m6 = matrix[6];
  final m7 = matrix[7];
  final m8 = matrix[8];
  final m9 = matrix[9];
  final m10 = matrix[10];
  final m11 = matrix[11];
  final m12 = matrix[12];
  final m13 = matrix[13];
  final m14 = matrix[14];
  final m15 = matrix[15];
  final m16 = matrix[16];
  final m17 = matrix[17];
  final m18 = matrix[18];
  final m19 = matrix[19];
  final m20 = matrix[20];
  final m21 = matrix[21];
  final m22 = matrix[22];
  final m23 = matrix[23];
  final m24 = matrix[24];

  int roundFloor(double v) => v.floor();

  int clampRowBase(int row) {
    if (row < 0) return 0;
    if (row >= height) return (height - 1) * width;
    return row * width;
  }

  for (int j = 0; j < height; j++) {
    int sourcePosUp2 = clampRowBase(j - 2);
    int sourcePosUp1 = clampRowBase(j - 1);
    int sourcePos = j * width;
    int sourcePosDown1 = clampRowBase(j + 1);
    int sourcePosDown2 = clampRowBase(j + 2);
    int outputIndex = j * width;

    // First pixel (x = 0)
    output[outputIndex] = roundFloor((px(sourcePosUp2) * m0 +
            px(sourcePosUp2) * m5 +
            px(sourcePosUp2) * m10 +
            px(sourcePosUp2 + 1) * m15 +
            px(sourcePosUp2 + 2) * m20 +
            px(sourcePosUp1) * m1 +
            px(sourcePosUp1) * m6 +
            px(sourcePosUp1) * m11 +
            px(sourcePosUp1 + 1) * m16 +
            px(sourcePosUp1 + 2) * m21 +
            px(sourcePos) * m2 +
            px(sourcePos) * m7 +
            px(sourcePos) * m12 +
            px(sourcePos + 1) * m17 +
            px(sourcePos + 2) * m22 +
            px(sourcePosDown1) * m3 +
            px(sourcePosDown1) * m8 +
            px(sourcePosDown1) * m13 +
            px(sourcePosDown1 + 1) * m18 +
            px(sourcePosDown1 + 2) * m23 +
            px(sourcePosDown2) * m4 +
            px(sourcePosDown2) * m9 +
            px(sourcePosDown2) * m14 +
            px(sourcePosDown2 + 1) * m19 +
            px(sourcePosDown2 + 2) * m24) *
        normalizationInv);

    sourcePosUp2++;
    sourcePosUp1++;
    sourcePos++;
    sourcePosDown1++;
    sourcePosDown2++;
    outputIndex++;

    // Second pixel (x = 1)
    output[outputIndex] = roundFloor((px(sourcePosUp2 - 1) * m0 +
            px(sourcePosUp2 - 1) * m5 +
            px(sourcePosUp2) * m10 +
            px(sourcePosUp2 + 1) * m15 +
            px(sourcePosUp2 + 2) * m20 +
            px(sourcePosUp1 - 1) * m1 +
            px(sourcePosUp1 - 1) * m6 +
            px(sourcePosUp1) * m11 +
            px(sourcePosUp1 + 1) * m16 +
            px(sourcePosUp1 + 2) * m21 +
            px(sourcePos - 1) * m2 +
            px(sourcePos - 1) * m7 +
            px(sourcePos) * m12 +
            px(sourcePos + 1) * m17 +
            px(sourcePos + 2) * m22 +
            px(sourcePosDown1 - 1) * m3 +
            px(sourcePosDown1 - 1) * m8 +
            px(sourcePosDown1) * m13 +
            px(sourcePosDown1 + 1) * m18 +
            px(sourcePosDown1 + 2) * m23 +
            px(sourcePosDown2 - 1) * m4 +
            px(sourcePosDown2 - 1) * m9 +
            px(sourcePosDown2) * m14 +
            px(sourcePosDown2 + 1) * m19 +
            px(sourcePosDown2 + 2) * m24) *
        normalizationInv);

    sourcePosUp2++;
    sourcePosUp1++;
    sourcePos++;
    sourcePosDown1++;
    sourcePosDown2++;
    outputIndex++;

    // Middle pixels (x = 2 .. width-3)
    for (int i = 2; i < width - 2; i++) {
      output[outputIndex] = roundFloor((px(sourcePosUp2 - 2) * m0 +
              px(sourcePosUp2 - 1) * m5 +
              px(sourcePosUp2) * m10 +
              px(sourcePosUp2 + 1) * m15 +
              px(sourcePosUp2 + 2) * m20 +
              px(sourcePosUp1 - 2) * m1 +
              px(sourcePosUp1 - 1) * m6 +
              px(sourcePosUp1) * m11 +
              px(sourcePosUp1 + 1) * m16 +
              px(sourcePosUp1 + 2) * m21 +
              px(sourcePos - 2) * m2 +
              px(sourcePos - 1) * m7 +
              px(sourcePos) * m12 +
              px(sourcePos + 1) * m17 +
              px(sourcePos + 2) * m22 +
              px(sourcePosDown1 - 2) * m3 +
              px(sourcePosDown1 - 1) * m8 +
              px(sourcePosDown1) * m13 +
              px(sourcePosDown1 + 1) * m18 +
              px(sourcePosDown1 + 2) * m23 +
              px(sourcePosDown2 - 2) * m4 +
              px(sourcePosDown2 - 1) * m9 +
              px(sourcePosDown2) * m14 +
              px(sourcePosDown2 + 1) * m19 +
              px(sourcePosDown2 + 2) * m24) *
          normalizationInv);

      sourcePosUp2++;
      sourcePosUp1++;
      sourcePos++;
      sourcePosDown1++;
      sourcePosDown2++;
      outputIndex++;
    }

    // Last-but-one pixel (x = width-2)
    output[outputIndex] = roundFloor((px(sourcePosUp2 - 2) * m0 +
            px(sourcePosUp2 - 1) * m5 +
            px(sourcePosUp2) * m10 +
            px(sourcePosUp2 + 1) * m15 +
            px(sourcePosUp2 + 1) * m20 +
            px(sourcePosUp1 - 2) * m1 +
            px(sourcePosUp1 - 1) * m6 +
            px(sourcePosUp1) * m11 +
            px(sourcePosUp1 + 1) * m16 +
            px(sourcePosUp1 + 1) * m21 +
            px(sourcePos - 2) * m2 +
            px(sourcePos - 1) * m7 +
            px(sourcePos) * m12 +
            px(sourcePos + 1) * m17 +
            px(sourcePos + 1) * m22 +
            px(sourcePosDown1 - 2) * m3 +
            px(sourcePosDown1 - 1) * m8 +
            px(sourcePosDown1) * m13 +
            px(sourcePosDown1 + 1) * m18 +
            px(sourcePosDown1 + 1) * m23 +
            px(sourcePosDown2 - 2) * m4 +
            px(sourcePosDown2 - 1) * m9 +
            px(sourcePosDown2) * m14 +
            px(sourcePosDown2 + 1) * m19 +
            px(sourcePosDown2 + 1) * m24) *
        normalizationInv);

    sourcePosUp2++;
    sourcePosUp1++;
    sourcePos++;
    sourcePosDown1++;
    sourcePosDown2++;
    outputIndex++;

    // Last pixel (x = width-1)
    output[outputIndex] = roundFloor((px(sourcePosUp2 - 2) * m0 +
            px(sourcePosUp2 - 1) * m5 +
            px(sourcePosUp2) * m10 +
            px(sourcePosUp2) * m15 +
            px(sourcePosUp2) * m20 +
            px(sourcePosUp1 - 2) * m1 +
            px(sourcePosUp1 - 1) * m6 +
            px(sourcePosUp1) * m11 +
            px(sourcePosUp1) * m16 +
            px(sourcePosUp1) * m21 +
            px(sourcePos - 2) * m2 +
            px(sourcePos - 1) * m7 +
            px(sourcePos) * m12 +
            px(sourcePos) * m17 +
            px(sourcePos) * m22 +
            px(sourcePosDown1 - 2) * m3 +
            px(sourcePosDown1 - 1) * m8 +
            px(sourcePosDown1) * m13 +
            px(sourcePosDown1) * m18 +
            px(sourcePosDown1) * m23 +
            px(sourcePosDown2 - 2) * m4 +
            px(sourcePosDown2 - 1) * m9 +
            px(sourcePosDown2) * m14 +
            px(sourcePosDown2) * m19 +
            px(sourcePosDown2) * m24) *
        normalizationInv);
  }
}

void processConvolutionFilterRGBLine3x3({
  required int width,
  required int height,
  required List<double> matrix,
  required double normalizationInv,
  required int topLineOffset,
  required int lineOffset,
  required int bottomLineOffset,
  required Uint8List pixels,
  required int rgbOrder,
  required Uint8List output,
  required int outputOffset,
}) {
  int blockLen = width * 3;
  final List<int> blocks = <int>[];

  if (rgbOrder == 0) {
    blocks.add(0);
  } else {
    blockLen = width;
    blocks.add(0);
    blocks.add(blockLen);
    blocks.add(blockLen * 2);
  }

  final int pixSize = (rgbOrder == 0) ? 3 : 1;

  for (final int block in blocks) {
    int top1 = topLineOffset + block;
    int middle1 = lineOffset + block;
    int bottom1 = bottomLineOffset + block;
    int out = outputOffset + block;

    // First pixel
    for (int i = 0; i < pixSize; i++) {
      int value = ((pixels[top1] * matrix[3] +
                  pixels[top1 + pixSize] * matrix[6] +
                  pixels[middle1] * matrix[4] +
                  pixels[middle1 + pixSize] * matrix[7] +
                  pixels[bottom1] * matrix[5] +
                  pixels[bottom1 + pixSize] * matrix[8]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      middle1++;
      bottom1++;
      out++;
    }

    // Other pixels
    for (int i = pixSize; i < blockLen - pixSize; i++) {
      int value = ((pixels[top1 - pixSize] * matrix[0] +
                  pixels[top1] * matrix[3] +
                  pixels[top1 + pixSize] * matrix[6] +
                  pixels[middle1 - pixSize] * matrix[1] +
                  pixels[middle1] * matrix[4] +
                  pixels[middle1 + pixSize] * matrix[7] +
                  pixels[bottom1 - pixSize] * matrix[2] +
                  pixels[bottom1] * matrix[5] +
                  pixels[bottom1 + pixSize] * matrix[8]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      middle1++;
      bottom1++;
      out++;
    }

    // Last pixel
    for (int i = 0; i < pixSize; i++) {
      int value = ((pixels[top1 - pixSize] * matrix[0] +
                  pixels[top1] * matrix[3] +
                  pixels[middle1 - pixSize] * matrix[1] +
                  pixels[middle1] * matrix[4] +
                  pixels[bottom1 - pixSize] * matrix[2] +
                  pixels[bottom1] * matrix[5]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      middle1++;
      bottom1++;
      out++;
    }
  }
}

void processConvolutionFilterRGBLine5x5({
  required int width,
  required int height,
  required List<double> matrix,
  required double normalizationInv,
  required int topLineOffset1,
  required int topLineOffset2,
  required int lineOffset,
  required int bottomLineOffset1,
  required int bottomLineOffset2,
  required Uint8List pixels,
  required int rgbOrder,
  required Uint8List output,
  required int outputOffset,
}) {
  int blockLen = width * 3;
  final List<int> blocks = <int>[];

  if (rgbOrder == 0) {
    blocks.add(0);
  } else {
    blockLen = width;
    blocks.add(0);
    blocks.add(width * height);
    blocks.add(width * height * 2);
  }

  final int pixSize = (rgbOrder == 0) ? 3 : 1;

  for (final int block in blocks) {
    int top1 = topLineOffset1 + block;
    int top2 = topLineOffset2 + block;
    int middle1 = lineOffset + block;
    int bottom1 = bottomLineOffset1 + block;
    int bottom2 = bottomLineOffset2 + block;
    int out = outputOffset + block;

    // First pixel
    for (int i = 0; i < pixSize; i++) {
      int value = ((pixels[top2] * matrix[0] +
                  pixels[top2] * matrix[5] +
                  pixels[top2] * matrix[10] +
                  pixels[top2 + pixSize] * matrix[15] +
                  pixels[top2 + pixSize * 2] * matrix[20] +
                  pixels[top1] * matrix[1] +
                  pixels[top1] * matrix[6] +
                  pixels[top1] * matrix[11] +
                  pixels[top1 + pixSize] * matrix[16] +
                  pixels[top1 + pixSize * 2] * matrix[21] +
                  pixels[middle1] * matrix[2] +
                  pixels[middle1] * matrix[7] +
                  pixels[middle1] * matrix[12] +
                  pixels[middle1 + pixSize] * matrix[17] +
                  pixels[middle1 + pixSize * 2] * matrix[22] +
                  pixels[bottom1] * matrix[3] +
                  pixels[bottom1] * matrix[8] +
                  pixels[bottom1] * matrix[13] +
                  pixels[bottom1 + pixSize] * matrix[18] +
                  pixels[bottom1 + pixSize * 2] * matrix[23] +
                  pixels[bottom2] * matrix[4] +
                  pixels[bottom2] * matrix[9] +
                  pixels[bottom2] * matrix[14] +
                  pixels[bottom2 + pixSize] * matrix[19] +
                  pixels[bottom2 + pixSize * 2] * matrix[24]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      top2++;
      middle1++;
      bottom1++;
      bottom2++;
      out++;
    }

    // Second pixel
    for (int i = 0; i < pixSize; i++) {
      int value = ((pixels[top2 - pixSize] * matrix[0] +
                  pixels[top2 - pixSize] * matrix[5] +
                  pixels[top2] * matrix[10] +
                  pixels[top2 + pixSize] * matrix[15] +
                  pixels[top2 + pixSize * 2] * matrix[20] +
                  pixels[top1 - pixSize] * matrix[1] +
                  pixels[top1 - pixSize] * matrix[6] +
                  pixels[top1] * matrix[11] +
                  pixels[top1 + pixSize] * matrix[16] +
                  pixels[top1 + pixSize * 2] * matrix[21] +
                  pixels[middle1 - pixSize] * matrix[2] +
                  pixels[middle1 - pixSize] * matrix[7] +
                  pixels[middle1] * matrix[12] +
                  pixels[middle1 + pixSize] * matrix[17] +
                  pixels[middle1 + pixSize * 2] * matrix[22] +
                  pixels[bottom1 - pixSize] * matrix[3] +
                  pixels[bottom1 - pixSize] * matrix[8] +
                  pixels[bottom1] * matrix[13] +
                  pixels[bottom1 + pixSize] * matrix[18] +
                  pixels[bottom1 + pixSize * 2] * matrix[23] +
                  pixels[bottom2 - pixSize] * matrix[4] +
                  pixels[bottom2 - pixSize] * matrix[9] +
                  pixels[bottom2] * matrix[14] +
                  pixels[bottom2 + pixSize] * matrix[19] +
                  pixels[bottom2 + pixSize * 2] * matrix[24]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      top2++;
      middle1++;
      bottom1++;
      bottom2++;
      out++;
    }

    // Other pixels
    for (int i = pixSize * 2; i < blockLen - pixSize * 2; i++) {
      int value = ((pixels[top2 - pixSize * 2] * matrix[0] +
                  pixels[top2 - pixSize] * matrix[5] +
                  pixels[top2] * matrix[10] +
                  pixels[top2 + pixSize] * matrix[15] +
                  pixels[top2 + pixSize * 2] * matrix[20] +
                  pixels[top1 - pixSize * 2] * matrix[1] +
                  pixels[top1 - pixSize] * matrix[6] +
                  pixels[top1] * matrix[11] +
                  pixels[top1 + pixSize] * matrix[16] +
                  pixels[top1 + pixSize * 2] * matrix[21] +
                  pixels[middle1 - pixSize * 2] * matrix[2] +
                  pixels[middle1 - pixSize] * matrix[7] +
                  pixels[middle1] * matrix[12] +
                  pixels[middle1 + pixSize] * matrix[17] +
                  pixels[middle1 + pixSize * 2] * matrix[22] +
                  pixels[bottom1 - pixSize * 2] * matrix[3] +
                  pixels[bottom1 - pixSize] * matrix[8] +
                  pixels[bottom1] * matrix[13] +
                  pixels[bottom1 + pixSize] * matrix[18] +
                  pixels[bottom1 + pixSize * 2] * matrix[23] +
                  pixels[bottom2 - pixSize * 2] * matrix[4] +
                  pixels[bottom2 - pixSize] * matrix[9] +
                  pixels[bottom2] * matrix[14] +
                  pixels[bottom2 + pixSize] * matrix[19] +
                  pixels[bottom2 + pixSize * 2] * matrix[24]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      top2++;
      middle1++;
      bottom1++;
      bottom2++;
      out++;
    }

    // Pixel just before the last pixel
    for (int i = 0; i < pixSize; i++) {
      int value = ((pixels[top2 - pixSize * 2] * matrix[0] +
                  pixels[top2 - pixSize] * matrix[5] +
                  pixels[top2] * matrix[10] +
                  pixels[top2 + pixSize] * matrix[15] +
                  pixels[top2 + pixSize] * matrix[20] +
                  pixels[top1 - pixSize * 2] * matrix[1] +
                  pixels[top1 - pixSize] * matrix[6] +
                  pixels[top1] * matrix[11] +
                  pixels[top1 + pixSize] * matrix[16] +
                  pixels[top1 + pixSize] * matrix[21] +
                  pixels[middle1 - pixSize * 2] * matrix[2] +
                  pixels[middle1 - pixSize] * matrix[7] +
                  pixels[middle1] * matrix[12] +
                  pixels[middle1 + pixSize] * matrix[17] +
                  pixels[middle1 + pixSize] * matrix[22] +
                  pixels[bottom1 - pixSize * 2] * matrix[3] +
                  pixels[bottom1 - pixSize] * matrix[8] +
                  pixels[bottom1] * matrix[13] +
                  pixels[bottom1 + pixSize] * matrix[18] +
                  pixels[bottom1 + pixSize] * matrix[23] +
                  pixels[bottom2 - pixSize * 2] * matrix[4] +
                  pixels[bottom2 - pixSize] * matrix[9] +
                  pixels[bottom2] * matrix[14] +
                  pixels[bottom2 + pixSize] * matrix[19] +
                  pixels[bottom2 + pixSize] * matrix[24]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      top2++;
      middle1++;
      bottom1++;
      bottom2++;
      out++;
    }

    // Last pixel
    for (int i = 0; i < pixSize; i++) {
      int value = ((pixels[top2 - pixSize * 2] * matrix[0] +
                  pixels[top2 - pixSize] * matrix[5] +
                  pixels[top2] * matrix[10] +
                  pixels[top2] * matrix[15] +
                  pixels[top2] * matrix[20] +
                  pixels[top1 - pixSize * 2] * matrix[1] +
                  pixels[top1 - pixSize] * matrix[6] +
                  pixels[top1] * matrix[11] +
                  pixels[top1] * matrix[16] +
                  pixels[top1] * matrix[21] +
                  pixels[middle1 - pixSize * 2] * matrix[2] +
                  pixels[middle1 - pixSize] * matrix[7] +
                  pixels[middle1] * matrix[12] +
                  pixels[middle1] * matrix[17] +
                  pixels[middle1] * matrix[22] +
                  pixels[bottom1 - pixSize * 2] * matrix[3] +
                  pixels[bottom1 - pixSize] * matrix[8] +
                  pixels[bottom1] * matrix[13] +
                  pixels[bottom1] * matrix[18] +
                  pixels[bottom1] * matrix[23] +
                  pixels[bottom2 - pixSize * 2] * matrix[4] +
                  pixels[bottom2 - pixSize] * matrix[9] +
                  pixels[bottom2] * matrix[14] +
                  pixels[bottom2] * matrix[19] +
                  pixels[bottom2] * matrix[24]) *
              normalizationInv)
          .floor();

      value = math.max(0, math.min(value, 255));
      output[out] = value;

      top1++;
      top2++;
      middle1++;
      bottom1++;
      bottom2++;
      out++;
    }
  }
}

void processConvolutionFilter3x3ForRGBData({
  required ConvolutionFilter filter,
  required int width,
  required int height,
  required Uint8List pixels,
  required int rgbOrder,
  required Uint8List output,
}) {
  double normalization = filter.normalization;
  List<double> matrix = filter.matrix;
  if (matrix.length < 9) {
    return;
  }

  if (normalization == 0.0) normalization = 1.0;
  double normalizationInv = (1.0 / normalization);
  int lineStride = rgbOrder == 0 ? width * 3 : width;

  //top line:
  processConvolutionFilterRGBLine3x3(
    width: width,
    height: height,
    matrix: matrix,
    normalizationInv: normalizationInv,
    topLineOffset: 0,
    lineOffset: 0,
    bottomLineOffset: lineStride,
    pixels: pixels,
    rgbOrder: rgbOrder,
    output: output,
    outputOffset: 0,
  );

  //middle lines:
  for (int j = 1; j < height - 1; j++) {
    processConvolutionFilterRGBLine3x3(
      width: width,
      height: height,
      matrix: matrix,
      normalizationInv: normalizationInv,
      topLineOffset: (j - 1) * lineStride,
      lineOffset: j * lineStride,
      bottomLineOffset: (j + 1) * lineStride,
      pixels: pixels,
      rgbOrder: rgbOrder,
      output: output,
      outputOffset: j * lineStride,
    );
  }

  //bottom line:
  processConvolutionFilterRGBLine3x3(
    width: width,
    height: height,
    matrix: matrix,
    normalizationInv: normalizationInv,
    topLineOffset: (height - 2) * lineStride,
    lineOffset: (height - 1) * lineStride,
    bottomLineOffset: (height - 1) * lineStride,
    pixels: pixels,
    rgbOrder: rgbOrder,
    output: output,
    outputOffset: (height - 1) * lineStride,
  );
}

void processConvolutionFilter5x5ForRGBData({
  required ConvolutionFilter filter,
  required int width,
  required int height,
  required Uint8List pixels,
  required int rgbOrder,
  required Uint8List output,
}) {
  double normalization = filter.normalization;
  List<double> matrix = filter.matrix;
  if (matrix.length < 25) {
    return;
  }
  if (normalization == 0.0) normalization = 1.0;
  double normalizationInv = (1.0 / normalization);
  int lineStride = rgbOrder == 0 ? width * 3 : width;

  //first line:
  processConvolutionFilterRGBLine5x5(
    width: width,
    height: height,
    matrix: matrix,
    normalizationInv: normalizationInv,
    topLineOffset1: 0,
    topLineOffset2: 0,
    lineOffset: 0,
    bottomLineOffset1: lineStride,
    bottomLineOffset2: 2 * lineStride,
    pixels: pixels,
    rgbOrder: rgbOrder,
    output: output,
    outputOffset: 0,
  );

  //second lines:
  processConvolutionFilterRGBLine5x5(
    width: width,
    height: height,
    matrix: matrix,
    normalizationInv: normalizationInv,
    topLineOffset1: 0,
    topLineOffset2: 0,
    lineOffset: lineStride,
    bottomLineOffset1: 2 * lineStride,
    bottomLineOffset2: 3 * lineStride,
    pixels: pixels,
    rgbOrder: rgbOrder,
    output: output,
    outputOffset: lineStride,
  );

  //middle lines:
  for (int j = 2; j < height - 2; j++) {
    processConvolutionFilterRGBLine5x5(
      width: width,
      height: height,
      matrix: matrix,
      normalizationInv: normalizationInv,
      topLineOffset1: (j - 1) * lineStride,
      topLineOffset2: (j - 2) * lineStride,
      lineOffset: j * lineStride,
      bottomLineOffset1: (j + 1) * lineStride,
      bottomLineOffset2: (j + 2) * lineStride,
      pixels: pixels,
      rgbOrder: rgbOrder,
      output: output,
      outputOffset: j * lineStride,
    );
  }

  //before last line:
  processConvolutionFilterRGBLine5x5(
    width: width,
    height: height,
    matrix: matrix,
    normalizationInv: normalizationInv,
    topLineOffset1: (height - 3) * lineStride,
    topLineOffset2: (height - 4) * lineStride,
    lineOffset: (height - 2) * lineStride,
    bottomLineOffset1: (height - 1) * lineStride,
    bottomLineOffset2: (height - 1) * lineStride,
    pixels: pixels,
    rgbOrder: rgbOrder,
    output: output,
    outputOffset: (height - 2) * lineStride,
  );

  //last line:
  processConvolutionFilterRGBLine5x5(
    width: width,
    height: height,
    matrix: matrix,
    normalizationInv: normalizationInv,
    topLineOffset1: (height - 2) * lineStride,
    topLineOffset2: (height - 3) * lineStride,
    lineOffset: (height - 1) * lineStride,
    bottomLineOffset1: (height - 1) * lineStride,
    bottomLineOffset2: (height - 1) * lineStride,
    pixels: pixels,
    rgbOrder: rgbOrder,
    output: output,
    outputOffset: (height - 1) * lineStride,
  );
}
