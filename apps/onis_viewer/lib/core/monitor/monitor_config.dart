import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';

class OsMonitorConfig {
  bool _useVirtualMonitors = false;
  int _virtualMonitorCount = 0;
  final List<OsMonitor> _physicalMonitors = [];
  final List<OsMonitor> _virtualMonitors = [];
  OsMonitor? _current;

  bool shouldUseVirtualMonitors() {
    return _useVirtualMonitors;
  }

  List<OsMonitor> getPhysicalMonitors() {
    return List.unmodifiable(_physicalMonitors);
  }

  List<OsMonitor> getVirtualMonitors() {
    return List.unmodifiable(_virtualMonitors);
  }

  List<OsMonitor> getMonitors() {
    return _useVirtualMonitors
        ? List.unmodifiable(_virtualMonitors)
        : List.unmodifiable(_physicalMonitors);
  }

  //operations:
  bool setShouldUseVirtualMonitors(bool useVirtual, int monitorCount) {
    if (useVirtual) {
      if (monitorCount <= 0 || monitorCount > 10) return false;
      _virtualMonitorCount = monitorCount;
      _useVirtualMonitors = true;
      //detect_monitors();
      return true;
    } else {
      _useVirtualMonitors = false;
      return true;
    }
  }
  //void detect_monitors();
  //void resolve_conflicts();
  //void init_from_document(onis::xml::pdoc_ptr doc);

  //current monitor:
  OsMonitor? getCurrentMonitor() {
    return _current;
  }

  void setCurrentMonitor(OsMonitor? monitor) {
    _current = monitor;
  }

  void detectMonitors() {
    List<OsMonitor> monitors = [];
    List<OsMonitor> virtualMonitors = [];

    OsMonitor monitor = OsMonitor('mon1');
    monitor.setActive(true);
    monitor.setArea([0, 0, 800, 600]);
    monitor.setLabelIndex(0);
    monitors.add(monitor);

    if (monitors.isNotEmpty) {
      OsMonitor mon = monitors.first;
      List<double> area = [0, 0, 0, 0];
      mon.getArea(area);

      if (area[2] >= area[3]) {
        double width =
            (area[2] / _virtualMonitorCount.toDouble()).floorToDouble();
        for (int i = 0; i < _virtualMonitorCount; i++) {
          List<double> monitorArea = [];
          monitorArea[0] = i * width + area[0];
          monitorArea[1] = area[1];
          monitorArea[2] = (i == _virtualMonitorCount - 1)
              ? area[2] - (_virtualMonitorCount - 1) * width
              : width;
          monitorArea[3] = area[3];

          String id = "$i";
          OsMonitor virtualMonitor = OsMonitor(id);
          virtualMonitor.setArea(area);
          virtualMonitor.setArea(monitorArea);
          virtualMonitor.setActive(true);
          virtualMonitors.add(virtualMonitor);
        }
      } else {
        double height =
            (area[3] / _virtualMonitorCount.toDouble()).floorToDouble();
        for (int i = 0; i < _virtualMonitorCount; i++) {
          List<double> monitorArea = [];
          monitorArea[0] = area[0];
          monitorArea[1] = i * height + area[1];
          monitorArea[2] = area[2];
          monitorArea[3] = (i == _virtualMonitorCount - 1)
              ? area[3] - (_virtualMonitorCount - 1) * height
              : height;

          String id = "$i";
          OsMonitor virtualMonitor = OsMonitor(id);
          virtualMonitor.setArea(area);
          virtualMonitor.setArea(monitorArea);
          virtualMonitor.setActive(true);
          virtualMonitors.add(virtualMonitor);
        }
      }
    }

    for (int i = 0; i < 2; i++) {
      List<OsMonitor> sourceMonitors = (i == 0) ? monitors : virtualMonitors;
      List<OsMonitor> targetMonitors =
          (i == 0) ? _physicalMonitors : _virtualMonitors;

      if (targetMonitors.isEmpty) {
        for (final monitor in sourceMonitors) {
          targetMonitors.add(monitor);
        }
        sourceMonitors.clear();
      } else {
        //Need to merge the result with the existing monitors:
        for (int it1 = 0, it2 = 0;
            it1 < sourceMonitors.length && it2 < targetMonitors.length;
            it1++, it2++) {
          OsMonitor mon1 = sourceMonitors[it1];
          OsMonitor mon2 = targetMonitors[it2];
          mon1.setActive(mon2.isActive());
          int count = mon2.getPageCount();
          for (int j = 0; j < count; j++) {
            mon1.addPage(mon2.getPageAtIndex(j));
          }
          mon1.setLabelIndex(mon2.getLabelIndex());
          //mon1->set_use_default_histoy_bar_modality_filter(mon2->is_default_histoy_bar_modality_filter());
          //mon1->set_use_default_histoy_bar_bodyparts_filter(mon2->is_default_histoy_bar_bodyparts_filter());
        }
        targetMonitors.clear();
        for (final monitor in sourceMonitors) {
          targetMonitors.add(monitor);
        }
        sourceMonitors.clear();
      }
    }
    resolveConflicts();
  }

