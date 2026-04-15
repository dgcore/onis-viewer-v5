import 'package:onis_viewer/core/monitor/page.dart';

class OsPageWnd {
  final WeakReference<OsPage>? _page;

  OsPageWnd(OsPage page) : _page = WeakReference(page);

  OsPage? getPage() {
    return _page?.target;
  }
}
