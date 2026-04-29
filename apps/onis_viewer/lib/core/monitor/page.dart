import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';
import 'package:onis_viewer/core/monitor/page_wnd.dart';

abstract class OsPage {
  final WeakReference<OsPageType>? _wtype;
  final WeakReference<OsMonitor>? _wmonitor;
  OsPageWnd? _wnd;

  OsPage(OsPageType type, OsMonitor monitor)
      : _wtype = WeakReference(type),
        _wmonitor = WeakReference(monitor) {
    _wnd = createPageWnd();
  }

  OsPageType? getType() {
    return _wtype?.target;
  }

  OsPageWnd? getWnd() {
    return _wnd;
  }

  OsMonitor? getMonitor() {
    return _wmonitor?.target;
  }

  OsPageWnd createPageWnd();
}
