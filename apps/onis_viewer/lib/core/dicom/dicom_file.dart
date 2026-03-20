import 'package:onis_viewer/core/dicom/dicom_frame.dart';
import 'package:onis_viewer/core/dicom/dicom_tags.dart';
import 'package:onis_viewer/core/dicom/image_region.dart';
import 'package:onis_viewer/core/dicom/intermediate_pixel_data.dart';
import 'package:onis_viewer/core/dicom/raw_palette.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/result/result.dart';

class DicomFile {
  final Map<String, dynamic>? _tags;
  List<IntermediatePixelData?> _pixelData = [];
  int _downloadedFrameCount = 0;
  final List<DicomRawPalette?> _palette = [null, null, null];

  DicomFile(this._tags) {
    _allocateIntermediatePixelData();
  }

  /*public getTagList():string[] {
      let ret:string[] = [];
      for (var prop in this._tags) {
        if (this._tags.hasOwnProperty(prop)) {
          ret.push(prop);
        }
      }
      return ret;
    }*/

  String getStringElement(String tag, List<String>? vr, List<bool>? present) {
    if (present != null) present[0] = false;
    if (_tags == null) return '';
    try {
      if (_tags.containsKey(tag)) {
        if (present != null) present[0] = true;
        if (vr != null) vr[0] = _tags[tag]["vr"];
        return _tags[tag]["val"];
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  int getUsElement(String tag, List<bool>? present) {
    if (present != null) present[0] = false;
    if (_tags == null) return 0;
    try {
      if (_tags.containsKey(tag)) {
        if (present != null) present[0] = true;
        return int.parse(_tags[tag]["val"]);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void setUsElement(String tag, int val) {
    if (_tags == null) return;
    _tags[tag] = {"vr": 1, "vm": "US", val: val.toString()};
  }

  int getFrameCount(bool receivedOnly) {
    if (receivedOnly) return _downloadedFrameCount;
    if (_pixelData.isEmpty) _allocateIntermediatePixelData();
    return _pixelData.length;
  }

  void setPalette(int chanel, DicomRawPalette? palette) {
    if (!identical(_palette[chanel], palette)) {
      _palette[chanel] = palette;
    }
  }

  DicomRawPalette? getPalette(int chanel) {
    return _palette[chanel];
  }

  IntermediatePixelData? getIntermediatePixelData(int index) {
    if (_pixelData.isEmpty) _allocateIntermediatePixelData();
    if (index < 0 || index >= _pixelData.length) return null;
    return _pixelData[index];
  }

  bool setIntermediatePixelData(int index, IntermediatePixelData? data) {
    if (_pixelData.isEmpty) _allocateIntermediatePixelData();
    if (index < 0 || index >= _pixelData.length) return false;
    IntermediatePixelData? tmp = _pixelData[index];
    if (tmp != null) {
      _downloadedFrameCount--;
    }
    _pixelData[index] = data;
    if (data != null) {
      _downloadedFrameCount++;
    }
    return true;
  }

  bool isIntermediatePixelCompleted() {
    if (_pixelData.isEmpty) return false;
    for (int i = 0; i < _pixelData.length; i++) {
      IntermediatePixelData? tmp = _pixelData[i];
      if (tmp == null ||
          tmp.resCount == 0 ||
          tmp.resCount != tmp.resIndex + 1) {
        return false;
      }
    }
    return true;
  }

  bool _allocateIntermediatePixelData() {
    int frameCount = 1;
    String tmp = getStringElement(DicomTags.tagNumberOfFrames, null, null);
    if (tmp.isNotEmpty) {
      try {
        frameCount = int.parse(tmp);
        if (frameCount < 1 || frameCount > 5000) frameCount = 0;
      } catch (e) {
        frameCount = 0;
      }
    }
    if (frameCount >= 1) {
      _pixelData = List<IntermediatePixelData?>.filled(frameCount, null);
      return true;
    }
    return false;
  }

//-----------------------------------------------------------------------
  //window level
  //-----------------------------------------------------------------------

  (double center, double width)? get windowLevel {
    List<double> centerwidth = [0, 1];
    String swidth = getStringElement(DicomTags.tagWindowWidth, null, null);
    String scenter = getStringElement(DicomTags.tagWindowCenter, null, null);
    if (swidth.isEmpty || scenter.isEmpty) {
      /*onis::dicom_sequence_item_ptr seq = dataset->get_sequence_of_items(TAG_FRAME_VOI_LUT_SEQUENCE);
            if (seq != NULL) {
                seq->get_string_element(swidth, TAG_WINDOW_WIDTH, "DS");
                seq->get_string_element(scenter, TAG_WINDOW_CENTER, "DS");
            }*/
    }
    /*if (swidth.empty() || scenter.empty()) {

            //support for GE private tag:
            onis::dicom_sequence_item_ptr seq1 = dataset->get_sequence_of_items(0x52009229UL);
            if (seq1 != NULL) {

                onis::dicom_sequence_item_ptr seq2 = seq1->get_sequence_of_items(TAG_FRAME_VOI_LUT_SEQUENCE);
                if (seq2 != NULL) {

                    seq2->get_string_element(swidth, TAG_WINDOW_WIDTH, "DS");
                    seq2->get_string_element(scenter, TAG_WINDOW_CENTER, "DS");

                }
            }
        }*/
    bool valid = true;
    if (scenter.isEmpty) {
      centerwidth[0] = 0;
      valid = false;
    } else {
      int pos = scenter.indexOf('\\');
      if (pos == -1) {
        centerwidth[0] = double.parse(scenter);
      } else {
        centerwidth[0] = double.parse(scenter.substring(0, pos));
      }
    }
    if (swidth.isEmpty) {
      centerwidth[1] = 1;
      valid = false;
    } else {
      int pos = swidth.indexOf('\\');
      if (pos == -1) {
        centerwidth[1] = double.parse(swidth);
      } else {
        centerwidth[1] = double.parse(swidth.substring(0, pos));
      }
    }
    if (valid && centerwidth[1] == 0.0 && centerwidth[0] == 0.0) valid = false;
    return valid ? (centerwidth[0], centerwidth[1]) : null;
  }

  List<ImageRegion> getRegions() {
    List<ImageRegion> regions = [];
    if (_tags != null && _tags.containsKey('regions')) {
      try {
        for (var item in _tags['regions']) {
          ImageRegion region = ImageRegion();
          region.dataType = int.parse(item['data_type']);
          region.spatialFormat = int.parse(item['spatial_format']);
          region.originalUnit[0] = int.parse(item['units'][0]);
          region.originalUnit[1] = int.parse(item['units'][1]);
          region.calibratedUnit[0] = region.originalUnit[0];
          region.calibratedUnit[1] = region.originalUnit[1];
          region.originalSpacing[0] = double.parse(item['spacing'][0]);
          region.originalSpacing[1] = double.parse(item['spacing'][1]);
          region.calibratedSpacing[0] = region.originalSpacing[0];
          region.calibratedSpacing[1] = region.originalSpacing[1];
          region.x0 = int.parse(item['area'][0]);
          region.x1 = int.parse(item['area'][1]);
          region.y0 = int.parse(item['area'][2]);
          region.y1 = int.parse(item['area'][3]);
          regions.add(region);
        }
      } catch (e) {
        return [];
      }
    }
    return regions;
  }

  DicomFrame? extractFrame(int index, OsResult? result) {
    //the dicom file must exist:
    DicomFrame? frame;
    result ??= OsResult();
    if (_tags == null) {
      result.status = ResultStatus.failure;
      result.reason = OnisErrorCodes.noFile;
    } else {
      //check if the frame index is valid:
      int frameCount = getFrameCount(false);
      if (index < 0 || index >= frameCount) {
        result.status = ResultStatus.failure;
        result.reason = OnisErrorCodes.noFile;
      } else if (_pixelData[index] == null) {
        result.status = ResultStatus.failure;
        result.reason = OnisErrorCodes.missingPixelData;
      } else {
        //is it a mpeg file?
        String transferSyntax =
            getStringElement(DicomTags.tagTransferSyntaxUid, null, null);
        if (transferSyntax == "1.2.840.10008.1.2.4.100" ||
            transferSyntax == "1.2.840.10008.1.2.4.101" ||
            transferSyntax == "1.2.840.10008.1.2.4.102" ||
            transferSyntax == "1.2.840.10008.1.2.4.103") {
          result.status = ResultStatus.failure;
          result.reason = OnisErrorCodes.noSupport;
        } else {
          //read the photometric information:
          String photometric = getStringElement(
              DicomTags.tagPhotometricInterpretation, null, null);
          PhotoType photo = PhotoType.mono2;
          if (photometric == "RGB" ||
              photometric == "YBR_FULL_422" ||
              photometric == "YBR_FULL" ||
              photometric == "YBR_RCT" ||
              photometric == "YBR_ICT") {
            photo = PhotoType.rgb;
          }
          //Handle the palette color:
          IntermediatePixelData? pixelData = _pixelData[index];
          if (pixelData != null) {
            if (photometric == "MONOCHROME1") photo = PhotoType.mono1;
            frame =
                DicomFrame(frameIndex: index, photo: photo, data: pixelData);
            if (photo == PhotoType.mono1 || photo == PhotoType.mono2) {
              //get the rescale slope and intercept
              String intercept =
                  getStringElement(DicomTags.tagRescaleIntercept, null, null);
              String slope =
                  getStringElement(DicomTags.tagRescaleSlope, null, null);
              if (intercept.isNotEmpty && slope.isNotEmpty) {
                frame.rescaleSlope = double.parse(slope);
                frame.intercept = double.parse(intercept);
              }
              String voiLutFunction = getStringElement('0028:1056', null, null);
              if (voiLutFunction == "SIGMOID") {
                frame.voiLutFunction = VoiLutFunction.sigmoid;
              }
              //get the min/max values:
              List<double> minmax = [0, 0];
              IntermediatePixelData? data = frame.intermediatePixelData;
              if (data != null) {
                minmax =
                    data.getMinMaxValues(data.bits, data.isSigned, 1.0, 0.0);
              }
              for (int i = 0; i < 3; i++) {
                frame.setPalette(i, _palette[i]);
              }
              frame.setMinMaxValues(minmax[0], minmax[1]);

              //set the original window level:
              double center = 128.0;
              double width = 256.0;
              if (!frame.havePalette) {
                (double center, double width)? wl = windowLevel;
                if (wl == null) {
                  (double min, double max)? minMax =
                      frame.getMinMaxValues(false);
                  if (minMax != null) {
                    width = minMax.$2 - minMax.$1 + 1.0;
                    center = minMax.$1 + width * 0.5;
                  } else {
                    if (data != null) {
                      if (data.bits == 32 || data.bits > 8) {
                        width = 65536;
                        if (data.isSigned) {
                          center = 0;
                        } else {
                          center = 32768;
                        }
                      } else {
                        width = 256;
                        if (data.isSigned) {
                          center = 0;
                        } else {
                          center = 128;
                        }
                      }
                    }
                  }
                }
              }
              frame.setOriginalWindowLevel(center, width);
              frame.setWindowLevel(center, width);
            }
          }
        }
      }
    }
    return frame;
  }
}
