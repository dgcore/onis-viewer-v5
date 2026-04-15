import 'package:onis_viewer/core/monitor/monitor_wnd.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';
import 'package:onis_viewer/core/monitor/page_wnd.dart';

class OsPage {
  final WeakReference<OsPageType>? _wtype;
  final WeakReference<OsMonitorWnd>? _wmonitor;
  OsPageWnd? _wnd;

  OsPage(OsPageType type, OsMonitorWnd monitorWnd)
      : _wtype = WeakReference(type),
        _wmonitor = WeakReference(monitorWnd);

  OsPageType? getType() {
    return _wtype?.target;
  }

  OsMonitorWnd? getMonitor() {
    return _wmonitor?.target;
  }

  OsPageWnd? getWindow() {
    return _wnd;
  }
}
