import 'package:onis_viewer/core/monitor/monitor_wnd.dart';

class OsMonitor {
  final String _id;
  bool _active = false;
  int _labelIndex = -1;
  OsMonitorWnd? _wnd;
  final List<double> _area = [0, 0, 128, 128];
  final List<double> _visibleArea = [0, 0, 128, 128];
  final List<String> pages = [];

  OsMonitor(this._id);

  //-----------------------------------------------------------------------
  //copy
  //-----------------------------------------------------------------------

  OsMonitor clone() {
    OsMonitor copy = OsMonitor(_id);
    copy.setArea(_area);
    copy.setVisibleArea(_visibleArea);
    copy.setActive(_active);
    copy.setLabelIndex(_labelIndex);
    for (final page in pages) {
      copy.addPage(page);
    }
    return copy;
  }

  //-----------------------------------------------------------------------
  // Properties
  //-----------------------------------------------------------------------

  String get id => _id;

  //-----------------------------------------------------------------------
  //area
  //-----------------------------------------------------------------------

  void getArea(List<double> area) {
    for (int i = 0; i < 4; i++) {
      area[i] = _area[i];
    }
  }

  void getVisibleArea(List<double> area) {
    for (int i = 0; i < 4; i++) {
      area[i] = _visibleArea[i];
    }
  }

  void setArea(List<double> rect) {
    for (int i = 0; i < 4; i++) {
      _area[i] = rect[i];
    }
  }

  void setVisibleArea(List<double> area) {
    for (int i = 0; i < 4; i++) {
      _visibleArea[i] = area[i];
    }
  }

  //-----------------------------------------------------------------------
  //label
  //-----------------------------------------------------------------------

  void setLabelIndex(int index) {
    _labelIndex = index;
  }

  int getLabelIndex() {
    return _labelIndex;
  }

  //-----------------------------------------------------------------------
  //pages
  //-----------------------------------------------------------------------

  int getPageCount() {
    return pages.length;
  }

  String getPageAtIndex(int index) {
    if (index >= 0 && index < pages.length) {
      return pages[index];
    }
    return "";
  }

  bool addPage(String id) {
    if (havePage(id)) return false;
    pages.add(id);
    return true;
  }

  bool removePage(String id) {
    for (int i = 0; i < pages.length; i++) {
      if (pages[i] == id) {
        pages.removeAt(i);
        return true;
      }
    }
    return false;
  }

  bool havePage(String id) {
    for (int i = 0; i < pages.length; i++) {
      if (pages[i] == id) {
        return true;
      }
    }
    return false;
  }

  void removeAllPages() {
    pages.clear();
    _labelIndex = -1;
  }

  //-----------------------------------------------------------------------
  // Active
  //-----------------------------------------------------------------------

  bool isActive() {
    return _active;
  }

  void setActive(bool active) {
    _active = active;
  }

  //-----------------------------------------------------------------------
  // Window
  //-----------------------------------------------------------------------

  OsMonitorWnd? getWindow() {
    return _wnd;
  }

  bool setWindow(OsMonitorWnd? wnd) {
    /*if (_wnd != null && identical(_wnd, wnd)) return true;
    if (_wnd != null) _wnd.monitor = null;
    _wnd = wnd;
    if (_wnd != null) _wnd.monitor = this;*/
    return true;
  }
}
