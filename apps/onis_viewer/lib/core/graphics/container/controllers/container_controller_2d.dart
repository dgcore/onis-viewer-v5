import 'package:onis_viewer/api/graphics/renderers/renderer_2d.dart';
import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/container/controllers/container_controller.dart';
import 'package:onis_viewer/core/graphics/renderer/items/camera.dart';
import 'package:onis_viewer/core/graphics/renderer/items/group.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/items/item.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/models/database/color_lut.dart';
import 'package:onis_viewer/core/models/database/convolution_filter.dart';
import 'package:onis_viewer/core/models/database/opacity_table.dart';
import 'package:onis_viewer/core/models/database/window_level.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/onis_exception.dart';
import 'package:onis_viewer/core/result/result.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';

///////////////////////////////////////////////////////////////////////
// OsDisplayedSeriesInfo
///////////////////////////////////////////////////////////////////////

class OsDisplayedSeriesInfo {
  WeakReference<entities.Series>? _wSeries;
  int rendererCount = 0;
  int preloadCount = 0;
  bool firstImageArrived = false;
  OsItemDuplicateInfo? dupInfo;

  entities.Series? get series => _wSeries?.target;
  set series(entities.Series? series) {
    _wSeries = series != null ? WeakReference<entities.Series>(series) : null;
  }
}

class OsContainerController2D extends OsContainerController {
  final List<OsDisplayedSeriesInfo> _listOfSeriesInfo = [];
  final List<OsRenderer2D> _listRenderElements = [];
  final OsIncomingImageProperties _incomingImageProperties =
      OsIncomingImageProperties();
  final String _stateId = "";
  int? _messageSubscription;

  OsContainerController2D() {
    _messageSubscription = OVApi().messages.subscribe(onReceivedMessage);
  }

  void dispose() {
    if (_messageSubscription != null) {
      OVApi().messages.unsubscribe(_messageSubscription!);
      _messageSubscription = null;
    }
  }

  @override
  List<OsRenderer2D> get rendererElements => _listRenderElements;

  @override
  OsRenderer? createRenderer() {
    OsRendererType? type = OVApi().renderTypes.get('2d');
    return type?.createRenderer();
  }

  //series:
  @override
  void resetContent(
      bool resetSynchro, List<OsContainerWnd>? modifiedContainers) {
    //Stop playing the container:
    /*let container:OsContainerWnd|null = this.getWindow();
        if (container) {
            container.stopPlaying();
            container.zoomImageBox(false, 0, notify);
        }
        
        //Save all state:
        for (let iinnumber=0; i<_listOfSeriesInfo.length; i++) {
            //let series:OsOpenedSeries = this._listOfSeriesInfo[i].getSeries(false);
            this._saveSeriesState(_listOfSeriesInfo[i]);
            //if (this._listOfSeriesInfo[i].dupInfo) this._listOfSeriesInfo[i].dupInfo.release();
            //this._listOfSeriesInfo[i].dupInfo = null;
            //if (series) {
                //store_series_state(series);
                //fire the callback:
                /*if (this._removeSeriesHandler) {
                    let bindData:OsStrongObject = this._wremoveSeriesData?this._wremoveSeriesData.lock(false):null;
                    if (bindData && series)
                        this._removeSeriesHandler.bind(bindData)(this, series); 
                }*/
            //}
        }

    //#ifdef OS_AUTO_EXPORT_WHEN_CONTAINER_CLEAR
        //_app->send_message(OSMSG_IMGCONT_AUTO_EXPORT, WPARAM(_container.get()), 0);
    //#endif
        
        //unselect all the images (to fire annotation selection event):
        if (container) container.unselectAll(true, false, null, null, null);

        //we destroy all the render elements:
        for (let i=0; i<this._listRenderElements.length; i++) this._listRenderElements[i].release();
        this._listRenderElements.splice(0, this._listRenderElements.length);
        
        //we release all the series info:
        for (let i=0; i<_listOfSeriesInfo.length; i++) _listOfSeriesInfo[i].destroy();
        _listOfSeriesInfo.splice(0, _listOfSeriesInfo.length);
        
