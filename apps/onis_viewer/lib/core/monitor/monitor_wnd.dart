import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/page.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';

class OsMonitorWnd extends ChangeNotifier {
  final WeakReference<OsMonitor>? _wMonitor;
  int? _messageSubscription;
  final bool _showStatus = true;
  final bool _showMenu = true;
  final bool _fullScreen = false;
  final List<OsPage> pages = [];
  OsPage? selectedPage;

  OsMonitorWnd(OsMonitor monitor) : _wMonitor = WeakReference(monitor) {
    _messageSubscription = OVApi().messages.subscribe(onReceivedMessage);
    for (final pageType in OVApi().pageTypes.getList()) {
      onPageRegistered(pageType);
    }
  }

  @override
  void dispose() {
    if (_messageSubscription != null) {
      OVApi().messages.unsubscribe(_messageSubscription!);
      _messageSubscription = null;
    }
    super.dispose();
  }

  void onReceivedMessage(int id, dynamic data) {
    if (id == OSMSG.pageTypeRegistered) {
      String? pageId = data['id'];
      OsPageType? pageType =
          pageId != null ? OVApi().pageTypes.find(pageId) : null;
      if (pageType != null) onPageRegistered(pageType);
    }
  }

  void onPageRegistered(OsPageType type) {
    final monitor = _wMonitor?.target;
    if (monitor == null) return;
    bool inserted = false;
    if (monitor.havePage(type.getId())) {
      inserted = true;
      addPage(type);
    }
    if (!inserted) {
      if (type.pageMustExist) {
        if (type.singleMonitor) {
          if (monitor.getLabelIndex() == 0) {
            addPage(type);
          }
        } else {
          addPage(type);
        }
      }
    }
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  /*public getStatusBarHeight() { return this._statusHeight; }
    //f64 get_menu_bar_height();*/

  //full screen:
  //b32 set_should_use_full_screen(b32 value);
  //b32 should_use_full_screen();

  //sizing:
  //virtual void on_size(u32 type, f64 cx, f64 cy);
  //void replace_widgets();

  void addPage(OsPageType type) {
    final monitor = _wMonitor?.target;
    if (monitor == null) return;
    if (findPage(type.getId()) != null) return;
    OsPage page = type.createPage(monitor);
    pages.add(page);
    selectedPage ??= page;
    notifyListeners();
  }

  void removePageType(OsPageType type) {
    /*for (let i=this.pages.length-1; i>=0; i--) {
            if (this.pages[i].getType(false) == type) {
                this.pages[i].release();
                this.pages.splice(i, 1);
            }
        }*/
  }

  void selectPage(String id, bool makeFocus) {
    for (final page in pages) {
      final type = page.getType();
      if (type != null && type.getId() == id) {
        if (!identical(selectedPage, page)) {
          selectedPage = page;
          notifyListeners();
        }
        return;
      }
    }
  }

  OsPage? getSelectedPage() {
    return selectedPage;
  }

  OsPage? findPage(String id) {
    for (final page in pages) {
      OsPageType? pgt = page.getType();
      if (pgt != null && pgt.getId() == id) return page;
    }
    return null;
  }
}
