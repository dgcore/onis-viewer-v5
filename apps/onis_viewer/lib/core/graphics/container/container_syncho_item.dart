///////////////////////////////////////////////////////////////////////
// OsContainerSynchroInfo
///////////////////////////////////////////////////////////////////////
library;

import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/math/vector3d.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

enum OsSyncType {
  page, // 0
  slicePosAbsolute, // 1
  slicePosOffset, // 2
  sliceIdAbsolutem, // 3
  sliceIdOffset //4
}

///////////////////////////////////////////////////////////////////////
// OsContainerSyncOrientationInfo
///////////////////////////////////////////////////////////////////////

class OsContainerSyncOrientationInfo {
  OsMatrix orientation = OsMatrix();
  List<OsContainerWnd> containers = [];
}

class OsContainerSynchroInfo {
  double offset = 0.0;
  bool _haveReference = false;
  bool _resolved = false;
  bool _wishToBeAReference = true;
  WeakReference<OsContainerWnd>? _wcontainer;
  WeakReference<OsContainerWnd>? _wreference;

  //-----------------------------------------------------------------------
  //properties
  //-----------------------------------------------------------------------
  OsContainerWnd? getContainer() {
    return _wcontainer?.target;
  }

  OsContainerWnd? getReferenceContainer() {
    if (_haveReference) {
      return _wreference?.target;
    }
    return null;
  }

  bool get haveReferenceContainer => _haveReference;
  bool get isResolved => _resolved;
  bool get wishToBeAReference => _wishToBeAReference;

  //-----------------------------------------------------------------------
  //operations
  //-----------------------------------------------------------------------

  void setContainer(OsContainerWnd? container) {
    if (container == null) _wcontainer = null;
    _wcontainer = WeakReference<OsContainerWnd>(container!);
  }

  void setReferenceContainer(OsContainerWnd? container) {
    _wreference = container == null ? null : WeakReference(container);
  }

  set isResolved(bool value) => _resolved = value;

  set wishToBeAReference(bool value) => _wishToBeAReference = value;

  void setHaveReferenceContainer(bool value, OsContainerWnd? container) {
    _haveReference = value;
    _wreference = null;
    if (!value) {
      _wreference = null;
    } else if (container != null) {
      _wreference = WeakReference(container);
    }
  }
}

///////////////////////////////////////////////////////////////////////
// container_synchro_item
///////////////////////////////////////////////////////////////////////

class OsContainerSynchroItem {
  final String _id;
  OsSyncType _syncType = OsSyncType.sliceIdOffset;
  bool _limitToSameStudy = true;
  final List<OsContainerSynchroInfo> _infos = [];
  WeakReference<OsContainerWnd>? _wmainContainer;

  OsContainerSynchroItem(this._id);

  //-----------------------------------------------------------------------
  //id
  //-----------------------------------------------------------------------

  get id => _id;

  //-----------------------------------------------------------------------
  //properties
  //-----------------------------------------------------------------------

  get syncType => _syncType;

  get shouldLimitToTheSameStudy => _limitToSameStudy;

  double getContainerOffset(OsContainerWnd container) {
    if (_syncType == OsSyncType.slicePosOffset ||
        _syncType == OsSyncType.sliceIdOffset) {
      OsContainerSynchroInfo? info = getContainerInfo(container);
      if (info == null) return 0.0;
      if (info.isResolved) {
        if (info.haveReferenceContainer) {
          return info.offset;
        } else {
          return 0.0;
        }
      } else {
        return 0.0;
      }
    } else {
      return 0.0;
    }
  }

  bool shouldSynchronize(OsContainerWnd container) {
    OsContainerSynchroInfo? info = getContainerInfo(container);
    return info != null;
  }

  bool isReferenceContainer(OsContainerWnd container) {
    OsContainerSynchroInfo? info = getContainerInfo(container);
    if (info == null) return false;
    if (info.isResolved) {
      return !info.haveReferenceContainer;
    }
    return false;
  }

  void getListOfSynchronizedContainers(List<OsContainerWnd> list) {
    for (final info in _infos) {
      OsContainerWnd? container = info.getContainer();
      if (container != null) list.add(container);
    }
  }

  OsContainerSynchroInfo? getContainerInfo(OsContainerWnd? container) {
    for (int i = 0; i < _infos.length; i++) {
      OsContainerWnd? currentContainer = _infos[i].getContainer();
      if (currentContainer == null) {
        _infos.removeAt(i);
        i--;
      } else if (identical(currentContainer, container)) {
        return _infos[i];
      }
    }
    return null;
  }

