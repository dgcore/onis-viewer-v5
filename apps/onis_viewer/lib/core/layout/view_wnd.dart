import 'package:flutter/material.dart';
import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/core/layout/view_layout_node_wnd.dart';
import 'package:onis_viewer/core/layout/view_type.dart';

class ViewWnd {
  ViewLayoutNodeWnd? _parent;
  ViewType? _type;
  bool show = false;

  ViewWnd(ViewLayoutNodeWnd parent, ViewType type) {
    _parent = parent;
    _type = type;
  }

  // getters:
  ViewLayoutNodeWnd? get parent => _parent;
  ViewType? get type => _type;
  int get index => 0;
  ViewLayout? get layout {
    ViewLayoutNode? layoutNode = parent?.layoutNode;
    return layoutNode?.layout;
  }

  Widget? get widget {
    return null;
  }

  /*protected _destroy():void {
        this._type = null;
        this.parent = null;
        this.onis = null;
        this.viewer = null;
        super._destroy();
    }

    public setRect(rect:Array<number>) {
        for (let i=0; i<4; i++) this._rect[i] = rect[i];
    }

    public getRectConst() {
        return this._rect;
    }

   

    //properties:
    public getViewType():OsViewType|null { return this._type; }
    public getViewTypeIndex():number { return 0; }
    public isHidden() { return !this._show }

    //operations:
    public show(value:boolean) { this._show = value; }
    public configureForIndex(index:number):void {}

    public isSeriesDisplayed(series:OsOpenedSeries):boolean {
        let list:OsContainerWnd[] = [];
        this.getListOfContainerWindows(list);
        for (let i:number=0; i<list.length; i++) {
            let controller:OsContainerController|null = list[i].getController();
            if (controller) 
                if (controller.isSeriesDisplayed(series))
                    return true;
        }
        return false;
    }

    //containers:
    public getListOfContainerWindows(list:Array<OsContainerWnd>) {}
    public getActiveContainerWindow():OsContainerWnd|null { return null; }
    public haveContainerWindow(dial:OsContainerWnd):boolean { return false; }

    //-----------------------------------------------------------------------
    //states
    //-----------------------------------------------------------------------

    public getStateId():string {
        let node:OsViewLayoutNode|null = this.parent?this.parent.getLayoutNode(false):null;
        let layout:OsViewLayout|null = node?node.getLayout(false):null;
        let id:string = layout?layout.getStateBaseId():'';
        let type:OsViewType|null = id.length?this.getViewType():null;
        return type?id+'_'+type.getId():'';
    }

    public getSeriesStates(states:OsSeriesState[], forSaving:boolean):void {
        let containers:OsContainerWnd[] = [];
        this.getListOfContainerWindows(containers);
        if (containers.length && this.getStateId().length) {
            for (let i:number=0; i<containers.length; i++) {
                let controller:OsContainerController|null = containers[i].getController();
                let allSeries:OsOpenedSeries[] = [];
                if (controller) controller.getDisplayedSeries(allSeries);
                for (let it2:number=0; it2<allSeries.length; it2++) {
                    if (forSaving) {
                        let source:IPacsSource|null = allSeries[it2].getSource();
                        if (source && !source.getSupport(SourceFlags.SUPPORT_SAVING)) continue;
                    }
                    let state:OsSeriesState|null = controller?controller.getSeriesState(allSeries[it2], forSaving):null;
                    if (state) {
                        //some images of the series may not be present and be contained in a different container (mammography for example)
                        //this.mergeImageStates(allSeries[it2], imgStates, dial2);
                        states.push(state);
                    }
                }
            }
        }
    }

    public setSeriesStates(series:OsOpenedSeries, state:OsSeriesState):void {
        let containers:OsContainerWnd[] = [];
        this.getListOfContainerWindows(containers);
        for (let i:number=0; i<containers.length; i++) {
            let controller:OsContainerController|null = containers[i].getController();
            if (controller) controller.setSeriesState(state);
            containers[i].setCurrentPage(containers[i].getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        }
    }*/

  //operations:
  void makeFirstResponder() {}
}
