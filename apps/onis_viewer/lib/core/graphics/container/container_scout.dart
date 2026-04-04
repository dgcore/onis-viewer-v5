import 'package:onis_viewer/core/dicom/image_region.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

///////////////////////////////////////////////////////////////////////
// OsContainerScoutInfo
///////////////////////////////////////////////////////////////////////

class OsContainerScoutInfo {
  WeakReference<OsContainerWnd>? _wContainer;

  OsContainerWnd? getContainer() {
    return _wContainer?.target;
  }

  void setContainer(OsContainerWnd? container) {
    if (container == null) {
      _wContainer = null;
    } else {
      _wContainer = WeakReference(container);
    }
  }
}

///////////////////////////////////////////////////////////////////////
// container_scout_item
///////////////////////////////////////////////////////////////////////

class OsContainerScoutItem {
  final String _id;
  bool _enable = true;
  bool _limitToSameStudy = true;
  WeakReference<OsContainerWnd>? _wMainContainer;
  final List<OsContainerScoutInfo> _infos = [];

  OsContainerScoutItem(this._id);

  String get id => _id;
  bool get enable => _enable;
  bool get shouldLimitToTheSameStudy => _limitToSameStudy;

  OsContainerScoutInfo? getContainerInfo(OsContainerWnd container) {
    for (int i = 0; i < _infos.length; i++) {
      if (identical(_infos[i].getContainer(), container)) {
        return _infos[i];
      }
    }
    return null;
  }

  OsContainerWnd? getMainContainer() {
    return _wMainContainer?.target;
  }

  set enable(bool value) {
    _enable = value;
    process(null, null);
  }

  set shouldLimitToTheSameStudy(bool limit) {
    _limitToSameStudy = limit;
  }

  void registerContainer(OsContainerWnd container, bool reg) {
    if (reg == true) {
      if (getContainerInfo(container) == null) {
        OsContainerScoutInfo info = OsContainerScoutInfo();
        info.setContainer(container);
        _infos.add(info);
      }
    } else {
      if (identical(getMainContainer(), container)) {
        _wMainContainer = null;
      }
      for (int i = 0; i < _infos.length; i++) {
        if (identical(_infos[i].getContainer(), container)) {
          _infos.removeAt(i);
          break;
        }
      }
    }
  }

  void setMainContainer(OsContainerWnd? container) {
    _wMainContainer = container == null ? null : WeakReference(container);
  }

  void process(
      OsContainerWnd? from, List<OsContainerWnd>? containersToRefresh) {
    bool valid = false;
    OsMatrix mainOrientation = OsMatrix();
    entities.Study? mainStudy;
    entities.Series? mainSeries;
    OsContainerWnd? mainContainer;
    List<double> realSize = [0, 0];
    if (_enable) {
      mainContainer = getMainContainer();
      if (mainContainer != null) {
        //get the selected renderer:
        final controller = mainContainer.controller;

        List<OsRenderer> renderers = [];
        mainContainer.getSelected(renderers);
        if (renderers.length == 1) {
          OsRenderer render = renderers[0];
          OsGraphicImage? img = render.getPrimaryImageItem();
          entities.Image? image = img?.getImage();
          if (image != null) {
            if (image.getImageOrientation(mainOrientation)) valid = true;
            mainSeries = image.series;
            mainStudy = mainSeries?.study;
            if (valid) {
              valid = false;
              ImageRegionInfo? info = image.getRegionInfo();
              if (info != null) {
                if (info.regions.length == 1) {
                  ImageRegion region = info.regions[0];
                  if (region.spatialFormat == OsRsf.none ||
                      region.spatialFormat == OsRsf.twoDim) {
                    if (region.calibratedUnit[0] == region.calibratedUnit[1]) {
                      if (region.calibratedUnit[0] == OsUnit.cm) {
                        valid = true;
                        realSize[0] = info.dimensions[0] *
                            (region.calibratedSpacing[0]).abs() *
                            10.0;
                        realSize[1] = info.dimensions[1] *
                            (region.calibratedSpacing[1]).abs() *
                            10.0;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      if (valid && _limitToSameStudy && mainStudy == null) valid = false;
    }
    for (int i = 0; i < _infos.length; i++) {
      OsContainerWnd? container = _infos[i].getContainer();
      if (container == null) {
        _infos.removeAt(i);
        i--;
      } else {
        bool redraw = false;
        if (container == mainContainer) {
          //reset the container localizer!
          if (container.setShouldDrawLocalizer(
              draw: false,
              study: null,
              series: null,
              mat: null,
              dimensions: null)) {
            redraw = true;
          }
        } else {
          if (valid) {
            if (container.setShouldDrawLocalizer(
                draw: true,
                study: mainStudy,
                series: mainSeries,
                mat: mainOrientation,
                dimensions: realSize)) {
              redraw = true;
            }
          } else {
            //reset the container localizer!
            if (container.setShouldDrawLocalizer(
                draw: false,
                study: null,
                series: null,
                mat: null,
                dimensions: null)) {
              redraw = true;
            }
          }
        }
        if (redraw) {
          if (containersToRefresh == null) {
            container.setCurrentPage(
                index: container.currentPage, mode: OsContDraw.osForceRedraw);
          } else {
            if (!containersToRefresh.contains(container)) {
              containersToRefresh.add(container);
            }
          }
        }
      }
    }
  }
}