        let localModifiedContainers:Array<OsContainerWnd> = [];
        let targetModifiedContainers:Array<OsContainerWnd> = modifiedContainers;
        if (!targetModifiedContainers) targetModifiedContainers = localModifiedContainers;
        if (container) {
            if (targetModifiedContainers.indexOf(container) == -1)
                targetModifiedContainers.push(container);		
            if (resetSynchro) {
                let synchro:IContainerSynchroItem|null = container.getSynchroItem();
                if (synchro) {
                    synchro.setShouldSynchronize(container, false, false, 0.0, false, targetModifiedContainers); 
                    synchro.synchronize(null, null);
                }
            }
        }
        this._incomingImageProperties.reset();
        if (notify && this._viewer && this._viewer.messageService) {
            for (let i=0; i<targetModifiedContainers.length; i++) 
                this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, targetModifiedContainers[i]);
        }*/
  }

  @override
  bool canAddSeries(List<entities.Series> list) {
    return true;
  }

  @override
  void addSeries({
    required entities.Series series,
    required bool refresh,
    required bool fromHangingProtocol,
    List<OsContainerWnd>? modifiedContainers,
  }) {
    //Don't add the series if we are already displaying it:
    if (isSeriesDisplayed(series)) return;

    //Stop playing the container:
    //let container:OsContainerWnd|null = this.getWindow();

    //Add the series:
    final seriesInfo = OsDisplayedSeriesInfo();
    seriesInfo.series = series;
    seriesInfo.rendererCount = 0;
    _listOfSeriesInfo.add(seriesInfo);

    //prepare to load the states if required:
    if (_stateId.isNotEmpty) {
      seriesInfo.dupInfo = OsItemDuplicateInfo();
    }

    final container = getContainer();

    int imageCount = series.images.length;
    if (imageCount == 0) {
      //the series may be not loaded yet
      final render = createRenderer() as OsRenderer2D?;
      if (render == null) {
        throw OnisException(
            OnisErrorCodes.logicError, 'Failed to create renderer');
      }
      seriesInfo.rendererCount++;
      OsGraphicGroup? grp = render.getImageGroupItem();
      OsGraphicImage item = OsGraphicImage("");
      item.setNullImage(series);
      item.setParent(grp);
      item.setLoadImageIndex(0);
      render.setActiveImageItem(item);
      render.setPrimaryImageItem(item);
      _listRenderElements.add(render);
    } else {
      if (container != null) {
        /*let matrix:[number, number] = [0, 0]; //rows, cols
                container.getImageMatrix(matrix);
                let imageBoxCount:number = matrix[0] * matrix[1];
                let refresh:boolean = false;
                let pageToRefresh:number = -1;
                let propagate:IContainerPropagateItem|null = container.getPropagationItem();
                for (let i=0; i<imageCount; i++) {
                    let render:OsRenderer2D = <OsRenderer2D>createRenderer();
                    seriesInfo.rendererCount++;
                    let grp:OsGraphicGroup|null = render.getImageGroupItem(false);
                    if (grp) {
                        let item:OsGraphicImage = OsGraphicImage("");
                        if (!series.images[i]) {
                            item.setNullImage(series);
                            item.setLoadImageIndex(i);
                        }
                        else {
                            item.setImage(series.images[i]);
                            item.setLoadImageIndex(series.images[i].loadIndex);
                        }
                        item.setParent(grp);
                        if (!render.getActiveImageItem(false)) render.setActiveImageItem(item);
                        if (!render.getPrimaryImageItem(false)) render.setPrimaryImageItem(item);
                        item.release();
                    }
                    _listRenderElements.push(render);
                    pageToRefresh = applyIncomingImageProperties(render, false);
                    if (pageToRefresh != container.getCurrentPage()) refresh = true;
                    else {
                        //refresh only if renderer is visible:
                        for (let j=0; j<imageBoxCount; j++) {
                            if (container.getImageBoxRenderer(j) == render) {
                                refresh = true;
                                break;
                            }
                        }
                    }
                    //restore the states:
                    let img1:OsGraphicImage|null = render.getPrimaryImageItem(false);
                    let image1:OsOpenedImage|null = img1?img1.getImage():null;
                    if (image1 && seriesInfo.dupInfo) this._applyImageStates(i, render, series, image1, seriesInfo.dupInfo, series.findState(_stateId, 0), fromHangingProtocol);
                    
                    //propagate:
                    if (propagate) propagate.onReceivedImage(container, render);
                }
           

                
                
                if (refresh) 
                    if (pageToRefresh != -1) container.setCurrentPage(pageToRefresh, OsContDraw.OS_FORCE_REDRAW);
                    else container.setCurrentPage(container.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                    */
      }
    }

    if (series.loadStatus.status == ResultStatus.pending) {
      if (getContainer() != null) {
        final dbApi =
            OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
        dbApi?.downloadController.addSeriesToLoadingQueue(series, true);
      }
    }

    /* let localModifiedContainers:Array<OsContainerWnd> = [];
        let targetModifiedContainers:Array<OsContainerWnd>|null = modifiedContainers;
        if (!targetModifiedContainers) targetModifiedContainers = localModifiedContainers;
        if (container) {
            if (targetModifiedContainers.indexOf(container) == -1)
                targetModifiedContainers.push(container);		
            let synchro:IContainerSynchroItem|null = container.getSynchroItem();
            if (synchro) {
                synchro.resolve(null, false, targetModifiedContainers);
                synchro.synchronize(null, null);
            }
        }
        if (notify && this._viewer && this._viewer.messageService) {
            for (let i=0; i<targetModifiedContainers.length; i++) 
                this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, targetModifiedContainers[i]);
        }

        //Start preloading:
        this.preloadRenderers();
        if (container) container.startLoadingRefreshTimer();*/
  }

  @override
  bool isSeriesDisplayed(entities.Series series) {
    for (int i = 0; i < _listOfSeriesInfo.length; i++) {
      if (_listOfSeriesInfo[i].series == series) {
        return true;
      }
    }
    return false;
  }

  @override
  void getDisplayedSeries(List<entities.Series> list) {
    for (int i = 0; i < _listOfSeriesInfo.length; i++) {
      entities.Series? displayedSeries = _listOfSeriesInfo[i].series;
      if (displayedSeries != null) {
        list.add(displayedSeries);
      } else {
        _listOfSeriesInfo.removeAt(i);
        i--;
      }
    }
  }

  OsDisplayedSeriesInfo? _findSeriesInfo(entities.Series series) {
    for (int i = 0; i < _listOfSeriesInfo.length; i++) {
      if (_listOfSeriesInfo[i].series == series) {
        return _listOfSeriesInfo[i];
      }
    }
    return null;
  }

  void onReceivedMessage(int id, dynamic message) {
    if (id == OSMSG.seriesDownloadReceivedInfo) {
      _onReceivedSeriesInfo(message!.data["series"] as entities.Series);
    } else if (id == OSMSG.seriesImagesReceived) {
      _onReceivedImages(message!.data as List<entities.Image>, false);
    }
  }

  void _onReceivedSeriesInfo(entities.Series series) {
    OsDisplayedSeriesInfo? info = _findSeriesInfo(series);
    if (info == null) return;
    for (int i = 0; i < _listRenderElements.length; i++) {
      OsGraphicImage? img = _listRenderElements[i].getPrimaryImageItem();
      if (img != null) {
        if (identical(img.isNullImage(), series)) {
          int count = series.images.length;
          info.rendererCount += count - 1;
          for (int j = 0; j < count - 1; j++) {
            final render = createRenderer() as OsRenderer2D?;
            if (render == null) {
              throw OnisException(
                  OnisErrorCodes.logicError, 'Failed to create renderer');
            }
            _listRenderElements.insert(i, render);
          }
          for (int j = 0; j < count; j++) {
            OsGraphicGroup? grp =
                _listRenderElements[i + j].getImageGroupItem();
            if (grp != null) {
              OsGraphicImage? item =
                  _listRenderElements[i + j].getPrimaryImageItem();
              if (item == null) {
                item = OsGraphicImage('');
                item.setParent(grp);
                _listRenderElements[i + j].setActiveImageItem(item);
                _listRenderElements[i + j].setPrimaryImageItem(item);
              }
              item.setImage(series.images[j]);
            }
          }
          OsContainerWnd? container = getContainer();
          if (container != null) {
            OVApi()
                .messages
                .sendMessage(OSMSG.imageContainerModified, container);
          }
          break;
        }
      }
    }
    OsContainerWnd? container = getContainer();
    container?.setCurrentPage(
        index: container.currentPage, mode: OsContDraw.osForceRedraw);
  }

  void _onReceivedImages(
      List<entities.Image> images, bool fromHangingProtocol) {
    for (entities.Image image in images) {
      entities.Series? series = image.series;
      if (series == null) continue;
      OsDisplayedSeriesInfo? seriesInfo = _findSeriesInfo(series);
      if (seriesInfo == null) continue;
      bool spaceAdded = false;
      OsRenderer2D? incomingImageRender;

      //search an the first render matching the series:
      int first = -1;
      for (int j = 0; j < _listRenderElements.length; j++) {
        OsGraphicImage? img = _listRenderElements[j].getPrimaryImageItem();
        if (img == null) continue;
        entities.Image? image1 = img.getImage();
        entities.Series? series1 = image1?.series;
        series1 ??= img.isNullImage();
        if (identical(series, series1)) {
          first = j;
          break;
        }
      }

      if (first != -1) {
        bool ok = true;
        //find the last position for the series:
        int last = first;
        if (seriesInfo.rendererCount > 1) {
          if (last + seriesInfo.rendererCount - 1 <
              _listRenderElements.length) {
            last += seriesInfo.rendererCount - 1;
          } else {
            ok = false;
          }
        }
        //check if we need to allocate more renderers for incoming images:
        if (ok) {
          int totalExpected = series.images.length;
          int allocatedSpaces = seriesInfo.rendererCount;
          if (totalExpected > allocatedSpaces) {
            //we should allocate additional renderers:
            int dif = totalExpected - allocatedSpaces;
            seriesInfo.rendererCount += dif;
            //if space is added everytime, it will be too slow send the modified message each time.
            //we will send only once when it became more than 1
            if (allocatedSpaces == 1) spaceAdded = true;
            for (int j = 0; j < dif; j++) {
              OsRenderer2D? newRender = createRenderer() as OsRenderer2D?;
              if (newRender == null) {
                throw OnisException(
                    OnisErrorCodes.logicError, 'Failed to create renderer');
              }
              OsGraphicGroup? grp = newRender.getImageGroupItem();
              if (grp != null) {
                OsGraphicImage item = OsGraphicImage("");
                item.setImage(series.images[allocatedSpaces + j]);
                //item.setNullImage(series);
                //item.setLoadImageIndex(allocatedSpaces+j);
                item.setParent(grp);
                newRender.setActiveImageItem(item);
                newRender.setPrimaryImageItem(item);
              }
              int last1 = last;
              last1++;
              if (last1 == _listRenderElements.length) {
                _listRenderElements.add(newRender);
              } else {
                _listRenderElements.insert(last1, newRender);
              }
              last++;
            }

            //update the last position:
            last = first;
            if (seriesInfo.rendererCount > 1) {
              if (last + seriesInfo.rendererCount - 1 <
                  _listRenderElements.length) {
                last += seriesInfo.rendererCount - 1;
              } else {
                ok = false;
              }
            }
          }
        }

        //find the position where we should insert the image:
        if (ok) {
          int loadIndex = image.loadIndex;
          int pos = first;
          if (loadIndex >= 0 && pos + loadIndex < _listRenderElements.length) {
            pos += loadIndex;
          } else {
            ok = false;
          }
          if (ok && pos != _listRenderElements.length) {
            OsGraphicImage? img =
                _listRenderElements[pos].getPrimaryImageItem();
            if (img != null) {
              entities.Image? image1 = img.getImage();
              entities.Series? series1 = image1?.series;
              series1 ??= img.isNullImage();
              if (identical(series, series1)) {
                //great, we found the right place!
                incomingImageRender = _listRenderElements[pos];
              }
            }
          }
        }
      }

      OsContainerWnd? container = getContainer();

      if (incomingImageRender != null) {
        OsGraphicImage? img = incomingImageRender.getPrimaryImageItem();
        if (img != null) {
          img.setImage(image);
          if (incomingImageRender.getActiveImageItem() == null) {
            incomingImageRender.setActiveImageItem(img);
          }
          if (incomingImageRender.getPrimaryImageItem() == null) {
            incomingImageRender.setPrimaryImageItem(img);
          }
        }
        //Apply the properties:
        int pageToRefresh = applyIncomingImageProperties(incomingImageRender,
            false); //if we redraw here, it become slow with little images (too much redrawing)
        //restore the states:
        OsGraphicImage? img1 = incomingImageRender.getPrimaryImageItem();
        entities.Image? image1 = img1?.getImage();
        //if (image1 != null && seriesInfo.dupInfo) this._applyImageStates(-1, incomingImageRender, series, image1, seriesInfo.dupInfo, series.findState(this._stateId, 0), fromHangingProtocol);
        //propagate:
        /*OsContainerPropagateItem? propagate = container?.getPropagationItem();
        if (container != null) {
          if (propagate != null) {
            propagate.onReceivedImage(container, incomingImageRender);
          }
          if (pageToRefresh != container.currentPage) {
            container.setCurrentPage(
                index: pageToRefresh, mode: OsContDraw.osForceRedraw);
          }
        }*/
        //this.preloadRenderers();
      }
      if (spaceAdded || !seriesInfo.firstImageArrived) {
        //if space is added everytime, it will be too slow send the modified message each time.
        //we will send only once when it became more than 1
        //if (this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, container);
      }

      if (image.loadStatus.reason == OnisErrorCodes.none) {
        seriesInfo.firstImageArrived = true;
        if (container != null) {
          /*let synchro:IContainerSynchroItem|null = container.getSynchroItem();
                        if (synchro) {
                            synchro.onReceiveImage(container);
                            synchro.synchronize(null, null);
                        }*/
        }
      }

//TODO: Remove later
      container?.setCurrentPage(
          index: container.currentPage, mode: OsContDraw.osForceRedraw);
    }
  }

  //----------------------------------------------------------------------------
  //incoming image
  //----------------------------------------------------------------------------

  OsIncomingImageProperties? getIncomingImageProperties() {
    return _incomingImageProperties;
  }

  int applyIncomingImageProperties(OsRenderer2D render, bool refresh) {
    OsContainerWnd? container = getContainer();
    if (container == null) return -1;

    render.setInitialized();
    WindowLevel? preset = _incomingImageProperties.windowLevelPreset;
    if (preset != null) render.setWindowLevel(preset, false);
    ColorLut? colorLutPreset = _incomingImageProperties.colorLutPreset;
    if (colorLutPreset != null) {
      render.setColorLut(colorLutPreset);
    }
    OpacityTable? opacityTablePreset =
        _incomingImageProperties.opacityTablePreset;
    if (opacityTablePreset != null) {
      render.setOpacityTable(opacityTablePreset);
    }
    ConvolutionFilter? convolutionFilterPreset =
        _incomingImageProperties.convolutionFilterPreset;
    if (convolutionFilterPreset != null) {
      render.setConvolutionFilter(convolutionFilterPreset);
    }

    final rect = container.getImageBoxRect(0);

    if (_incomingImageProperties.zoom == 1) {
      render.scaleCameraToOriginal(rect.width, rect.height);
    } else {
      render.fitCamera(rect.width, rect.height);
    }

    OsGraphicCamera camera = render.getCamera();
    if (_incomingImageProperties.rotation != 0.0) {
      camera.rot[2] = _incomingImageProperties.rotation;
    }
    if (_incomingImageProperties.flipHorizontally) camera.sca[0] = -1;
    if (_incomingImageProperties.flipVertically) camera.sca[1] = -1;
    camera.validateMatrix();

    int pageIndexToRefresh = container.currentPage;
    //if (_incomingImageProperties.targetMode == OsHpMode.mode_page) {
    //try to go the target page:
    if (_incomingImageProperties.targetPage == -1) {
      _incomingImageProperties.targetMode = 0;
      pageIndexToRefresh = container.pageCount - 1;
    } else if (_incomingImageProperties.targetPage < container.pageCount) {
      _incomingImageProperties.targetMode = 0;
      pageIndexToRefresh = _incomingImageProperties.targetPage;
    }
    //}
    /*else if (_incomingImageProperties.targetMode == OSHP.mode_dicom_tags) {
      for (let index=0; index<this._listRenderElements.length; index++) {
                    if (this._listRenderElements[index].isHidden()) continue;
                    let img:OsGraphicImage|null = this._listRenderElements[index].getPrimaryImageItem(false);
                    if (img) {
                        let image:OsOpenedImage|null = img.getImage();
                        let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                        if (dcm) {
                            let match:boolean = true;
                            for (let i=0; i<this._incomingImageProperties.targetTags.length; i++) {
                                let value:string = '';
                                let stag:string = this. _convertTag(this._incomingImageProperties.targetTags[i].tag);
                                if(stag.length > 0){
                                    value = dcm.getStringElement(stag, null, null);
                                    if (value.length == 0) { 
                                        match = false; 
                                        break; 
                                    }
                                    if (value !== this._incomingImageProperties.targetTags[i].value) {
                                        match = false; 
                                        break; 
                                    }
                                }
                            }
                            if (match) {
                                this._incomingImageProperties.targetMode = 0;
                                pageIndexToRefresh = index;
                            }
                        }
                    }
                }
    }*/
    if (refresh) {
      container.setCurrentPage(
          index: pageIndexToRefresh, mode: OsContDraw.osForceRedraw);
    }
    return pageIndexToRefresh;
  }
}
