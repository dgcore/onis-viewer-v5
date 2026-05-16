import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/container/controllers/container_controller.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/math/vector3d.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

class OsPropagateFlags {
  static const int currentView = 1 << 0;
  static const int allViews = 1 << 1;
  static const int syncViews = 1 << 2;
  static const int patient = 1 << 3;
  static const int study = 1 << 4;
  static const int series = 1 << 5;
}

///////////////////////////////////////////////////////////////////////
// propagate_property
///////////////////////////////////////////////////////////////////////

class OsPropagateProperty {
  WeakReference<OsContainerPropagateItem>? _wpropagation;
  late String _type;
  late String _name;
  late int _mode;

  OsPropagateProperty(
      {required OsContainerPropagateItem propagation,
      required String type,
      required String name,
      required int mode}) {
    _wpropagation = WeakReference(propagation);
    _type = type;
    _name = name;
    _mode = mode;
  }

  String get name => _name;
  int get mode => _mode;
  String get type => _type;

  void setMode(
      {required int mode,
      required bool refresh,
      List<OsContainerWnd>? modifiedList}) {
    if (_mode != mode) {
      _mode = mode;
      bool doIt = false;
      if ((_mode & OsPropagateFlags.currentView) != 0) doIt = true;
      if ((_mode & OsPropagateFlags.allViews) != 0) doIt = true;
      if ((_mode & OsPropagateFlags.syncViews) != 0) doIt = true;
      if (doIt) {
        OsContainerPropagateItem? propagation = _wpropagation?.target;
        if (propagation != null) {
          List<OsContainerWnd> containers = [];
          propagation.getRegisteredContainers(containers);
          OsContainerWnd? mainContainer = propagation.getMainContainer();
          if (mainContainer != null) {
            int index = containers.indexOf(mainContainer);
            if (index >= 0) {
              containers.removeAt(index);
              containers.insert(0, mainContainer);
            }
          }
          for (OsContainerWnd container in containers) {
            propagation.propagate(
                from: container,
                render: null,
                type: _type,
                refresh: refresh,
                modifiedList: modifiedList);
          }
        }
      }
    }
  }
}

///////////////////////////////////////////////////////////////////////
// container_propagate_item
///////////////////////////////////////////////////////////////////////

class OsContainerPropagateItem {
  final String _id;
  final List<WeakReference<OsContainerWnd>> _wcontainers = [];
  WeakReference<OsContainerWnd>? _wmainContainer;
  final List<OsPropagateProperty> _properties = [];

