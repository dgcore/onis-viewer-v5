import 'package:onis_viewer/api/graphics/renderers/renderer_2d.dart';
import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/api/services/message_service.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/container/controllers/container_controller.dart';
import 'package:onis_viewer/core/graphics/renderer/items/group.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/items/item.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
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
  final String _stateId = "";
  OsMessageSubscription? _messageSubscription;

  OsContainerController2D() {
    _messageSubscription = OVApi().messages.subscribe(onReceivedMessage);
  }

  void dispose() {
    _messageSubscription?.cancel();
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
    }

    if (series.loadStatus.status == ResultStatus.pending) {
      if (container != null) {
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

  OsDisplayedSeriesInfo? _findSeriesInfo(entities.Series series) {
    for (int i = 0; i < _listOfSeriesInfo.length; i++) {
      if (_listOfSeriesInfo[i].series == series) {
        return _listOfSeriesInfo[i];
      }
    }
    return null;
  }

  void onReceivedMessage(OsMessage? message) {
    if (message?.id == OSMSG.seriesDownloadReceivedInfo) {
      _onReceivedSeriesInfo(message!.data["series"] as entities.Series);
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
                item.setImage(series.images[j]);
              }
            }
          }
          OVApi().messages.sendMessage(OSMSG.imageContainerModified, container);
          break;
        }
      }
    }
    container?.setCurrentPage(
        index: container!.currentPage, mode: OsContDraw.osForceRedraw);
  }
}
