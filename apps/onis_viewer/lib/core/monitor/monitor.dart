import 'package:onis_viewer/core/monitor/monitor_wnd.dart';

/// Represents a monitor.
/// @author Cedric Lemoigne
class OsMonitor {
  final String _id;
  bool _active = false;
  int _labelIndex = -1;
  OsMonitorWnd? _wnd;
  final List<double> _area = [0, 0, 128, 128];
  final List<double> _visibleArea = [0, 0, 128, 128];
  final List<String> pages = [];

  /// Creates a new monitor.
  /// @param id The id of the monitor.
  OsMonitor(this._id);

  //-----------------------------------------------------------------------
  //copy
  //-----------------------------------------------------------------------

  /// Clones this monitor.
  /// @return A new monitor with the same properties.
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

  /// Returns the id of this monitor.
  /// @return The id.
  String get id => _id;

  //-----------------------------------------------------------------------
  //area
  //-----------------------------------------------------------------------

  /// Returns the area of this monitor.
  /// @param area The area to fill.
  /// @return The area.
  void getArea(List<double> area) {
    for (int i = 0; i < 4; i++) {
      area[i] = _area[i];
    }
  }

  /// Returns the visible area of this monitor.
  /// @param area The area to fill.
  /// @return The visible area.
  void getVisibleArea(List<double> area) {
    for (int i = 0; i < 4; i++) {
      area[i] = _visibleArea[i];
    }
  }

  /// Sets the area of this monitor.
  /// @param rect The area to set.
  /// @return The area.
  void setArea(List<double> rect) {
    for (int i = 0; i < 4; i++) {
      _area[i] = rect[i];
    }
  }

  /// Sets the visible area of this monitor.
  /// @param area The area to set.
  /// @return The visible area.
  void setVisibleArea(List<double> area) {
    for (int i = 0; i < 4; i++) {
      _visibleArea[i] = area[i];
    }
  }

  //-----------------------------------------------------------------------
  //label
  //-----------------------------------------------------------------------

  /// Sets the label index of this monitor.
  /// @param index The index to set.
  /// @return The label index.
  void setLabelIndex(int index) {
    if (_labelIndex == index) {
      return;
    }
    _labelIndex = index;
  }

  /// Returns the label index of this monitor.
  /// @return The label index.
  int getLabelIndex() {
    return _labelIndex;
  }

  //-----------------------------------------------------------------------
  //pages
  //-----------------------------------------------------------------------

  /// Returns the number of pages associated with this monitor.
  /// @return The number of pages.
  int getPageCount() {
    return pages.length;
  }

  /// Returns the page at the given index.
  /// @param index The index of the page.
  /// @return The page id.
  String getPageAtIndex(int index) {
    if (index >= 0 && index < pages.length) {
      return pages[index];
    }
    return "";
  }

  /// Adds a new page to this monitor.
  /// @param id The id of the page.
  /// @return True if the page was added, false otherwise.
  bool addPage(String id) {
    if (havePage(id)) return false;
    pages.add(id);
    return true;
  }

  /// Removes a page from this monitor.
  /// @param id The id of the page.
  /// @return True if the page was removed, false otherwise.
  bool removePage(String id) {
    for (int i = 0; i < pages.length; i++) {
      if (pages[i] == id) {
        pages.removeAt(i);
        return true;
      }
    }
    return false;
  }

  /// Checks if this monitor has a page with the given id.
  /// @param id The id of the page.
  /// @return True if the monitor has the page, false otherwise.
  bool havePage(String id) {
    for (int i = 0; i < pages.length; i++) {
      if (pages[i] == id) {
        return true;
      }
    }
    return false;
  }

  /// Removes all pages from this monitor.
  void removeAllPages() {
    if (pages.isEmpty && _labelIndex == -1) {
      return;
    }
    pages.clear();
    _labelIndex = -1;
  }

  //-----------------------------------------------------------------------
  // Active
  //-----------------------------------------------------------------------

  /// Returns the active state of this monitor.
  /// @return True if the monitor is active, false otherwise.
  bool isActive() {
    return _active;
  }

  /// Sets the active state of this monitor.
  /// @param active The new active state.
  /// @return True if the active state was changed, false otherwise.
  void setActive(bool active) {
    if (_active == active) {
      return;
    }
    _active = active;
  }

  //-----------------------------------------------------------------------
  // Window
  //-----------------------------------------------------------------------

  /// Returns the window associated with this monitor.
  /// @return The window.
  OsMonitorWnd? getWindow() {
    return _wnd;
  }

  /// Creates a new window associated with this monitor if it doesn't exist.
  void createWindow() {
    if (_wnd != null) return;
    _wnd = OsMonitorWnd(this);
  }
}