  OsContainerPropagateItem(this._id) {
    addProperty(
        type: "POS",
        name: "Position",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "ROT",
        name: "Rotation",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "FOV",
        name: "FOV",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "FLIP",
        name: "Flip",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "WL",
        name: "Window Level",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "CL",
        name: "Color Lut",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "OT",
        name: "Opacity Table",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
    addProperty(
        type: "CF",
        name: "Convolution Filter",
        mode: OsPropagateFlags.currentView | OsPropagateFlags.study);
  }

  //-----------------------------------------------------------------------
  //id
  //-----------------------------------------------------------------------

  String get id => _id;

  //-----------------------------------------------------------------------
  //containers
  //-----------------------------------------------------------------------

  void registerContainer(OsContainerWnd container, bool reg) {
    int findIndex = -1;
    for (int i = 0; i < _wcontainers.length; i++) {
      OsContainerWnd? win = _wcontainers[i].target;
      if (win == null) {
        _wcontainers.removeAt(i);
        i--;
      } else if (identical(win, container)) {
        findIndex = i;
      }
    }
    if (reg) {
      if (findIndex == -1) {
        _wcontainers.add(WeakReference(container));
      }
    } else if (findIndex >= 0) {
      _wcontainers.removeAt(findIndex);
      if (identical(getMainContainer(), container) && _wmainContainer != null) {
        _wmainContainer = null;
      }
    }
  }

  void getRegisteredContainers(List<OsContainerWnd> list) {
    for (int i = 0; i < _wcontainers.length; i++) {
      OsContainerWnd? win = _wcontainers[i].target;
      if (win == null) {
        _wcontainers.removeAt(i);
        i--;
      } else {
        list.add(win);
      }
    }
  }

  void setMainContainer(OsContainerWnd container) {
    _wmainContainer = WeakReference(container);
  }

  OsContainerWnd? getMainContainer() {
    return _wmainContainer?.target;
  }

  //-----------------------------------------------------------------------
  //properties
  //-----------------------------------------------------------------------

  bool addProperty(
      {required String type,
      required String name,
      int mode = OsPropagateFlags.currentView | OsPropagateFlags.series}) {
    if (findProperty(type) != null) return false;
    if (type.isEmpty || name.isEmpty) return false;
    OsPropagateProperty prop = OsPropagateProperty(
        propagation: this, type: type, name: name, mode: mode);
    _properties.add(prop);
    return true;
  }

  void removeProperty(String type) {
    for (int i = 0; i < _properties.length; i++) {
      if (_properties[i].type == type) {
        _properties.removeAt(i);
        break;
      }
    }
  }

  OsPropagateProperty? findProperty(String type) {
    for (OsPropagateProperty property in _properties) {
      if (property.type == type) {
        return property;
      }
    }
    return null;
  }

  List<OsPropagateProperty> getListOfProperties() {
    return List.unmodifiable(_properties);
  }

  //-----------------------------------------------------------------------
  //action renderers
  //-----------------------------------------------------------------------

  bool getActionRenderers(
      OsContainerWnd container, String type, List<OsRenderer> list) {
    OsPropagateProperty? property = findProperty(type);
    if (property == null) return false;
    if (shouldPropagateInCurrentView(type)) {
      bool samePatient =
          ((property.mode & OsPropagateFlags.patient) == 0) ? false : true;
      bool sameStudy =
          ((property.mode & OsPropagateFlags.study) == 0) ? false : true;
      bool sameSeries =
          ((property.mode & OsPropagateFlags.series) == 0) ? false : true;
      if (samePatient || sameStudy || sameSeries) {
        bool needSelection = true;
        OsContainerController? controller = container.controller;
        List<entities.Series> displayedSeries = [];
        List<entities.Study> displayedStudies = [];
        List<entities.Patient> displayedPatients = [];
        controller.getDisplayedSeries(displayedSeries);
        for (int i = 0; i < displayedSeries.length; i++) {
          entities.Study? study = displayedSeries[i].study;
          if (study != null) {
            if (!displayedStudies.contains(study)) {
              displayedStudies.add(study);

              entities.Patient? patient = study.patient;
              if (patient != null) {
                if (!displayedPatients.contains(patient)) {
                  displayedPatients.add(patient);
                }
              }
            }
          }
        }
        if (displayedSeries.length == 1) {
          needSelection = false;
        } else if (displayedStudies.length == 1 && sameStudy) {
          needSelection = false;
        } else if (displayedPatients.length == 1 && samePatient) {
          needSelection = false;
        }

        if (needSelection) {
          List<entities.Series> displayedSeries = [];
          List<entities.Study> displayedStudies = [];
          List<entities.Patient> displayedPatients = [];

          List<OsRenderer> renderers = [];
          container.getSelected(renderers);
          for (OsRenderer renderer in renderers) {
            OsGraphicImage? img = renderer.getPrimaryImageItem();
            if (img == null) continue;
            entities.Image? image = img.getImage();
            entities.Series? series = image?.series;
            entities.Study? study = series?.study;
            entities.Patient? patient = study?.patient;
            if (sameSeries) {
              if (series != null && !displayedSeries.contains(series)) {
                displayedSeries.add(series);
                list.add(renderer);
              }
            } else if (sameStudy) {
              if (study != null && !displayedStudies.contains(study)) {
                displayedStudies.add(study);
                list.add(renderer);
              }
            } else if (samePatient) {
              if (patient != null && !displayedPatients.contains(patient)) {
                displayedPatients.add(patient);
                list.add(renderer);
              }
            }
          }
        } else {
          bool done = false;
          OsRenderer? defaultRender = container.getDefaultRenderer();
          if (defaultRender != null) {
            if (!defaultRender.hidden) {
              list.add(defaultRender);
              done = true;
            }
          }
          if (!done) {
            List<OsRenderer> renderers = container.controller.rendererElements;
            for (OsRenderer renderer in renderers) {
              if (!renderer.hidden) {
                list.add(renderer);
                break;
              }
            }
          }
        }
      } else {
        bool done = false;
        OsRenderer? defaultRender = container.getDefaultRenderer();
        if (defaultRender != null) {
          if (!defaultRender.hidden) {
            list.add(defaultRender);
            done = true;
          }
        }
        if (!done) {
          List<OsRenderer> renderers = container.controller.rendererElements;
          for (OsRenderer renderer in renderers) {
            if (!renderer.hidden) {
              list.add(renderer);
              break;
            }
          }
        }
      }
      return list.length != container.controller.rendererElements.length;
    } else {
      container.getSelected(list);
      return false;
    }
  }

  bool haveActionRenderers(OsContainerWnd container, String type) {
    OsPropagateProperty? property = findProperty(type);
    if (property == null) return false;
    if (shouldPropagateInCurrentView(type)) {
      bool samePatient =
          ((property.mode & OsPropagateFlags.patient) == 0) ? false : true;
      bool sameStudy =
          ((property.mode & OsPropagateFlags.study) == 0) ? false : true;
      bool sameSeries =
          ((property.mode & OsPropagateFlags.series) == 0) ? false : true;
      if (samePatient || sameStudy || sameSeries) {
        bool needSelection = true;

        OsContainerController controller = container.controller;

        List<entities.Series> displayedSeries = [];
        List<entities.Study> displayedStudies = [];
        List<entities.Patient> displayedPatients = [];
        controller.getDisplayedSeries(displayedSeries);
        for (int i = 0; i < displayedSeries.length; i++) {
          entities.Study? study = displayedSeries[i].study;
          if (study != null) {
            if (!displayedStudies.contains(study)) {
              displayedStudies.add(study);
              entities.Patient? patient = study.patient;
              if (patient != null) {
                if (!displayedPatients.contains(patient)) {
                  displayedPatients.add(patient);
                }
              }
            }
          }
        }
        if (displayedSeries.length == 1) {
          needSelection = false;
        } else if (displayedStudies.length == 1 && sameStudy) {
          needSelection = false;
        } else if (displayedPatients.length == 1 && samePatient) {
          needSelection = false;
        }

        if (needSelection) {
          return container.haveSelected();
        } else {
          return container.haveVisible();
        }
      } else {
        return container.haveVisible();
      }
    } else {
      return container.haveSelected();
    }
  }

  //-----------------------------------------------------------------------
  //action renderers
  //-----------------------------------------------------------------------

  void onReceivedImage(OsContainerWnd container, OsRenderer render) {
    OsContainerWnd? winnerContainer;
    OsRenderer? winnerRenderer;
    entities.Image? image;
    entities.Series? series;
    entities.Study? study;
    entities.Patient? patient;
    OsGraphicImage? img = render.getPrimaryImageItem();

    image = img?.getImage();
    series = image?.series;
    study = series?.study;
    patient = study?.patient;

    List<String> types = [];
    for (OsPropagateProperty property in _properties) {
      types.add(property.type);
    }

    //For optimizing, we pack the property that have the same mode:
    List<int> optimizedModes = [];
    List<String> optimizeList = [];
    for (final type in types) {
      OsPropagateProperty? prop = findProperty(type);
      if (prop == null) continue;
      bool found = false;
      for (int j = 0; j < optimizedModes.length; j++) {
        if (optimizedModes[j] == prop.mode) {
          optimizeList[j] = "${optimizeList[j]}|$type";
          found = true;
          break;
        }
        if (!found) {
          optimizedModes.add(prop.mode);
          optimizeList.add(type);
        }
      }
    }
    for (int i = 0; i < optimizedModes.length; i++) {
      int currentMode = optimizedModes[i];
      String currentType = optimizeList[i];

      List<OsContainerWnd> containers = [];

      if ((currentMode & OsPropagateFlags.syncViews) != 0) {
      } else if ((currentMode & OsPropagateFlags.allViews) != 0) {
        getRegisteredContainers(containers);
        int it = containers.indexOf(container);
        if (it >= 0) {
          containers.removeAt(it);
          containers.insert(0, container);
        }
      } else if ((currentMode & OsPropagateFlags.currentView) != 0) {
        containers.add(container);
      } else {
        continue;
      }
      for (int j = 0; j < 2; j++) {
        //first pass: try to find a container that displays the series
        //second pass: try all containers
        for (int it3 = 0; it3 < containers.length; it3++) {
          OsContainerController? controller = containers[it3].controller;

          bool candidate = false;
          if (j == 0 &&
              series != null &&
              controller.isSeriesDisplayed(series)) {
            candidate = true;
          } else if (j == 1 &&
              series != null &&
              !controller.isSeriesDisplayed(series)) {
            if ((currentMode & OsPropagateFlags.study) != 0) {
              if (study != null && controller.isStudyDisplayed(study)) {
                candidate = true;
              }
            } else if ((currentMode & OsPropagateFlags.patient) != 0) {
              if (patient != null && controller.isPatientDisplayed(patient)) {
                candidate = true;
              }
            } else if ((currentMode & OsPropagateFlags.series) != 0) {
            } else {
              candidate = true;
            }
          }
          if (!candidate) continue;
          //Search if we can find a matching renderer:
          List<OsRenderer> renderers = controller.rendererElements;
          for (int it4 = 0; it4 < renderers.length; it4++) {
            OsRenderer render1 = renderers[it4];
            if (identical(render1, render)) continue;
            if (!render1.isInitialized()) continue;

            entities.Image? image1;
            entities.Series? series1;
            entities.Study? study1;
            entities.Patient? patient1;
            OsGraphicImage? img1 = render1.getPrimaryImageItem();
            image1 = img1?.getImage();
            series1 = image1?.series;
            study1 = series1?.study;
            patient1 = study1?.patient;
            if (image1 != null) {
              /*if (image1.dicomFile != null) {
                if (identical(series, series1)) {
                  winnerRenderer = render1;
                } else if ((currentMode & OsPropagateFlags.study) != 0) {
                  if (study == study1) winnerRenderer = render1;
                } else if ((currentMode & OsPropagateFlags.patient) != 0) {
                  if (patient == patient1) winnerRenderer = render1;
                } else if ((currentMode & OsPropagateFlags.series) == 0) {
                  winnerRenderer = render1;
                }
                if (winnerRenderer != null) {
                  winnerContainer = containers[it3];
                  break;
                }
              }*/
            }
          }
        }
      }
    }
  }

  //propagation:
  void propagate({
    required OsContainerWnd from,
    required OsRenderer? render,
    required String type,
    bool refresh = true,
    List<OsContainerWnd>? modifiedList,
  }) {
    if (render == null) {
      final renderers = from.controller.rendererElements;
      final uniqueRenderers = <OsRenderer>[];
      final seenSeries = <entities.Series>[];

      for (final renderer in renderers) {
        final img = renderer.getPrimaryImageItem();
        final image = img?.getImage();
        final series = image?.series;
        if (series == null) continue;

        if (!seenSeries.contains(series)) {
          seenSeries.add(series);
          uniqueRenderers.add(renderer);
        }
      }

      for (final renderer in uniqueRenderers) {
        propagate(
          from: from,
          render: renderer,
          type: type,
          refresh: refresh,
          modifiedList: modifiedList,
        );
      }
      return;
    }

    final img = render.getPrimaryImageItem();
    if (img == null) return;

    final types = type.split('|').where((e) => e.isNotEmpty).toList();

    final optimizedModes = <int>[];
    final optimizedTypes = <String>[];

    for (final currentType in types) {
      final prop = findProperty(currentType);
      if (prop == null) continue;

      final index = optimizedModes.indexOf(prop.mode);
      if (index >= 0) {
        optimizedTypes[index] = '${optimizedTypes[index]}|$currentType';
      } else {
        optimizedModes.add(prop.mode);
        optimizedTypes.add(prop.type);
      }
    }

    final containersToRefresh = <OsContainerWnd>[];

    for (int i = 0; i < optimizedModes.length; i++) {
      final currentMode = optimizedModes[i];
      final currentType = optimizedTypes[i];

      final containers = <OsContainerWnd>[];
      var onlySelected = false;

      if ((currentMode & OsPropagateFlags.syncViews) != 0) {
        final synchro = from.getSynchroItem();
        if (synchro != null) {
          synchro.getListOfSynchronizedContainers(containers);
          if (!containers.contains(from)) {
            containers
              ..clear()
              ..add(from);
          }
        } else {
          containers.add(from);
        }
      } else if ((currentMode & OsPropagateFlags.currentView) != 0) {
        containers.add(from);
      } else if ((currentMode & OsPropagateFlags.allViews) != 0) {
        getRegisteredContainers(containers);
      } else {
        containers.add(from);
        onlySelected = true;
      }

      final limitToPatient = (currentMode & OsPropagateFlags.patient) != 0;
      final limitToStudy = (currentMode & OsPropagateFlags.study) != 0;
      final limitToSeries = (currentMode & OsPropagateFlags.series) != 0;

      final sourceImage = img.getImage();
      final targetSeries = sourceImage?.series;
      final targetStudy = targetSeries?.study;
      final targetPatient = targetStudy?.patient;

      for (final container in containers) {
        final controller = container.controller;
        List<OsRenderer> targetRenderers;

        if (limitToPatient || limitToStudy || limitToSeries) {
          targetRenderers = <OsRenderer>[];

          if (sourceImage != null) {
            for (final renderer1 in controller.rendererElements) {
              final img1 = renderer1.getPrimaryImageItem();
              final image1 = img1?.getImage();
              final series1 = image1?.series;
              final study1 = series1?.study;
              final patient1 = study1?.patient;

              var add = false;

              if (limitToPatient &&
                  targetPatient != null &&
                  targetPatient == patient1) {
                add = true;
              } else if (limitToStudy &&
                  targetStudy != null &&
                  targetStudy == study1) {
                add = true;
              } else if (limitToSeries &&
                  targetSeries != null &&
                  targetSeries == series1) {
                add = true;
              }

              if (add && onlySelected && !renderer1.selected) {
                add = false;
              }

              if (add) {
                targetRenderers.add(renderer1);
              }
            }
          }
        } else if (onlySelected) {
          targetRenderers = controller.rendererElements
              .where((renderer1) => renderer1.selected)
              .toList();
        } else {
          targetRenderers = controller.rendererElements;
        }

        final redraw =
            propagate3(from, render, container, targetRenderers, currentType);

        if (redraw && !containersToRefresh.contains(container)) {
          containersToRefresh.add(container);
        }
      }
    }

    if (!refresh) return;

    for (final container in containersToRefresh) {
      container.setCurrentPage(
        index: container.currentPage,
        mode: OsContDraw.osForceRedraw,
      );
    }

    if (modifiedList != null) {
      for (final container in containersToRefresh) {
        if (!modifiedList.contains(container)) {
          modifiedList.add(container);
        }
      }
    }
  }

  /*public propagate2(from:IContainerWnd, renders:IRenderer[], type:string, refresh:boolean = true, modifiedList:IContainerWnd[]|null = null):void {
        for (let it1:number = 0; it1<renders.length; it1++)
            this.propagate(from, renders[it1], type, refresh, modifiedList);
    }*/

  bool propagate3(OsContainerWnd? from, OsRenderer? fromRender,
      OsContainerWnd target, List<OsRenderer> targetRenders, String type) {
    bool redraw = false;

    final types = type.split('|').where((e) => e.isNotEmpty).toList();

    final img = fromRender?.getPrimaryImageItem();
    if (img == null) return false;

    if (types.contains("CL")) {
      final lut = img.getColorLut();
      for (final targetRender in targetRenders) {
        final img1 = targetRender.getPrimaryImageItem();
        if (img1 == null) continue;
        img1.setColorLut(lut);
        redraw = true;
      }
    }

    if (types.contains("OT")) {
      final table = img.getOpacityTable();
      for (final targetRender in targetRenders) {
        final img1 = targetRender.getPrimaryImageItem();
        if (img1 == null) continue;
        img1.setOpacityTable(table);
        redraw = true;
      }
    }

    if (types.contains("CF")) {
      final preset = img.getConvolutionFilter();
      for (final targetRender in targetRenders) {
        final img1 = targetRender.getPrimaryImageItem();
        if (img1 == null) continue;
        img1.setConvolutionFilter(preset);
        redraw = true;
      }
    }

    if (types.contains("WL")) {
      /*final centerWidth = img.getWindowLevelValues();

      if (centerWidth != null) {
        final preset = img.getWindowLevel();

        bool isMonochrome = false;
        final sourceImage = img.getImage();
        final sourceDcm = sourceImage?.dicomFile;

        if (sourceDcm != null) {
          final photometric = sourceDcm.getStringElement(
            DicomTags.tagPhotometricInterpretation,
            null,
            null,
          );

          isMonochrome =
              photometric == "MONOCHROME1" || photometric == "MONOCHROME2";

          if (isMonochrome) {
            final palette = sourceDcm.getStringElement(
              DicomTags.tagRedPaletteColorLookupTableDescriptor,
              null,
              null,
            );
            if (palette.isNotEmpty) {
              isMonochrome = false;
            }
          }
        }

        for (final targetRender in targetRenders) {
          final img1 = targetRender.getPrimaryImageItem();
          if (img1 == null) continue;

          final image1 = img1.getImage();
          final dcm1 = image1?.dicomFile;
          if (dcm1 == null) continue;

          bool isMonochrome1 = false;

          final photometric1 = dcm1.getStringElement(
            DicomTags.tagPhotometricInterpretation,
            null,
            null,
          );

          isMonochrome1 =
              photometric1 == "MONOCHROME1" || photometric1 == "MONOCHROME2";

          if (isMonochrome1) {
            final palette = dcm1.getStringElement(
              DicomTags.tagRedPaletteColorLookupTableDescriptor,
              null,
              null,
            );
            if (palette.isNotEmpty) {
              isMonochrome1 = false;
            }
          }

          if (isMonochrome != isMonochrome1) continue;

          if (preset != null) {
            img1.setWindowLevel(preset, false);
          } else {
            img1.setWindowLevelValues(centerWidth.center, centerWidth.width);
          }
        }

        redraw = true;
      }*/
    }

    bool doPosition = types.contains("POS");
    final bool doRotation = types.contains("ROT");
    final bool doFov = types.contains("FOV");
    final bool doFlip = types.contains("FLIP");

    if (doPosition || doRotation || doFov || doFlip) {
      final cam = fromRender?.getCamera();
      final sourceImage = img.getImage();

      if (cam != null && sourceImage != null) {
        final orientationMat = OsMatrix();
        final haveOrientationMatrix =
            sourceImage.getImageOrientation(orientationMat);

        for (final targetRender in targetRenders) {
          if (identical(targetRender, fromRender)) continue;

          final cam1 = targetRender.getCamera();
          final img1 = targetRender.getPrimaryImageItem();
          final image1 = img1?.getImage();

          if (image1 == null) continue;

          final orientationMat1 = OsMatrix();
          final haveOrientationMatrix1 =
              image1.getImageOrientation(orientationMat1);

          bool canPropagatePosition = doPosition;

          if (canPropagatePosition) {
            if (haveOrientationMatrix != haveOrientationMatrix1) {
              canPropagatePosition = false;
            } else if (haveOrientationMatrix) {
              bool sameOrientation = true;

              if ((1.0 -
                          OsVec3D.scalarProductWidthOffset(
                            orientationMat.mat,
                            8,
                            orientationMat1.mat,
                            8,
                          ))
                      .abs() >
                  0.0001) {
                sameOrientation = false;
              } else if ((1.0 -
                          OsVec3D.scalarProductWidthOffset(
                            orientationMat.mat,
                            0,
                            orientationMat1.mat,
                            0,
                          ))
                      .abs() >
                  0.0001) {
                sameOrientation = false;
              }

              if (!sameOrientation) {
                canPropagatePosition = false;
              }
            }
          }

          if (canPropagatePosition) {
            cam1.pos[0] = cam.pos[0];
            cam1.pos[1] = cam.pos[1];
          }

          if (doRotation) {
            for (int i = 0; i < 3; i++) {
              cam1.rot[i] = cam.rot[i];
            }
          }

          if (doFov) {
            if (cam.isOrthographicMode() && cam1.isOrthographicMode()) {
              if (from != null) {
                final rect = from.getImageBoxRect(0);
                final rect1 = target.getImageBoxRect(0);

                if (rect.width >= 1 && rect1.width >= 1) {
                  cam1.setOrthoWidth(
                    (cam.getOrthoWidth() * rect1.width) / rect.width,
                  );
                }
              }
            }
          }

          if (doFlip) {
            cam1.sca[0] = cam.sca[0];
            cam1.sca[1] = cam.sca[1];
          }

          cam1.setModify(cam.getModify());
          cam1.validateMatrix();
          redraw = true;
        }
      }
    }

    return redraw;
  }

  bool shouldPropagateInCurrentView(String type) {
    OsPropagateProperty? prop = findProperty(type);
    if (prop == null) return false;
    if ((prop.mode & OsPropagateFlags.currentView) != 0) return true;
    if ((prop.mode & OsPropagateFlags.allViews) != 0) return true;
    if ((prop.mode & OsPropagateFlags.syncViews) != 0) return true;
    return false;
  }
}
