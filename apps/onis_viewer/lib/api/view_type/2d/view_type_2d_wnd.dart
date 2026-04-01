import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/view_type/2d/view_type_2d_widget.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/container/controllers/container_controller_2d.dart';
import 'package:onis_viewer/core/graphics/drivers/dart_driver.dart';
import 'package:onis_viewer/core/layout/view_wnd.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';
import 'package:onis_viewer/plugins/database/public/download_controller_interface.dart';

class ViewType2DWnd extends ViewWnd {
  late final OsContainerWnd _imageContainer;

  ViewType2DWnd(super.parent, super.type) {
    final OsContainerController2D controller = OsContainerController2D();
    _imageContainer = OsContainerWnd(
        driver: OsDartDriver(), controller: controller, view: this);

    final dbApi =
        OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    IDownloadController? downloadController = dbApi?.downloadController;

    /*let manager:OsGraphicManager = this.viewer.getGraphicManager();
            if (manager) {
                let type:OsContainerControllerType|null = manager.findContainerControllerType("2D CONTROLLER");
                let supportSet:OsContainerSupportSet|null = manager.findContainerSupportSet("2D", false);
                if (type != null) this._imageContainer = manager.createContainer(type, true, this);*/

    //this._imageContainer.setSupportSet(supportSet);
    /*let controller:OsContainerController|null = this._imageContainer.controller;
                    if (controller) {
                        controller.setStateId(this.getStateId());
                    }*/

    downloadController?.registerContainer(_imageContainer, true);
    //}
    //}
  }

  void dispose() {
    final dbApi =
        OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    IDownloadController? downloadController = dbApi?.downloadController;
    downloadController?.registerContainer(_imageContainer, false);
  }

  @override
  Widget? get widget {
    return ViewType2dWidget(viewType2DWnd: this);
  }

  /// Called when the user taps or clicks in the 2D view container.
  /// [localPosition] is the position relative to the widget.
  void onTap(Offset localPosition) {
    layout?.activeNode = parent?.layoutNode;
    layout?.notifyLayoutChanged();
  }

  //private _rectTimeout:any = null;

  /*constructor(parent:OsViewLayoutNodeWnd, type:OsViewType) {
        super(parent, type);
        //ViewType2DWnd.count++;
        //console.log("create ViewType2DWnd " + ViewType2DWnd.count);

        //_app->add_observer_for_message(OSMSG_SERIES_LOADED, this, _notification_handler);

        if (this.viewer) {
            let manager:OsGraphicManager = this.viewer.getGraphicManager();
            if (manager) {
                let type:OsContainerControllerType|null = manager.findContainerControllerType("2D CONTROLLER");
                let supportSet:OsContainerSupportSet|null = manager.findContainerSupportSet("2D", false);
                if (type != null) this._imageContainer = manager.createContainer(type, true, this);
                if (this._imageContainer) {
                    /*onis::graphics::container_toolbar_ptr toolbar = _image_container->get_toolbar();
                    if (toolbar != NULL) {
                        toolbar->visible = OSTRUE;
                        toolbar->active = OSTRUE;
                    }*/
                    this._imageContainer.setSupportSet(supportSet);
                    /*_image_container->set_should_auto_hide_annotations(OSTRUE);
                    _image_container->set_callback(OS_IMGCONT_AUTO_SELECT_1_1, (void (*)())should_auto_select);
                    _image_container->set_callback(OS_IMGCONT_MOUSE_RIGHT_BUTTON_MENU_CBK, (void(*)())on_mouse_right_button_menu, shared_from_this());*/
                    let controller:OsContainerController|null = this._imageContainer.getController();
                    if (controller) {
                        //controller.setAddSeriesCallback(this.onAddSeriesHandler, this);
                        //controller.setAddImageCallback(this.onAddImageHandler, this);
                        //controller.setRemoveSeriesCallback(this.onRemoveSeriesHandler, this);
                        //controller.setGetSeriesStateCallback(this.getSeriesStateHandler, this);
                        controller.setStateId(this.getStateId());
                    }

                    let dlmgr:OsDownloadManager = this.viewer.getDownloadManager();
                    if (dlmgr) dlmgr.registerContainer(this._imageContainer, true);
                }
            }
        }
    }

    protected _destroy():void {
        //for (let i:number=0; i<this._loadSeriesDupInfo.length; i++) this._loadSeriesDupInfo[i].release();
        //this._loadSeriesDupInfo.splice(0, this._loadSeriesDupInfo.length);
        if (this._rectTimeout) clearTimeout(this._rectTimeout);
        if (this._imageContainer) {
            let dlmgr:OsDownloadManager|null = this.viewer?this.viewer.getDownloadManager():null;
            if (dlmgr) dlmgr.registerContainer(this._imageContainer, false);
            this._imageContainer.release();
        }
        super._destroy();
    }

    
    public setRect(rect:Array<number>) {
        super.setRect(rect);
        if (!this._imageContainer) return;
        for (let i=0; i<4; i++) this._imageContainer.rect[i]=rect[i];
        this._imageContainer.replaceWidgets();
        if (this._rectTimeout) clearTimeout(this._rectTimeout);
        this._rectTimeout = setTimeout(()=>{ this._rectTimeout = null; if (this._imageContainer) this._imageContainer.redrawSingleWindow(); }, 0);
    }*/

  //containers:
  @override
  List<OsContainerWnd> get containers => [_imageContainer];

  @override
  OsContainerWnd? get activeContainer => _imageContainer;

  /*
    public haveContainerWindow(dial:OsContainerWnd):boolean { if (dial && dial === this._imageContainer) return true; else return false; }*/
}
