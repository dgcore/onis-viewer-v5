import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/api/request/async_request.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/result/result.dart';
import 'package:onis_viewer/plugins/database/controller/download/download_candidate.dart';
import 'package:onis_viewer/plugins/database/controller/download/download_container.dart';
import 'package:onis_viewer/plugins/database/controller/download/download_performance.dart';
import 'package:onis_viewer/plugins/database/controller/download/download_series.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';
import 'package:onis_viewer/plugins/database/public/download_controller_interface.dart';

class DownloadController extends IDownloadController {
  //for series download
  final List<DownloadContainer> _containers = [];
  final List<DownloadSeries> _waitingList = [];
  final List<DownloadSeries> _downloadingList = [];
  int _maxConcurrentDownload = 4;
  final List<DownloadPerformance> _performanceSources = [];
  final int _containerIndex = -1;
  //final List<OsJ2kDecodeItem> _j2kItems = [];
  //final List<OsJ2kDecoder> _j2kDecoders = [];

  //for multi-frames images:
  //private _mfWaitingList:OsDownloadMultiFrames[] = [];
  //private _mfDownloadingList:OsDownloadMultiFrames[] = [];
  //private _mfMaxConcurrentDownload:number = 2;

  //for icon download:
  //private _iconItems:OsSeriesIconsItem[] = [];
  //private _currentIconDownloadCount:number = 0;
  //private _maxConcurrentIconRetrieve:number = 2;

  //for image decoders:
  //private _maxImageDecoders:number = 2;

  DownloadController() {
    // for (let iinnumber = 0; i<this._maxImageDecoders; i++) _j2kDecoders.push(OsJ2kDecoder(this));
  }

  /*public destroy() {
        _containers.forEach(item=>item.destroy());
        _containers.splice(0, _containers.length);
        //this._currentRequests.forEach(elt=>elt.destroy());
        _performanceSources.forEach(elt=>elt.destroy());
        //this._seriesInfo.forEach(elt=>elt.destroy());

        _waitingList.forEach(item=>item.release());
        _downloadingList.forEach(item=>item.release());
        this._mfWaitingList.forEach(item=>item.release());
        this._mfDownloadingList.forEach(item=>item.release());
        _waitingList.splice(0, _waitingList.length);
        _downloadingList.splice(0, _downloadingList.length);
        this._mfWaitingList.splice(0, this._mfWaitingList.length);
        this._mfDownloadingList.splice(0, this._mfDownloadingList.length);

        for (let i=0; i<_j2kItems.length; i++) _j2kItems[i].release();
        _j2kItems.splice(0, _j2kItems.length);
        for (let i=0; i<_j2kDecoders.length; i++) _j2kDecoders[i].release();
        _j2kDecoders.splice(0, _j2kDecoders.length);

        for (let i=0; i<this._iconItems.length; i++) this._iconItems[i].release();
        this._iconItems.splice(0, this._iconItems.length);

        this._cleanSourcePerformances();

    }*/

  get maxConcurrentDownload => _maxConcurrentDownload;
  //get maxImageDecoders => _maxImageDecoders;

  set maxConcurrentDownload(count) {
    if (count >= 1 && count <= 10) {
      _maxConcurrentDownload = count;
      processLoadingQueue();
    }
  }

  /*public setMaxImageDecoders(count =number):boolean {
        if (count >= 1 && count <= 10 && this._maxImageDecoders != count) {
            let prev:number = this._maxImageDecoders;
            this._maxImageDecoders = count;
            let dif:number = this._maxImageDecoders - prev;
            if (dif > 0) {
                for (let iinnumber=0; i<dif; i++) 
                    _j2kDecoders.push(OsJ2kDecoder(this));
            }
            else {
                for (let i=_j2kDecoders.length-1; i>=0 && _j2kDecoders.length > this._maxImageDecoders; i--) {
                    if (!_j2kDecoders[i].isBusy()) {
                        _j2kDecoders[i].release();
                        _j2kDecoders.splice(i, 1);
                    }
                }
            }
            return true;
        }
        return false;
    }*/

  //-----------------------------------------------------
  // Containers
  //-----------------------------------------------------

  /*public registerContainer(container =IContainerWnd, reg =boolean):void {
        let index:[number] = [-1];
        this._findContainer(container, index);
        //register or unregister:
        if (reg && index[0] == -1) _containers.push(OsDownloadContainer(container));
        else
        if (!reg && index[0] != -1) {
            _containers[index[0]].destroy();
            _containers.splice(index[0], 1);
        }
    }

    public setContainerPriority(container =IContainerWnd, hasPriority =boolean):void {
        let info:OsDownloadContainer|null = this._findContainer(container, null);
        if (info) info.hasPriority = hasPriority;
    }

    private _findContainer(container =IContainerWnd, index =[number]|null):OsDownloadContainer|null {
        for (let iinnumber=0; i<_containers.length; i++) 
            if (_containers[i].getContainer() === container) {
                if (index) index[0] = i;
                return _containers[i];
            }
        if (index) index[0] = -1;
        return null;
    }

    private _cleanContainers():void {
        for (let iinnumber=0; i<_containers.length; i++) 
            if (_containers[i].getContainer() === null) {
                _containers[i].destroy();
                _containers.splice(i, 1);
                i--;
            }
    }*/

  //-----------------------------------------------------
  // download series
  //-----------------------------------------------------

  @override
  void addSeriesToLoadingQueue(entities.Series series, bool process) {
    for (final item in _waitingList) {
      if (item.series == series) {
        return;
      }
    }
    for (final item in _downloadingList) {
      if (item.series == series) {
        return;
      }
    }
    final info = DownloadSeries(series);
    _waitingList.add(info);
    if (process) {
      processLoadingQueue();
    }
  }

  void processLoadingQueue() {
    //clean up the active list:
    for (int i = 0; i < _downloadingList.length; i++) {
      entities.Series? series = _downloadingList[i].series;

      bool remove = series != null
          ? series.loadStatus.status != ResultStatus.pending &&
              series.loadStatus.status != ResultStatus.waiting
          : true;
      if (remove) {
        _downloadingList.removeAt(i);
        i--;
      }
    }
    //cleanup the waiting list:

    //start series download:
    while (_waitingList.isNotEmpty) {
      if (_maxConcurrentDownload > 0 &&
          _downloadingList.length >= _maxConcurrentDownload) {
        break;
      }
      _downloadingList.add(_waitingList[0]);
      _waitingList.removeAt(0);
      if (!_startDownload(_downloadingList[_downloadingList.length - 1])) {
        _downloadingList.removeAt(_downloadingList.length - 1);
      }
    }
  }

  bool _startDownload(DownloadSeries info) {
    entities.Series? series = info.series;
    series?.loadStatus.status = ResultStatus.waiting;

    String? sourceUid = series?.sourceUid;
    if (sourceUid == null) return false;

    final dbApi =
        OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    final source = dbApi?.sourceController.sources.findSourceByUid(sourceUid);
    if (source == null) return false;

    Map<String, dynamic> data = {
      "series": [series]
    };
    info.request = source.createRequest(RequestType.initSeriesDownload, data);
    if (info.request != null) {
      info.request?.send().then((response) {
        _onInitSeriesDownloadResponse(info, response);
      });
    }
    return info.request != null;
  }

  /*@override
  Future<FindPatientStudyResponse> findStudies(String sourceUid,
      {DBFilters? filters, bool withSeries = false}) async {
    final source = _databaseSourceManager.findSourceByUid(sourceUid);
    if (source == null) {
      throw OnisException(
        OnisErrorCodes.logicError,
        'Source not found: $sourceUid',
      );
    }
    Map<String, dynamic> data = {};
    if (filters != null) {
      data['filters'] = filters.toJson();
    }
    if (withSeries) {
      data['with-series'] = true;
    }
    AsyncRequest? request = source.createRequest(RequestType.findStudies, data);
    try {
      AsyncResponse? response = await request?.send();
      if (response != null && response.data != null) {
        return FindPatientStudyResponse.fromJson(source, response.data!);
      } else {
        return FindPatientStudyResponse(
            source: source,
            status: OnisErrorCodes.invalidResponse,
            sources: []);
      }
    } on OnisException catch (e) {
      return FindPatientStudyResponse(
          source: source, status: e.code, sources: []);
    } catch (e) {
      return FindPatientStudyResponse(
          source: source, status: OnisErrorCodes.unknown, sources: []);
    }
  }*/

