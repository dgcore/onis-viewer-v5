import 'package:onis_viewer/core/monitor/monitor_wnd.dart';

class OsMonitorStatusWnd {
  //private _rect:Array<number> = [0, 0, 0, 0];
  //public pages:Array<OsPage> = [];
  WeakReference<OsMonitorWnd>? _wParent;

  //public selectedPage:OsPage|null = null;

  OsMonitorStatusWnd(OsMonitorWnd parent) {
    _wParent = WeakReference(parent);
  }

  OsMonitorWnd? getParent() {
    return _wParent?.target;
  }

  //destructor:
  /*public destroy() {
        this.parent = null;
        this.selectedPage = null;
        for (let i=0; i<this.pages.length; i++) 
            this.pages[i].release();
        this.pages = [];
        //console.log("destroy monitor status window");
    }*/

  //area:
  //public getRect():Array<number> { return this._rect; }
  //public setRect(rect:Array<number>) { for (let i=0; i<4; i++) this._rect[i] = rect[i]; }

  //pages:
  /*public addPage(type:OsPageType) {
        let pg:OsPage|null = this.parent?type.createPage(this.parent):null;
        if (pg != null) {
            this.pages.push(pg);
            if (this.selectedPage == null) this.selectPage(type.id, false);
            this.replaceWidgets();
        }
    }

    public removePageType(type:OsPageType) {
        for (let i=this.pages.length-1; i>=0; i--) {
            if (this.pages[i].getType(false) == type) {
                this.pages[i].release();
                this.pages.splice(i, 1);
            }
        }
    }

    public selectPage(id:string, makeFocus:boolean):void {
        this.selectedPage = null;
        for (let i=0; i<this.pages.length; i++) {
            let type:OsPageType|null = this.pages[i].getType(false);
            if (type && type.id === id) {
                this.selectedPage = this.pages[i];
                break;
            }
        }
    }

    public getSelectedPage():OsPage|null {
        return this.selectedPage;
    }

    public findPage(id:string):OsPage|null {
        for (let i=0; i<this.pages.length; i++) {
            let pgt:OsPageType|null = this.pages[i].getType(false);
            if (pgt && pgt.id === id) return this.pages[i];
        }
        return null;
    }*/

  //resize:
  //public replaceWidgets() {}
}
