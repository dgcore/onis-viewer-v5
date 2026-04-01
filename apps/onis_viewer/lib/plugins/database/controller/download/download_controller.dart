import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/api/request/async_request.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/dicom/dicom_file.dart';
import 'package:onis_viewer/core/dicom/intermediate_pixel_data.dart';
import 'package:onis_viewer/core/dicom/raw_palette.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/container/controllers/container_controller.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
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
  int _containerIndex = -1;
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

  @override
  void registerContainer(OsContainerWnd container, bool reg) {
    List<int> index = [-1];
    _findContainer(container, index);
    //register or unregister:
    if (reg && index[0] == -1) {
      _containers.add(DownloadContainer(container));
    } else if (!reg && index[0] != -1) {
      _containers.removeAt(index[0]);
    }
  }

  @override
  void setContainerPriority(OsContainerWnd container, bool hasPriority) {
    DownloadContainer? info = _findContainer(container, null);
    info?.hasPriority = hasPriority;
  }

  DownloadContainer? _findContainer(
      OsContainerWnd container, List<int>? index) {
    for (int i = 0; i < _containers.length; i++) {
      if (identical(_containers[i].getContainer(), container)) {
        if (index != null) {
          index[0] = i;
        } else {
          return _containers[i];
        }
      }
    }
    if (index != null) index[0] = -1;
    return null;
  }

  void _cleanContainers() {
    for (int i = 0; i < _containers.length; i++) {
      if (_containers[i].getContainer() == null) {
        _containers.removeAt(i);
        i--;
      }
    }
  }

  //-----------------------------------------------------
  // download series
  //-----------------------------------------------------

  @override
  void addSeriesToLoadingQueue(entities.Series series, bool process) {
    for (final item in _waitingList) {
      if (identical(item.getSeries(), series)) {
        return;
      }
    }
    for (final item in _downloadingList) {
      if (identical(item.getSeries(), series)) {
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
      entities.Series? series = _downloadingList[i].getSeries();
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
    entities.Series? series = info.getSeries();
    series?.loadStatus.status = ResultStatus.waiting;
    final source = info.getSource();
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
    entities.Series? series = info.getSeries();
    if (series == null || series.loadStatus.status != ResultStatus.waiting) {
      processLoadingQueue();
      return;
    }
    DownloadCandidates? candidates = _getImagesToDownload(info);
    if (candidates == null) return;
    DatabaseSource source = candidates.source;

    List<Map<String, dynamic>> items = [];
    for (int j = 0; j < candidates.images.length; j++) {
      entities.Image image = candidates.images[j];
      DicomFile? dcm = image.dicomFile;
      if (dcm == null) {
        items.add(
            {"dl": info.downloadSeq, "index": image.loadIndex, "from": -1});
      } else {
        IntermediatePixelData? interData = dcm.getIntermediatePixelData(0);
        if (interData != null) {
          items.add({
            "dl": info.downloadSeq,
            "index": image.loadIndex,
            "from": interData.resIndex
          });
        }
      }
    }
    if (items.isNotEmpty) {
      //let sp:DownloadPerformance|null = this._getSourcePerformance(source, true);
      //info.tm = performance.now();

      Map<String, dynamic> data = {
        "images": items,
        "pendingRanges": candidates.pendingRanges,
        "max_bytes": info.maxBytes,
      };
      info.request = source.createRequest(RequestType.downloadImages, data);
      if (info.request != null) {
        info.request?.send().then((response) {
          _onDownloadImagesResponse(info, response);
        });
      }

      //info.request = this._onis.viewerService.downloadImages(server, source.session, source.subType, source.sourceId, items, candidates.pendingRanges, info.maxBytes, _onDownloadImagesResponse, this, info.guid);
    }
  }

  DownloadCandidates? _getImagesToDownload(DownloadSeries info) {
    DownloadCandidates? candidates;

    //make sure all containers are valid:
    _cleanContainers();
    //we alternate the first container to analyze, to make the download more balanced.
    entities.Series? series = info.getSeries();
    final source = info.getSource();
    if (source == null) return null;
    candidates = DownloadCandidates(source);

    if (_containers.length > 1) {
      _containerIndex = (_containerIndex + 1) % _containers.length;
    } else {
      _containerIndex = 0;
    }

    //prepare container information.
    List<Map<String, dynamic>> contInfo = [];
    for (int k = 0; k < 2; k++) {
      int start = k == 0 ? _containerIndex : 0;
      int stop = k == 0 ? _containers.length : _containerIndex;
      for (int i = start; i < stop; i++) {
        OsContainerWnd? container = _containers[i].getContainer();
        OsContainerController? controller = container?.controller;
        if (controller == null) continue;
        if (!controller.isSeriesDisplayed(series!)) continue;
        List<OsRenderer> renderers = controller.rendererElements;
        if (renderers.isEmpty) continue;

        List<int> rowCol = container!.getImageMatrix();
        int count = rowCol[0] * rowCol[1];
        int startIndex = container.currentPage;
        if (container.pageMode) startIndex *= count;
        int firstPos = container.findStartingPosition(renderers, startIndex);
        if (firstPos == -1) continue;
        int lastPos = firstPos;
        if (count > 1) {
          for (int j = firstPos; j < renderers.length; j++) {
            if (identical(
                renderers[j], container.getImageBoxRenderer(count - 1))) {
              lastPos = j;
              break;
            }
          }
        }
        contInfo.add({
          "container": _containers[i],
          "renderers": renderers,
          "firstPos": firstPos,
          "lastPos": lastPos,
          "done": false,
        });
      }
    }

    //search within displayed images:
    for (int i = 0; i < _containers.length; i++) {
      OsContainerWnd? container = _containers[i].getContainer();
      OsContainerController? controller = container?.controller;
      if (controller == null || !controller.isSeriesDisplayed(series!)) {
        continue;
      }

      //get all candidates:
      List<int> rowCol = container!.getImageMatrix();
      int count = rowCol[0] * rowCol[1];
      for (int j = 0; j < count; j++) {
        OsRenderer? render = container.getImageBoxRenderer(j);
        if (render == null) continue;
        List<(entities.Series?, entities.Image?)> data =
            _getRenderInfo(candidates, series, render);
        if (data[0].$1 != null) {
          candidates.registerCandidate(data[0].$1!, data[0].$2);
        }
      }
    }
    candidates.analyzeCandidates(true);

    //now, search within undisplayed images:
    if (contInfo.isNotEmpty) {
      int done = 0;
      int index = 0;
      while (true) {
        if (!contInfo[index]["done"]) {
          contInfo[index]["firstPos"]--;
          contInfo[index]["lastPos"]++;
          if (contInfo[index]["firstPos"] < 0 &&
              contInfo[index]["lastPos"] >=
                  contInfo[index]["renderers"].length) {
            contInfo[index]["done"] = true;
            done++;
          } else {
            if (contInfo[index]["lastPos"] <
                contInfo[index]["renderers"].length) {
              List<(entities.Series?, entities.Image?)> info = _getRenderInfo(
                  candidates,
                  series,
                  contInfo[index]["renderers"][contInfo[index]["lastPos"]]);
              if (info[0].$1 != null) {
                candidates.registerCandidate(info[0].$1!, info[0].$2);
              }
            }
            if (contInfo[index]["firstPos"] >= 0) {
              List<(entities.Series?, entities.Image?)> info = _getRenderInfo(
                  candidates,
                  series,
                  contInfo[index]["renderers"][contInfo[index]["firstPos"]]);
              if (info[0].$1 != null) {
                candidates.registerCandidate(info[0].$1!, info[0].$2);
              }
            }
          }
        }
        if (done == contInfo.length) break;
        index = (index + 1) % contInfo.length;
      }
      candidates.analyzeCandidates(false);
    }

    if (candidates.images.isEmpty &&
        series!.loadStatus.status == ResultStatus.waiting) {
      for (int i = 0; i < series.images.length; i++) {
        //ignore if the image download is completed:
        entities.Image image = series.images[i];
        if (image.loadStatus.status != ResultStatus.pending &&
            image.loadStatus.status != ResultStatus.streaming) {
          continue;
        }
        if (!candidates.registerCandidate(series, image)) break;
      }
      candidates.analyzeCandidates(false);
    }

    //indicate the range of images we can download:
    for (var elt in info.pendingRanges) {
      candidates.pendingRanges.add([elt[0], elt[1]]);
    }

    return candidates;
  }

  List<(entities.Series?, entities.Image?)> _getRenderInfo(
      DownloadCandidates candidates,
      entities.Series? from,
      OsRenderer? render) {
    if (render == null) return [(null, null)];
    if (candidates.isFull) return [(null, null)];
    OsGraphicImage? img = render.getPrimaryImageItem();
    entities.Series? series = img?.isNullImage();
    entities.Image? image = img?.getImage();
    if (image != null && series == null) {
      series = image.series;
    }
    if (!identical(series, from)) return [(null, null)];

    //ignore if the series download is completed or if there is no series:
    if (series == null ||
        (series.loadStatus.status != ResultStatus.pending &&
            series.loadStatus.status != ResultStatus.waiting)) {
      return [(null, null)];
    }

    //ignore if the image download is completed:
    if (image != null &&
        image.loadStatus.status != ResultStatus.pending &&
        image.loadStatus.status != ResultStatus.streaming) {
      return [(null, null)];
    }

    String? sourceUid = series.sourceUid;
    if (sourceUid == null) return [(null, null)];

    final dbApi =
        OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    final source = dbApi?.sourceController.sources.findSourceByUid(sourceUid);
    if (source == null) return [(null, null)];

    return [(series, image)];
  }

  //-----------------------------------------------------
  // series response
  //-----------------------------------------------------

  void _onInitSeriesDownloadResponse(
      DownloadSeries info, AsyncResponse response) {
    final series = info.getSeries();
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
    }*/

  void _onDownloadImagesResponse(DownloadSeries info, AsyncResponse response) {
    if (!_downloadingList.contains(info)) return;
    entities.Series? series = info.getSeries();
    bool delayNextDownload = false;
    List<entities.Image> completedImages = [];
    List<entities.Image> firstTimeImages = [];
    //if the series is null, it means the series was closed, so we don't have anything to do
    if (series != null) {
      //the series was not closed!
      if (info.request != null) {
        //cleanup the request
        info.request!.cancel();
        info.request = null;
      }
      if (!response.isSuccess || response.data == null) {
        //the connection has failed, or the response is not valid (we expect to receive binary data)
        _interruptSeriesDownload(series, ResultStatus.failure,
            OnisErrorCodes.invalidRequest, completedImages);
      } else {
        //we got some binary data to analyze.
        Uint8List bytes = response.data!['binary'] as Uint8List;

        int offset = 0;
        //this._analyzeBandwidth(srinfo, series, bytes);
        int responseStatus = ((bytes[offset + 3] << 24) |
                (bytes[offset + 2] << 16) |
                (bytes[offset + 1] << 8) |
                bytes[offset]) >>>
            0;
        offset += 4;
        if (responseStatus != 0) {
          //bad response, we interrupt the download of the series:
          _interruptSeriesDownload(
              series, ResultStatus.failure, responseStatus, completedImages);
        } else {
          //how many series information we have?
          //it should be at most only one since we are downloading just one series at a time
          int count = ((bytes[offset + 3] << 24) |
                  (bytes[offset + 2] << 16) |
                  (bytes[offset + 1] << 8) |
                  bytes[offset]) >>>
              0;
          offset += 4;
          if (count != 0 && count != 1) {
            //invalid value, we interrupt the download of the series:
            _interruptSeriesDownload(series, ResultStatus.failure,
                OnisErrorCodes.invalidResponse, completedImages);
          } else {
            //read series information if provided:
            if (count == 1) {
              offset = _readSeriesInformation(info, series, bytes, offset);
            }
            if (offset == -1) {
              _interruptSeriesDownload(series, ResultStatus.failure,
                  OnisErrorCodes.invalidResponse, completedImages);
            } else {
              //read the images information:
              while (offset < bytes.length) {
                if (offset == -1)
                  break; //offset equals -1 when an error occurred.
                List<dynamic> imageInfo =
                    _readImageInformation(series, bytes, offset);
                offset = imageInfo[0];
                if (offset == -1) {
                  _interruptSeriesDownload(series, ResultStatus.failure,
                      OnisErrorCodes.invalidResponse, completedImages);
                } else {
                  //the image information is correct:
                  entities.Image? image = imageInfo[2];

                  int imageIndex = imageInfo[3];
                  int imageResult = imageInfo[4];
                  //update the download range index (to prevent to redownload the same image twice)
                  _updateImageRangeIndex(info, imageIndex);
                  //analyze the image result:
                  if (imageResult != 0) {
                    //if the image is not found but the download is not complete, the server may need more time to get the image (this is no an error in this case, we will have to resend the download request later)
                    if (imageResult == OnisErrorCodes.notFound &&
                        !info.completed) {
                      delayNextDownload = true;
                    } else {
                      _setImageLoadStatus(info, image!, completedImages,
                          ResultStatus.failure, imageResult, "");
                    }
                  } else {
                    //no error for image
                    //do we already have a dicom file for the image?
                    DicomFile? dcm = image!.dicomFile;
                    if (dcm == null) {
                      //we don't have a dicom file yet
                      //read the format of the image:
                      int imageFormat = ((bytes[offset + 3] << 24) |
                              (bytes[offset + 2] << 16) |
                              (bytes[offset + 1] << 8) |
                              bytes[offset]) >>>
                          0;
                      offset += 4;
                      EncodedFormat encodedFormat =
                          EncodedFormatExtension.fromInt(imageFormat);
                      if (encodedFormat != EncodedFormat.raw &&
                          encodedFormat != EncodedFormat.png &&
                          encodedFormat != EncodedFormat.j2k) {
                        offset = _interruptSeriesDownload(
                            series,
                            ResultStatus.failure,
                            OnisErrorCodes.invalidResponse,
                            completedImages);
                      } else {
                        //pre-read for j2k:
                        /*let j2kRes:number = -1;
                          let j2kDataLen:number = -1;
                          let j2kEndOffset:number = -1;
                          let version:string = "";
                          if (imageFormat == ENCODED_FORMAT.J2K) {
                            j2kRes = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                            //read file version:
                            let version_len:number = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                            if (version_len >= 0 && version_len <= 10) {
                              for (let i:number=0; i<version_len; i++) version += String.fromCharCode(bytes[i+offset]);
                              offset += version_len;
                              //read j2k data len:
                              j2kDataLen = ((bytes[offset + 3] << 24) | (bytes[offset + 2] << 16) | (bytes[offset + 1] << 8) | bytes[offset]) >>> 0; offset += 4;
                              j2kEndOffset = offset + j2kDataLen;
                            }
                            else this._interruptSeriesDownload(series, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, completedImages);
                          }*/

                        if (series.loadStatus.reason == 0) {
                          //read the dicom tags:
                          offset =
                              _readDicomFileInformation(image, bytes, offset);
                          if (offset == -1) {
                            _interruptSeriesDownload(
                                series,
                                ResultStatus.failure,
                                OnisErrorCodes.invalidResponse,
                                completedImages);
                          } else {
                            if (encodedFormat == EncodedFormat.raw ||
                                encodedFormat == EncodedFormat.png) {
                              int width = ((bytes[offset + 3] << 24) |
                                      (bytes[offset + 2] << 16) |
                                      (bytes[offset + 1] << 8) |
                                      bytes[offset]) >>>
                                  0;
                              offset += 4;
                              int height = ((bytes[offset + 3] << 24) |
                                      (bytes[offset + 2] << 16) |
                                      (bytes[offset + 1] << 8) |
                                      bytes[offset]) >>>
                                  0;
                              offset += 4;
                              bool isRgb = bytes[offset] == 0 ? false : true;
                              offset += 1;
                              if (width < 0 ||
                                  height < 0 ||
                                  width > 8192 ||
                                  height > 8192) {
                                offset = _interruptSeriesDownload(
                                    series,
                                    ResultStatus.failure,
                                    OnisErrorCodes.invalidResponse,
                                    completedImages);
                              } else {
                                if (encodedFormat == EncodedFormat.raw) {
                                  if (isRgb) {
                                    offset = _readRgbRawData(image, width,
                                        height, bytes, offset, firstTimeImages);
                                  } else {
                                    offset = _readMonochromeRawData(
                                        image,
                                        width,
                                        height,
                                        bytes,
                                        offset,
                                        firstTimeImages);
                                  }
                                } else if (encodedFormat == EncodedFormat.png) {
                                  if (isRgb) {
                                    offset = _readRgbPngData(image, width,
                                        height, bytes, offset, firstTimeImages);
                                  } else {
                                    offset = _readMonochromePngData(
                                        image,
                                        width,
                                        height,
                                        bytes,
                                        offset,
                                        firstTimeImages);
                                  }
                                }
                                if (offset == -1) {
                                  offset = _interruptSeriesDownload(
                                      series,
                                      ResultStatus.failure,
                                      OnisErrorCodes.invalidResponse,
                                      completedImages);
                                } else {
                                  _setImageLoadStatus(
                                      info,
                                      image,
                                      completedImages,
                                      ResultStatus.success,
                                      OnisErrorCodes.none,
                                      "");
                                }
                              }
                            } else {
                              //handle J2K Format:
                              /*if (j2kDataLen < 0 || j2kRes == -1 || j2kEndOffset > bytes.length) offset = this._interruptSeriesDownload(series, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, completedImages);
                                else {

                                  let minValue:number = 0;
                                  let maxValue:number = 0;
                                  if (version == "3.0") {
                                    //read min and max values:
                                    var buf = ArrayBuffer(8);
                                    var view = DataView(buf);
                                    for (let iinnumber=0; i<8; i++) view.setUint8(i, bytes[offset+7-i]);
                                    minValue = view.getFloat64(0);
                                    offset += 8;
                                    for (let iinnumber=0; i<8; i++) view.setUint8(i, bytes[offset+7-i]);
                                    maxValue = view.getFloat64(0);
                                    offset += 8;
                                  }

                                  offset++;                                  
                                  let imageBytes = bytes.slice(offset, j2kEndOffset);
                                  offset += j2kEndOffset-offset;
                                  offset = this._readJ2kData(srinfo, image, imageBytes, offset, minValue, maxValue, firstTimeImages, completedImages);
                                  if (offset == -1) offset = this._interruptSeriesDownload(series, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, completedImages);
                                }*/
                            }
                          }
                        }
                      }
                    } else {
                      //the dicom file already exists.
                      //we should come here only in case the J2K Streaming
                      /*offset = this._addJ2kData(srinfo, image, dcm, bytes, offset, completedImages);
                        if (offset == -1) offset = this._interruptSeriesDownload(series, RESULT.OSRSP_FAILURE, RESULT.EOS_INVALID_RESPONSE, completedImages);*/
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    if (!delayNextDownload) {
      _downloadImages(info);
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        _downloadImages(info);
      });
    }

    OVApi().messages.sendMessage(OSMSG.seriesImagesReceived, firstTimeImages);
    OVApi()
        .messages
        .sendMessage(OSMSG.seriesImagesDownloadCompleted, completedImages);
  }

  int _interruptSeriesDownload(entities.Series series, ResultStatus status,
      int reason, List<entities.Image> completedImages) {
    for (entities.Image image in series.images) {
      if (image.loadStatus.status == ResultStatus.pending) {
        image.loadStatus.status = status;
        image.loadStatus.reason = reason;
        completedImages.add(image);
      }
    }
    series.loadStatus.status = status;
    series.loadStatus.reason = reason;
    return -1;
  }

  void _setImageLoadStatus(
      DownloadSeries srinfo,
      entities.Image image,
      List<entities.Image> completedImages,
      ResultStatus status,
      int reason,
      String info) {
    srinfo.received++;
    completedImages.add(image);
    image.loadStatus.status = status;
    image.loadStatus.reason = reason;
    image.loadStatus.info = info;
    if (srinfo.expected == srinfo.received) {
      entities.Series? series = srinfo.getSeries();
      if (series != null) {
        setSeriesLoadStatus(
            series, ResultStatus.success, OnisErrorCodes.none, info);
      }
    }
  }

  int _readSeriesInformation(DownloadSeries info, entities.Series series,
      Uint8List bytes, int offset) {
    bool valid = true;
    //read the series uid:
    int length = bytes[offset];
    offset++;
    String str = '';
    if (length < 0 || length > 100) {
      valid = false;
    } else {
      for (int j = 0; j < length; j++) {
        str += String.fromCharCode(bytes[j + offset]);
      }
      offset += length;
      //make sure the series id matches:
      /*if (series.downloadSeq != str) {
          valid = false;
        }
        else {*/
      //information if all the series images are ready to transfer at server side, and also how many images to expect in the series:
      int completed = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      int expected = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      //console.log("series uid: " + series.getDatabaseInfo().uid + " completed: " + completed + " expected: " + expected);
      if (completed != 0 && completed != 1) {
        valid = false;
      } else if (expected != 0xFFFFFF && (expected < 0 || expected > 2000)) {
        valid = false;
      } else {
        info.completed = completed == 1;
        if (expected != 0xFFFFFF) {
          if (info.expected != expected) {
            info.expected = expected;
            series.prepareForDownload(expected);
          }
        }
        if (info.completed && info.pendingRanges.isNotEmpty) {
          if (info.pendingRanges[info.pendingRanges.length - 1][1] ==
              0xFFFFFF) {
            info.pendingRanges[info.pendingRanges.length - 1][1] =
                series.images.length - 1;
          }
        }
      }
      // }
    }
    return valid ? offset : -1;
  }

  List<dynamic> _readImageInformation(
      entities.Series series, Uint8List bytes, int offset) {
    bool valid = true;
    String str = '';
    int imageIndex = -1;
    int imageResult = OnisErrorCodes.internal;
    entities.Image? image;
    int length = bytes[offset];
    offset++;
    if (length < 0 || length > 100) {
      valid = false;
    } else {
      for (int j = 0; j < length; j++) {
        str += String.fromCharCode(bytes[j + offset]);
      }
      offset += length;
      imageIndex = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      imageResult = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      if (imageResult < 0 ||
          imageIndex < 0 ||
          imageIndex >= series.images.length) {
        valid = false;
      } else {
        for (entities.Image img in series.images) {
          if (img.loadIndex == imageIndex) {
            image = img;
            break;
          }
        }
        if (image == null) {
          valid = false;
        }
      }
    }
    return valid
        ? [offset, str, image, imageIndex, imageResult]
        : [-1, '', null, -1, -1];
  }

  void _updateImageRangeIndex(DownloadSeries info, int imageIndex) {
    for (int i = 0; i < info.pendingRanges.length; i++) {
      if (imageIndex >= info.pendingRanges[i][0] &&
          imageIndex <= info.pendingRanges[i][1]) {
        if (info.pendingRanges[i][0] == info.pendingRanges[i][1] &&
            info.pendingRanges[i][0] == imageIndex) {
          info.pendingRanges.removeAt(i);
        } else if (imageIndex == info.pendingRanges[i][0]) {
          info.pendingRanges[i][0] = imageIndex + 1;
        } else if (imageIndex == info.pendingRanges[i][1]) {
          info.pendingRanges[i][1] = imageIndex - 1;
        } else {
          info.pendingRanges.insert(
            i + 1,
            [imageIndex + 1, info.pendingRanges[i][1]],
          );
          info.pendingRanges[i][1] = imageIndex - 1;
        }
        break;
      }
    }
  }

  int _readDicomFileInformation(
      entities.Image image, Uint8List bytes, int offset) {
    bool valid = true;
    int tagsLength = ((bytes[offset + 3] << 24) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 1] << 8) |
            bytes[offset]) >>>
        0;
    offset += 4;
    if (tagsLength <= 0 || tagsLength + offset > bytes.length) {
      valid = false;
    } else {
      //read the tags:
      String jsonStr = '';
      Uint8List tagData = Uint8List.view(
        bytes.buffer,
        bytes.offsetInBytes + offset,
        tagsLength,
      );
      jsonStr = utf8.decode(tagData);

      offset += tagsLength;
      //read the palette:
      List<DicomRawPalette?> palette = [null, null, null];
      int paletteLen = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      if (paletteLen > 0) {
        for (int k = 0; k < 3; k++) {
          DicomRawPalette pl = DicomRawPalette();
          pl.count = ((bytes[offset + 3] << 24) |
                  (bytes[offset + 2] << 16) |
                  (bytes[offset + 1] << 8) |
                  bytes[offset]) >>>
              0;
          offset += 4;
          pl.bits = ((bytes[offset + 3] << 24) |
                  (bytes[offset + 2] << 16) |
                  (bytes[offset + 1] << 8) |
                  bytes[offset]) >>>
              0;
          offset += 4;
          pl.value = ((bytes[offset + 3] << 24) |
                  (bytes[offset + 2] << 16) |
                  (bytes[offset + 1] << 8) |
                  bytes[offset]) >>>
              0;
          offset += 4;
          int dataLen = ((bytes[offset + 3] << 24) |
                  (bytes[offset + 2] << 16) |
                  (bytes[offset + 1] << 8) |
                  bytes[offset]) >>>
              0;
          offset += 4;
          if (dataLen < 0 ||
              dataLen > 150000 ||
              dataLen + offset > bytes.length) {
            valid = false;
            break;
          } else {
            pl.data = bytes.sublist(offset, offset + dataLen);
            offset += dataLen;
          }
          palette[k] = pl;
        }
      }
      try {
        dynamic decodedTags = json.decode(jsonStr);
        DicomFile dcm = DicomFile(decodedTags);
        image.dicomFile = dcm;
        for (int k = 0; k < 3; k++) {
          dcm.setPalette(k, palette[k]);
        }
      } catch (e) {
        valid = false;
      }
    }
    return valid ? offset : -1;
  }

  int _readMonochromeRawData(entities.Image image, int width, int height,
      Uint8List bytes, int offset, List<entities.Image> firstTimeImages) {
    bool valid = true;
    int representation = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
    offset += 2;
    bool signedData = bytes[offset] == 0 ? false : true;
    offset += 1;
    int pixLen = ((bytes[offset + 3] << 24) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 1] << 8) |
            bytes[offset]) >>>
        0;
    offset += 4;
    if (pixLen <= 0 || pixLen + offset > bytes.length) {
      valid = false;
    } else if (representation != 8 &&
        representation != 12 &&
        representation != 16) {
      valid = false;
    } else {
      IntermediatePixelData? interData;
      DicomFile? dcm = image.dicomFile;
      if (dcm != null) {
        interData = IntermediatePixelData();
        interData.encodedDataFormat = EncodedFormat.raw;
        interData.resIndex = 0;
        interData.resCount = 1;
        interData.width = width;
        interData.height = height;
        interData.bits = representation;
        interData.isSigned = signedData;
        interData.intermediatePixelData =
            bytes.sublist(offset, offset + pixLen);
        dcm.setIntermediatePixelData(0, interData);
        firstTimeImages.add(image);
        offset += pixLen;
      } else {
        valid = false;
      }
    }
    return valid ? offset : -1;
  }

  int _readRgbRawData(entities.Image image, int width, int height,
      Uint8List bytes, int offset, List<entities.Image> firstTimeImages) {
    bool valid = true;
    int bitsPerPixel = bytes[offset];
    offset += 1;
    if (bitsPerPixel != 24 && bitsPerPixel != 32) {
      valid = false;
    } else {
      int pixLen = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      if (pixLen <= 0 || pixLen + offset > bytes.length) {
        valid = false;
      } else {
        DicomFile? dcm = image.dicomFile;
        if (dcm != null) {
          IntermediatePixelData interData = IntermediatePixelData();
          interData.encodedDataFormat = EncodedFormat.raw;
          interData.rgbOrder = 1;
          interData.resIndex = 0;
          interData.resCount = 1;
          interData.width = width;
          interData.height = height;
          interData.bits = bitsPerPixel;
          interData.isSigned = false;
          interData.intermediatePixelData =
              bytes.sublist(offset, offset + pixLen);
          dcm.setIntermediatePixelData(0, interData);
          firstTimeImages.add(image);
          offset += pixLen;
        } else {
          valid = false;
        }
      }
    }
    return valid ? offset : -1;
  }

  int _readMonochromePngData(entities.Image image, int width, int height,
      Uint8List bytes, int offset, List<entities.Image> firstTimeImages) {
    bool valid = true;
    int representation = ((bytes[offset + 1] << 8) | bytes[offset]) >>> 0;
    offset += 2;
    bool signedData = bytes[offset] == 0 ? false : true;
    offset += 1;
    int pixLen = ((bytes[offset + 3] << 24) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 1] << 8) |
            bytes[offset]) >>>
        0;
    offset += 4;
    if (pixLen <= 0 || pixLen + offset > bytes.length) {
      valid = false;
    } else if (representation != 8 &&
        representation != 12 &&
        representation != 16) {
      valid = false;
    } else {
      final Uint8List pngData = Uint8List.view(
        bytes.buffer,
        bytes.offsetInBytes + offset,
        pixLen,
      );
      /*try {
        final StringBuffer sb = StringBuffer();
        sb.writeln('pngData length=${pngData.length}');
        const int bytesPerLine = 32;
        for (int i = 0; i < pngData.length; i += bytesPerLine) {
          final int end = (i + bytesPerLine < pngData.length)
              ? i + bytesPerLine
              : pngData.length;
          sb.write(i.toRadixString(16).padLeft(8, '0'));
          sb.write(': ');
          for (int j = i; j < end; j++) {
            sb.write(pngData[j].toRadixString(16).padLeft(2, '0'));
            if (j + 1 < end) sb.write(' ');
          }
          sb.writeln();
        }
        final String content = sb.toString();
        final String home = Platform.environment['HOME'] ?? '';
        String dumpPath = home.isNotEmpty
            ? p.join(home, 'Documents', 'pngData.txt')
            : p.join(Directory.current.path, 'pngData.txt');
        void tryWrite(String path) {
          final File file = File(path);
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(content, flush: true);
        }
        try {
          tryWrite(dumpPath);
          print('_readMonochromePngData dumped pngData hex to $dumpPath');
        } on FileSystemException catch (e) {
          dumpPath = p.join(Directory.systemTemp.path, 'pngData.txt');
          tryWrite(dumpPath);
          print(
            '_readMonochromePngData: ~/Documents/pngData.txt failed ($e), '
            'wrote to $dumpPath instead',
          );
        }
      } catch (e, st) {
        print('_readMonochromePngData failed to dump pngData: $e\n$st');
      }*/

      offset += pixLen;
      IntermediatePixelData? interData;
      DicomFile? dcm = image.dicomFile;
      if (dcm != null) {
        interData = IntermediatePixelData();
        interData.resIndex = 0;
        interData.resCount = 1;
        interData.width = width;
        interData.height = height;
        interData.bits = representation;
        interData.isSigned = signedData;
        interData.encodedDataFormat = EncodedFormat.raw;

        final img.Image? decoded = img.decodePng(pngData);

        /*if (decoded != null) {
          final Uint8List decodedBytes = decoded.getBytes();
          if (decodedBytes.length >= 2) {
            int minU16 = 0xFFFF;
            int maxU16 = 0;
            for (int i = 0; i + 1 < decodedBytes.length; i += 2) {
              final int v = decodedBytes[i] | (decodedBytes[i + 1] << 8);
              if (v < minU16) minU16 = v;
              if (v > maxU16) maxU16 = v;
            }
            print(
              '_readMonochromePngData unsigned16 min=$minU16 max=$maxU16 '
              '(bytes=${decodedBytes.length})',
            );
          } else {
            print(
              '_readMonochromePngData decoded PNG has insufficient bytes: '
              '${decodedBytes.length}',
            );
          }
        }*/

        if (decoded == null) {
          valid = false;
        } else {
          final Uint8List raw = decoded.getBytes();
          int factor = 1;
          if (representation <= 8) {
            factor = 1;
          } else if (representation <= 16) {
            factor = 2;
          } else {
            factor = 4;
          }
          if (representation > 8) {
            // PNG 16-bit samples are decoded in opposite byte order for our
            // pipeline; swap each 16-bit word to match expected layout.
            for (int i = 0; i + 1 < raw.length; i += 2) {
              final int b0 = raw[i];
              raw[i] = raw[i + 1];
              raw[i + 1] = b0;
            }
          }
          if (raw.length >= width * height * factor) {
            interData.intermediatePixelData =
                raw.sublist(0, width * height * factor);
            dcm.setIntermediatePixelData(0, interData);
          } else {
            valid = false;
          }
        }
        firstTimeImages.add(image);
      } else {
        valid = false;
      }
    }
    return valid ? offset : -1;
  }

  int _readRgbPngData(entities.Image image, int width, int height,
      Uint8List bytes, int offset, List<entities.Image> firstTimeImages) {
    bool valid = true;
    int bitsPerPixel = bytes[offset];
    offset += 1;
    if (bitsPerPixel != 24 && bitsPerPixel != 32) {
      valid = false;
    } else {
      int pixLen = ((bytes[offset + 3] << 24) |
              (bytes[offset + 2] << 16) |
              (bytes[offset + 1] << 8) |
              bytes[offset]) >>>
          0;
      offset += 4;
      if (pixLen < 0 || pixLen + offset > bytes.length) {
        valid = false;
      } else {
        final Uint8List pngData = Uint8List.view(
          bytes.buffer,
          bytes.offsetInBytes + offset,
          pixLen,
        );
        offset += pixLen;

        DicomFile? dcm = image.dicomFile;
        if (dcm != null) {
          IntermediatePixelData interData = IntermediatePixelData();
          interData.encodedDataFormat = EncodedFormat.raw;
          interData.rgbOrder = 1;
          interData.resIndex = 0;
          interData.resCount = 1;
          interData.width = width;
          interData.height = height;
          interData.bits = bitsPerPixel;
          interData.isSigned = false;

          try {
            final img.Image? decoded = img.decodePng(pngData);

            if (decoded == null) {
              valid = false;
            } else {
              final Uint8List raw = decoded.getBytes();
              if (raw.length >= width * height * 3) {
                interData.intermediatePixelData =
                    raw.sublist(0, width * height * 3);
                dcm.setIntermediatePixelData(0, interData);
                interData.rgbOrder = 0;
              } else {
                valid = false;
              }
            }
          } catch (e) {
            valid = false;
          }
          firstTimeImages.add(image);
        } else {
          valid = false;
        }
      }
    }
    return valid ? offset : -1;
  }

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

  void setSeriesLoadStatus(
      entities.Series series, ResultStatus status, int reason, String info) {
    series.loadStatus.status = status;
    series.loadStatus.reason = reason;
    series.loadStatus.info = info;
  }

  //-----------------------------------------------------
  // utilities for images
  //-----------------------------------------------------

  void setImageLoadStatus(
      DownloadSeries srinfo,
      entities.Image image,
      List<entities.Image> completedImages,
      ResultStatus status,
      int reason,
      String info) {
    srinfo.received++;
    completedImages.add(image);
    image.loadStatus.status = status;
    image.loadStatus.reason = reason;
    image.loadStatus.info = info;
    if (srinfo.expected == srinfo.received) {
      entities.Series? series = srinfo.getSeries();
      if (series != null) {
        setSeriesLoadStatus(
            series, ResultStatus.success, OnisErrorCodes.none, info);
      }
    }
  }

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
