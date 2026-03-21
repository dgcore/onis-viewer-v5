import 'package:onis_viewer/core/dicom/dicom_frame.dart';
import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/renderer/items/item.dart';
import 'package:onis_viewer/core/graphics/renderer/items/responder.dart';
import 'package:onis_viewer/core/models/database/color_lut.dart';
import 'package:onis_viewer/core/models/database/convolution_filter.dart';
import 'package:onis_viewer/core/models/database/opacity_table.dart';
import 'package:onis_viewer/core/models/database/window_level.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/result/result.dart';

class OsGraphicImage extends OsGraphicResponder {
  ColorLut? _colorLut;
  OpacityTable? _opacityTable;
  ConvolutionFilter? _convolutionFilter;
  WindowLevel? _windowLevelPreset;

  bool _isDirty = true;
  double _windowWidth = double.infinity;
  double _windowCenter = double.infinity;

  WeakReference<entities.Series>? _wseries;
  WeakReference<entities.Image>? _wimage;

  List<DicomFrame?> _frames = [];
  int _currentFrame = 0;

  OsDriverImage? _texture;
  int _filterType = 0;
  bool _showAllOverlays = false;
  OsResult _drawStatus = OsResult();
  //final List<OsGraphicAnnotation> _annotations = [];

  OsGraphicImage([String name = ''])
      : super(type: OsRenderItemType.osImageItem, name: name) {
    _isDirty = true;
    _currentFrame = 0;
  }

  @override
  OsGraphicItem clone() {
    final image = OsGraphicImage(getName());
    image.copyProperties(this);
    return image;
  }

  @override
  bool copyProperties(OsGraphicItem from) {
    final ret = super.copyProperties(from);

    final img = from as OsGraphicImage;

    if (img._wseries != null) {
      final series = img._wseries!.target;
      if (series != null) {
        _wseries = WeakReference<entities.Series>(series);
      }
    }

    if (img._wimage != null) {
      final img1 = img._wimage!.target;
      if (img1 != null) {
        _wimage = WeakReference<entities.Image>(img1);
      }
    }

    final frameCount = img.getFrameCount();
    if (frameCount > 0) {
      _allocateFrames(frameCount);
    }

    _currentFrame = img._currentFrame;
    _windowWidth = img._windowWidth;
    _windowCenter = img._windowCenter;
    _filterType = img._filterType;
    _drawStatus = img._drawStatus;
    _showAllOverlays = img._showAllOverlays;

    return ret;
  }

  void setImage(entities.Image img) {
    _wimage = null;
    _wseries = null;
    _releaseFrames();
    _wimage = WeakReference<entities.Image>(img);
    final frameCount = img.getFrameCount();
    _allocateFrames(frameCount);
  }

  entities.Image? getImage() {
    return _wimage?.target;
  }

  void setNullImage(entities.Series? series) {
    _wimage = null;
    _wseries = series != null ? WeakReference<entities.Series>(series) : null;
  }

  entities.Series? isNullImage() {
    return _wseries?.target;
  }

  void setLoadImageIndex(int index) {}

  int getLoadImageIndex() => 0;

  bool getRealSize(List<double> realSize) => false;

  bool setCurrentFrame(int index) {
    if (index < 0 || index >= _frames.length) {
      return false;
    }
    _currentFrame = index;
    _isDirty = true;
    return true;
  }

  int getCurrentFrame() => _currentFrame;

  int getFrameCount() => _frames.length;

  DicomFrame? getFrame(int index) {
    if (index >= 0 && index < _frames.length) {
      return _frames[index];
    }
    return null;
  }

  void setFrame(int index, DicomFrame? frame) {
    if (index >= 0 && index < _frames.length) {
      if (_frames[index] != null) {
        if (identical(_frames[index], frame)) {
          return;
        }
      }
      _frames[index] = frame;
    }
  }

