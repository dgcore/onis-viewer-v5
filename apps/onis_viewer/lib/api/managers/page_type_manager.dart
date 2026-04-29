import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/manager/simple_manager.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';

//typedef OsPageTypeManager = SimpleManager<OsPageType>;

class OsPageTypeManager extends SimpleManager<OsPageType> {
  OsPageTypeManager()
      : super('page_type_manager', OSMSG.pageTypeRegistered,
            OSMSG.pageTypeUnregistered);

  @override
  Map<String, dynamic> getMessageMap(OsPageType element) {
    return {
      'id': element.getId(),
    };
  }
}