  bool isResolved(OsContainerWnd container) {
    OsContainerSynchroInfo? info = getContainerInfo(container);
    if (info == null) return false;
    return info.isResolved;
  }

  entities.Study? getStudyFromContainer(OsContainerWnd container) {
    OsRenderer? render = container.getImageBoxRenderer(0);
    if (render == null) {
      //choose the first render from the controller:
      final controller = container.controller;
      final elements = controller.rendererElements;

      if (elements.isNotEmpty) render = elements[0];
    }
    OsGraphicImage? img = render?.getPrimaryImageItem();

    entities.Image? image = img?.getImage();
    entities.Series? series = image == null ? img?.isNullImage() : image.series;
    return series?.study;
  }

  OsContainerWnd? getReferenceContainer(OsContainerWnd container) {
    OsContainerSynchroInfo? info = getContainerInfo(container);
    return info?.getReferenceContainer();
  }

  OsContainerWnd? getMainContainer() {
    return _wmainContainer?.target;
  }

  int getContainerOrientation(OsContainerWnd container, OsMatrix? orientation) {
    //0 -> no orientation
    //1 -> single orientation
    //2 -> multiple orientations
    //3 -> undefined orientation (no image yet)
    final controller = container.controller;
    final renderers = controller.rendererElements;

    bool hadImages = false;
    bool nullMat = false;
    OsMatrix mat1 = OsMatrix();
    bool first = true;
    for (final renderer in renderers) {
      OsGraphicImage? img = renderer.getPrimaryImageItem();
      if (img == null) return 3;
      entities.Image? image = img.getImage();
      if (image != null) {
        hadImages = true;
        OsMatrix mat2 = OsMatrix();
        if (image.getImageOrientation(mat2)) {
          mat2.mat[12] = 0;
          mat2.mat[13] = 0;
          mat2.mat[14] = 0;
          if (first) {
            mat1.copyFrom(mat2);
            first = false;
          } else {
            if (nullMat) {
              return 2;
            }
            if (!mat1.isEqual(mat2)) return 2;
          }
        } else {
          if (first) {
            nullMat = true;
            first = false;
          } else if (!nullMat) {
            return 2;
          }
        }
      }
    }
    if (!hadImages) {
      return 3;
    } else if (nullMat) {
      return 0;
    } else {
      orientation?.copyFrom(mat1);
      return 1;
    }
  }

  void setSyncType(OsSyncType type) {
    if (_syncType != type) {
      _syncType = type;
      for (final info in _infos) {
        info.offset = 0;
      }

      resolve(null, true, null);
      synchronize(null, null);
    }
  }

  void setShouldLimitToTheSameStudy(bool limit) {
    _limitToSameStudy = limit;
    resolve(null, true, null);
    synchronize(null, null);
  }