  /*@override
  void willDraw(OsWillDrawInfo info, bool propagate) {
    if (info.context == null) {
      return;
    }

    if (info.render != null) {
      setFilterType(info.render!.getFilterType());
    }

    if (_texture == null) {
      final driver = info.context!.getDriver();
      if (driver != null) {
        _texture = driver.createImage();
      }
    }

    final loadStatus = getLoadStatus();

    if (_texture != null &&
        (loadStatus.status == RESULT.osrspSuccess ||
            loadStatus.status == RESULT.osrspStreaming)) {
      _texture!.setFilterType(getFilterType());

      bool regenerate = _isDirty;
      if (_texture!.willDraw(info.context!)) {
        regenerate = true;
      }

      final imageSize = <double>[128, 128];
      final image = getImage();

      if (image != null) {
        OsDicomFrame? frame = getFrame(_currentFrame);

        if (frame != null) {
          final dcm1 = image.getDicomFile();
          if (dcm1 != null &&
              frame.getIntermediatePixelData() !=
                  dcm1.getIntermediatePixelData(_currentFrame)) {
            setFrame(_currentFrame, null);
            frame = null;
            regenerate = true;
          } else {
            final interData = frame.getIntermediatePixelData();
            if (interData == null ||
                frame.getCurrentResolution() != interData.currentRes) {
              setFrame(_currentFrame, null);
              frame = null;
              regenerate = true;
            }
          }
        }

        if (frame == null) {
          for (int i = 0; i < 2; i++) {
            frame = image.extractFrame(_currentFrame, loadStatus);
            if (frame != null) {
              setFrame(_currentFrame, frame);
              frame.release();
              frame = getFrame(_currentFrame);
              regenerate = true;
              break;
            } else {
              if (loadStatus.reason == RESULT.eosMemory && i == 0) {
                if (info.render == null) {
                  break;
                }
              } else {
                break;
              }
            }
          }
        }

        _drawStatus.status = loadStatus.status;
        _drawStatus.reason = loadStatus.reason;
        _drawStatus.info = loadStatus.info;

        if (frame != null && regenerate) {
          frame.setColorLut(getColorLut());
          frame.setConvolutionFilter(getConvolutionFilter());
          frame.setOpacityTable(getOpacityTable());
          frame.showAllOverlays(_showAllOverlays);

          if (_windowWidth == VALUE.f64Max || _windowCenter == VALUE.f64Max) {
            final centerWidth = <double>[0, 0];
            frame.getOriginalWindowLevel(centerWidth);
            frame.setWindowLevel(centerWidth[0], centerWidth[1]);
            _windowWidth = centerWidth[1];
            _windowCenter = centerWidth[0];
          } else {
            frame.setWindowLevel(_windowCenter, _windowWidth);
          }

          _texture!.initWithFrame(frame);
        }

        if (frame != null) {
          frame.getDimensions(imageSize);

          OsImageRegion? region;
          final regions = <OsImageRegion>[];
          final deleteRegions = image.getRegionsForFrame(frame, regions);

          if (regions.length == 1) {
            final tmp = regions[0];
            if (tmp.x0 == 0 &&
                tmp.y0 == 0 &&
                tmp.x1 == imageSize[0] - 1 &&
                tmp.y1 == imageSize[1] - 1) {
              if (tmp.spatialFormat == OS_RSF.twoDim) {
                if (tmp.calibratedUnit[0] == tmp.calibratedUnit[1]) {
                  if (tmp.calibratedUnit[0] == OS_UNIT.cm ||
                      tmp.calibratedUnit[0] == OS_UNIT.none) {
                    region = tmp;
                  }
                }
              }
            }
          }

          if (region != null) {
            sca[0] = imageSize[0] * region.calibratedSpacing[0].abs();
            sca[1] = imageSize[1] * region.calibratedSpacing[1].abs();
          } else {
            sca[0] = imageSize[0];
            sca[1] = imageSize[1];
          }

          if (deleteRegions) {
            for (final region in regions) {
              region.destroy();
            }
          }
        }

        validateMatrix();
        _isDirty = false;
      }
    } else {
      _isDirty = true;
    }

    if (_drawStatus.status == RESULT.osrspSuccess) {
      for (final annot in _annotations) {
        annot.willDraw(info, propagate);
      }
    }

    super.willDraw(info, propagate);
  }

  @override
  void draw(OsDriver driver, OsRenderInfo info) {
    info.pushMatrix();

    if (_texture != null &&
        (_drawStatus.status == RESULT.osrspSuccess ||
            _drawStatus.status == RESULT.osrspStreaming)) {
      final filterType = info.render != null ? info.render!.getFilterType() : 0;
      _texture!.setFilterType(filterType);
      info.applyWorldTransformation(localMatrix);

      if (visible) {
        _texture!.draw(driver, info, false);
      }
    }

    super.draw(driver, info);
    info.popMatrix();
  }*/

  /*void drawAnnotations(OsDriver driver, OsRenderInfo info) {
    for (final annot in _annotations) {
      annot.draw(driver, info);
    }
  }*/

  void setFilterType(int type) {
    _filterType = type;
  }

  int getFilterType() => _filterType;

  @override
  bool isDirty([bool propagate = false]) {
    if (_isDirty) {
      return true;
    }
    return super.isDirty(propagate);
  }

  @override
  void setDirty(bool dirty) {
    _isDirty = dirty;
  }

  /*@override
  void releaseMemory(IRenderer render, int level, bool propagate) {
    if (level == 0 || level == 2) {
      if (_texture != null) {
        _texture!.destroy();
        _texture = null;
        _isDirty = true;
      }
    }

    if (level == 1 || level == 2) {
      for (int i = 0; i < _frames.length; i++) {
        final frame = _frames[i];
        if (frame != null) {
          frame.release();
          _frames[i] = null;
        }
      }
    }

    for (final annot in _annotations) {
      annot.releaseMemory(render, level, propagate);
    }

    super.releaseMemory(render, level, propagate);
  }*/