  //-----------------------------------------------------
  // download images
  //-----------------------------------------------------
  void _downloadImages(DownloadSeries info) {
    if (!_downloadingList.contains(info) || info.request != null) return;
    entities.Series? series = info.series;
    if (series == null || series.loadStatus.status != ResultStatus.waiting) {
      processLoadingQueue();
      return;
    }
    DownloadCandidates? candidates = _getImagesToDownload(info);
    if (candidates == null) return;
    DatabaseSource source = candidates.source;

    /*let items:any[] = [];
    for (let jinnumber=0; j<candidates.images.length; j++) {
        let image:OsOpenedImage = candidates.images[j];
        let dcm:OsDicomFile|null = image.getDicomFile();
        if (!dcm) items.push({dl:info.downloadSeq, index: image.loadIndex, from: -1});
        else {
            let interData:OsIntermediatePixelData|null = dcm.getIntermediatePixelData(0);
            if (interData) items.push({dl:info.downloadSeq, index: image.loadIndex, from: interData.resIndex});
        }
    }
    if (items.length) {
        let sp:DownloadPerformance|null = this._getSourcePerformance(source, true);
        info.tm = performance.now();
        info.request = this._onis.viewerService.downloadImages(server, source.session, source.subType, source.sourceId, items, candidates.pendingRanges, info.maxBytes, _onDownloadImagesResponse, this, info.guid);
    }*/
  }

  DownloadCandidates? _getImagesToDownload(DownloadSeries info) {
    DownloadCandidates? candidates;
    /*let candidates:OsDownloadCandidates|null = null;
        //make sure all containers are valid:
        this._cleanContainers();
        //we alternate the first container to analyze, to make the download more balanced.
        let series:OsOpenedSeries|null = info.getSeries();
        let source:IPacsSource|null = series?series.getSource():null;
        if (series && source) {
            candidates = OsDownloadCandidates(source);
            if (_containers.length > 1) _containerIndex = (_containerIndex + 1) % _containers.length;
            else _containerIndex = 0;
            //prepare container information.
            let contInfo:any[] = [];
            for (let kinnumber=0; k<2; k++) {
                let start:number = k?0:_containerIndex;
                let stop:number = k?_containerIndex:_containers.length;
                for (let iinnumber=start; i<stop; i++) {
                    let container:IContainerWnd|null = _containers[i].getContainer();
                    let controller:IContainerController|null = container?container.getController():null;
                    if (!container || !controller || !controller.isSeriesDisplayed(series)) continue;
                    let renderers:IRenderer[] = controller.getRendererElements();
                    if (renderers) {
                        let rowCol:[number, number] = [0, 0];
                        container.getImageMatrix(rowCol);
                        let count:number = rowCol[0]*rowCol[1];
                        let startIndex = container.getCurrentPage();
                        if (container.getPageMode()) startIndex *= count;
                        let firstPos:number = container.findStartingPosition(renderers, startIndex);
                        let lastPos:number = firstPos;
                        if (count > 1) {
                            for (let jinnumber=firstPos; j<renderers.length; j++) 
                                if (renderers[j] === container.getImageBoxRenderer(count-1)) {
                                    lastPos = i;
                                    break;
                                }
                        }
                        contInfo.push({
                            container: _containers[i],
                            renderers: renderers,
                            firstPos: firstPos,
                            lastPos: lastPos,
                            done: false,
                        });
                    }
                }
            }

            

            for (let iinnumber=0; i<_containers.length; i++) {
                let container:IContainerWnd|null = _containers[i].getContainer();
                let controller:IContainerController|null = container?container.getController():null;
                if (container && controller) {
                    if (controller.isSeriesDisplayed(series)) {
                        //get all candidates:
                        let rowCol:[number, number] = [0, 0];
                        container.getImageMatrix(rowCol);
                        let count:number = rowCol[0]*rowCol[1];
                        for (let jinnumber=0; j<count; j++) {
                            let render:IRenderer|null = container.getImageBoxRenderer(j);
                            if (!render) continue;
                            let data:[OsOpenedSeries|null, OsOpenedImage|null] = this._getRenderInfo(candidates, series, render);
                            if (data[0]) candidates.registerCandidate(data[0], data[1]);
                        }
                    }
                }
            }
            candidates.analyzeCandidates(true);

            //now, search within undisplayed images:
            if (contInfo.length) {
                let done:number = 0;
                let index:number = 0;
                while (1) {
                    if (!contInfo[index].done) {
                        contInfo[index].firstPos--;
                        contInfo[index].lastPos++;
                        if (contInfo[index].firstPos < 0 && contInfo[index].lastPos >= contInfo[index].renderers.length) {
                            contInfo[index].done = true;
                            done++;
                        }
                        else {
                            if (contInfo[index].lastPos < contInfo[index].renderers.length) {
                                let info:[OsOpenedSeries|null, OsOpenedImage|null] = this._getRenderInfo(candidates, series, contInfo[index].renderers[contInfo[index].lastPos]);
                                if (info[0]) candidates.registerCandidate(info[0], info[1]);
                            }
                            if (contInfo[index].firstPos >= 0) {
                                let info:[OsOpenedSeries|null, OsOpenedImage|null] = this._getRenderInfo(candidates, series, contInfo[index].renderers[contInfo[index].firstPos]);
                                if (info[0]) candidates.registerCandidate(info[0], info[1]);
                            }
                        }
                    }
                    if (done == contInfo.length) break;
                    index = (index+1)%contInfo.length;
                }
                candidates.analyzeCandidates(false);
            }

            if (candidates.images.length == 0 && series.loadStatus.status == RESULT.OSRSP_WAITING) {
                for (let iinnumber=0; i<series.images.length; i++) {
                    //ignore if the image download is completed:
                    let image:OsOpenedImage = series.images[i];
                    if (image && image.loadStatus.status != RESULT.OSRSP_PENDING && image.loadStatus.status != RESULT.OSRSP_STREAMING) continue;
                    if (!candidates.registerCandidate(series, image)) break;
                }
                candidates.analyzeCandidates(false);
            }

            //indicate the range of images we can download:
            info.pendingRanges.forEach(elt=>{if (candidates) candidates.pendingRanges.push([elt[0], elt[1]]);});
        }*/
    return candidates;
  }

  /*private _getRenderInfo(candidates =OsDownloadCandidates, from =OsOpenedSeries, render =IRenderer):[OsOpenedSeries|null, OsOpenedImage|null] {
        if (!render) return [null, null];
        if (candidates.isFull()) return [null, null];
        let img:OsGraphicImage|null = render?render.getPrimaryImageItem(false):null;
        let series:OsOpenedSeries|null = img?img.isNullImage():null;
        let image:OsOpenedImage|null = img?img.getImage():null;
        if (image && !series) series = image.getParent(false);
        if (series !== from) return [null, null];
        //ignore if the series download is completed or if there is no series:
        if (!series || (series.loadStatus.status != RESULT.OSRSP_PENDING && series.loadStatus.status != RESULT.OSRSP_WAITING)) return [null, null];
        //ignore if the image download is completed:
        if (image && image.loadStatus.status != RESULT.OSRSP_PENDING && image.loadStatus.status != RESULT.OSRSP_STREAMING) return [null, null];
        //get the source:
        let source = series.getSource();
        if (!source) return [null, null];
        return [series, image];
    }*/

  //-----------------------------------------------------
  // series response
  //-----------------------------------------------------

  void _onInitSeriesDownloadResponse(
      DownloadSeries info, AsyncResponse response) {
    final series = info.series;
    if (response.isSuccess && response.data != null) {
      try {
        String downloadSeq = response.data!["data"][0]['seq'] as String;
        int imageCount = response.data!["data"][0]['image_count'] as int;
        info.downloadSeq = downloadSeq;
        if (imageCount == -1) {
          //don't know yet how many images there is in the series, we prepare just one:
          series?.prepareForDownload(1);
          info.pendingRanges = [
            [0, 0xFFFFFF]
          ];
        } else {
          series?.prepareForDownload(imageCount);
          info.pendingRanges = [
            [0, 0xFFFFFF]
          ];
        }

        /*let properties:{} = null;
        if ('properties' in data.data[0]) {
            if ('version' in data.data[0].properties && 'properties' in data.data[0].properties) {
                if (data.data[0].properties.version === '1.0.0.0') {
                    properties = data.data[0].properties.properties;
                    /*let manager:OsGraphicManager = this._viewer.getGraphicManager();
                    let vtypes:OsViewType[] = manager?manager.getListOfViewTypes():null;
                    vtypes.forEach(type=>{
                        let stateId:string = 'VIEWER_'+type.getId();
                        if (stateId in properties) {
                            type.loadStates(info.series, stateId, properties[stateId]);
                        }
                    });*/
                }
            }
        }*/

