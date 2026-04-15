import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/monitor_status_wnd.dart';

class OsMonitorWnd {
  final WeakReference<OsMonitor>? _wMonitor;
  OsMonitorStatusWnd? _dialStatus;
  //private _statusHeight:number = 35;
  bool _showStatus = true;
  final bool _showMenu = true;
  final bool _fullScreen = false;

  OsMonitorWnd(OsMonitor monitor) : _wMonitor = WeakReference(monitor) {
    _dialStatus = OsMonitorStatusWnd(this);
  }

  /*public getStatusBarHeight() { return this._statusHeight; }
    //f64 get_menu_bar_height();*/

  void setShouldDisplayStatusBar(bool show) {
    if (_showStatus == show) return;
    _showStatus = show;
    //if (updateNow) this.replaceWidgets();
  }

  bool shouldDisplayStatusBar() {
    return _showStatus;
  }

  OsMonitorStatusWnd? getStatusBar() {
    return _dialStatus;
  }

  //full screen:
  //b32 set_should_use_full_screen(b32 value);
  //b32 should_use_full_screen();

  //sizing:
  //virtual void on_size(u32 type, f64 cx, f64 cy);
  //void replace_widgets();

  //pages:
  void selectPage(String id, bool makeFocus) {
    //if (_dialStatus != null) _dialStatus.selectPage(id, makeFocus);
  }

  //public getSelectedPage():OsPage|null { return this._dialStatus?this._dialStatus.getSelectedPage():null }
  //  public findPage(id:string):OsPage|null { return this._dialStatus?this._dialStatus.findPage(id):null; }

  //application menu:
  //void show_page_menu(const onis::page_ptr &pg);
  //void set_should_display_menu_bar(b32 show, b32 update_now);
  //b32 should_display_menu_bar();
  //void update_menu();

  //preference panel:
  /*public showPreferencePanel(show:boolean):void {}
    public getPreferencePanel():IPreferencePanel|null { return null; }

    //dicom tags:
    public showDicomTagPanel(dcm:OsDicomFile):void {}
    public pickDicomTag():Promise<string>|null { return null; }

    //close panel:
    public showClosePanel(items:OsOpenedPatient[]|OsOpenedStudy[]|OsOpenedSeries[]|null):Promise<boolean>|null { return null; }

    //logout panel:
    public showLogoutPanel(source:IPacsSource):Promise<boolean>|null { return null; }

    //widgets:
    public showWidget(component:any):OsMonitorWidget|null { return null; }
    public closeWidget(widget:OsMonitorWidget):void {}*/
}
