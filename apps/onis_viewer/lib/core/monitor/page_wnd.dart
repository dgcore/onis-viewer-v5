import 'package:flutter/material.dart';
import 'package:onis_viewer/core/monitor/page.dart';
import 'package:onis_viewer/core/monitor/page_widget.dart';

class OsPageWnd extends ChangeNotifier {
  final WeakReference<OsPage>? _page;

  OsPageWnd({
    required OsPage page,
  }) : _page = WeakReference(page) {
    debugPrint('OsPageWnd: constructor, page=${page.getType()?.name}');
  }

  OsPage? getPage() {
    return _page?.target;
  }

  OsPageWidget? createPageWidget() {
    return null;
  }
}
