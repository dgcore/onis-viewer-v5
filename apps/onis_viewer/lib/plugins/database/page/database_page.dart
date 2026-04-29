import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/page.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';
import 'package:onis_viewer/core/monitor/page_widget.dart';
import 'package:onis_viewer/core/monitor/page_wnd.dart';
import 'package:onis_viewer/plugins/database/page/database_page_widget.dart';

class OsDatabasePageType extends OsPageType {
  OsDatabasePageType() : super(id: 'database', name: 'Database');

  @override
  OsPage createPage(OsMonitor monitor) {
    return DatabasePage(this, monitor);
  }
}

class DatabasePage extends OsPage {
  DatabasePage(super.type, super.monitor);

  @override
  OsPageWnd createPageWnd() {
    return DatabasePageWnd(page: this);
  }
}

class DatabasePageWnd extends OsPageWnd {
  DatabasePageWnd({
    required super.page,
  });

  @override
  OsPageWidget? createPageWidget() {
    OsPage? page = getPage();
    if (page == null) {
      return null;
    }
    return DatabasePageWidget(page: page);
  }
}