  void resolve(OsContainerWnd? from, bool notify,
      List<OsContainerWnd>? modifiedContainers) {
    //OsContainerSynchroInfo? info = from != null ? getContainerInfo(from) : null;
    List<OsContainerWnd> localModifiedContainers = [];
    List<OsContainerWnd> targetModified =
        modifiedContainers ?? localModifiedContainers;
    if (_syncType == OsSyncType.sliceIdAbsolutem ||
        _syncType == OsSyncType.slicePosAbsolute) {
      //we don't need any reference!
      for (final info in _infos) {
        final container = info.getContainer();
        if (container == null) continue;
        if (info.isResolved) {
          if (info.haveReferenceContainer) {
            info.setHaveReferenceContainer(false, null);
            info.offset = 0.0;
            if (!targetModified.contains(container)) {
              targetModified.add(container);
            }
          }
        } else {
          info.setHaveReferenceContainer(false, null);
          info.offset = 0.0;
          info.isResolved = true;
          if (!targetModified.contains(container)) {
            targetModified.add(container);
          }
        }
      }
    } else {
      //we are using offsets, we need reference for that!
      List<entities.Study> displayedStudies = [];
      //check if the container "from" wants to be the reference (it will get the priority)
      bool fromWantsToBeTheReference = false;
      if (from != null) {
        bool isCandidate = false;
        OsContainerSynchroInfo? info1 = getContainerInfo(from);
        if (info1 != null) {
          if (info1.isResolved) {
            if (!info1.haveReferenceContainer) fromWantsToBeTheReference = true;
          } else if (info1.wishToBeAReference) {
            fromWantsToBeTheReference = true;
          }
        }
      }
      if (_limitToSameStudy) {
        //remove the containers that contains multiple studies or no study at all:
        for (int it1 = 0; it1 < _infos.length; it1++) {
          bool remove = false;
          final container = _infos[it1].getContainer();
          if (container == null) {
            remove = true;
          } else {
            final controller = container.controller;

            List<entities.Series> displayedSeries = [];
            controller.getDisplayedSeries(displayedSeries);
            bool first = true;
            entities.Study? study;
            for (int it2 = 0; it2 < displayedSeries.length; it2++) {
              if (first) {
                study = displayedSeries[it2].study;
                first = false;
              } else if (study != displayedSeries[it2].study) {
                study = null;
              }
              if (study == null) {
                remove = true;
                break;
              }
            }
            if (study == null && !remove) {
              remove = true;
            } else if (!remove && study != null) {
              if (!displayedStudies.contains(study)) {
                displayedStudies.add(study);
              }
            }
          }
          if (remove) {
            _infos.removeAt(it1);
            it1--;
            if (container != null) {
              if (!targetModified.contains(container)) {
                targetModified.add(container);
              }
            }
          }
        }
      }
      if (_syncType == OsSyncType.slicePosOffset) {
        //remove the containers that contains multiple orientations or no orientation at all:
        for (int it1 = 0; it1 < _infos.length; it1++) {
          bool remove = false;
          OsContainerWnd? container = _infos[it1].getContainer();
          if (container == null) {
            remove = true;
          } else {
            OsMatrix orientation = OsMatrix();
            int test = getContainerOrientation(container, orientation);
            if (test == 0 || test == 2) remove = true;
          }
          if (remove) {
            _infos.removeAt(it1);
            it1--;
            if (container != null && !targetModified.contains(container)) {
              targetModified.add(container);
            }
          }
        }
      }
      if (_limitToSameStudy) {
        for (int it1 = 0; it1 < displayedStudies.length; it1++) {
          //for each study, we search the containers that could become the reference:
          List<OsContainerWnd> candidates = [];
          for (int it2 = 0; it2 < _infos.length; it2++) {
            OsContainerWnd? container = _infos[it2].getContainer();
            if (container != null) {
              List<entities.Series> displayedSeries = [];
              final controller = container.controller;

              controller.getDisplayedSeries(displayedSeries);
              if (displayedSeries.isNotEmpty) {
                if (identical(
                    displayedSeries[0].study, displayedStudies[it1])) {
                  candidates.add(container);
                }
              }
            }
          }
          _resolveCandidates(
              from, fromWantsToBeTheReference, candidates, targetModified);
        }
      } else {
        //not limited to the same study!
        List<OsContainerWnd> candidates = [];
        for (int it2 = 0; it2 < _infos.length; it2++) {
          OsContainerWnd? container = _infos[it2].getContainer();
          if (container != null) candidates.add(container);
        }
        _resolveCandidates(
            from, fromWantsToBeTheReference, candidates, targetModified);
      }
    }
    if (notify) {
      for (final container in targetModified) {
        OVApi().messages.sendMessage(OSMSG.imageContainerModified, container);
      }
    }
  }