  void setColorLut(ColorLut? preset) {
    _colorLut = preset;
    _isDirty = true;
  }

  ColorLut? getColorLut() => _colorLut;

  void setOpacityTable(OpacityTable? preset) {
    _opacityTable = preset;
    _isDirty = true;
  }

  OpacityTable? getOpacityTable() => _opacityTable;

  void setConvolutionFilter(ConvolutionFilter? preset) {
    _convolutionFilter = preset;
    _isDirty = true;
  }

  ConvolutionFilter? getConvolutionFilter() => _convolutionFilter;

  void setWindowLevel(WindowLevel? preset, bool resetOriginal) {
    _windowLevelPreset = preset;
    _isDirty = true;

    if (preset == null) {
      if (resetOriginal) {
        _windowWidth = double.infinity;
        _windowCenter = double.infinity;
        _isDirty = true;
      }
    } else {
      _windowWidth = preset.width;
      _windowCenter = preset.center;
    }
  }

  WindowLevel? getWindowLevel() => _windowLevelPreset;

  void setWindowLevelValues(double center, double width) {
    _windowLevelPreset = null;
    _windowCenter = center;
    _windowWidth = width;
    _isDirty = true;
  }

  (double center, double width)? getWindowLevelValues() {
    if (_windowCenter == double.infinity || _windowWidth == double.infinity) {
      final image = getImage();
      if (image != null) {
        DicomFrame? frame = getFrame(_currentFrame);
        if (frame != null) {
          return frame.getOriginalWindowLevel();
        } else {
          final file = image.dicomFile;
          if (file != null) {
            (double, double)? windowLevel = file.windowLevel;
            if (windowLevel != null) {
              frame = file.extractFrame(0, null);
              if (frame != null) {
                return frame.getOriginalWindowLevel();
              } else {
                return null;
              }
            } else {
              return windowLevel;
            }
          }
        }
      }
      return null;
    } else {
      return (_windowCenter, _windowWidth);
    }
  }

  /*bool addAnnotation(OsGraphicAnnotation annot, OsGraphicItem? parent) {
    if (_annotations.contains(annot)) {
      return false;
    }

    if (annot.getParent(false) != null) {
      return false;
    }

    if (parent != null) {
      annot.setParent(parent);
    } else {
      annot.retain();
      _annotations.add(annot);
    }

    return true;
  }

  void removeAnnotation(OsGraphicAnnotation annot) {
    if (annot.getParent(false) != null) {
      annot.setParent(null);
    } else {
      final index = _annotations.indexOf(annot);
      if (index >= 0) {
        annot.release();
        _annotations.removeAt(index);
      }
    }
  }

  void regenerateAnnotationSegments() {}

  void getAnnotationList(
    List<OsGraphicAnnotation> list, [
    int mode = 2,
    OsRenderer? render,
  ]) {
    for (final annot in _annotations) {
      list.add(annot);
      annot.getChildrenByType(list, OsRenderItemType.osAnnotationItem, false);
    }

    if (mode != 2 && render != null) {
      list.removeWhere((item) {
        if (mode == 0) {
          return item.isSelected(render);
        }
        if (mode == 1) {
          return !item.isSelected(render);
        }
        return false;
      });
    }
  }

  bool unselectAllAnnotations(OsRenderer render) {
    bool ret = false;
    final list = <OsGraphicAnnotation>[];
    getAnnotationList(list, 2);

    for (final annot in list) {
      if (annot.select(false, render)) {
        ret = true;
      }
    }

    return ret;
  }

  bool haveAnnotation(OsGraphicAnnotation annot) {
    OsGraphicAnnotation topParent = annot;
    while (true) {
      final tmp = topParent.getParentAnnotation();
      if (tmp != null) {
        topParent = tmp;
      } else {
        break;
      }
    }

    return _annotations.contains(topParent);
  }

  void resetAnnotationCalculation() {
    final list = <OsGraphicAnnotation>[];
    getAnnotationList(list, 2, null);

    for (final item in list) {
      if (item.have2dSurface()) {
        (item as OsGraphicAnnotationSurface).resetSurface(null);
      }
    }
  }*/

  OsResult getLoadStatus() {
    final image = getImage();
    if (image != null) {
      return image.loadStatus;
    } else {
      final series = isNullImage();
      if (series != null) {
        return series.loadStatus;
      }
    }
    return OsResult();
  }

  OsResult getDrawStatus() {
    final result = getLoadStatus();
    if (result.status == ResultStatus.success) {
      return _drawStatus;
    }
    return result;
  }

  void _allocateFrames(int frameCount) {
    if (_frames.isNotEmpty) {
      return;
    }
    if (frameCount > 0) {
      _frames = List<DicomFrame?>.filled(frameCount, null);
    }
  }

  void _releaseFrames() {
    _frames.clear();
  }
}
