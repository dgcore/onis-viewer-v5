import 'package:onis_viewer/core/manager/simple_manager.dart';
import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/page.dart';

abstract class OsPageType extends HasId {
  final String _id;
  final String _name;
  final bool _pageMustExist;
  final bool _singleMonitor;

  OsPageType(
      {required String id,
      required String name,
      bool pageMustExist = true,
      bool singleMonitor = true})
      : _id = id,
        _name = name,
        _pageMustExist = pageMustExist,
        _singleMonitor = singleMonitor;

  bool get pageMustExist => _pageMustExist;
  bool get singleMonitor => _singleMonitor;
  String get name => _name;

  @override
  String getId() {
    return _id;
  }

  OsPage createPage(OsMonitor monitor);
}