  //init:
  /*void initDefault(List<OsPageType> pageTypes) {
    _useVirtualMonitors = false;
    _physicalMonitors.clear();
    OsMonitor monitor = OsMonitor('mon1');
    _physicalMonitors.add(monitor);
    resolveConflicts(pageTypes);
    //this._current = monitor;
  }*/

  void resolveConflicts() {
    for (int i = 0; i < 2; i++) {
      List<OsMonitor> monitors =
          (i == 0) ? _physicalMonitors : _virtualMonitors;
      if (monitors.isEmpty) continue;
      List<OsMonitor> activeMonitors = [];
      for (int j = 0; j < monitors.length; j++) {
        if (monitors[j].isActive()) {
          activeMonitors.add(monitors[j]);
        } else {
          monitors[j].removeAllPages();
        }
      }
      //Make sure that we have at least one active monitor:
      if (activeMonitors.isEmpty) {
        if (monitors.isNotEmpty) {
          monitors[0].setActive(true);
          activeMonitors.add(monitors[0]);
        }
      }
      //Analyze the pages:
      List<OsPageType> pageTypes = OVApi().pageTypes.getList();
      for (int j = 0; j < pageTypes.length; j++) {
        if (pageTypes[j].pageMustExist) {
          List<OsMonitor> owners = [];
          for (int k = 0; k < activeMonitors.length; k++) {
            if (activeMonitors[k].havePage(pageTypes[j].getId())) {
              owners.add(activeMonitors[k]);
            }
          }
          if (owners.isEmpty) {
            if (pageTypes[j].singleMonitor) {
              activeMonitors[0].addPage(pageTypes[j].getId());
            } else {
              for (int k = 0; k < activeMonitors.length; k++) {
                activeMonitors[k].addPage(pageTypes[j].getId());
              }
            }
          } else if (owners.length > 1 && pageTypes[j].singleMonitor) {
            owners.removeAt(0);
            for (int k = 0; k < owners.length; k++) {
              owners[k].removePage(pageTypes[j].getId());
            }
          }
        }
      }
      //Analyze the viewer label indexes:
      List<int> indexes = [];
      List<OsMonitor> viewerMonitors = [];
      for (int j = 0; j < activeMonitors.length; j++) {
        if (activeMonitors[j].havePage("VIEWER")) {
          viewerMonitors.add(activeMonitors[j]);
        }
      }
      for (int j = 0; j < viewerMonitors.length; j++) {
        bool chooseNewValue = false;
        int current = viewerMonitors[j].getLabelIndex();
        if (current >= 0 && current < viewerMonitors.length) {
          if (indexes.contains(current)) {
            chooseNewValue = true;
          }
        } else {
          chooseNewValue = true;
        }
        if (chooseNewValue) {
          for (int k = 0; k < viewerMonitors.length; k++) {
            if (!indexes.contains(k)) {
              indexes.add(k);
              viewerMonitors[j].setLabelIndex(k);
            }
          }
        } else {
          indexes.add(current);
        }
      }
    }
  }
}
