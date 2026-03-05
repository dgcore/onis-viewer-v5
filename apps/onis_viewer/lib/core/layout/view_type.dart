import 'package:onis_viewer/core/layout/view_layout_node_wnd.dart';
import 'package:onis_viewer/core/layout/view_wnd.dart';

class ViewType {
  String _id = '';
  String _name = '';

  ViewType(String name, String id) {
    _id = id;
    _name = name;
  }

  String get name => _name;
  String get id => _id;

  //operations
  ViewWnd? createView(ViewLayoutNodeWnd parent, int index) {
    return null;
  }

  //export:
  //public haveExportTemplates():boolean{ return false; }
  //public useCustomExport():boolean{ return false; }
  //public useTemplatedExport():boolean{ return false; }
  //public openCustomExportWnd(container:OsContainerWnd, set:OsDbPreferenceSet|null){}
  //public openTemplatedExportWnd(set:OsDbPreferenceSet|null){}
  //public processTemplatedExport(container:OsContainerWnd, set:OsDbPreferenceSet|null):boolean{ return false; }
  // public createHangingProtocolViewport():OsHpViewport|null {
  //   return null;
  //}
}
