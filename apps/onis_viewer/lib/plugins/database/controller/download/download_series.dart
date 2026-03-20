import 'package:onis_viewer/api/request/async_request.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:uuid_v4/uuid_v4.dart';

class DownloadSeries {
  final guid = UUIDv4().toString();
  final WeakReference<entities.Series>? _wSeries;
  String downloadSeq = '';
  AsyncRequest? request;
  bool completed = false;
  int expected = 0xFFFFFF; //may change time to time
  int received = 0; //number of received images (no more download)
  List<List<int>> pendingRanges = [
    [0, 0xFFFFFF]
  ];
  //num tm = performance.now();
  int maxBytes = 50 * 1024;

  DownloadSeries(entities.Series series)
      : _wSeries = WeakReference<entities.Series>(series);

  entities.Series? get series => _wSeries?.target;
}
