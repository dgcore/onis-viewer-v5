import 'dart:math' as math;

import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/result/result.dart';
import 'package:uuid_v4/uuid_v4.dart';

class DownloadCandidates {
  String guid = UUIDv4().toString();
  final DatabaseSource source;
  final List<entities.Image> images =
      []; //list of images we want to download the pixel data
  final List<entities.Series> series =
      []; //list of series that need to initiate a download (no image yet for those series)
  final List<List<int>> pendingRanges = [];
  final int _maxLength = 20; //max number of images to download
  final List<entities.Image> _imageCandidates =
      []; //list of potential images to download
  final List<entities.Series> _seriesCandidates =
      []; //list of potential series to download (no image yet for those series)
  final List<entities.Image> _imageMemo = []; //use to prevent duplicates
  final bool _full = false;
  //public srRequest:AsyncHttpRequest|null = null;
  //public imRequest:AsyncHttpRequest|null = null;

  DownloadCandidates(this.source);

  bool registerCandidate(entities.Series? series, entities.Image? image) {
    if (_imageCandidates.length + images.length > _maxLength) return false;
    if (image != null) {
      if (!_imageMemo.contains(image)) {
        if (!_full && _imageCandidates.length + images.length <= _maxLength) {
          _imageCandidates.add(image);
          _imageMemo.add(image);
        } else {
          return true;
        }
      } else {
        return false;
      }
    } else if (series != null) {
      _seriesCandidates.add(series);
    }
    return true;
  }

  void analyzeCandidates(bool doSort) {
    //analyze the images:
    if (_imageCandidates.isNotEmpty) {
      if (doSort) {
        //sort the images by resolution and load index:
        _imageCandidates.sort((a, b) {
          bool aPending = a.loadStatus.status == ResultStatus.pending;
          bool bPending = b.loadStatus.status == ResultStatus.pending;

          if (aPending && bPending) {
            return a.loadIndex.compareTo(b.loadIndex);
          }
          if (aPending) return -1;
          if (bPending) return 1;
          return 0;
        });
      }
      int count = math.min(_maxLength - images.length, _imageCandidates.length);
      for (int i = 0; i < count; i++) {
        images.add(_imageCandidates[i]);
      }
    }
    //analyze the series:
    if (_seriesCandidates.isNotEmpty) {
      int count = math.min(1, _seriesCandidates.length);
      for (int i = 0; i < count; i++) {
        series.add(_seriesCandidates[i]);
      }
    }
    //cleanup:
    _imageCandidates.clear();
    _seriesCandidates.clear();
  }

  get isFull => _full;
}