  void _resolveCandidates(
      OsContainerWnd? from,
      bool fromWantsToBeTheReference,
      List<OsContainerWnd> candidates,
      List<OsContainerWnd> modifiedContainers) {
    if (_syncType == OsSyncType.slicePosOffset) {
      //In this list of candidates, we may have different orientations!
      //Split the list of candidates by orientation:
      double syncTolerance = /*manager?manager.getSyncOrientationTolerance():*/
          1.0;
      List<OsContainerWnd> undefinedOrientationContainers = [];
      List<OsContainerSyncOrientationInfo> candidatesPerOrientation = [];
      for (int it2 = 0; it2 < candidates.length; it2++) {
        OsMatrix orientation = OsMatrix();
        int test = getContainerOrientation(candidates[it2], orientation);
        if (test == 1) {
          OsContainerSyncOrientationInfo? winner;
          for (int tmp = 0; tmp < candidatesPerOrientation.length; tmp++) {
            //strict mode:
            if (syncTolerance == 1.0) {
              if (candidatesPerOrientation[tmp]
                  .orientation
                  .isEqual(orientation)) {
                winner = candidatesPerOrientation[tmp];
                break;
              }
            } else {
              //less strict mode:
              double sca = OsVec3D.scalarProductWidthOffset(orientation.mat, 8,
                  candidatesPerOrientation[tmp].orientation.mat, 8);
              if (sca >= syncTolerance) {
                winner = candidatesPerOrientation[tmp];
                break;
              }
            }
          }
          if (winner == null) {
            winner = OsContainerSyncOrientationInfo();
            winner.orientation.copyFrom(orientation);
            candidatesPerOrientation.add(winner);
          }
          winner.containers.add(candidates[it2]);
        } else if (test == 3) {
          undefinedOrientationContainers.add(candidates[it2]);
        }
      }
      //all undefined orientation containers must be set as unresolved:
      for (int it2 = 0; it2 < undefinedOrientationContainers.length; it2++) {
        OsContainerSynchroInfo? info1 =
            getContainerInfo(undefinedOrientationContainers[it2]);
        if (info1 != null) {
          if (info1.isResolved) {
            info1.isResolved = false;
            info1.wishToBeAReference = !info1.haveReferenceContainer;
            info1.setReferenceContainer(null);
            if (!modifiedContainers
                .contains(undefinedOrientationContainers[it2])) {
              modifiedContainers.add(undefinedOrientationContainers[it2]);
            }
          }
        }
      }
      //try to find the reference for each orientation:
      for (int it3 = 0; it3 < candidatesPerOrientation.length; it3++) {
        bool canResolve = true;
        List<OsContainerWnd> refCandidates = [];
        OsContainerWnd? winnerRef;
        for (int it4 = 0;
            it4 < candidatesPerOrientation[it3].containers.length;
            it4++) {
          OsContainerSynchroInfo? info1 =
              getContainerInfo(candidatesPerOrientation[it3].containers[it4]);
          if (info1 != null) {
            if (info1.isResolved) {
              if (!info1.haveReferenceContainer) {
                refCandidates
                    .add(candidatesPerOrientation[it3].containers[it4]);
              }
            } else if (info1.wishToBeAReference) {
              refCandidates.add(candidatesPerOrientation[it3].containers[it4]);
            }
          }
        }
        //we should give the priority to the "from" container:
        if (fromWantsToBeTheReference && from != null) {
          if (refCandidates.contains(from)) {
            winnerRef = from;
          } else if (undefinedOrientationContainers.contains(from)) {
            //from wants to be the reference but we don't know yet its orientation
            //we have no idea if from can be the reference or not,
            //we cannot resolve!
            canResolve = false;
          }
        }
        //if still no winner, take the first candidate if available!
        if (canResolve && winnerRef == null && refCandidates.isNotEmpty) {
          winnerRef = refCandidates[0];
        }
        //if still no winner, take the first candidate:
        if (canResolve &&
            winnerRef == null &&
            candidatesPerOrientation[it3].containers.isNotEmpty)
          winnerRef = candidatesPerOrientation[it3].containers[0];
        if (canResolve && winnerRef != null) {
          //ok, we got our winner!
          OsContainerSynchroInfo? info = getContainerInfo(winnerRef);
          if (info != null) {
            if (!info.isResolved) {
              info.setHaveReferenceContainer(false, null);
              info.isResolved = true;
              info.offset = 0;
              if (!modifiedContainers.contains(winnerRef)) {
                modifiedContainers.add(winnerRef);
              }
            } else {
              if (info.haveReferenceContainer) {
                info.setHaveReferenceContainer(false, null);
                info.offset = 0;
                if (!modifiedContainers.contains(winnerRef)) {
                  modifiedContainers.add(winnerRef);
                }
              }
            }
            //others become slaves:
            for (int it4 = 0;
                it4 < candidatesPerOrientation[it3].containers.length;
                it4++) {
              if (candidatesPerOrientation[it3].containers[it4] != winnerRef) {
                if (!undefinedOrientationContainers
                    .contains(candidatesPerOrientation[it3].containers[it4])) {
                  OsContainerSynchroInfo? info = getContainerInfo(
                      candidatesPerOrientation[it3].containers[it4]);
                  if (info != null) {
                    if (!info.isResolved) {
                      info.isResolved = true;
                      info.setHaveReferenceContainer(true, winnerRef);
                      if (info.offset == double.infinity) {
                        //Try to calculate the current offset:
                        info.offset = calculateOffset(
                            candidatesPerOrientation[it3].containers[it4],
                            winnerRef);
                        if (info.offset == double.infinity) info.offset = 0.0;
                      }
                      if (!modifiedContainers.contains(
                          candidatesPerOrientation[it3].containers[it4])) {
                        modifiedContainers
                            .add(candidatesPerOrientation[it3].containers[it4]);
                      }
                    } else {
                      bool modif = false;
                      if (!info.haveReferenceContainer) {
                        modif = true;
                      } else if (info.getReferenceContainer() != winnerRef) {
                        modif = true;
                      }
                      info.setHaveReferenceContainer(true, winnerRef);
                      if (info.offset == double.infinity) {
                        //Try to calculate the current offset:
                        info.offset = calculateOffset(
                            candidatesPerOrientation[it3].containers[it4],
                            winnerRef);
                        if (info.offset == double.infinity) info.offset = 0.0;
                      }
                      if (modif) {
                        if (!modifiedContainers.contains(
                            candidatesPerOrientation[it3].containers[it4])) {
                          modifiedContainers.add(
                              candidatesPerOrientation[it3].containers[it4]);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      candidatesPerOrientation.clear();
    } else {
      //slice_id_offset!
      List<OsContainerWnd> refCandidates = [];
      OsContainerWnd? winnerRef;
      for (int it4 = 0; it4 < candidates.length; it4++) {
        OsContainerSynchroInfo? info1 = getContainerInfo(candidates[it4]);
        if (info1 != null) {
          if (info1.isResolved) {
            if (!info1.haveReferenceContainer) {
              refCandidates.add(candidates[it4]);
            }
          } else if (info1.wishToBeAReference) {
            refCandidates.add(candidates[it4]);
          }
        }
      }
      //we should give the priority to the "from" container:
      if (fromWantsToBeTheReference && from != null) {
        if (refCandidates.contains(from)) {
          winnerRef = from;
        }
      }
      //if still no winner, take the first candidate if available!
      if (winnerRef == null && refCandidates.isNotEmpty) {
        winnerRef = refCandidates[0];
      }
      //if still no winner, take the first candidate:
      if (winnerRef == null && candidates.isNotEmpty) {
        winnerRef = candidates[0];
      }
      if (winnerRef != null) {
        //ok, we got our winner!
        OsContainerSynchroInfo? info = getContainerInfo(winnerRef);
        if (info != null) {
          if (!info.isResolved) {
            info.setHaveReferenceContainer(false, null);
            info.isResolved = true;
            info.offset = 0;
            if (!modifiedContainers.contains(winnerRef)) {
              modifiedContainers.add(winnerRef);
            }
          } else {
            if (info.haveReferenceContainer) {
              info.setHaveReferenceContainer(false, null);
              info.offset = 0;
              if (!modifiedContainers.contains(winnerRef)) {
                modifiedContainers.add(winnerRef);
              }
            }
          }
          //others become slaves:
          for (int it4 = 0; it4 < candidates.length; it4++) {
            if (candidates[it4] != winnerRef) {
              OsContainerSynchroInfo? info = getContainerInfo(candidates[it4]);
              if (info != null) {
                if (!info.isResolved) {
                  info.isResolved = true;
                  info.setHaveReferenceContainer(true, winnerRef);
                  if (info.offset == double.infinity) {
                    //Try to calculate the current offset:
                    info.offset = calculateOffset(candidates[it4], winnerRef);
                    if (info.offset == double.infinity) info.offset = 0.0;
                  }
                  if (!modifiedContainers.contains(candidates[it4])) {
                    modifiedContainers.add(candidates[it4]);
                  }
                } else {
                  bool modif = false;
                  if (!info.haveReferenceContainer) {
                    modif = true;
                  } else if (!identical(
                      info.getReferenceContainer(), winnerRef)) {
                    modif = true;
                  }
                  info.setHaveReferenceContainer(true, winnerRef);
                  if (info.offset == double.infinity) {
                    //Try to calculate the current offset:
                    info.offset = calculateOffset(candidates[it4], winnerRef);
                    if (info.offset == double.infinity) {
                      info.offset = 0.0;
                    }
                  }
                  if (modif && !modifiedContainers.contains(candidates[it4])) {
                    modifiedContainers.add(candidates[it4]);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  void setShouldSynchronize(
      {required OsContainerWnd container,
      required bool synchro,
      bool asRef = true,
      double offset = 0,
      bool notify = false,
      List<OsContainerWnd>? modifiedContainers}) {
    List<OsContainerWnd> localModifiedContainers = [];
    List<OsContainerWnd> targetModified =
        modifiedContainers ?? localModifiedContainers;
    targetModified.add(container);
    OsContainerSynchroInfo? info = getContainerInfo(container);
    if (synchro) {
      //stop playing the container if it is playing:
      container.stopPlaying(true);
      //create the info:
      if (info == null) {
        info = OsContainerSynchroInfo();
        info.setContainer(container);
        _infos.add(info);
      }
      //init:
      info.isResolved = false;
      info.wishToBeAReference = asRef;
      if (asRef) {
        info.offset = 0;
      } else {
        info.offset = offset;
      }
      //resolve:
      resolve(container, false, targetModified);
    } else {
      if (info != null) {
        int index = _infos.indexOf(info);
        if (index >= 0) {
          //Delete the info and remove it from the list:
          _infos.removeAt(index);
        }
      }
      //resolve:
      resolve(container, false, targetModified);
    }
    if (notify) {
      for (final container in targetModified) {
        OVApi().messages.sendMessage(OSMSG.imageContainerModified, container);
      }
    }
  }

  void setMainContainer(OsContainerWnd? container) {
    if (container == null) {
      _wmainContainer = null;
    } else {
      _wmainContainer = WeakReference(container);
    }
  }

  void synchronize(
      OsContainerWnd? from, List<OsContainerWnd>? containersToRefresh) {
    double syncTolerance = /*manager?manager.getSyncOrientationTolerance():*/
        1.0;
    if (from == null) {
      OsContainerWnd? mainContainer = getMainContainer();
      if (_syncType == OsSyncType.sliceIdOffset ||
          _syncType == OsSyncType.slicePosOffset) {
        for (int it = 0; it < _infos.length; it++) {
          if (_infos[it].haveReferenceContainer) {
            OsContainerWnd? reference = _infos[it].getContainer();
            if (reference != null) {
              List<OsContainerWnd> list = [];
              list.add(reference);
              for (int it1 = 0; it1 < _infos.length; it1++) {
                if (identical(_infos[it1].getReferenceContainer(), reference)) {
                  OsContainerWnd? tmp = _infos[it1].getContainer();
                  if (tmp != null) list.add(tmp);
                }
              }
              if (mainContainer != null && list.contains(mainContainer)) {
                synchronize(mainContainer, containersToRefresh);
              } else {
                synchronize(list[0], containersToRefresh);
              }
            }
          }
        }
      } else {
        if (_limitToSameStudy) {
          List<OsContainerSynchroInfo> list = [];
          for (int it = 0; it < _infos.length; it++) {
            list.add(_infos[it]);
          }
          for (int it1 = 0; it1 < list.length; it1++) {
            OsContainerWnd? container1 = list[it1].getContainer();
            entities.Study? study =
                container1 == null ? null : getStudyFromContainer(container1);
            if (study != null) {
              List<OsContainerWnd> containers = [];
              containers.add(container1!);
              for (int it2 = it1 + 1; it2 < list.length; it2++) {
                OsContainerSynchroInfo info2 = list[it2];
                OsContainerWnd? container2 = info2.getContainer();
                entities.Study? study2 = container2 == null
                    ? null
                    : getStudyFromContainer(container2);
                if (study2 != null) {
                  if (identical(study, study2)) {
                    containers.add(container2!);
                    list.removeAt(it2);
                    it2--;
                  }
                }
              }
              if (mainContainer != null && containers.contains(mainContainer)) {
                synchronize(mainContainer, containersToRefresh);
              } else {
                synchronize(containers[0], containersToRefresh);
              }
            }
          }
        } else {
          if (mainContainer != null) {
            synchronize(mainContainer, containersToRefresh);
          }
        }
      }
      return;
    }

    //If the main container does not belong to the synchronization group, we have nothing to do:
    OsContainerSynchroInfo? info = getContainerInfo(from);
    if (info == null) return;

    //Get the current slice position
    OsMatrix mainOrientationMatrix = OsMatrix();
    if (_syncType == OsSyncType.slicePosAbsolute ||
        _syncType == OsSyncType.slicePosOffset) {
      OsRenderer? render = from.getImageBoxRenderer(0);
      OsGraphicImage? img = render?.getPrimaryImageItem();
      entities.Image? image = img?.getImage();
      if (image == null) return;
      if (!image.getImageOrientation(mainOrientationMatrix)) return;
    }
    OsContainerWnd? refContainer = info.getReferenceContainer();
    refContainer ??= from;
    entities.Study? refStudy = (_syncType == OsSyncType.slicePosAbsolute ||
            _syncType == OsSyncType.sliceIdAbsolutem)
        ? getStudyFromContainer(from)
        : null;

    //Try to synchronize each container:
    for (int it = 0; it < _infos.length; it++) {
      OsContainerSynchroInfo infoCandidate = _infos[it];
      if (identical(infoCandidate, info)) continue;
      OsContainerWnd? candidate = infoCandidate.getContainer();
      if (candidate == null) continue;
      bool isCandidate = false;
      if (_syncType == OsSyncType.slicePosOffset ||
          _syncType == OsSyncType.sliceIdOffset) {
        if (infoCandidate.haveReferenceContainer) {
          if (identical(infoCandidate.getReferenceContainer(), refContainer)) {
            isCandidate = true;
          }
        } else if (identical(infoCandidate.getContainer(), refContainer)) {
          isCandidate = true;
        }
      } else {
        if (_limitToSameStudy) {
          if (refStudy != null) {
            if (identical(getStudyFromContainer(candidate), refStudy)) {
              isCandidate = true;
            }
          }
        } else {
          isCandidate = true;
        }
      }
      if (!isCandidate) continue;

      final controller = candidate.controller;
      int winnerPageIndex = -1;
      bool shouldInactive = true;
      if (_syncType == OsSyncType.slicePosAbsolute ||
          _syncType == OsSyncType.slicePosOffset) {
        int pageIndex = -1;
        OsMatrix orientationMatrix = OsMatrix();
        double k1 = double.infinity;
        double k2 = -100000000.0;
        double winnerK = double.infinity;

        //define the plane vector and the target position (belonging to the plane):
        List<double> planeVec = [0, 0, 0];
        planeVec[0] = mainOrientationMatrix.mat[8];
        planeVec[1] = mainOrientationMatrix.mat[9];
        planeVec[2] = mainOrientationMatrix.mat[10];
        OsVec3D.normalize(planeVec);
        List<double> targetPosition = [0, 0, 0];
        targetPosition[0] = mainOrientationMatrix.mat[12];
        targetPosition[1] = mainOrientationMatrix.mat[13];
        targetPosition[2] = mainOrientationMatrix.mat[14];
        if (_syncType == OsSyncType.slicePosOffset) {
          targetPosition[0] +=
              (infoCandidate.offset - info.offset) * planeVec[0];
          targetPosition[1] +=
              (infoCandidate.offset - info.offset) * planeVec[1];
          targetPosition[2] +=
              (infoCandidate.offset - info.offset) * planeVec[2];
        }
        List<OsRenderer> renderers = controller.rendererElements;
        for (int it1 = 0; it1 < renderers.length; it1++) {
          if (renderers[it1].hidden) continue;
          pageIndex++;
          OsGraphicImage? img = renderers[it1].getPrimaryImageItem();
          if (img == null) continue;
          entities.Image? image = img.getImage();
          if (image == null) continue;
          if (!image.getImageOrientation(orientationMatrix)) continue;
          if (syncTolerance == 1.0) {
            //strict mode
            //must be the same orientation:
            if (orientationMatrix.mat[0] != mainOrientationMatrix.mat[0])
              continue;
            if (orientationMatrix.mat[1] != mainOrientationMatrix.mat[1])
              continue;
            if (orientationMatrix.mat[2] != mainOrientationMatrix.mat[2])
              continue;
            if (orientationMatrix.mat[4] != mainOrientationMatrix.mat[4])
              continue;
            if (orientationMatrix.mat[5] != mainOrientationMatrix.mat[5])
              continue;
            if (orientationMatrix.mat[6] != mainOrientationMatrix.mat[6])
              continue;
            if (orientationMatrix.mat[8] != mainOrientationMatrix.mat[8])
              continue;
            if (orientationMatrix.mat[9] != mainOrientationMatrix.mat[9])
              continue;
            if (orientationMatrix.mat[10] != mainOrientationMatrix.mat[10])
              continue;
          } else {
            //less strict mode:
            if (OsVec3D.scalarProductWidthOffset(orientationMatrix.mat, 8,
                        mainOrientationMatrix.mat, 8) <
                    syncTolerance ||
                OsVec3D.scalarProductWidthOffset(orientationMatrix.mat, 0,
                        mainOrientationMatrix.mat, 0) <
                    syncTolerance) {
              continue;
            }
          }
          List<double> k = [0];
          if (OsVec3D.getKFactorByOffset(
              targetPosition, 0, planeVec, orientationMatrix.mat, 12, k)) {
            if (k1 == double.infinity) {
              k1 = k[0];
              k2 = k[0];
              winnerPageIndex = pageIndex;
              winnerK = k[0];
            } else {
              if (k[0] < k1) k1 = k[0];
              if (k[0] > k2) k2 = k[0];
              if (k[0].abs() < winnerK.abs()) {
                winnerK = k[0];
                winnerPageIndex = pageIndex;
              }
            }
          }
        }
        if (winnerPageIndex != -1) {
          if (k1 * k2 > 0) {
            shouldInactive = true;
          } else {
            shouldInactive = false;
          }
        } else {
          shouldInactive = false;
        }
      } else if (_syncType == OsSyncType.sliceIdOffset ||
          _syncType == OsSyncType.sliceIdOffset) {
        winnerPageIndex = from.currentPage;
        if (_syncType == OsSyncType.sliceIdOffset) {
          winnerPageIndex += (infoCandidate.offset - info.offset).round();
        }
        //Make sure that the new page index is valid:
        if (winnerPageIndex < 0) {
          winnerPageIndex = 0;
        } else if (winnerPageIndex >= candidate.pageCount) {
          winnerPageIndex = candidate.pageCount - 1;
        } else {
          shouldInactive = false;
        }
      }
      if (winnerPageIndex != -1) {
        bool modifInactive =
            candidate.isInactive() == shouldInactive ? false : true;
        bool modifPage = candidate.currentPage != winnerPageIndex;
        if (modifInactive || modifPage) {
          if (modifInactive) {
            candidate.setInactive(
                inactive: shouldInactive, sendModifiedMessage: false);
            candidate.setCurrentPage(
                index: winnerPageIndex, mode: OsContDraw.osForceRedraw);
          } else {
            candidate.setCurrentPage(
                index: winnerPageIndex, mode: OsContDraw.osDraw);
          }
        }
      } else {
        bool oldInactive = candidate.isInactive();
        if (_syncType == OsSyncType.sliceIdAbsolutem ||
            _syncType == OsSyncType.sliceIdOffset) {
          candidate.setInactive(inactive: true, sendModifiedMessage: false);
        } else {
          candidate.setInactive(inactive: false, sendModifiedMessage: false);
        }
        if (oldInactive != candidate.isInactive()) {
          candidate.setCurrentPage(
              index: candidate.currentPage, mode: OsContDraw.osForceRedraw);
        }
      }
    }
  }

  void onReceiveImage(OsContainerWnd container) {
    if (_syncType == OsSyncType.slicePosOffset) {
      resolve(null, true, null);
    }
  }

  double calculateOffset(
      OsContainerWnd? container, OsContainerWnd? referenceContainer) {
    if (container == null || referenceContainer == null) return double.infinity;
    if (_syncType == OsSyncType.sliceIdOffset) {
      return (container.currentPage - referenceContainer.currentPage)
          .toDouble();
    } else if (_syncType == OsSyncType.slicePosOffset) {
      OsMatrix refOrientationMatrix = OsMatrix();
      OsMatrix orientationMatrix = OsMatrix();
      OsRenderer? render;
      OsGraphicImage? img;
      entities.Image? image;
      render = referenceContainer.getImageBoxRenderer(0);
      img = render?.getPrimaryImageItem();
      image = img?.getImage();
      if (image == null) return double.infinity;
      if (!image.getImageOrientation(refOrientationMatrix)) {
        return double.infinity;
      }
      image = null;
      render = container.getImageBoxRenderer(0);
      img = render?.getPrimaryImageItem();
      image = img?.getImage();
      if (image == null) return double.infinity;
      if (!image.getImageOrientation(orientationMatrix)) return double.infinity;

      //must be the same orientation:
      if (orientationMatrix.mat[0] != refOrientationMatrix.mat[0]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[1] != refOrientationMatrix.mat[1]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[2] != refOrientationMatrix.mat[2]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[4] != refOrientationMatrix.mat[4]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[5] != refOrientationMatrix.mat[5]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[6] != refOrientationMatrix.mat[6]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[8] != refOrientationMatrix.mat[8]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[9] != refOrientationMatrix.mat[9]) {
        return double.infinity;
      }
      if (orientationMatrix.mat[10] != refOrientationMatrix.mat[10]) {
        return double.infinity;
      }

      //return the offset:
      List<double> planeVec = [0, 0, 0];
      planeVec[0] = orientationMatrix.mat[8];
      planeVec[1] = orientationMatrix.mat[9];
      planeVec[2] = orientationMatrix.mat[10];
      OsVec3D.normalize(planeVec);
      List<double> k = [0];
      if (OsVec3D.getKFactorByOffset(refOrientationMatrix.mat, 12, planeVec,
          orientationMatrix.mat, 12, k)) {
        return k[0];
      } else {
        return 0;
      }
    }
    return double.infinity;
  }
}