        OVApi().messages.sendMessage(OSMSG.seriesDownloadReceivedInfo,
            {"series": series, "properties": null});
      } catch (e) {
        series?.loadStatus.setStatus(
            ResultStatus.failure, OnisErrorCodes.invalidResponse, "");
      }
    } else {
      series?.loadStatus.setStatus(
          ResultStatus.failure, OnisErrorCodes.networkConnection, "");
    }
    if (info.request != null) {
      //info.request.cancel();
      info.request = null;
    }
    _downloadImages(info);
  }

  ///////////////////////////////////////////////////////
  // image response
  ///////////////////////////////////////////////////////

  /*private _analyzeBandwidth(srinfo =DownloadSeries, series =OsOpenedSeries, bytes =Uint8Array):void {
      let sp:DownloadPerformance|null = this._getSourcePerformance(series.getSource(), false);
      var duration = (performance.now() - srinfo.tm) / 1000.0;
      //console.log("duration: " + duration + " / ping time: " + sp.pingTime);
      if (sp) duration -= sp.pingTime;
      if (duration > 0) {
        srinfo.maxBytes = Math.round(Math.floor(bytes.length / duration));
        let prev:number = srinfo.maxBytes;
        if (srinfo.maxBytes < 50*1024) srinfo.maxBytes = 50*1024;
        else if (srinfo.maxBytes > 512*1024) srinfo.maxBytes = 512*1024;
        srinfo.maxBytes = 10*1024;
        //console.log("bandwidth: " + srinfo.maxBytes + " prev: " + prev + " new: " + srinfo.maxBytes);
      }
    }

    private _onDownloadImagesResponse(status =boolean, data =any, cbkdata =any) {
      let srinfo:DownloadSeries|undefined = _downloadingList.find(elt=>elt.guid === cbkdata);
      let series:OsOpenedSeries|null = srinfo?srinfo.getSeries():null;
      let delayNextDownload:boolean = false;
      let completedImages:OsOpenedImage[] = [];
      let firstTimeImages:OsOpenedImage[] = [];
      if (!delayNextDownload) this._downloadImages(srinfo.guid);
      else setTimeout(()=>{if (srinfo) this._downloadImages(srinfo.guid);}, 500);

      if (this._viewer.messageService) {
        if (firstTimeImages.length > 0) this._viewer.messageService.sendMessage(MSG.SERIES_IMAGES_RECEIVED, firstTimeImages);
        if (completedImages.length > 0) this._viewer.messageService.sendMessage(MSG.SERIES_IMAGES_DOWNLOAD_COMPLETED, completedImages);
      }

    }

    private _interruptSeriesDownload(series =OsOpenedSeries, status =number, reason =number, completedImages =OsOpenedImage[]):number {
      series.images.forEach(image=> {
        if (image.loadStatus.status == RESULT.OSRSP_PENDING) {
          image.loadStatus.status = status;
          image.loadStatus.reason = reason;
          completedImages.push(image);
        } 
      });
      series.loadStatus.status = status;
      series.loadStatus.reason = reason;
      return -1;
    }

    private _readSeriesInformation(srinfo =DownloadSeries, series =OsOpenedSeries, bytes =Uint8Array, offset =number):number {
      let valid:boolean = true;
      //read the series uid:
      let length:number = bytes[offset]; offset++;
      let str:string = '';
      if (length < 0 || length > 100) valid = false;
      else {
        for (let j=0; j<length; j++) str += String.fromCharCode(bytes[j+offset]);
        offset += length;
        //make sure the series id matches:
        if (series.downloadSeq !== str) valid = false;
        else {
          //information if all the series images are ready to transfer at server side, and also how many images to expect in the series: 
          let completed:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
          let expected:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;  
          //console.log("series uid: " + series.getDatabaseInfo().uid + " completed: " + completed + " expected: " + expected);
          if (completed != 0 && completed != 1) valid = false;
          else if (expected != 0xFFFFFF && (expected < 0 || expected > 2000)) valid = false;
          else {
            srinfo.completed = completed == 1;
            if (expected != 0xFFFFFF) {
              if (srinfo.expected != expected) {
                srinfo.expected = expected;
                series.prepareForDownload(expected);
              }
            }
            if (srinfo.completed && srinfo.pendingRanges.length) {
              if (srinfo.pendingRanges[srinfo.pendingRanges.length-1][1] == 0xFFFFFF) {
                srinfo.pendingRanges[srinfo.pendingRanges.length-1][1] = series.images.length-1;
              }
            }      
          }
        }
      }
      return valid?offset:-1;
    }

    private _readImageInformation(series =OsOpenedSeries, bytes =Uint8Array, offset =number):[number, string, OsOpenedImage|null, number, number] {
      let valid:boolean = true;
      let str:string = '';
      let imageIndex:number = -1;
      let imageResult:number = RESULT.EOS_INTERNAL;
      let image:OsOpenedImage|undefined = undefined;
      let length:number = bytes[offset]; offset++;
      if (length < 0 || length > 100) valid = false;
      else {
        for (let j=0; j<length; j++) str += String.fromCharCode(bytes[j+offset]);
        offset += length;
        imageIndex = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
        imageResult = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
        if (imageResult < 0 || imageIndex < 0 || imageIndex >= series.images.length) valid = false;
        else {
          image = series.images.find(elt=>elt.loadIndex == imageIndex);
          if (!image) valid = false;
        }
      }
      return valid?[offset, str, image, imageIndex, imageResult]:[-1, '', null, -1, -1];
    }

    private _updateImageRangeIndex(srinfo =DownloadSeries, imageIndex =number):void {
      for (let iinnumber=0; i<srinfo.pendingRanges.length; i++) {
        if (imageIndex >= srinfo.pendingRanges[i][0] && imageIndex <= srinfo.pendingRanges[i][1]) {
            if (srinfo.pendingRanges[i][0] == srinfo.pendingRanges[i][1] && srinfo.pendingRanges[i][0] == imageIndex) srinfo.pendingRanges.splice(i, 1);
            else if (imageIndex == srinfo.pendingRanges[i][0]) srinfo.pendingRanges[i][0] = imageIndex+1;
            else if (imageIndex == srinfo.pendingRanges[i][1]) srinfo.pendingRanges[i][1] = imageIndex-1;
            else {
                srinfo.pendingRanges.splice(i+1, 0, [imageIndex+1, srinfo.pendingRanges[i][1]]);
                srinfo.pendingRanges[i][1] = imageIndex-1;
            }
            break;
        }
      }
    }

    private _readDicomFileInformation(image =OsOpenedImage, bytes =Uint8Array, offset =number):number {
      let valid:boolean = true;
      let tagsLength:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
      if (tagsLength <= 0 || tagsLength+offset > bytes.length) valid = false;
      else {
        //read the tags:
        let jsonStr:string = '';
        //for (let i=0; i<tagsLength; i++) jsonStr += String.fromCharCode(bytes[i+offset]);
        let tagData:Uint8Array = bytes.subarray(offset, offset+tagsLength);
        jsonStr = TextDecoder("utf-8").decode(tagData);


        offset += tagsLength;
        //read the palette:
        let palette:Array<OsDicomRawPalette|null> = [null, null, null];
        let paletteLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
        if (paletteLen > 0) {
          for (let kinnumber = 0; k < 3; k++) {
            let pl:OsDicomRawPalette = OsDicomRawPalette();
            pl.count = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
            pl.bits = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
            pl.value = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
            let dataLen:number = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
            if (dataLen < 0 || dataLen > 150000 || dataLen+offset>bytes.length) { valid = false; pl.release(); break; }
            else {
                pl.data = bytes.slice(offset, offset+dataLen);
                offset += dataLen;
            }
            palette[k] = pl;
          }
        }
        try {
          let decodedTags:any = JSON.parse(jsonStr);
          let dcm:OsDicomFile = OsDicomFile(decodedTags);
          image.setDicomFile(dcm);
          for (let kinnumber=0; k<3; k++) dcm.setPalette(k, palette[k]);
          dcm.release();
        }
        catch(e) {
          valid = false;
        }
        palette.forEach(item=>item?.release());
      }
      return valid?offset:-1;
    }

    private _readMonochromeRawData(image =OsOpenedImage, width =number, height =number, bytes =Uint8Array, offset =number, firstTimeImages =OsOpenedImage[]):number {
      let valid:boolean = true;
      let representation:number = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 2;
      let signedData:boolean = bytes[offset] == 0 ? false : true; offset += 1;
      let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
      if (pixLen <= 0 || pixLen+offset > bytes.length) valid = false;
      else if (representation != 8 && representation != 12 && representation != 16) valid = false;
      else {
        let interData:OsIntermediatePixelData|null = null;
        let dcm:OsDicomFile|null = image.getDicomFile();
        valid = false;
      }
      return valid?offset:-1;
    }

    private _readRgbRawData(image =OsOpenedImage, width =number, height =number, bytes =Uint8Array, offset =number, firstTimeImages =OsOpenedImage[]):number {
      let valid:boolean = true;
      let bitsPerPixel:number = bytes[offset]; offset += 1;
      if (bitsPerPixel != 24 && bitsPerPixel != 32) valid = false;
      else {
        let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
        if (pixLen <= 0 || pixLen+offset > bytes.length) valid = false;
        else {
          let dcm:OsDicomFile|null = image?image.getDicomFile():null;
          valid = false;
        }
      }
      return valid?offset:-1;
    }

    private _readMonochromePngData(image =OsOpenedImage, width =number, height =number, bytes =Uint8Array, offset =number, firstTimeImages =OsOpenedImage[]):number {
      let valid:boolean = true;
      let representation:number = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 2;
      let signedData:boolean = bytes[offset] == 0 ? false : true; offset += 1;
      let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
      if (pixLen <= 0 || pixLen+offset > bytes.length) valid = false;
      else if (representation != 8 && representation != 12 && representation != 16) valid = false;
      else {
        let pngData:Uint8Array = bytes.slice(offset, offset+pixLen);
        offset += pixLen;
        let interData:OsIntermediatePixelData|null = null;
        let dcm:OsDicomFile|null = image.getDicomFile();
        valid = false;
      }
      return valid?offset:-1;
    }

    private _readRgbPngData(image =OsOpenedImage, width =number, height =number, bytes =Uint8Array, offset =number, firstTimeImages =OsOpenedImage[]):number {
      let valid:boolean = true;
      let bitsPerPixel:number = bytes[offset]; offset += 1;
      if (bitsPerPixel != 24 && bitsPerPixel != 32) valid = false;
      else {
        let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
        if (pixLen < 0 || pixLen+offset > bytes.length) valid = false;
        else {
          let pngData:Uint8Array = bytes.slice(offset, offset+pixLen);
          offset += pixLen;
          let dcm:OsDicomFile|null = image?image.getDicomFile():null;
          valid = false;
        }
      }
      return valid?offset:-1;
    }*/

  /*private _readJ2kData(srinfo:DownloadSeries, image:OsOpenedImage, imageBytes:Uint8Array, offset:number, minValue:number, maxValue:number, firstTimeImages:OsOpenedImage[], completedImages:OsOpenedImage[]):number {
      let valid:boolean = true;
      let dcm:OsDicomFile|null = image?image.getDicomFile():null;
      if (dcm != null) { 
        let interData:OsIntermediatePixelData = new OsIntermediatePixelData();
        interData.finalMinValue = minValue;
        interData.finalMaxValue = maxValue;
        interData.encodedData = [];
        interData.encodedData.push(imageBytes);
        interData.encodedDataFormat = ENCODED_FORMAT.J2K;
        interData.rgbOrder = 0;
        let info:[number,number] = this._getJ2kResInfo(interData.encodedData);
        interData.resIndex = info[0];
        interData.resCount = info[1];
        dcm.setIntermediatePixelData(0, interData);
        interData.release();
        firstTimeImages.push(image);
        if (interData.resIndex == interData.resCount-1) 
            this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
        else {
            image.loadStatus.status = RESULT.OSRSP_STREAMING;
            image.loadStatus.reason = RESULT.EOS_NONE;
        }
        this.addJ2kStreamToDecode(image);
      }
      else valid = false;
      return valid?offset:-1;
    }

    private _addJ2kData(srinfo:DownloadSeries, image:OsOpenedImage, dcm:OsDicomFile, bytes:Uint8Array, offset:number, completedImages:OsOpenedImage[]):number {
      let valid:boolean = true;
      let interData:OsIntermediatePixelData|null = dcm.getIntermediatePixelData(0);
      if (interData && interData.encodedDataFormat == ENCODED_FORMAT.J2K) {
        let dataLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
        if (dataLen > 0 && dataLen+offset <= bytes.length) {
            if (interData.encodedData) {
                interData.encodedData.push(bytes.slice(offset, offset+dataLen));
                let info:[number,number] = this._getJ2kResInfo(interData.encodedData);
                interData.resIndex = info[0];
                interData.resCount = info[1];
                if (interData.resIndex == interData.resCount-1) 
                  this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                this.addJ2kStreamToDecode(image);
            }
            else {
              //we should not be here
              this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INTERNAL, "");
            }
            offset += dataLen;
        }
        else {
          if (dataLen == 0) {
              //there is a problem with file on the server:
              this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_NO_FILE, "");
          }
          else valid = false;
        }
      }
      else valid = false;
      return valid?offset:-1;
    }*/

  /*private _onDownloadImagesResponse1(status =boolean, data =any, cbkdata =any) {
        let srinfo:DownloadSeries|undefined = _downloadingList.find(elt=>elt.guid === cbkdata);
        let series:OsOpenedSeries|null = srinfo?srinfo.getSeries():null;
        if (srinfo && series) {
            let sp:DownloadPerformance|null = this._getSourcePerformance(series.getSource(), false);
            let gotImageData:boolean = false;
            if (status && data) {
                let bytes:Uint8Array = Uint8Array(data);
                var duration = (performance.now() - srinfo.tm) / 1000.0;
                //console.log("duration: " + duration + " / ping time: " + sp.pingTime);
                if (sp) duration -= sp.pingTime;
                if (duration > 0) {
                    srinfo.maxBytes = bytes.length / duration;
                    //console.log("bandwidth: " + srinfo.maxBytes);
                    if (srinfo.maxBytes < 50*1024) srinfo.maxBytes = 50*1024;
                    else if (srinfo.maxBytes > 512*1024) srinfo.maxBytes = 512*1024;

                    srinfo.maxBytes = 10*1024;

                }
                let offset:number = 0;
                let responseStatus:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                offset += 4;
                if (responseStatus == 0) {
                    //read the number of series information:
                    let count:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                    offset += 4;
                    if (count > 0 && count < 1000) {
                        for (let iinnumber=0; i<count; i++) {
                            let length:number = bytes[offset]; offset++;
                            let str:string = '';
                            for (let j=0; j<length; j++) str += String.fromCharCode(bytes[j+offset]);
                            offset += length;
                            let completed:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                            let expected:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                            //if completed is 1, it means that the server has information about the total number of images for the series and that all the images are avaialble for transfer
                            //let srinfo:DownloadSeries = this._seriesInfo.find(elt=>elt.downloadSeq==str);
                            //if (srinfo) {
                                srinfo.completed = completed == 1;
                                if (expected != 0xFFFFFF) {
                                    if (srinfo.expected != expected) {
                                        srinfo.expected = expected;
                                        let series:OsOpenedSeries|null = srinfo.getSeries();
                                        if (series) series.prepareForDownload(expected);
                                    }
                                }
                                if (srinfo.completed && srinfo.pendingRanges.length) {
                                    if (srinfo.pendingRanges[srinfo.pendingRanges.length-1][1] == 0xFFFFFF) {
                                        let series:OsOpenedSeries|null = srinfo.getSeries();
                                        if (series) srinfo.pendingRanges[srinfo.pendingRanges.length-1][1] = series.images.length-1;
                                    }
                                }
                            //}
                        }
                    }
                    let valid:boolean = true;
                    let completedImages:OsOpenedImage[] = [];
                    let firstTimeImages:OsOpenedImage[] = [];

                    while (offset < bytes.length) {

                        let length:number = bytes[offset]; offset++;
                        let str:string = '';
                        for (let j=0; j<length; j++) str += String.fromCharCode(bytes[j+offset]);
                        offset += length;
                        let imageIndex:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                        let imageResult:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                        let image:OsOpenedImage|undefined = series.images.find(elt=>elt.loadIndex == imageIndex);

                        
                        //update the range index:
                        for (let iinnumber=0; i<srinfo.pendingRanges.length; i++) {
                            if (imageIndex >= srinfo.pendingRanges[i][0] && imageIndex <= srinfo.pendingRanges[i][1]) {
                                if (srinfo.pendingRanges[i][0] == srinfo.pendingRanges[i][1] && srinfo.pendingRanges[i][0] == imageIndex) srinfo.pendingRanges.splice(i, 1);
                                else if (imageIndex == srinfo.pendingRanges[i][0]) srinfo.pendingRanges[i][0] = imageIndex+1;
                                else if (imageIndex == srinfo.pendingRanges[i][1]) srinfo.pendingRanges[i][1] = imageIndex-1;
                                else {
                                    srinfo.pendingRanges.splice(i+1, 0, [imageIndex+1, srinfo.pendingRanges[i][1]]);
                                    srinfo.pendingRanges[i][1] = imageIndex-1;
                                }
                                break;
                            }
                        }

                       
                        
                        if (imageResult != 0) {
                            if (imageResult == RESULT.EOS_NOT_EXIST) {
                                //the image was not found. 
                                //if the download is not completed, it may arrive later. 
                                //Otherwise, it should have been founded.
                                if (srinfo.completed && image) this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, imageResult, "");
                            }
                            else {
                                if (image) {
                                    gotImageData = true;
                                    this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, imageResult, "");
                                }
                            }
                        }
                        else {
                            gotImageData = true;
                            let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                            if (!dcm) {
                                let type:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                if (type == ENCODED_FORMAT.RAW) {
                                    let tagsLength:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                    if (tagsLength > 0 && tagsLength+offset <= bytes.length) {
                                        let jsonStr:string = '';
                                            for (let i=0; i<tagsLength; i++)
                                                jsonStr += String.fromCharCode(bytes[i+offset]);
                                        offset += tagsLength;

                                        let palette:Array<OsDicomRawPalette|null> = [null, null, null];
                                        let paletteLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        if (paletteLen > 0) {
                                            for (let kinnumber = 0; k < 3; k++) {
                                                let pl:OsDicomRawPalette = OsDicomRawPalette();
                                                pl.count = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                pl.bits = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                pl.value = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                let dataLen:number = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                if (dataLen < 0 || dataLen > 150000) valid = false;
                                                else {
                                                    pl.data = bytes.slice(offset, offset+dataLen);
                                                    offset += dataLen;
                                                }
                                                palette[k] = pl;
                                            }
                                        }
                                        let width:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let height:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let isRgb:boolean = bytes[offset] == 0 ? false : true; offset += 1;
                                        if (isRgb) {
                                            let bitsPerPixel:number = bytes[offset]; offset += 1;
                                            if (bitsPerPixel == 24 || bitsPerPixel == 32) {
                                                let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                if (pixLen > 0 && pixLen+offset <= bytes.length) {
                                                    let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                                                    if (image) { 
                                                        try {
                                                            let decodedTags:any = JSON.parse(jsonStr);
                                                            dcm = OsDicomFile(decodedTags);
                                                            image.setDicomFile(dcm);
                                                            let interData:OsIntermediatePixelData = OsIntermediatePixelData();
                                                            interData.rgbOrder = 1;
                                                            interData.resIndex = 0;
                                                            interData.resCount = 1;
                                                            interData.width = width;
                                                            interData.height = height;
                                                            interData.bits = bitsPerPixel;
                                                            interData.isSigned = false;
                                                            interData.intermediatePixelData = bytes.slice(offset, offset+pixLen);
                                                            dcm.setIntermediatePixelData(0, interData);
                                                            dcm.release();
                                                            dcm = null;

                                                            firstTimeImages.push(image);
                                                            this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                                                        }
                                                        catch(e) {
                                                            this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, "");
                                                        }
                                                    }
                                                    offset += pixLen;
                                                }
                                                else valid = false;
                                            }
                                        }   
                                        else {
                                            let representation:number = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 2;
                                            let signedData:boolean = bytes[offset] == 0 ? false : true; offset += 1;
                                            let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                            if (pixLen > 0 && pixLen+offset <= bytes.length) {
                                                let interData:OsIntermediatePixelData|null = null;
                                                let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                                                if (image) { 
                                                    try {
                                                        let decodedTags:any = JSON.parse(jsonStr);
                                                        dcm = OsDicomFile(decodedTags);
                                                        for (let kinnumber=0; k<3; k++) dcm.setPalette(k, palette[k]);
                                                        image.setDicomFile(dcm);
                                                        //let interData:OsIntermediatePixelData = new OsIntermediatePixelData();
                                                        interData = OsIntermediatePixelData();
                                                        interData.resIndex = 0;
                                                        interData.resCount = 1;
                                                        interData.width = width;
                                                        interData.height = height;
                                                        interData.bits = representation;
                                                        interData.isSigned = signedData;
                                                        interData.intermediatePixelData = bytes.slice(offset, offset+pixLen);
                                                        dcm.setIntermediatePixelData(0, interData);
                                                        dcm.release();
                                                        dcm = null;
                                                        firstTimeImages.push(image);
                                                        this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                                                        //assign state:
                                                        //info.series.assignPendingStates(openedImage);
                                                    }
                                                    catch(e) {
                                                        this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, "");
                                                    }
                                                }
                                                offset += pixLen;
                                            }
                                            else valid = false;
                                        }
                                        palette.forEach(elt=>{if(elt) elt.release();});
                                    }
                                    else valid = false;
                                }
                                else
                                if (type == ENCODED_FORMAT.PNG) {
                                    let tagsLength:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                    if (tagsLength > 0 && tagsLength+offset <= bytes.length) {
                                        let jsonStr:string = '';
                                            for (let i=0; i<tagsLength; i++)
                                                jsonStr += String.fromCharCode(bytes[i+offset]);
                                        offset += tagsLength;

                                        let palette:Array<OsDicomRawPalette|null> = [null, null, null];
                                        let paletteLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        if (paletteLen > 0) {
                                            for (let kinnumber = 0; k < 3; k++) {
                                                let pl:OsDicomRawPalette = OsDicomRawPalette();
                                                pl.count = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                pl.bits = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                pl.value = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                let dataLen:number = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                if (dataLen < 0 || dataLen > 150000) valid = false;
                                                else {
                                                    pl.data = bytes.slice(offset, offset+dataLen);
                                                    offset += dataLen;
                                                }
                                                palette[k] = pl;
                                            }
                                        }
                                        let width:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let height:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let isRgb:boolean = bytes[offset] == 0 ? false : true; offset += 1;
                                        if (isRgb) {
                                            let bitsPerPixel:number = bytes[offset]; offset += 1;
                                            if (bitsPerPixel == 24 || bitsPerPixel == 32) {
                                                let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                if (pixLen > 0 && pixLen+offset <= bytes.length) {
                                                    let pngData:Uint8Array = bytes.slice(offset, offset+pixLen);
                                                    let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                                                    if (image) { 
                                                        try {
                                                            let decodedTags:any = JSON.parse(jsonStr);
                                                            dcm = OsDicomFile(decodedTags);
                                                            image.setDicomFile(dcm);
                                                            let interData:OsIntermediatePixelData = OsIntermediatePixelData();
                                                            interData.rgbOrder = 1;
                                                            interData.resIndex = 0;
                                                            interData.resCount = 1;
                                                            interData.width = width;
                                                            interData.height = height;
                                                            interData.bits = bitsPerPixel;
                                                            interData.isSigned = false;
                                                            //interData.intermediatePixelData = bytes.slice(offset, offset+pixLen);

                                                            if ((<any>window)['UPNG'] && pngData) {
                                                                let res:any = (<any>window)['UPNG'].decode(pngData);
                                                                if (res && res.data) {
                                                                    if (res.data.length >= width*height*3) 
                                                                    interData.intermediatePixelData = res.data.slice(0, width*height*3);
                                                                    interData.rgbOrder = 0;
                                                                }
                                                            }

                                                            dcm.setIntermediatePixelData(0, interData);
                                                            dcm.release();
                                                            dcm = null;
                                                            firstTimeImages.push(image);
                                                            this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                                                        }
                                                        catch(e) {
                                                            this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, "");
                                                        }
                                                    }
                                                    offset += pixLen;
                                                }
                                                else valid = false;
                                            }
                                        }   
                                        else {
                                            let representation:number = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 2;
                                            let signedData:boolean = bytes[offset] == 0 ? false : true; offset += 1;
                                            let pixLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                            if (pixLen > 0 && pixLen+offset <= bytes.length) {
                                                let pngData:Uint8Array = bytes.slice(offset, offset+pixLen);
                                                let interData:OsIntermediatePixelData|null = null;
                                                let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                                                if (image) { 
                                                    try {
                                                        let decodedTags:any = JSON.parse(jsonStr);
                                                        dcm = OsDicomFile(decodedTags);
                                                        for (let kinnumber=0; k<3; k++) dcm.setPalette(k, palette[k]);
                                                        image.setDicomFile(dcm);
                                                        //let interData:OsIntermediatePixelData = new OsIntermediatePixelData();
                                                        interData = OsIntermediatePixelData();
                                                        interData.resIndex = 0;
                                                        interData.resCount = 1;
                                                        interData.width = width;
                                                        interData.height = height;
                                                        interData.bits = representation;
                                                        interData.isSigned = signedData;
                                                        if ((<any>window)['UPNG'] && pngData) {
                                                            let res:any = (<any>window)['UPNG'].decode(pngData);
                                                            if (res && res.data) {
                                                                let factor:number = 1;
                                                                if (representation <= 8) factor = 1;
                                                                else if (representation <= 16) factor = 2;
                                                                else factor = 4;
                                                                if (res.data.length > width*height*factor) 
                                                                interData.intermediatePixelData = res.data.slice(0, width*height*factor);
                                                            }
                                                        }
                                                        dcm.setIntermediatePixelData(0, interData);
                                                        dcm.release();
                                                        dcm = null;
                                                        firstTimeImages.push(image);
                                                        this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                                                        //assign state:
                                                        //info.series.assignPendingStates(openedImage);
                                                    }
                                                    catch(e) {
                                                        this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, "");
                                                    }
                                                }
                                                offset += pixLen;

                                                

                                            }
                                            else valid = false;
                                        }
                                        palette.forEach(elt=>{if(elt) elt.release();});
                                    }
                                    else valid = false;
                                }  
                                else 
                                if (type == ENCODED_FORMAT.J2K) {
                                    let res:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                    if (res != -1) {
                                        let dataLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let endOffset:number = offset + dataLen;
                                        if (dataLen > 0 && endOffset <= bytes.length) {
                                            //DICOM Tags:
                                            let jsonLen:number = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                            let jsonBin = bytes.slice(offset, offset+jsonLen);
                                            let jsonStr:string = '';
                                            for (let i=0; i<jsonBin.length; i++)
                                                jsonStr += String.fromCharCode(jsonBin[i]);
                                            offset += jsonLen;
                                            //Palette info:
                                            //let paletteLen:number = ((bytes[offset+4+jsonLen+3] << 24) | (bytes[offset+4+jsonLen+2] << 16) | (bytes[offset+4+jsonLen+1] << 8) | bytes[offset+4+jsonLen+0]) >>> 0; offset += 4;
                                            let palette:Array<OsDicomRawPalette|null> = [null, null, null];
                                            let paletteLen:number = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset+0]) >>> 0; offset += 4;
                                            if (paletteLen > 0) {
                                                for (let kinnumber = 0; k < 3; k++) {
                                                    let pl:OsDicomRawPalette = OsDicomRawPalette();
                                                    pl.count = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                    pl.bits = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                    pl.value = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                    let dataLen:number = ((bytes[offset+3] << 24) | (bytes[offset+2] << 16) | (bytes[offset+1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                                    if (dataLen < 0 || dataLen > 100000) valid = false;
                                                    else {
                                                        pl.data = bytes.slice(offset, offset+dataLen);
                                                        offset += dataLen;
                                                    }
                                                    palette[k] = pl;
                                                }
                                            }
                                            //let imageBytes = bytes.slice(offset+9+jsonLen+paletteLen, offset+dataLen);
                                            offset++; //progression order
                                            let imageBytes = bytes.slice(offset, endOffset);
                                            offset += endOffset-offset;
                                            let dcm:OsDicomFile|null = image?image.getDicomFile():null;
                                            if (image) { 
                                                try {
                                                    let decodedTags:any = JSON.parse(jsonStr);
                                                    dcm = OsDicomFile(decodedTags);
                                                    for (let kinnumber=0; k<3; k++) dcm.setPalette(k, palette[k]);
                                                    image.setDicomFile(dcm);
                                                    let interData:OsIntermediatePixelData = OsIntermediatePixelData();
                                                    interData.encodedData = [];
                                                    interData.encodedData.push(imageBytes);
                                                    interData.encodedDataFormat = ENCODED_FORMAT.J2K;
                                                    interData.rgbOrder = 0;
                                                    let info:[number,number] = this._getJ2kResInfo(interData.encodedData);
                                                    interData.resIndex = info[0];
                                                    interData.resCount = info[1];
                                                    dcm.setIntermediatePixelData(0, interData);
                                                    dcm.release();
                                                    dcm = null;
                                                    firstTimeImages.push(image);
                                                    if (interData.resIndex == interData.resCount-1) 
                                                        this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                                                    else {
                                                        image.loadStatus.status = RESULT.OSRSP_STREAMING;
                                                        image.loadStatus.reason = RESULT.EOS_NONE;
                                                    }
                                                    /*if (interData.resIndex == interData.resCount-1) {
                                                        image.loadStatus.status = RESULT.OSRSP_SUCCESS;
                                                        image.loadStatus.reason = RESULT.EOS_NONE;
                                                        completedImages.push(image);
                                                    }*/
                                                    this.addJ2kStreamToDecode(image);
                                                }
                                                catch(e) {
                                                    this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, "");
                                                }
                                            }
                                            palette.forEach(elt=>{if(elt) elt.release();});
                                            //offset += dataLen;
                                        }
                                        else valid = false;
                                    }
                                    else {
                                        //we should not be here
                                        valid = false;
                                    }
                                }
                                else valid = false;
                            }
                            else {
                                let interData:OsIntermediatePixelData|null = dcm.getIntermediatePixelData(0);
                                if (image && interData) {
                                    if (interData.encodedDataFormat == ENCODED_FORMAT.J2K) {
                                        let dataLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        if (dataLen > 0 && dataLen+offset <= bytes.length) {
                                            if (interData.encodedData) {
                                                interData.encodedData.push(bytes.slice(offset, offset+dataLen));
                                                let info:[number,number] = this._getJ2kResInfo(interData.encodedData);
                                                interData.resIndex = info[0];
                                                interData.resCount = info[1];
                                                if (interData.resIndex == interData.resCount-1) 
                                                    this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, "");
                                                this.addJ2kStreamToDecode(image);
                                            }
                                            else {
                                                //we should not be here
                                                this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_INTERNAL, "");
                                            }
                                        }
                                        else {
                                            if (dataLen == 0) {
                                                //there is a problem with file on the server:
                                                this._setImageLoadStatus(srinfo, image, completedImages, RESULT.OSRSP_FAILURE, RESULT.EOS_NO_FILE, "");
                                            }
                                            else valid = false;
                                        }
                                        offset += dataLen;
                                    }
                                }
                            }
                        }
                        if (!valid) break;
                    }
                    
                    if (this._viewer.messageService) {
                        if (firstTimeImages.length > 0) this._viewer.messageService.sendMessage(MSG.SERIES_IMAGES_RECEIVED, firstTimeImages);
                        if (completedImages.length > 0) this._viewer.messageService.sendMessage(MSG.SERIES_IMAGES_DOWNLOAD_COMPLETED, completedImages);
                    }
                    if (!valid) {
                        //mark the loading of all series as failed:
                        if (series.loadStatus.status == RESULT.OSRSP_WAITING) {
                            this._setSeriesLoadStatus(series, RESULT.OSRSP_FAILURE, RESULT.EOS_INTERNAL, "");
                        }
                    }
                }
            }
            if (srinfo.request) {
                srinfo.request.cancel();
                srinfo.request = null;
            }
            if (gotImageData) this._downloadImages(srinfo.guid);
            else setTimeout(()=>{if (srinfo) this._downloadImages(srinfo.guid);}, 500);
        }
    }*/

  //-----------------------------------------------------
  // download multi-frames
  //-----------------------------------------------------

  /*public isBuffering(image:OsOpenedImage):number {
        if (this._mfDownloadingList.find((item)=>item.getImage() === image)) return 1;
        if (this._mfWaitingList.find((item)=>item.getImage() === image)) return 2;
        return 0;
    }

    public addMultiFrameImageToLoadingQueue(image:OsOpenedImage, processLoadingQueue:boolean):void {
        for (let i=0; i<this._mfWaitingList.length; i++) 
            if (this._mfWaitingList[i].getImage() === image) 
                return;
        for (let i=0; i<this._mfDownloadingList.length; i++) 
            if (this._mfDownloadingList[i].getImage() === image) 
                return;
        //image must be loaded
        if (image.loadStatus.status != RESULT.OSRSP_SUCCESS) return; 
        //image must have multiple frames
        if (image.getFrameCount() <= 1) return;
        //image must have frames to download:
        let dcm:OsDicomFile|null = image.getDicomFile();
        if (!dcm) return;
        if (dcm.getFrameCount(true) == dcm.getFrameCount(false)) return;
        //register the image to download:
        let info:OsDownloadMultiFrames = new OsDownloadMultiFrames(image);
        this._mfWaitingList.push(info);
        if (processLoadingQueue) this.processMultiFrameLoadingQueue();
    }
    
    public processMultiFrameLoadingQueue():void {
        //clean up the active list:
        for (let i=0; i<this._mfDownloadingList.length; i++) {
            let image:OsOpenedImage|null = this._mfDownloadingList[i].getImage();
            let remove:boolean = image == null;
            if (image && !remove) {
                if (image.loadStatus.status != RESULT.OSRSP_SUCCESS) remove = true;
                let dcm:OsDicomFile|null = image.getDicomFile();
                if (!dcm) remove = true;
                else if (dcm.getFrameCount(true) == dcm.getFrameCount(false)) remove = true;
            }
            if (remove) {
                this._mfDownloadingList[i].release();
                this._mfDownloadingList.splice(i, 1);
                i--;
            }
        }
        //cleanup the waiting list:
        for (let i=0; i<this._mfWaitingList.length; i++) {
            if (!this._mfWaitingList[i].getImage()) {
                this._mfWaitingList[i].release();
                this._mfWaitingList.splice(i, 1);
                i--;
            }
        }
        //start downloading the frames:
        while (this._mfWaitingList.length) {
            if (this._mfMaxConcurrentDownload > 0 && this._mfDownloadingList.length >= this._mfMaxConcurrentDownload) break;
            this._mfDownloadingList.push(this._mfWaitingList[0]);
            this._mfWaitingList.splice(0, 1);
            this._downloadImageFrames(this._mfDownloadingList[this._mfDownloadingList.length-1]);
        }
    }

    private _downloadImageFrames(info:OsDownloadMultiFrames) {
        let image:OsOpenedImage|null = info.getImage();
        let series:OsOpenedSeries|null = image?image.getParent(false) : null;
        let source:IPacsSource|null = series ? series.getSource() : null;
        let server:IPacsServer|null = source?source.getServer():null;
        //get the ranges:
        let dcm:OsDicomFile|null = image ? image.getDicomFile() : null;
        if (dcm) {
            let ranges:[number, number][] = [];
            let count:number = dcm.getFrameCount(false);
            for (let i:number = 0; i < count; i++) {
                if (!dcm.getIntermediatePixelData(i)) {
                    let range:[number, number] = [i, count-1];
                    for (let j:number = i; j < count; j++) 
                        if (dcm.getIntermediatePixelData(j)) {
                            range[1] = j-1;
                            break;
                        }
                    i = range[1];
                    ranges.push(range);
                }
            }
            if (source && source.session && server && image && ranges.length) info.request = this._onis.viewerService.downloadFrames(server, source.session, source.subType, source.sourceId, image, ranges, info.maxBytes, this._onDownloadImageFramesResponse, this, info.guid);
            else {
                //no more frame to download, stop to download the frames:
                this.processMultiFrameLoadingQueue();    
            }
        }
        else {
            //no dicom file, stop to download the frames:
            this.processMultiFrameLoadingQueue();
        }
    }*/

  //-----------------------------------------------------
  // multi-frame init response
  //-----------------------------------------------------

  /*private _onDownloadImageFramesResponse(status:boolean, data:any, cbkdata:any) {
        let info:OsDownloadMultiFrames|undefined = this._mfDownloadingList.find(elt=>elt.guid === cbkdata);
        let image:OsOpenedImage|null = info?info.getImage():null;
        if (image) {
            let reason:number = RESULT.EOS_NONE;
            if (status && data) {
                let bytes:Uint8Array = new Uint8Array(data);
                if (bytes.length < 12) reason = RESULT.EOS_INVALID_RESPONSE;
                else {
                    let offset:number = 0;
                    let responseStatus:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                    offset += 4;
                    let loadIndex:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                    offset += 4;
                    let frameCount:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                    offset += 4;
                    if (frameCount > 0 && frameCount < 1000) {
                        for (let i:number = 0; i < frameCount; i++) {
                            if (offset + 8 >= bytes.length) reason = RESULT.EOS_INVALID_RESPONSE;
                            else {
                                let frameIndex:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                                offset += 4;
                                let frameResult:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                                offset += 4;
                                if (frameResult == 0) {
                                    if (offset + 10 >= bytes.length) reason = RESULT.EOS_INVALID_RESPONSE;
                                    else {
                                        //read frame header:
                                        let width:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let height:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                                        let isRgb:boolean = bytes[offset] == 0 ? false : true; offset += 1;
                                        let representation:number = 0;
                                        let isSigned:boolean = false;
                                        if (isRgb) { representation = bytes[offset]; offset += 1; }
                                        else {
                                            if (offset + 2 >= bytes.length) reason = RESULT.EOS_INVALID_RESPONSE;
                                            else {
                                                representation = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 2;
                                                isSigned = bytes[offset] == 0 ? false : true; offset += 1;
                                            }
                                        }
                                        //decode the frame:
                                        if (reason == RESULT.EOS_NONE) {
                                            if (offset + 8 >= bytes.length) reason = RESULT.EOS_INVALID_RESPONSE;
                                            let dataType:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                                            offset += 4;
                                            let dataLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                                            offset += 4;
                                            if (dataLen >= 0 && offset + dataLen <= bytes.length) {
                                                if (dataType == 1 || dataType == 3) {
                                                    let dcm:OsDicomFile|null = image.getDicomFile();
                                                    if (dcm) {
                                                        if (frameIndex >= 0 && frameIndex < dcm.getFrameCount(false)) {
                                                            if (!dcm.getIntermediatePixelData(frameIndex)) {
                                                                let interData:OsIntermediatePixelData = new OsIntermediatePixelData();
                                                                interData.decodingError = RESULT.EOS_INTERNAL;
                                                                interData.width = width;
                                                                interData.height = height;
                                                                interData.bits = representation;
                                                                interData.isSigned = isSigned;
                                                                interData.resIndex = 0;
                                                                interData.resCount = 1;
                                                                let pngData:Uint8Array = bytes.slice(offset, offset+dataLen);
                                                                if (isRgb) {
                                                                    if (representation == 24 || representation == 32) {
                                                                        try {
                                                                            interData.rgbOrder = 1;
                                                                            
                                                                            if ((<any>window)['UPNG'] && pngData) {
                                                                                let res:any = (<any>window)['UPNG'].decode(pngData);
                                                                                if (res && res.data) {
                                                                                    if (res.data.length >= width*height*3) {
                                                                                        interData.intermediatePixelData = res.data.slice(0, width*height*3);
                                                                                        interData.rgbOrder = 0;
                                                                                        interData.decodingError = RESULT.EOS_NONE;
                                                                                    }
                                                                                    else interData.decodingError = RESULT.EOS_DECODING;
                                                                                }
                                                                            }
                                                                        }
                                                                        catch(e) {
                                                                            interData.decodingError = RESULT.EOS_DECODING;
                                                                        }
                                                                    }
                                                                }   
                                                                else {
                                                                    try {
                                                                        if ((<any>window)['UPNG'] && pngData) {
                                                                            let res:any = (<any>window)['UPNG'].decode(pngData);
                                                                            if (res && res.data) {
                                                                                let factor:number = 1;
                                                                                if (representation <= 8) factor = 1;
                                                                                else if (representation <= 16) factor = 2;
                                                                                else factor = 4;
                                                                                if (res.data.length > width*height*factor) {
                                                                                    interData.intermediatePixelData = res.data.slice(0, width*height*factor);
                                                                                    interData.decodingError = RESULT.EOS_NONE;
                                                                                }
                                                                                else interData.decodingError = RESULT.EOS_DECODING;
                                                                            }
                                                                        }
                                                                    }
                                                                    catch(e) {
                                                                        interData.decodingError = RESULT.EOS_DECODING;
                                                                    }
                                                                }
                                                                dcm.setIntermediatePixelData(frameIndex, interData);
                                                            }
                                                            else reason = RESULT.EOS_DUPLICATE;
                                                        }
                                                        else reason = RESULT.EOS_INVALID_RESPONSE;
                                                    }
                                                    offset += dataLen;
                                                }
                                                else reason = RESULT.EOS_INVALID_RESPONSE;
                                            }
                                            else reason = RESULT.EOS_INVALID_RESPONSE;
                                        }
                                    }
                                }
                            }
                            if (reason != RESULT.EOS_NONE) break;                            
                        }
                    }
                    else reason = RESULT.EOS_INVALID_RESPONSE;
                }
            }
            else reason = RESULT.EOS_INVALID_RESPONSE;
            if (reason != RESULT.EOS_NONE) {
                //invalidate all non received frames:
                let count:number = image.getFrameCount();
                let dcm:OsDicomFile|null = image.getDicomFile();
                if (dcm) {
                    for (let i=0; i<count; i++) {
                        if (!dcm.getIntermediatePixelData(i)) {
                            let interData:OsIntermediatePixelData = new OsIntermediatePixelData();
                            interData.decodingError = reason;
                            dcm.setIntermediatePixelData(i, interData);
                        }                        
                    }
                }
            }
        }
        if (info && info.request) {
            info.request.cancel();
            info.request = null;
        }
        if (info) this._downloadImageFrames(info);
    }*/

  //-----------------------------------------------------
  // utilities for series
  //-----------------------------------------------------

  /*private _setSeriesLoadStatus(series =OsOpenedSeries, status =number, reason =number, info =string):void {
        series.loadStatus.status = status;
        series.loadStatus.reason = reason;
        series.loadStatus.info = info;
    }

    //-----------------------------------------------------
    // utilities for images
    //-----------------------------------------------------

    private _setImageLoadStatus(srinfo =DownloadSeries, image =OsOpenedImage, completedImages =OsOpenedImage[], status =number, reason =number, info =string):void {
        srinfo.received++;
        completedImages.push(image);
        image.loadStatus.status = status;
        image.loadStatus.reason = reason;
        image.loadStatus.info = info;
        if (srinfo.expected == srinfo.received) {
            let series:OsOpenedSeries|null = srinfo.getSeries();
            if (series) {
              this._setSeriesLoadStatus(series, RESULT.OSRSP_SUCCESS, RESULT.EOS_NONE, info);
              //console.log("complete");
            }
        }
    }*/

  //-----------------------------------------------------
  // utilities for sources
  //-----------------------------------------------------

  /*private _getSourcePerformance(source:IPacsSource|null, reg:boolean):DownloadPerformance|null {
        if (!source) return null;
        let sp:DownloadPerformance|undefined = this._performanceSources.find(elt=>elt.getSource()===source);
        if (!sp && reg) {
            this._cleanSourcePerformances();
            sp = new DownloadPerformance(this._onis, source);
            this._performanceSources.push(sp);
        }
        return sp==undefined?null:sp;
    }

    private _cleanSourcePerformances():void {
        for (let i:number=0; i<this._performanceSources.length; i++) {
            if (!this._performanceSources[i].getSource()) {
                this._performanceSources[i].destroy();
                this._performanceSources.splice(i, 1);
                i--;
            }
        }
    }*/

  //-----------------------------------------------------
  // j2k utilities
  //-----------------------------------------------------

  /*protected _getJ2kResInfo(encodedData:Uint8Array[]):[number, number] {
        let resolution:number = -1;
        let resolutionCount:number = -1;
        let data:Uint8Array = encodedData[0];
        resolutionCount = ((data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0]) >>> 0;
        let layerCount = ((data[7] << 24) | (data[6] << 16) | (data[5] << 8) | data[4]) >>> 0;
        if (resolutionCount > 0 && resolutionCount <= 6 && layerCount == 1) {
            if (data.length >= 8 + resolutionCount * 2 * 4 + resolutionCount * layerCount * 4) {
                let offset:number = 8 + resolutionCount * 2 * 4;
                let offsets:number[] = [];
                let i:number;
                for (i = 0; i < resolutionCount * layerCount; i++) {
                    offsets[i] = ((data[offset + 3] << 24) | (data[offset + 2] << 16) | (data[offset + 1] << 8) | data[offset]) >>> 0;
                    offset += 4;
                }
                let totalLength:number = 0;
                for (i = 0; i < encodedData.length; i++)
                    totalLength += encodedData[i].length;
                totalLength -= 8 + resolutionCount * 2 * 4 + resolutionCount * layerCount * 4;
                for (i = 0; i < offsets.length; i++)
                    if (totalLength == offsets[i]) {
                        resolution = i;
                        break;
                    }
            }
        }
        else resolutionCount = -1;
        return [resolution, resolutionCount];
    }

    public addJ2kStreamToDecode(image:OsOpenedImage):void {
        let add:boolean = true;
        for (let i:number = 0; i<this._j2kItems.length; i++) {
            if (this._j2kItems[i].getImage(false) === image) {
                add = false;
                break;
            }
        }
        if (add) {
            let item:OsJ2kDecodeItem = new OsJ2kDecodeItem(image, false);
            this._j2kItems.push(item);
        }
        //console.log("items to decode: " + this._j2kItems.length);
        this.decodeNextStream();
    }

    public decodeNextStream():void {
        //clean up image decoders:
        for (let i=this._j2kDecoders.length-1; i>=0 && this._j2kDecoders.length > this._maxImageDecoders; i--) {
            if (!this._j2kDecoders[i].isBusy()) {
                this._j2kDecoders[i].release();
                this._j2kDecoders.splice(i, 1);
            }
        }
        //search a decoder that is not busy:
        let decoder:OsJ2kDecoder|null = null;
        for (let i:number = 0; i < this._j2kDecoders.length; i++) 
            if (!this._j2kDecoders[i].isBusy()) {
                decoder = this._j2kDecoders[i];
                break;
            }
        if (!decoder) return;
        //get the next item to decode:
        let item:OsJ2kDecodeItem|null = null;
        for (let i:number = 0; i < this._j2kItems.length; i++) {
            let image:OsOpenedImage|null = this._j2kItems[i].getImage(false);
            let series:OsOpenedSeries|null = image ? image.getParent(false) : null;
            if (!series) { this._j2kItems[i].release(); this._j2kItems.splice(i, 1); i--; continue; } //the series or the image does not exist anymore
            if (this._j2kItems[i].getDecodingResolution() != -1) continue; //a thread is decoding one resolution at the moment
            let dcm:OsDicomFile|null = image?image.getDicomFile():null;
            let interData:OsIntermediatePixelData|null = dcm ? dcm.getIntermediatePixelData(0) : null;
            if (!interData) { this._j2kItems[i].release(); this._j2kItems.splice(i, 1); i--; continue; } //abnormal!
            if (interData.currentRes == interData.resCount-1 || interData.decodingError) { this._j2kItems[i].release(); this._j2kItems.splice(i, 1); i--; continue; } //completed (maybe because of an error)
            if (interData.currentRes + 1 <= interData.resIndex) {
                item = this._j2kItems[i]; //got our next candidate!
                break;
            }
        }
        if (item) {
            //get the next resolution to decode:
            let image:OsOpenedImage|null = item.getImage(false);
            let dcm:OsDicomFile|null = image?image.getDicomFile():null;
            let interData:OsIntermediatePixelData|null = dcm?dcm.getIntermediatePixelData(0):null;
            let resolutionToDecode = interData?interData.currentRes + 1:-1;
            //mark the image as decoding:
            if (resolutionToDecode != -1) {
                item.setDecodingResolution(resolutionToDecode);
                if (!decoder.decode(item, resolutionToDecode)) item.setDecodingResolution(-1);
            }
            else item.setDecodingResolution(-1);
        }
    }

    public onStreamDataDecoded(image:OsOpenedImage):void {
        if (this._viewer.messageService)
            this._viewer.messageService.sendMessage(MSG.SERIES_IMAGE_STREAM_DATA_DECODED, image);
    }*/

  //-----------------------------------------------------
  // icons
  //-----------------------------------------------------

  /*public addSeriesIconToRetrieve(study:OsOpenedStudy):void {
        let series:OsOpenedSeries[] = study.getSeries();
        let uids:string[] = [];
        for (let i=0; i<series.length; i++) {
            if (series[i].getIconStatus() != RESULT.OSRSP_WAITING) continue;
            if (series[i].getDatabaseInfo()) 
                if (series[i].getDatabaseInfo().uid.length)
                    uids.push(series[i].getDatabaseInfo().uid);
        }
        if (!uids.length) return;
        let item:OsSeriesIconsItem = new OsSeriesIconsItem(study, uids);
        this._iconItems.push(item);
        this._retrieveNextIcons();
    }

    private _retrieveNextIcons() {
        if (this._currentIconDownloadCount >= this._maxConcurrentIconRetrieve) return;
        let item:OsSeriesIconsItem = null;
        for (let i=0; i<this._iconItems.length; i++) {
            if (!this._iconItems[i].getStudy(false)) {
                this._iconItems[i].release();
                this._iconItems.splice(i, 1);
            }
            else 
            if (!this._iconItems[i].request) {
                item = this._iconItems[i];
                break;
            }
        }
        if (item) {
            this._currentIconDownloadCount++;
            let study:OsOpenedStudy = item.getStudy(false);
            let source:IPacsSource = study.getParent(false).getDatabaseInfo().source;
            item.request = this._onis.viewerService.downloadSeriesIcons(source.getServer(), source.session, source.subType, source.sourceId, study, this._onDownloadSeriesIconResponse, this, item);
            this._retrieveNextIcons();
        }
    }

    private _onDownloadSeriesIconResponse(status:boolean, data:any, cbkdata:any) {
        this._currentIconDownloadCount--;
        let item:OsSeriesIconsItem = <OsSeriesIconsItem>cbkdata;
        if (!item) return;
        let study:OsOpenedStudy = item.getStudy(false);
        if (study) {
            let allSeries:OsOpenedSeries[] = study.getSeries();
            if (status == true && data) {
                let valid:boolean = true;
                let bytes:Uint8Array = new Uint8Array(data);
                let offset:number = 0;
                let responseStatus:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                offset += 4;
                if (responseStatus == 0) {
                    let count:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                    offset += 4;
                    for (let i:number = 0; i < count; i++) {
                        let keyLen:number = bytes[offset];
                        offset += 1;
                        if (keyLen > 0 && keyLen+offset <= bytes.length) {
                            let key:string = '';
                            for (let i=0; i<keyLen; i++) key += String.fromCharCode(bytes[i+offset]);
                            offset += keyLen;
                            let targetSeries:OsOpenedSeries = null;
                            for (let j=0; j<allSeries.length; j++) {
                                if (allSeries[j].getDatabaseInfo().seq === key) {
                                    targetSeries = allSeries[j];
                                    break;
                                }
                            }
                            if (targetSeries.getIconStatus() != RESULT.OSRSP_PENDING) targetSeries = null;
                            let jpgLen:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
                            offset += 4;
                            if (jpgLen >= 0 && jpgLen+offset <= bytes.length) {
                                if (targetSeries != null) targetSeries.setIconStatus(RESULT.OSRSP_SUCCESS);
                                if (jpgLen != 0) {
                                    targetSeries.iconJpegData = bytes.slice(offset, offset+jpgLen);
                                    this._viewer.messageService.sendMessage(MSG.SERIES_ICON_RECEIVED, targetSeries);
                                }
                                offset += jpgLen;
                            }
                            else valid = false;
                        }
                        else valid = false;
                    }
                }
                else valid = false;
                if (!valid) {
                    for (let i=0; i<allSeries.length; i++) 
                        if (allSeries[i].getIconStatus() == RESULT.OSRSP_PENDING) 
                            allSeries[i].setIconStatus(RESULT.OSRSP_FAILURE);   
                }
            }
        }
        this._onDownloadSeriesIconCompleted(item);
    }

    public _onDownloadSeriesIconCompleted(item:OsSeriesIconsItem):void {
        for (let i=0; i<this._iconItems.length; i++) {
            if (this._iconItems[i] === item) {
                this._iconItems[i].release();
                this._iconItems.splice(i, 1);
            }
        }
        this._retrieveNextIcons();
    }*/
}
