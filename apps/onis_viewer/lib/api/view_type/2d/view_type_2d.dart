import 'package:onis_viewer/api/view_type/2d/view_type_2d_wnd.dart';
import 'package:onis_viewer/core/layout/view_layout_node_wnd.dart';
import 'package:onis_viewer/core/layout/view_type.dart';
import 'package:onis_viewer/core/layout/view_wnd.dart';

class ViewType2D extends ViewType {
  ViewType2D(super.name, super.id);

  //public getNameCount() { return 1; }
  //public getName(index:number) { return this._name; }
  //public getGlobalName() { return this._name; }

  //operations:
  @override
  ViewWnd? createView(ViewLayoutNodeWnd parent, int index) {
    final dial = ViewType2DWnd(parent, this);
    return dial;
  }

  /*public createView(parent:OsViewLayoutNodeWnd, index:number):OsViewWnd { 
        let dial:OsViewWnd = new ViewType2DWnd(parent, this);
        if (dial != null) {
            let ln:OsViewLayoutNode|null = parent.getLayoutNode(false);
            let layout:OsViewLayout|null = ln?ln.getLayout(false):null;
            if (layout != null) {
                let list:OsContainerWnd[] = [];
                dial.getListOfContainerWindows(list);
                for (let it:number = 0; it < list.length; it++) {
                    list[it].setPropagationItem(layout.getPropagationItem(this._id));
                    list[it].setSynchroItem(layout.getSynchroItem(this._id));
                    list[it].setScoutItem(layout.getScoutItem(this._id));
                }
            }
            
            
        }
        return dial;
    }*/
}
