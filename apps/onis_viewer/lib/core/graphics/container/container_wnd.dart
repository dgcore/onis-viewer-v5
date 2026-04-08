import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/graphics/canvas/canvas.dart';
import 'package:onis_viewer/core/graphics/container/container_syncho_item.dart';
import 'package:onis_viewer/core/graphics/container/container_tool.dart';
import 'package:onis_viewer/core/graphics/container/container_widget.dart';
import 'package:onis_viewer/core/graphics/container/controllers/container_controller.dart';
import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/layout/view_wnd.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/models/database/color_lut.dart';
import 'package:onis_viewer/core/models/database/convolution_filter.dart';
import 'package:onis_viewer/core/models/database/hanging_protocol.dart';
import 'package:onis_viewer/core/models/database/opacity_table.dart';
import 'package:onis_viewer/core/models/database/window_level.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

enum OsContDraw {
  osDraw,
  osForceRedraw,
  osNoDraw,
}

enum OsContDrawTarget {
  osDrawTargetScreen,
  osDrawTargetPrinter,
  osDrawTargetPrintPreviewContainer,
}

///////////////////////////////////////////////////////////////////////
// incoming_image_properties
///////////////////////////////////////////////////////////////////////

class OsIncomingImageProperties {
  bool flipHorizontally = false;
  bool flipVertically = false;
  double rotation = 0;
  double zoom = 0.0;
  WindowLevel? windowLevelPreset;
  ColorLut? colorLutPreset;
  OpacityTable? opacityTablePreset;
  ConvolutionFilter? convolutionFilterPreset;
  int targetMode = 0;
  int targetPage = 0;
  List<HpDicomTag> targetTags = [];

  void reset() {
    flipHorizontally = false;
    flipVertically = false;
    rotation = 0.0;
    zoom = 0.0;
    windowLevelPreset = null;
    colorLutPreset = null;
    opacityTablePreset = null;
    convolutionFilterPreset = null;
    targetTags.clear();
  }
}

///////////////////////////////////////////////////////////////////////
// container_image_box_info
///////////////////////////////////////////////////////////////////////

class OsContainerImageBoxInfo {
  List<double> rect = [0, 0, 0, 0];
  WeakReference<OsRenderer>? wRenderer;

  OsRenderer? get renderer => wRenderer?.target;
  set renderer(OsRenderer? renderer) {
    wRenderer = renderer != null ? WeakReference<OsRenderer>(renderer) : null;
  }
}

class OsContainerWnd extends ChangeNotifier {
  //private _image:OsDriverImage|null = null;
  //private _component:any = null;

  //protected _viewer:Viewer|null = null;
  final ValueNotifier<int> _redrawNotifier = ValueNotifier<int>(0);
  final OsContainerController _controller;
  final WeakReference<ViewWnd>? _wView;
  //private _view:OsViewWnd|null;
  //members:
  int _rowCnt = 0;
  int _colCnt = 0;
  List<OsContainerImageBoxInfo> _imageBoxes = [];
  final double _borderWidth = 1.0;
  final double _borderInter = 1.0;
  //private _lastDrawRowCnt;
  //private _lastDrawColCnt;
  bool _zoomed = false;
  final bool _canZoom = true;
  //private _saveRowCnt:number;
  //private _saveColCnt:number;
  //private _singleWindow:boolean;
  //private _idriver:number;
  final OsDriver _driver;
  late final OsDriverContext _context;
  List<double> _rect = [0, 0, 0, 0];
  final List<double> _lastCursorPosition = [0, 0];
  //private _refreshTimerId:any;
  //private _cineTimerId:any;
  //private _drawTarget:number;

  //private _autoPlaySupport:boolean;
  //private _minimizeMemoryUsage:boolean;
  //private _wanchor:OsWeakObject|null;
  //
  //b32 _selection_done;
  //private _selectionDone:boolean;

  //private _isCaptured:boolean;
  //private _capturedIndex:number;

  WeakReference<OsContainerTool>? _wtool;
  WeakReference<Object>? _wtoolData;
  WeakReference<OsContainerTool>? _wrunningTool;
  WeakReference<Object>? _wrunningToolData;

  //private _annotationAction:OsAnnotationAction|null; /*annotation_action_wptr _wannotation_action;*/
  //private _wrunningItem:OsWeakObject|null;

  //private _synchroItem:IContainerSynchroItem|null;
  //private _propagationItem:IContainerPropagateItem|null;
  //private _wscoutItem:OsWeakObject|null;

  int _currentPage = 0;
  //private _savePageIndex:number;
  bool _inactive = false;
  //private _inactiveColor:Array<number>;

  //private _cineSpeed:number;
  //private _cineMode:number;
  //private _isPlaying:boolean;
  //private _cineSupport:boolean;
  //private _cineSwingDirection:number;
  //private _cineOptionSource:number;
  //private _cineOptionSetId:string = '';
  //private _cineOptionCategory:string;
  final bool _freezeDrawing = false;

  //protected _shouldAutoHideAnnotations = false;
  //protected _shouldDisplayRuler:boolean = true;
  //protected _shouldDisplayGraphics:boolean = true;
  //protected _shouldDisplayOverlays:boolean = true;
  //protected _shouldDisplayDicom:boolean = true;
  //protected _haveAnnotationSet:boolean = false;
  //protected _wannotationSet:OsWeakObject|null = null;

  //protected _selectionRectangleIndex:number = -1;
  //protected _selectionRectangleRect:[number, number, number, number] = [0, 0, 0, 0];

  //private _filterType:number;

  //protected _pageSlider:OsContainerPageSlider|null;
  //private _pageSliderEnable:boolean;

  bool _pageMode = false;

  //private _drawLocalizer:boolean = false;
  //private _wLocalizerStudy:OsWeakObject|null = null;
  //private _wLocalizerSeries:OsWeakObject|null = null;
  //private _localizerMat:OsMatrix = new OsMatrix();
  //private _localizerSize:[number, number] = [0, 0];

  //private _redrawAsapTimerId:any;

  //private _fonts:any[] = [{name:'', size:12, color:'#ffffff'}, {name:'', size:12, color:'#00ff00'}];

  final List<int> _backCol = [0, 0, 0, 255];
  final List<int> _borderCol = [64, 64, 64, 255];
  final List<int> _selCol = [255, 255, 255, 255];
  //private _wsupportSet:OsWeakObject|null;

  //private _shouldAutoSelect1x1:boolean = true;
  //private _subscription: Subscription|null = null;
  //private _toolbar:OsGraphicToolbar|null = null;
  //onis::graphics::view_wnd_wptr _wview;

  //static count:number = 0;*/

  //--------------------------------------------------
  //constructor
  //--------------------------------------------------

  OsContainerWnd(
      {required OsDriver driver,
      required OsContainerController controller,
      required ViewWnd view})
      : _driver = driver,
        _context = driver.createContext(),
        _controller = controller,
        _wView = WeakReference<ViewWnd>(view) {
    _controller.container = this;
    setImageMatrix(2, 2);
  }

  get context => _context;
  int get rowCnt => _rowCnt;
  int get colCnt => _colCnt;
  double get borderWidth => _borderWidth;
  double get borderInter => _borderInter;

  OsContainerWidget? get widget {
    return OsContainerWidget(
      containerWnd: this,
    );
  }

  ValueNotifier<int> get redrawNotifier => _redrawNotifier;

  void setRect(double x, double y, double width, double height) {
    _rect = [x, y, width, height];
    replaceWidgets();
  }

  /*constructor(viewer:Viewer, type:OsContainerControllerType, view:OsViewWnd) {
        super();

        if (viewer && viewer.messageService) {
            this._subscription = viewer.messageService.getMessage().subscribe(
                next => this._onReceivedMessage(next.id, next.data),
            );
        }

        this._viewer = viewer;
        this._controller = type.createController();
        this._view = view;
        this._wsupportSet = null;
        this._synchroItem = null;
        this._wscoutItem = null;
        this._propagationItem = null;
        this._wtool = null;
        this._wtoolData = null;
        this._wrunningTool = null;
        this._wrunningToolData = null;
        this._refreshTimerId = null;
        this._cineTimerId = null;
        this._annotationAction = null;
        this._selectionDone = false;
        this._pageSliderEnable = true;
        this._wanchor = null;

        this._isCaptured = false;
        this._capturedIndex = -1;

        this._drawTarget = OsContDrawTarget.OS_DRAW_TARGET_SCREEN;
        /*_draw_factor = 1.0;*/
        this._pageMode = false;
        this._minimizeMemoryUsage = false;
        this._idriver = -1;
        this._driver = null;
        this._context = null;
        this._sharedContext = null;
        this._rowCnt = 0;
        this._colCnt = 0;
        this._lastDrawRowCnt = -1;
        this._lastDrawColCnt = -1;
        this._canZoom = true;
        this._singleWindow = false;
        this._currentPage = 0;
        this._savePageIndex = -1;
        this._imageBoxes = new Array<OsContainerImageBoxInfo>();
        this._inactive = false;
        this._inactiveColor = [255, 0, 0, 128];
        this._cineSpeed = 60;
        this._cineMode = 0;
        this._isPlaying = false;
        this._cineSupport = true;
        this._cineOptionSource = 0;
        this._cineOptionCategory = "";
        this._cineSwingDirection = 0;
        this._borderWidth = 1.0;
        this._borderInter = 1.0;
        this._autoPlaySupport = true;
        this._redrawAsapTimerId = null;
        //_timer_redraw_asap = OSFALSE;

        this._propagationItem = null;

        this._saveRowCnt = -1;
        this._saveColCnt = -1;

        this._freezeDrawing = false;

        this._wrunningItem = null;
        
        
        
        
        this._filterType = 1;
        this._zoomed = false;
        this._pageSlider = null;
        
        
       
        
        let openglIsSupported:boolean = false;
       
        this.useOpenGL(openglIsSupported, null);
        this.setSingleWindowMode(true);
        this.setImageMatrix(2, 2, false);

        if (this._controller) this._controller.setWindow(this);

        

    }
    
    //--------------------------------------------------
    //destroy
    //--------------------------------------------------

    protected _destroy():void {

        if (this._subscription) this._subscription.unsubscribe();
        this._subscription = null;

        if (this._refreshTimerId) clearInterval(this._refreshTimerId);
        this._refreshTimerId = null;
        if (this._cineTimerId) clearInterval(this._cineTimerId);
        this._cineTimerId = null;
        if (this._redrawAsapTimerId) clearTimeout(this._redrawAsapTimerId);
        this._redrawAsapTimerId = null;
        if (this._wscoutItem) this._wscoutItem.destroy();
        this._wscoutItem = null;
        if (this._wanchor) this._wanchor.destroy();
        this._wanchor = null;
        if (this._wsupportSet) this._wsupportSet.destroy();
        this._wsupportSet = null;
        if (this._image) this._image.destroy();
        this._image = null;

        if (this._wtool) this._wtool.destroy();
        this._wtool = null;
        if (this._wtoolData) this._wtoolData.destroy();
        this._wtoolData = null;
        if (this._wrunningTool) this._wrunningTool.destroy();
        this._wrunningTool = null;
        if (this._wrunningToolData) this._wrunningToolData.destroy();
        this._wrunningToolData = null;
        if (this._wannotationSet) this._wannotationSet.destroy();
        this._wannotationSet = null;

        if (this._wrunningItem) this._wrunningItem.destroy();
        this._wrunningItem = null;

        if (this._pageSlider) this._pageSlider.release();
        this._pageSlider = null;
        
        if (this._controller) this._controller.release();
        if (this._context) {
            this._context.destroy();
            this._context = null;
        }

        for (let i=0; i<this._imageBoxes.length; i++) this._imageBoxes[i].destroy();
        this._imageBoxes.splice(0, this._imageBoxes.length);

        this._sharedContext = null;
        this._view = null;
        this._controller = null;
        this._driver = null;
        this._propagationItem = null;
        this._synchroItem = null;
        this._annotationAction = null;

        this._viewer = null;

        if (this._wLocalizerStudy) this._wLocalizerStudy.destroy();
        if (this._wLocalizerSeries) this._wLocalizerSeries.destroy();
        this._wLocalizerStudy = null;
        this._wLocalizerSeries = null;
        
        super._destroy();

        //OsContainerWnd.count--;
        //console.log("OsContainerWnd.count = " + OsContainerWnd.count);

    }

        
    
    public getViewer():Viewer|null {
        return this._viewer;
    }

    public setComponent(component:any) {
        this._component = component;
    }
    

    //-----------------------------------------------------------------------
    //widgets
    //-----------------------------------------------------------------------
    public showWidget(component:any):OsContainerWidgetWnd|null {
        if (this._component) return this._component?this._component.showWidget(component):null;
        else return null;
    }

    public hideWidget(widget:OsContainerWidgetWnd) {
        if (this._component) this._component.hideWidget(widget);
    }

    //-----------------------------------------------------------------------
    //view
    //-----------------------------------------------------------------------
    public getView():OsViewWnd|null {
        return this._view;
    }
    
    public getLayout():OsViewLayout|null {
        return this._view?this._view.getLayout():null;
    }

    //-----------------------------------------------------------------------
    // cursor position
    //-----------------------------------------------------------------------
    public getLastMousePosition(xy:[number, number]):boolean {
        return this._component?this._component.getLastMousePosition(xy):false;
    }*/

  //-----------------------------------------------------------------------
  //controller
  //-----------------------------------------------------------------------
  OsContainerController get controller {
    return _controller;
  }

  //-----------------------------------------------------------------------
  //image matrix
  //-----------------------------------------------------------------------

  void setImageMatrix(int row, int col) {
    if (_rowCnt < 0 || _rowCnt > 10) return;
    if (_colCnt < 0 || _colCnt > 10) return;
    //Release the memory of all renderers:
    /*if (this._controller) {
            let list:Array<OsRenderer> = this._controller.getRendererElements();
            if (list) {
                for (let i=0; i<list.length; i++)
                    list[i].releaseMemory(0);
            }
        }*/
    setImageBoxStock(row * col);
    _rowCnt = row;
    _colCnt = col;
    if (_rowCnt != 1 || _colCnt != 1) _zoomed = false;
    replaceWidgets();
    //if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);*/
  }

  List<int> getImageMatrix() {
    return [_rowCnt, _colCnt];
  }

  OsRenderer? getImageBoxRenderer(int index) {
    if (index < 0 || index >= _rowCnt * _colCnt) return null;
    OsContainerImageBoxInfo? box = _imageBoxes[index];
    return box.renderer;
  }

  ({double x, double y, double width, double height}) getImageBoxRect(
      int index) {
    if (index < 0 || index >= _rowCnt * _colCnt) {
      return (x: 0, y: 0, width: 0, height: 0);
    }
    OsContainerImageBoxInfo? box = _imageBoxes[index];
    return (
      x: box.rect[0],
      y: box.rect[1],
      width: box.rect[2],
      height: box.rect[3]
    );
  }

  /*public getImageBoxRect(index:number, rect:[number, number, number, number]):void {
        let box:OsContainerImageBoxInfo|null = this._imageBoxes[index];
        if (!box) return;
        for (let i=0; i<4; i++) rect[i] = box.rect[i];
    }

    //virtual driver_context_ptr get_image_box_context(s32 index) const;

    public findImageBoxIndexFromRenderer(render:OsRenderer):number {
        for (let i=0; i<this._imageBoxes.length; i++) {
            let box:OsContainerImageBoxInfo|null = this._imageBoxes[i];
            if (box && box.getRenderer() === render)
                return i;
        }
        return -1;
    }*/

  void setImageBoxStock(int count) {
    if (count == _imageBoxes.length) return;
    if (count == 0) {
      _imageBoxes.clear();
      return;
    }
    List<OsContainerImageBoxInfo> tmp =
        List.filled(count, OsContainerImageBoxInfo());
    //Copy what we can:
    int copy = count > _imageBoxes.length ? _imageBoxes.length : count;
    for (int i = 0; i < copy; i++) {
      tmp[i] = _imageBoxes[i];
    }
    _imageBoxes.removeRange(0, copy);
    //Create additionals:
    int create = count - copy;
    for (int i = 0; i < create; i++) {
      tmp[i + copy] = OsContainerImageBoxInfo();
    }
    //Delete the extra:
    _imageBoxes.removeRange(0, _imageBoxes.length);
    //finalize:
    _imageBoxes = tmp;
  }

  /*public createImageBoxInfo(container:OsContainerWnd):OsContainerImageBoxInfo {
        let info:OsContainerImageBoxInfo = new OsContainerImageBoxInfo();
        if (!container.isUsingSingleWindow()) {
            
        }
        return info;
    }*/

  void setImageBoxRect(
      int index, double x, double y, double width, double height) {
    _imageBoxes[index].rect[0] = x;
    _imageBoxes[index].rect[1] = y;
    _imageBoxes[index].rect[2] = width;
    _imageBoxes[index].rect[3] = height;

    // console.log("set " + index + ": " + this._imageBoxes[index].rect[0] + " " + this._imageBoxes[index].rect[1] + " " + this._imageBoxes[index].rect[2] + " " + this._imageBoxes[index].rect[3]);
  }

  int findImageBoxIndexFromPoint(RawPointerInfo pointer) {
    double x = pointer.localPosition.dx;
    double y = pointer.localPosition.dy;
    for (int i = 0; i < _imageBoxes.length; i++) {
      if (x >= _imageBoxes[i].rect[0] &&
          x <= _imageBoxes[i].rect[0] + _imageBoxes[i].rect[2]) {
        if (y >= _imageBoxes[i].rect[1] &&
            y <= _imageBoxes[i].rect[1] + _imageBoxes[i].rect[3]) {
          return i;
        }
      }
    }
    return -1;
  }

  /*public setImageBoxRender(index:number, render:OsRenderer|null) {
        this._imageBoxes[index].setRenderer(render);
    }

   
    
    public getImageBoxContext(index:number):OsDriverContext|null{
        if (this._singleWindow) return this._context;
        else return this._imageBoxes[index].getWindowContext();
    }

    //driver_context_ptr get_image_box_context(s32 index) const;

    public zoomImageBox(zoom:boolean, index:number, notify:boolean = true):boolean {
        if (zoom == this._zoomed) return true;
        if (!this._canZoom) return false;
        let list:Array<OsRenderer>|null = this._controller?this._controller.getRendererElements():null;
        if (list) {
            if (list.length == 0) return false;
            if (this.getRunningTool(null, false) != null) return false;
        }
        if (zoom) {
            if (this._rowCnt == 1 && this._colCnt == 1) return false;
            this._saveRowCnt = this._rowCnt;
            this._saveColCnt = this._colCnt;
            this._freezeDrawing = true;
            this.setImageMatrix(1, 1, notify);
            let newIndex:number = 0;
            if (this._pageMode == true) newIndex = this._currentPage*this._saveRowCnt*this._saveColCnt;
            else newIndex = this._currentPage;
            newIndex += index;
            this._savePageIndex = this._currentPage;
            this._zoomed = true;
            this._freezeDrawing = false;
            this.setCurrentPage(newIndex, OsContDraw.OS_FORCE_REDRAW);
        }
        else {
            if (this._saveRowCnt < 1 && this._saveRowCnt > 10) return false;
            if (this._saveColCnt < 1 && this._saveColCnt > 10) return false;
            this._freezeDrawing = true;
            this.setImageMatrix(this._saveRowCnt, this._saveColCnt, notify);
            let newIndex:number = 0;
            if (this._pageMode) newIndex = this._currentPage / (this._saveRowCnt*this._saveColCnt);
            else {
                if (this._currentPage < this._savePageIndex + this._saveRowCnt*this._saveColCnt && this._currentPage >= this._savePageIndex) newIndex = this._savePageIndex;
                else newIndex = this._currentPage;
            }
            this._freezeDrawing = false;
            this.setCurrentPage(newIndex, OsContDraw.OS_FORCE_REDRAW);
            this._zoomed = false;
        }
    	return true;
    }

    public isImageBoxZoomEnable():boolean {
        return this._canZoom;
    }

    public enableImageBoxZoom(enable:boolean) {
        if (!enable) this.zoomImageBox(false, 0);
	    this._canZoom = enable;
    }
      
    //-----------------------------------------------------------------------
    //responder
    //-----------------------------------------------------------------------

    public makeFirstResponder():void {
        this.setInactive(false, false);
        this.processSynchro();
        if (this._component) this._component.setFocus();
    }

    public becameFirstResponder():void {
        let propagate:IContainerPropagateItem|null = this.getPropagationItem();
        if (propagate != null) propagate.setMainContainer(this);
        let synchro:IContainerSynchroItem|null = this.getSynchroItem();
        if (synchro != null) synchro.setMainContainer(this);
        let localizer:OsContainerScoutItem|null = this.getScoutItem();
        if (localizer != null) localizer.setMainContainer(this);
        if (this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_BECAME_FIRST_RESPONDER, this);
    }

    //-----------------------------------------------------------------------
    //resizing
    //-----------------------------------------------------------------------
    
    //virtual void on_size(u32 type, f64 cx, f64 cy);

    */
  void replaceWidgets() {
    if (_rect[3] <= 0) return;
    if (_rect[2] <= 0) return;
    if (_colCnt * _rowCnt <= 0) return;

    //we keep a minimum of d_BorderInter pixels between the images
    double borderInterCountInWidth = _colCnt - 1;
    double borderInterCountInHeight = _rowCnt - 1;
    //we keep a minimum of d_BorderWidth pixels on the edges!
    double imgWidth =
        (_rect[2] - borderInterCountInWidth * _borderInter - _borderWidth * 2) /
            _colCnt;
    double imgHeight = (_rect[3] -
            borderInterCountInHeight * _borderInter -
            _borderWidth * 2) /
        _rowCnt;
    imgWidth = imgWidth.floorToDouble();
    imgHeight = imgHeight.floorToDouble();
    double leftX = _rect[2] -
        (imgWidth * _colCnt) -
        _borderWidth * 2 -
        borderInterCountInWidth * _borderInter;
    double leftY = _rect[3] -
        (imgHeight * _rowCnt) -
        _borderWidth * 2 -
        borderInterCountInHeight * _borderInter;
    double offsetY = _borderWidth + (leftY * 0.5).floorToDouble();
    for (int j = 0; j < _rowCnt; j++) {
      double offsetX = _borderWidth + (leftX * 0.5).floorToDouble();
      for (int i = 0; i < _colCnt; i++) {
        setImageBoxRect(j * _colCnt + i, offsetX, offsetY, imgWidth, imgHeight);
        offsetX += imgWidth + _borderInter;
      }
      offsetY += imgHeight + _borderInter;
    }
    //this.setCurrentPage(this._currentPage, OsContDraw.OS_FORCE_REDRAW);
    //let propagation:IContainerPropagateItem|null = this.getPropagationItem();
    //if (propagation) propagation.propagate(this, null, "POS|ROT|FOV", true, null);
  }

  //-----------------------------------------------------------------------
  //single window mode
  //-----------------------------------------------------------------------
  /*public setSingleWindowMode(single:boolean):void {
        this._singleWindow = single;
        this.setImageMatrix(this._rowCnt, this._colCnt, false);
        if (this._singleWindow) {
            //we need a context for drawing:
            if (!this._context && this._driver) {
                let contextParam:OsDriverContextParam = new OsDriverContextParam();
                contextParam.setWindow(this);
                if (this._sharedContext) contextParam.setSharedContext(this._sharedContext);
                this._context = this._driver.createContext(contextParam);
                contextParam.destroy();
                //if (_on_context_created != NULL) _on_context_created(std::static_pointer_cast<onis::graphics::container_wnd>(shared_from_this()), _context, _wcontext_create_cbk_data.lock());
                //create_dynamics_fonts(_context);
            }
        }
        else {
            //we don't need a context for drawing:
            if (this._context) {
                this._context.destroy();
                this._context = null;
            }
        }
    }

    public isUsingSingleWindow():boolean {
        return this._singleWindow;
    }*/

  void redraw() {
    for (int i = 0; i < _rowCnt * _colCnt; i++) {
      final boxRect = _imageBoxes[i].rect;
      final info = OsWillDrawInfo();
      info.context = _context;
      info.viewport[0] = boxRect[0];
      info.viewport[1] = boxRect[1];
      info.viewport[2] = boxRect[2];
      info.viewport[3] = boxRect[3];

      //info.mouse[0] = mousePos[0] - boxRect[0];
      //info.mouse[1] = mousePos[1] - boxRect[1];

      prepareForDrawingImageBox(i, info);
      /*let tool:OsContainerTool|null = this.getRunningTool(null, false);
                if (!tool) tool = this.getCurrentTool(null, false);
                if (tool) tool.willDraw(this, i, info);
                info.destroy();*/
    }

    _driver.currentContext = _context;
    //Set the viewport:
    _driver.setViewport(0, 0, _rect[2], _rect[3]);
    //Disable the clipping mode:
    _driver.disableClipping();
    //Clear the window:
    _driver.setClearColor4i(
        _borderCol[0], _borderCol[1], _borderCol[2], _borderCol[3]);
    _driver.clearBuffers();

    if (_imageBoxes.isEmpty) return;
    final firstRect = _imageBoxes[0].rect;
    final lastRect = _imageBoxes[_rowCnt * _colCnt - 1].rect;
    final rinfo = OsRenderInfo(null);
    rinfo.projMat.buildOrthographicProjectionMatrixRH(
        0.0, _rect[2], 0.0, _rect[3], -1.0, 1.0);
    if (firstRect[0] != _borderWidth) {
      rinfo.worldMat.mat[12] = (firstRect[0] - _borderWidth) * 0.5;
      rinfo.worldMat.mat[13] = _rect[3] * 0.5;
      _driver.setColor4i(0, 0, 0, 255);
      _driver.fillSolidRect(rinfo, firstRect[0] - _borderWidth, _rect[3]);
    }
    if (lastRect[0] + lastRect[2] + _borderWidth != _rect[2]) {
      double tmp = _rect[2] - (lastRect[0] + lastRect[2]) - _borderWidth;
      rinfo.worldMat.mat[12] = _rect[2] - tmp * 0.5;
      rinfo.worldMat.mat[13] = _rect[3] * 0.5;
      _driver.setColor4i(0, 0, 0, 255);
      _driver.fillSolidRect(rinfo, tmp, _rect[3]);
    }
    if (lastRect[1] + lastRect[3] + _borderWidth != _rect[3]) {
      double tmp = _rect[3] - (lastRect[1] + lastRect[3]) - _borderWidth;
      rinfo.worldMat.mat[12] = _rect[2] * 0.5;
      rinfo.worldMat.mat[13] = tmp * 0.5;
      _driver.setColor4i(0, 0, 0, 255);
      _driver.fillSolidRect(rinfo, _rect[2], tmp);
    }
    if (firstRect[1] != _borderWidth) {
      rinfo.worldMat.mat[12] = _rect[2] * 0.5;
      rinfo.worldMat.mat[13] = _rect[3] - (firstRect[1] - _borderWidth) * 0.5;
      _driver.setColor4i(0, 0, 0, 255);
      _driver.fillSolidRect(rinfo, _rect[2], firstRect[1] - _borderWidth);
    }

    //draw each image:
    for (int i = 0; i < _rowCnt * _colCnt; i++) {
      redrawImageBoxHelp(i);
    }
  }

  /*public redrawSingleWindow():void {
        if (this._freezeDrawing) return;
        if (!this._singleWindow) return;
        if (!this._imageBoxes.length) return;
        if (this._context && this._driver && this._context.isInitialized()) {
           

            let mousePos:[number,number] = [0,0];
            if (!this.getLastMousePosition(mousePos)) {
                mousePos[0] = VALUE.F64_MAX;
                mousePos[1] = VALUE.F64_MAX;
            }

            for (let i = 0; i < this._rowCnt*this._colCnt; i++) {
                let boxRect:[number, number, number, number] = [0, 0, 0, 0];
                this.getImageBoxRect(i, boxRect);
                let info:OsWillDrawInfo = new OsWillDrawInfo();
                info.context = this._context;
                info.viewport[0] = boxRect[0];
                info.viewport[1] = boxRect[1];
                info.viewport[2] = boxRect[2];
                info.viewport[3] = boxRect[3];
                info.mouse[0] = mousePos[0] - boxRect[0];
                info.mouse[1] = mousePos[1] - boxRect[1];

                this.prepareForDrawingImageBox(i, info);
                let tool:OsContainerTool|null = this.getRunningTool(null, false);
                if (!tool) tool = this.getCurrentTool(null, false);
                if (tool) tool.willDraw(this, i, info);
                info.destroy();
            }
            
            //Make the context current:
            this._driver.setCurrentContext(this._context);
            //Set the viewport:
            this._driver.setViewport(0, 0, this.rect[2], this.rect[3]);
            //Disable the clipping mode:
            this._driver.disableClipping();
            //this._driver.enableClipping(false);
            //test if the window remains black:
            //if (!is_window_will_remain_black()) break;
            //Clear the window:
            this._driver.setClearColor4i(this._borderCol[0], this._borderCol[1], this._borderCol[2], 255);
            this._driver.clearBuffers();

            let firstRect = this._imageBoxes[0].rect;
            let lastRect = this._imageBoxes[this._rowCnt*this._colCnt-1].rect;
            let rinfo:OsRenderInfo = new OsRenderInfo(null);
            rinfo.projMat.buildOrthographicProjectionMatrixRH(0.0, this.rect[2], 0.0, this.rect[3], -1.0, 1.0);
            if (firstRect[0] != this._borderWidth) {
                rinfo.worldMat.mat[12] = (firstRect[0]-this._borderWidth)*0.5;
                rinfo.worldMat.mat[13] = this.rect[3]*0.5;
                this._driver.setColor4i(0, 0, 0, 255);
                this._driver.fillSolidRect(rinfo, firstRect[0]-this._borderWidth, this.rect[3]);
            }
            if (lastRect[0] + lastRect[2] + this._borderWidth != this.rect[2]) {
                let tmp:number = this.rect[2] - (lastRect[0]+ lastRect[2]) - this._borderWidth;
                rinfo.worldMat.mat[12] = this.rect[2] - tmp*0.5;
                rinfo.worldMat.mat[13] = this.rect[3]*0.5;
                this._driver.setColor4i(0, 0, 0, 255);
                this._driver.fillSolidRect(rinfo, tmp, this.rect[3]);
            }
            if (lastRect[1] + lastRect[3] + this._borderWidth != this.rect[3]) {
                let tmp:number = this.rect[3] - (lastRect[1] + lastRect[3]) - this._borderWidth;
                rinfo.worldMat.mat[12] = this.rect[2]*0.5;
                rinfo.worldMat.mat[13] = tmp*0.5;
                this._driver.setColor4i(0, 0, 0, 255);
                this._driver.fillSolidRect(rinfo, this.rect[2], tmp);
            }
            if (firstRect[1] != this._borderWidth) {
                rinfo.worldMat.mat[12] = this.rect[2]*0.5;
                rinfo.worldMat.mat[13] = this.rect[3] - (firstRect[1]-this._borderWidth)*0.5;
                this._driver.setColor4i(0, 0, 0, 255);
                this._driver.fillSolidRect(rinfo, this.rect[2], firstRect[1]-this._borderWidth);
            }

            //draw each image:
            for (let i=0; i<this._rowCnt*this._colCnt; i++) {
                this.redrawImageBoxHelp(i);
            }

            
            
            //container_controller_ptr controller = get_controller();

            //Draw the progression bar:
            if (this._refreshTimerId) {
                let progression:number = this._controller?this._controller.getLoadingProgression():-1;
                if (progression >= 0) {
                    this._driver.setViewport(0, 0, this.rect[2], this.rect[3]);
                    let rinfo:OsRenderInfo = new OsRenderInfo(null);
                    rinfo.projMat.buildOrthographicProjectionMatrixRH(0.0, this.rect[2], 0.0, this.rect[3], -1.0, 1.0);
                    let barWidth = Math.floor(this.rect[2]*progression);
                    let barHeight = 10;
                    rinfo.worldMat.mat[12] = barWidth*0.5;
                    rinfo.worldMat.mat[13] = this.rect[3]-barHeight*0.5;
                    this._driver.setColor4i(255, 201, 14, 255);
                    this._driver.fillSolidRect(rinfo, barWidth, barHeight);
                }
            }

            
            //Swapp the buffers:
            this._context.swappBuffers();
        }
    }

        
    //-----------------------------------------------------------------------
    //synchro
    //-----------------------------------------------------------------------

    public setSynchroItem(item:IContainerSynchroItem|null) {
        this._synchroItem = item;
    }*/

  OsContainerSynchroItem? getSynchroItem() {
    //return this._synchroItem;
    return null;
  }

  /*public processSynchro() {
        let containersToRedraw:Array<OsContainerWnd> = [];
        if (this._synchroItem) this._synchroItem.synchronize(this, containersToRedraw);
    }

    //-----------------------------------------------------------------------
    //scout
    //-----------------------------------------------------------------------

    public setScoutItem(item:OsContainerScoutItem|null):void {
        if (this._wscoutItem) this._wscoutItem.destroy();
        this._wscoutItem = item ? item.getWeakObject() : null;
        if (item != null) item.registerContainer(this, true);
    }
    
    public getScoutItem():OsContainerScoutItem|null {
        return this._wscoutItem ? <OsContainerScoutItem>this._wscoutItem.lock(false) : null;
    }*/

  bool setShouldDrawLocalizer(
      {required bool draw,
      required entities.Study? study,
      required entities.Series? series,
      required OsMatrix? mat,
      required List<double>? dimensions}) {
    return false;
    /*let ret:boolean = false;
        if (this._drawLocalizer != draw) ret = true;
        if (!ret && draw) {
            if (!this._wLocalizerStudy || this._wLocalizerStudy.lock(false) !== study) ret = true;
            if (!this._wLocalizerSeries || this._wLocalizerSeries.lock(false) !== series) ret = true;
            if (mat && !this._localizerMat.isEqual(mat)) ret = true;
            if (dimensions == null) ret = true;
            else {
                if (this._localizerSize[0] = dimensions[0]) ret = true;
                if (this._localizerSize[1] = dimensions[1]) ret = true;
            }
        }
        this._drawLocalizer = draw;
        if (this._wLocalizerStudy) this._wLocalizerStudy.destroy();
        this._wLocalizerStudy = study?study.getWeakObject():null;
        if (this._wLocalizerSeries) this._wLocalizerSeries.destroy();
        this._wLocalizerSeries = series?series.getWeakObject():null;
        if (mat) this._localizerMat.copyFrom(mat);
        if (dimensions != null) {
            this._localizerSize[0] = dimensions[0];
            this._localizerSize[1] = dimensions[1];
        }
        return ret;*/
  }

  //-----------------------------------------------------------------------
  //propagation
  //-----------------------------------------------------------------------
  /*public setPropagationItem(item =IContainerPropagateItem|null) {
        let current:IContainerPropagateItem|null = this._propagationItem;
        if (current) current.registerContainer(this, false);
        this._propagationItem = null;
        if (item) {
            this._propagationItem = item;
            item.registerContainer(this, true);
        }
    }

    public getPropagationItem():IContainerPropagateItem|null {
        return this._propagationItem;
    }
        
    //-----------------------------------------------------------------------
    //rendering drivers
    //-----------------------------------------------------------------------
    public useOpenGL(use =boolean, sharedContext =OsDriverContext|null):boolean {
        let idriver:number = (use) ? 2 : 1;
        let driverName:string = (idriver == 2) ? 'OPENGL1' : 'WEBCANVAS';
        let manager:OsGraphicManager|null = this._view&&this._view.viewer?this._view.viewer.getGraphicManager():null;
        let driver:OsDriver|null = manager?manager.findDriver(driverName):null;
        if (!driver) return false;
        _driver = driver;
        this._idriver = idriver;
        
        return true;
    }

    public isUsingOpengl():boolean {
        return this._idriver == 2;
    }*/

  //-----------------------------------------------------------------------
  //pages
  //-----------------------------------------------------------------------
  bool get pageMode {
    return _pageMode;
  }

  set pageMode(bool enable) {
    _pageMode = enable;
    setCurrentPage(index: 0, mode: OsContDraw.osForceRedraw);
  }

  int get pageCount {
    final items = _controller.rendererElements;
    int count = 0;
    for (final item in items) {
      if (!item.hidden) count++;
    }
    if (count <= _rowCnt * _colCnt) {
      return 1;
    } else {
      if (_pageMode) {
        int tmp = (count / (_rowCnt * _colCnt)).floor();
        if (tmp * _rowCnt * _colCnt < count) tmp++;
        return tmp;
      }
      return count;
    }
  }

  int get currentPage => _currentPage;

  bool setCurrentPage({required int index, required OsContDraw mode}) {
    bool ret = false;
    if (_freezeDrawing) return ret;
    //if (this._controller) this._controller.getLoadingProgression();
    if (_currentPage != index) {
      //We can change the page only if we are not running any tools:
      /*let tool:OsContainerTool|null = this.getRunningTool(null, false);
      if (tool) {
          if (tool.getId() !== 'IMGTOOL_SLIDER')
              return ret;
      }
      //Do we have a running annotation action?
      let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
      if (action) {
          if (action.isRunning()) 
              return ret;
      }*/
    }
    if (index <= 0 || index >= pageCount) {
      //Invalid page index, set to 0 by default:
      index = 0;
    }

    bool pageChanged = (_currentPage == index) ? false : true;
    ret = pageChanged;
    OsRenderer? previousFirstRender;
    if (_rowCnt * _colCnt == 1) previousFirstRender = getImageBoxRenderer(0);
    _currentPage = index;
    int startIndex = _currentPage;
    int count = _rowCnt * _colCnt;
    if (_pageMode) startIndex *= count;

    //Before drawing the page, we need to release the memory of the image boxes that will not be visible anymore in the page!
    //We also need to release the memory of the items that are context related if their context has changed!
    //This is because we need to release some data that may be context related!
    int releaseCount = 0;
    List<OsRenderer?> releaseItems = List.filled(count, null);

    int redrawCount = 0;
    List<int> redrawItems = List.filled(count, 0);
    final items = _controller.rendererElements;
    int pos = findStartingPosition(items, startIndex);
    for (int i = 0; i < count; i++) {
      OsRenderer? oldRender = getImageBoxRenderer(i);
      OsRenderer? newRender;
      if (pos != -1) {
        while (pos < items.length) {
          if (!items[pos].hidden) {
            newRender = items[pos];
            pos++;
            break;
          }
          pos++;
        }
      }
      if (newRender != null) {
        //start auto-playing if needed:
      }

      if (identical(oldRender, newRender)) {
        //we display the same item.
        //the context for the item will not change, we don't need to release the memory!
        //but we may need to redraw it:
        if (newRender != null) {
          if (newRender.dirty || newRender.wantRefreshAsSoonAsPossible) {
            redrawItems[redrawCount] = i;
            redrawCount++;
          }
        }
      } else {
        _imageBoxes[i].renderer = newRender;

        redrawItems[redrawCount] = i;
        redrawCount++;
        if (newRender != null) {
          //if the item was inserted in the list of item to release, we remove it:
          for (int j = 0; j < releaseCount; j++) {
            if (identical(newRender, releaseItems[j])) {
              releaseItems[j] = null;
              break;
            }
          }
        }
        if (oldRender != null) {
          //we need to add the old item in the list of items to release
          //if this old item will be drawn, this means that it will be visible so
          //we should not release its memory:
          int j;
          for (j = 0; j < redrawCount; j++) {
            if (identical(oldRender, getImageBoxRenderer(redrawItems[j]))) {
              break;
            }
          }
          if (j == redrawCount) {
            releaseItems[releaseCount] = oldRender;
            releaseCount++;
          }
        }
      }
    }

    //Release the memory of the items that are no more visible now:
    /*for (let i=0; i<releaseCount; i++) {
            if (releaseItems[i]) {
                if (this._autoPlaySupport) {
                    let tmp:OsRenderer|null = releaseItems[i];
                    if (tmp) {
                        tmp.pause(false);
                        if (this._minimizeMemoryUsage) tmp.releaseMemory(2);
                        else tmp.releaseMemory(0);
                    }
                }
            }
        }

        //in case of only one image box per page, we want it to be always selected!
        if (this._shouldAutoSelect1x1) {
            if (this._rowCnt*this._colCnt == 1) {
                let currentFirstRender:OsRenderer|null = this.getImageBoxRenderer(0);
                if (currentFirstRender != previousFirstRender ||  this._lastDrawColCnt != this._rowCnt || this._lastDrawColCnt != this._colCnt) {
                    //if (_should_auto_select_1_1(std::static_pointer_cast<onis::graphics::container_wnd>(shared_from_this()), _wauto_select_data.lock())) {
                        let modif1:number = this.unselectAll(false, false, currentFirstRender, null, null);
                        if (!this.isPlaying(null)) {
                            if (currentFirstRender != null) {
                                let modif2:number = this.select2(currentFirstRender, true, true, false, false, null);
                                if (this._viewer && this._viewer.messageService) {
                                    if (modif2 == 0) {
                                        if (modif1 != 0) {
                                            if (modif1 == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                                            this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
                                        }
                                    }
                                    else {
                                        if (modif1 == 2 || modif2 == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                                        this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
                                    }
                                }
                            }
                            else {
                                if (this._viewer && this._viewer.messageService && modif1 != 0) {
                                    if (modif1 == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                                    this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
                                }		
                            }
                        }
                        else {
                            if (this._viewer && this._viewer.messageService && modif1 != 0) {
                                if (modif1 == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                                this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
                            }
                        }
                    //}
                }
            }
        }*/

    //Redraw the items:
    if (mode == OsContDraw.osForceRedraw ||
        (mode == OsContDraw.osDraw && redrawCount > 0)) {
      _redrawNotifier.value++;
    }

    //check if one of the displayed renderers need to be redrawn asap:
    /*let refreshAsap = false;
        for (let i=0; i<count; i++) {
            let render:OsRenderer|null = this._imageBoxes[i].getRenderer();
            if (render) {
                if (render.wantRefreshAsSoonAsPossible()) {
                    refreshAsap = true;
                    break;
                }
            }
        }

        if (refreshAsap) {
            if (!this._redrawAsapTimerId) {
                this._redrawAsapTimerId = setTimeout(() => {
                    this._onReceiveTimerEvent(this._redrawAsapTimerId);
                }, 1);
            }
        }
        else {
            if (this._redrawAsapTimerId) {
                clearTimeout(this._redrawAsapTimerId);
                this._redrawAsapTimerId = null;
            }
        }
        
        if (pageChanged && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_PAGE_CHANGED, this);
        
        this._lastDrawRowCnt = this._rowCnt;
        this._lastDrawColCnt = this._colCnt;*/
    return ret;
  }

  /*public nextPage() {
        let pageCount:number = this.getPageCount();
        let newPage:number = this._currentPage+1;
        if (newPage < 0) newPage = 0;
        else if (newPage >= pageCount) newPage = pageCount-1;
        this.setCurrentPage(newPage, OsContDraw.OS_DRAW);
        this.processSynchro();
    }
    
    public previousPage() {
        let pageCount:number = this.getPageCount();
        let newPage:number = this._currentPage-1;
        if (newPage < 0) newPage = 0;
        else if (newPage >= pageCount) newPage = pageCount-1;
        this.setCurrentPage(newPage, OsContDraw.OS_DRAW);
        this.processSynchro();
    }

    
    
    public redrawImageBox(index:number):void {
        let list:Array<number> = new Array<number>();
        list.push(index);
        this.redrawImageBoxes(list);
    }
    
    public redrawImageBoxes(list:Array<number>):void {
        if (list.length == 0) return;
        if (this._singleWindow) this.redrawSingleWindow();
        else {
            for (let i=0; i<list.length; i++) 
                this.redrawImageBoxHelp(list[i]);
        }
    }*/

  void redrawImageBoxHelp(int index) {
    _redrawImageBox(_imageBoxes[index], index);
  }

  void _redrawImageBox(OsContainerImageBoxInfo imageBox, int index) {
    //Set the viewport:
    _driver.setViewport(
        imageBox.rect[0], imageBox.rect[1], imageBox.rect[2], imageBox.rect[3]);

    //Set the clipping:
    _driver.pushClipping(
        imageBox.rect[0], imageBox.rect[1], imageBox.rect[2], imageBox.rect[3]);

    //Get the renderer:
    final renderer = imageBox.renderer;

    //Draw the image box:
    if (renderer != null) {
      renderer.setSelectionColor4i(_selCol[0], _selCol[1], _selCol[2], 255);
      renderer.draw(_driver);

      /*if (this._inactive) {
                let rinfo:OsRenderInfo = OsRenderInfo(null);
                rinfo.projMat.buildOrthographicProjectionMatrixRH(0, imageBox.rect[2], 0, imageBox.rect[3], -1, 1);
                rinfo.worldMat.mat[12] = imageBox.rect[2]*0.5;
                rinfo.worldMat.mat[13] = imageBox.rect[3]*0.5;
                _driver.setColor4i(240, 190, 0, 50);
                _driver.fillSolidRect(rinfo, imageBox.rect[2], imageBox.rect[3]);
            }
            
            //Draw the selection rectangle:
            if (this._selectionRectangleIndex >= 0 && this._selectionRectangleIndex < _imageBoxes.length) {
                if (imageBox == _imageBoxes[this._selectionRectangleIndex]) {
                    let rinfo:OsRenderInfo = OsRenderInfo(null);
                    rinfo.projMat.buildOrthographicProjectionMatrixRH(0.0, imageBox.rect[2], 0.0, imageBox.rect[3], -1.0, 1.0);
                    rinfo.worldMat.mat[12] = this._selectionRectangleRect[0]+this._selectionRectangleRect[2]*0.5;
                    rinfo.worldMat.mat[13] = imageBox.rect[3] - (this._selectionRectangleRect[1]+this._selectionRectangleRect[3]*0.5) - 1.0;
                    _driver.setColor4i(255, 255, 255, 100);
                    _driver.fillSolidRect(rinfo, this._selectionRectangleRect[2], this._selectionRectangleRect[3]);
                }
            }
            
            //draw the page slider:
            this.setPageSliderInfo(index);
            let rinfo:OsRenderInfo = OsRenderInfo(null);
            rinfo.projMat.buildOrthographicProjectionMatrixRH(0.0, imageBox.rect[2], 0.0, imageBox.rect[3], -1.0, 1.0);

            let fontInfo:any = this._viewer?this._viewer.getCurrentFont(0):null;
            if (fontInfo) _driver.setColor3h(fontInfo.color);
            else _driver.setColor3h('#ffffff');
            if (this._pageSlider) this._pageSlider.draw(_driver, rinfo);*/
    } else {
      _driver.setClearColor4i(_backCol[0], _backCol[1], _backCol[2], 255);
      _driver.clearBuffers();
    }
    _driver.popClipping();
    //if (this._component) this._component.setCursor();
  }

  void prepareForDrawingImageBox(int index, OsWillDrawInfo info) {
    prepareForDrawingImageBox1(_imageBoxes[index], info);
  }

  void prepareForDrawingImageBox1(
      OsContainerImageBoxInfo imageBox, OsWillDrawInfo info) {
    OsRenderer? render = imageBox.renderer;
    if (render != null) {
      /*let annotSet:[OsDbAnnotationSet|null] = [null];
            let showAnnotSet:boolean = this.shouldDisplayDicomAnnotations(annotSet);
            render.setShouldDisplayDicomAnnotations(showAnnotSet, annotSet[0]);
            render.setShouldDisplayRuler(this._shouldDisplayRuler);
            render.setShouldDisplayGraphicAnnotations(this._shouldDisplayGraphics);
            render.setShouldAutoHideAnnotations(this._shouldAutoHideAnnotations);
            render.setShouldDisplayDicomOverlays(this._shouldDisplayOverlays);*/

      info.render = render;
      //render.setFilterType(this._filterType);
      //let wasPreloaded:boolean = render.isPreloaded();

      /*if (this._viewer) {
                let fontInfo:any = this._viewer.getCurrentFont(0);
                if (fontInfo) render.setFont(0, fontInfo.name, fontInfo.size, fontInfo.color);
                fontInfo = this._viewer.getCurrentFont(1);
                if (fontInfo) render.setFont(1, fontInfo.name, fontInfo.size, fontInfo.color);
            }*/

      //if (this._drawLocalizer) render.setShouldDrawLocalizer(true, this._wLocalizerStudy?<OsOpenedStudy>this._wLocalizerStudy.lock(false):null, this._wLocalizerSeries?<OsOpenedSeries>this._wLocalizerSeries.lock(false):null, this._localizerMat, this._localizerSize);
      //else render.setShouldDrawLocalizer(false, null, null, null, null);

      //render->set_draw_target(_draw_target, _draw_factor);
      render.willDraw(info);
      //if (!wasPreloaded && render.isPreloaded() && this._controller)
      //  this._controller.onPreloadedRenderer(render);
    }
  }

  /*public drawRectangleSelection(box:number, rect:[number, number, number, number]|null) {
        this._selectionRectangleIndex = box;
        if (rect) 
            for (let i:number=0; i<4; i++) this._selectionRectangleRect[i] = rect[i];
    }
        
    //-----------------------------------------------------------------------
    //fonts
    //-----------------------------------------------------------------------
       
    public setFont(target:number, name:string, size:number, color:string) {
        //_dicom_font_size = size;
        //_dicom_font_name = name;
        if (this._context && this._driver) {
            this._driver.setCurrentContext(this._context);
            this._context.resetTexts();
            let list:OsDriverCharacterList|null = this._context.findCharacterList('DICOM');
            if (list) {

                
            }
        }

        if (target == 0) { 
            
            
        }
        else 
        if (target == 1) { 
            
        }
    }*/

  int findStartingPosition(List<OsRenderer> list, int startIndex) {
    int index = 0;
    for (int i = 0; i < list.length; i++) {
      if (list[i].hidden) continue;
      if (index == startIndex) return i;
      index++;
    }
    return -1;
  }

  //-----------------------------------------------------------------------
  //selection
  //-----------------------------------------------------------------------

  /*public selectAll(message:boolean, redraw:boolean, renderers:OsRenderer[]|null, boxes:number[]|null):number {
        return this._doSelection(1, message, redraw, renderers, boxes, null);
    }

    public unselectAll(message:boolean, redraw:boolean, except:OsRenderer|null, renderers:OsRenderer[]|null, boxes:number[]|null):number {
        return this._doSelection(0, message, redraw, renderers, boxes, except);
    }

    public select1(list:OsRenderer[], value:boolean, message:boolean, redraw:boolean, boxes:number[]|null):number {
        let modification:number = 0;
        let listRedraw:number[] = [];
        for (let i=0; i<list.length; i++) {
            if (value && list[i].isHidden()) continue;
            if (list[i].isSelected() != value) {
                if (modification == 0) modification = 1;
                if (!value) {
                    if (list[i].unselectAllAnnotations()) 
                        modification = 2;
                }
                else {
                    //necessary if one annotation was copied by instance and has been modified in another render.
                    list[i].regenerateAnnotationSegments();
                }
                list[i].select(value);
                if (redraw || boxes != null) {
                    let index = this.findImageBoxIndexFromRenderer(list[i]);
                    if (index != -1) {
                        if (boxes) boxes.push(index);
                        listRedraw.push(index);
                    }
                }
            }
        }
        
        //if the line below is not commented, it makes trouble with the toolbar (key button for example when we unselected the current selection)
        //if (value) {
            
            if (modification != 0 && message && this._viewer && this._viewer.messageService) {
                if (modification == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
            }
        //}
        if (redraw) this.redrawImageBoxes(listRedraw);
        return modification;

    }

    public select2(render:OsRenderer, value:boolean, makeAnchor:boolean, message:boolean, redraw:boolean, box:[number]|null):number {
        if (box) box[0] = -1;
        let modification:number = 0;
        let boxes:number[] = [];
        let list:OsRenderer[] = [];
        list.push(render);
        if (box) {
            modification = this.select1(list, value, message, redraw, boxes);
            if (boxes.length) box[0] = boxes[0];
        }
        else modification = this.select1(list, value, message, redraw, null);
        if (makeAnchor) {
            if (!render.isHidden())
                this.setAnchor(render);
        }
        return modification;
    }

    public inverseSelection(message:boolean, redraw:boolean, renderers:OsRenderer[]|null, boxes:number[]|null):number {
        return this._doSelection(2, message, redraw, renderers, boxes, null);
    }

    public setAnchor(render:OsRenderer|null):void {
        if (this._wanchor) this._wanchor.destroy();
        this._wanchor = render ? render.getWeakObject() : null;
    }

    public getAnchor():OsRenderer|null {
        return this._wanchor ? <OsRenderer>this._wanchor.lock(false) : null;;
    }*/

  bool haveSelected() {
    List<OsRenderer> list = _controller.rendererElements;
    for (final renderer in list) {
      if (!renderer.hidden) {
        if (renderer.selected) return true;
      }
    }
    return false;
  }

  void getSelected(List<OsRenderer> list) {
    List<OsRenderer> elements = _controller.rendererElements;
    for (final renderer in elements) {
      if (!renderer.hidden) {
        if (renderer.selected) list.add(renderer);
      }
    }
  }

  /*public processSelection(render:OsRenderer, shiftKey:boolean, ctrlKey:boolean):boolean {
        if (render == null) return false;
        if (ctrlKey && !shiftKey) {
            let isSelected:boolean = render.isSelected();
            this.select2(render, !isSelected, true, true, true, null);
        }
        else
        if (shiftKey) {
            let anchorValid:boolean = false;
            let modification:number = 0;
            let anchor:OsRenderer|null = this._wanchor?<OsRenderer>this._wanchor.lock(false):null;
            //invalidate the anchor is it is hidden:
            if (anchor != null) {
                if (anchor.isHidden()) {
                    this.setAnchor(null);
                    anchor = null;
                }
            }
            if (anchor != null) {
                //make sure the anchor is still valid:
                let list:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
                if (list) {
                    let posAnchor = list.indexOf(anchor);
                    if (posAnchor == -1) {
                        this.setAnchor(null);
                    }
                    else {
                        //List of renderers that will need to be selected:
                        let toSelectList:OsRenderer[] = [];
                        //List of image boxes that need to be redraw:
                        let toRedrawList:number[] = [];
                        //List of renderers that change their status (selected to unselected or unselected to selected):
                        let modifiedList:OsRenderer[] = [];
                        //Search forward:
                        let found:boolean = false;
                        for (let i=posAnchor; i<list.length; i++) {
                            if (list[i].isHidden()) continue;
                            toSelectList.push(list[i]);
                            if (list[i] === render) {
                                found = true;
                                break;
                            }
                        }
                        //Search backward if necessary:
                        if (!found) {
                            toSelectList.splice(0, toSelectList.length);
                            for (let i=posAnchor; i>=0; i--) {
                                if (list[i].isHidden()) continue;
                                toSelectList.push(list[i]);
                                if (list[i] === render) {
                                    found = true;
                                    break;
                                }
                            }
                        }
                        if (found) {
                            anchorValid = true;
                            //Process the selection:
                            for (let i=0; i<list.length; i++) {
                                if (list[i].isHidden()) continue;
                                if (toSelectList.indexOf(list[i]) >= 0) {
                                    //Should be selected:
                                    if (!list[i].isSelected()) {
                                        modification = 1;
                                        list[i].select(true);
                                        modifiedList.push(list[i]);
                                    }
                                }
                                else {
                                    //should be unselected!
                                    if (list[i].isSelected()) {
                                        modification = 1;
                                        list[i].select(false);
                                        modifiedList.push(list[i]);
                                    }
                                }
                            }
                        }
                        if (modifiedList.length) {
                            //Get the list of image boxes that need to be redraw:
                            let count:number = this._rowCnt*this._colCnt;
                            for (let i=0; i<count; i++) {
                                let render1:OsRenderer|null = this.getImageBoxRenderer(i);
                                if (render1 != null) {
                                    if (modifiedList.indexOf(render1) >= 0)
                                        toRedrawList.push(i);
                                }
                            }
                        }
                        if (toRedrawList.length) {
                             this.redrawSingleWindow();
                            
                        }
                    }
                }
            }
            if (!anchorValid) {
                this.processSelection(render, false, false);
            }
            else 
            if (modification != 0 && this._viewer && this._viewer.messageService) {
                if (modification == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
            }
        }
        else {
               
            let toRedrawList:number[] = [];
            let redrawIndex:[number] = [-1];
            let modification:number = 0;
                
            if (!render.isSelected()) {
                modification = this.unselectAll(false, false, null, null, toRedrawList);
                let ret:number = this.select2(render, true, true, false, false, redrawIndex);
                if (modification == 0) modification = ret;
                else if (modification != 2) modification = ret;
            }
            else {
                //the renderer is already selected,
                //we need to unselect all the other renderers:
                modification = this.unselectAll(false, false, render, null, toRedrawList);
                this.setAnchor(render);
            }
                
            if (toRedrawList.indexOf(redrawIndex[0]) >= 0) redrawIndex[0] = -1;
            if (redrawIndex[0] != -1) toRedrawList.push(redrawIndex[0]);
            this.redrawImageBoxes(toRedrawList);
            if (modification != 0 && this._viewer && this._viewer.messageService) {
                if (modification == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
            }
        }
        return true;
    }

    

    private _doSelection(mode:number, message:boolean, redraw:boolean, renders:OsRenderer[]|null, boxes:number[]|null, except:OsRenderer|null):number {
        //mode = 0 -> unselect
        //mode = 1 -> select
        //mode = 2 -> inverse selection
        //return 0 if the selection didn't change
        //return 1 if selection has changed
        //return 2 if selection has changed and annotation selection has changed as well
        let modification:number = 0;
        let localListModified:OsRenderer[] = [];
        let localListRedraw:number[] = [];
        let listModified:OsRenderer[] = renders ? renders : localListModified;
        let listRedraw:number[] = boxes ? boxes : localListRedraw;
        let list:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
        if (list) {
            for (let i=0; i<list.length; i++) {
                if (list[i].isHidden()) continue;
                if (mode == 0) {
                    if (list[i] !== except) {
                        if (list[i].isSelected()) {
                            if (modification == 0) modification = 1;
                            if (list[i].unselectAllAnnotations()) modification = 2;
                            list[i].select(false);
                            listModified.push(list[i]);
                        }
                    }
                }
                else
                if (mode == 1) {
                    if (!list[i].isSelected()) {
                        if (modification == 0) modification = 1;
                        list[i].select(true);
                        listModified.push(list[i]);
                    }
                }
                else 
                if (mode == 2) {
                    if (modification == 0) modification = 1;
                    if (list[i].isSelected()) {
                        if (list[i].unselectAllAnnotations()) modification = 2;
                        list[i].select(false);
                    }
                    else list[i].select(true);
                    listModified.push(list[i]);
                }
            }
        }
        
        //Get the list of image boxes that need to be redraw:
        let count:number = this._rowCnt*this._colCnt;
        for (let i=0; i<count; i++) {
            let render:OsRenderer|null = this.getImageBoxRenderer(i);
            if (render) 
                if (listModified.indexOf(render) >= 0)
                    listRedraw.push(i);
        }
        if (redraw) this.redrawImageBoxes(listRedraw);
        if (message && modification != 0 && this._viewer && this._viewer.messageService) {
            if (modification == 2) this._viewer.messageService.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
            this._viewer.messageService.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
        }
        return modification;
    
    }

   

        //selection:
        
        
        //-----------------------------------------------------------------------
        //visibility
        //-----------------------------------------------------------------------

        public hide(list:OsRenderer[], value:boolean, message:boolean, redraw:boolean):number {
            let modification:number = 0;
            if (value) {
                //we may have to unselect some item first!
                let listToUnselect:OsRenderer[] = [];
                for (let it:number=0; it<list.length; it++) {
                    if (list[it].isSelected()) listToUnselect.push(list[it]);
                }
                if (listToUnselect.length) modification = this.select1(listToUnselect, false, message, false, null);
                //Reset the anchor if necessary:
                let anchor:OsRenderer|null = this._wanchor?<OsRenderer>this._wanchor.lock(false):null;
                if (anchor) {
                    if (anchor.isHidden() || list.indexOf(anchor) >= 0) 
                        this.setAnchor(null);
                }
            }
            for (let it:number=0; it<list.length; it++) {
                if (list[it].isHidden() != value) {
                    list[it].hide(value);
                    if (value) list[it].releaseMemory(0);
                }
            }
            if (message) {
                if (modification != 0 && this._viewer) {
                    if (modification == 2) this._viewer.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                    this._viewer.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
                }
            }
            if (redraw) this.setCurrentPage(this._currentPage, OsContDraw.OS_DRAW);
            return modification;
        }

       

        public haveHidden():boolean {
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements) {
                for (let it:number=0; it<elements.length; it++) {
                    if (elements[it].isHidden()) return true;
                }
            }
            return false;
        }

        
        

        public hideSelected(message:boolean, redraw:boolean):number {
            let listToHide:OsRenderer[] = [];
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements) {
                for (let it:number=0; it<elements.length; it++) {
                    if (!elements[it].isHidden() && elements[it].isSelected()) 
                    listToHide.push(elements[it]);
                }
            }
            if (listToHide.length) return this.hide(listToHide, true, message, redraw);
            else return 0;
        }

        public showOnlySelected(message:boolean, redraw:boolean) {
            let listToHide:OsRenderer[] = [];
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements) {
                for (let it:number=0; it<elements.length; it++) {
                    if (!elements[it].isHidden() && !elements[it].isSelected()) 
                    listToHide.push(elements[it]);
                }
            }
            if (listToHide.length) this.hide(listToHide, true, message, redraw);
        }

        public showHidden(message:boolean, redraw:boolean) {
            let listToShow:OsRenderer[] = [];
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements) {
                for (let it:number=0; it<elements.length; it++) {
                    if (elements[it].isHidden()) 
                        listToShow.push(elements[it]);
                }
            }
            if (listToShow.length) this.hide(listToShow, false, message, redraw);
        }

        public showOnlyKeyImages(message:boolean, redraw:boolean):number {
            let listToHide:OsRenderer[] = [];
            let listToShow:OsRenderer[] = [];
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements) {
                for (let it:number=0; it<elements.length; it++) {
                    if (elements[it].isKey()) {
                        if (elements[it].isHidden()) listToShow.push(elements[it]);
                    }
                    else {
                        if (!elements[it].isHidden()) {
                            listToHide.push(elements[it]);
                        }
                    }
                }
            }
            let modification1:number = 0;
            let modification2:number = 0;
            if (listToHide.length) modification1 = this.hide(listToHide, true, false, false);
            if (listToShow.length) modification2 = this.hide(listToShow, false, false, false);
            if (message && this._viewer) {
                if (modification1 != 0 || modification2 != 0) {
                    if (modification1 == 2 || modification2 == 2) this._viewer.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                    this._viewer.sendMessage(MSG.IMGCONT_SELECTION_CHANGED, this);
                }
            }
            if (redraw) this.setCurrentPage(this._currentPage, OsContDraw.OS_FORCE_REDRAW);
            if (modification1 == 2 || modification2 == 2) return 2;
            if (modification1 == 1 || modification2 == 1) return 1;
            return 0;
        }*/

  bool haveVisible() {
    List<OsRenderer> elements = _controller.rendererElements;
    for (final renderer in elements) {
      if (!renderer.hidden) return true;
    }
    return false;
  }

  /*public getVisible(list:OsRenderer[]){
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if(elements != null){
                for (let i=0; i<elements.length; i++){
                
                    if(!elements[i].isHidden()) list.push(elements[i]);

                }
            }
        }
        

        public haveKeyImages():boolean {
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements != null) {
                for (let i=0; i<elements.length; i++) 
                    if (elements[i].isKey()) return true;
            }
            return false;
        }

        public getKeyImages(list:OsRenderer[]){
            let elements:OsRenderer[]|null = this._controller?this._controller.getRendererElements():null;
            if (elements != null) {
                for (let i=0; i<elements.length; i++) 
                    if (elements[i].isKey()) list.push(elements[i]);
            }
            return false;
        }
        
        
    //-----------------------------------------------------------------------
    //filter
    //-----------------------------------------------------------------------
    public setFilterType(type:number, redraw:boolean, sendModifiedMessage:boolean) {
        //b32 do_callback = (_filter_type == type) ? OSFALSE : OSTRUE;
        this._filterType = type;
        if (redraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        
        if (sendModifiedMessage && this._viewer) this._viewer.sendMessage(MSG.IMGCONT_MODIFIED, this);
    }

    public getFilterType():number {
        return this._filterType;
    }*/

  //-----------------------------------------------------------------------
  //inactive
  //-----------------------------------------------------------------------

  void setInactive(
      {required bool inactive, required bool sendModifiedMessage}) {
    _inactive = inactive;
    if (sendModifiedMessage) {
      OVApi().messages.sendMessage(OSMSG.imageContainerModified, this);
    }
  }

  bool isInactive() {
    return _inactive;
  }

  //-----------------------------------------------------------------------
  //default renderer
  //-----------------------------------------------------------------------

  OsRenderer? getDefaultRenderer() {
    /*let winner:OsRenderer|null = null;
        //if we have a renderer with selected annotations, we choose this one in priority:
        let controller:OsContainerController|null = this.getController();
        if (controller != null) {
            let elements:OsRenderer[] = controller.getRendererElements();
            if (elements) {
                for (let i=0; i<elements.length; i++) {
                    if (elements[i].haveAnnotations(1)) {
                        winner = elements[i];
                        break;
                    }
                }
            }
        }
        if (winner == null) {
            let render:OsRenderer|null = this.getAnchor();
            if (render != null) {
                if (render.isSelected() && !render.isHidden())
                    winner = render;
            }
        }
        if (winner == null) {
            let rowcol:[number, number] = [0, 0];
            this.getImageMatrix(rowcol);
            let count:number = rowcol[0]*rowcol[1];
            let unselectedRender:OsRenderer|null = null;
            for (let i=0; i<count; i++) {
                let render:OsRenderer|null = this.getImageBoxRenderer(i);
                if (render == null) continue;
                if (render.isSelected()) {
                    winner = render;
                    break;
                }
                else 
                if (unselectedRender == null) 
                    unselectedRender = render;
            }
            if (winner == null) winner = unselectedRender;
        }
        return winner;*/
    return null;
  }

  /*public getActionRenderers(list:OsRenderer[], forPropagation:boolean, type:string):boolean {
        if (forPropagation) {
            let propagate:IContainerPropagateItem|null = this.getPropagationItem();
            if (propagate != null) return propagate.getActionRenderers(this, type, list);
            else { 
                this.getSelected(list);
                return false; 
            }
        }
        else {
            this.getSelected(list);
            return false;
        }
    }

    public getActionRenderersForPropagation(list:OsRenderer[], type:string):void {
        this.getSelected(list);
        if (list.length == 0) {
            let propagation:IContainerPropagateItem|null = this.getPropagationItem();
            if (propagation != null) {
                let list1:Array<IPropagateProperty|null> = [];
                list1.push(propagation.findProperty(type));
                //we need one of the properties to exist and can propagate in the container.
                for (let i=0; i<list1.length; i++) {
                    let tmp:IPropagateProperty|null = list1[i];
                    if (tmp != null) 
                        if (tmp.getMode() & OsPropagateFlags.propagate_current_view ||
                            tmp.getMode() & OsPropagateFlags.propagate_all_views ||
                            tmp.getMode() & OsPropagateFlags.propagate_sync_views) {
                            let renderer:OsRenderer|null = this.getDefaultRenderer();
                            if (renderer != null) list.push(renderer);
                            break;
                        }
                }
            }
        }
    }

    public haveActionRenderers(forPropagation:boolean, type:string):boolean {
        if (forPropagation) {
            let propagation:IContainerPropagateItem|null = this.getPropagationItem();
            if (propagation != null) return propagation.haveActionRenderers(this, type);
            else return this.haveSelected();
        }
        else return this.haveSelected();
    }
    
 

    //-----------------------------------------------------------------------
    //support set
    //-----------------------------------------------------------------------

    public setSupportSet(set:OsContainerSupportSet|null) {
        if (this._wsupportSet) this._wsupportSet.destroy();
        this._wsupportSet = set ? set.getWeakObject() : null;
    }

    public getSupportSet(retain:boolean):OsContainerSupportSet|null {
        if (this._wsupportSet) return <OsContainerSupportSet>this._wsupportSet.lock(retain);
        else return null;
    }*/

  //-----------------------------------------------------------------------
  //tools
  //-----------------------------------------------------------------------

  void setCurrentTool(
      OsContainerTool? tool, Object? data, bool sendModifiedMessage) {
    final currentTool = getCurrentTool();
    bool doCallback = !identical(currentTool.tool, tool);
    _wtool = tool != null ? WeakReference(tool) : null;
    _wtoolData = data != null ? WeakReference(data) : null;
    if (doCallback) {
      OVApi().messages.sendMessage(OSMSG.imageContainerToolSet, this);
    }
    if (sendModifiedMessage) {
      OVApi().messages.sendMessage(OSMSG.imageContainerModified, this);
    }
  }

  ({OsContainerTool? tool, Object? data}) getCurrentTool() {
    final tool = _wtool?.target;
    final data = _wtoolData?.target;
    return (tool: tool, data: data);
  }

  void setRunningTool(OsContainerTool? tool, Object? data) {
    _wrunningTool = tool != null ? WeakReference(tool) : null;
    _wrunningToolData = data != null ? WeakReference(data) : null;
  }

  ({OsContainerTool? tool, Object? data}) getRunningTool() {
    final tool = _wrunningTool?.target;
    final data = _wrunningToolData?.target;
    return (tool: tool, data: data);
  }

  //-----------------------------------------------------------------------
  //responder
  //-----------------------------------------------------------------------

  /*public setRunningItem(item:OsGraphicResponder|null) {
        if (this._wrunningItem) this._wrunningItem.destroy();
        this._wrunningItem = item ? item.getWeakObject() : null;
    }

    public getRunningItem():OsGraphicResponder|null {
        return this._wrunningItem ? <OsGraphicResponder>this._wrunningItem.lock(false) : null;
    }
        
    //-----------------------------------------------------------------------
    //annotation actions
    //-----------------------------------------------------------------------
    public setCurrentAnnotationAction(action:OsAnnotationAction|null) {
        this._annotationAction = action;
    }

    public getCurrentAnnotationAction():OsAnnotationAction|null {
        return this._annotationAction;
    }

    public findCandidateAnnotationActionByShortcut(key:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):OsAnnotationAction|null {
        if (!this.isPlaying(null)) {
            let supportSet:OsContainerSupportSet|null = this._wsupportSet?<OsContainerSupportSet>this._wsupportSet.lock(false):null;
            let list:OsAnnotationAction[]|null = supportSet?supportSet.getListOfAnnotationActions():null;
            if (list) {
                for (let i:number=0; i<list.length; i++) {
                    let sh:OsShortcut|null = list[i].getShortcut();
                    if (sh && sh.hit(true, key, shiftKey, controlKey, altKey)) return list[i];
                }
            }
        }
        return null;
        

    }*/

  //-----------------------------------------------------------------------
  //capture mouse
  //-----------------------------------------------------------------------

  void captureMouse(int box, double x, double y, bool shiftKey, bool controlKey,
      int mouseEvent) {
    /*this._isCaptured = true;
        this._capturedIndex = box;
        if (mouseEvent == 0) this.onLeftButtonDown(box, x, y, shiftKey, controlKey, false);
        else if (mouseEvent == 3) this.onLeftButtonDoubleClick(box, x, y, shiftKey, controlKey, false);*/
  }

  void releaseMouse(int box) {
    /*this.setRunningTool(null, null);
        this.setRunningItem(null);

        if (this._isCaptured) {
            
            let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
            if (action != null) {
                if (action.isRunning()) {
                    action.stop(this, this._capturedIndex, true);
                }
            }

          
            this._isCaptured = false;
        }*/
  }

  bool isMouseCaptured(List<int>? box) {
    /*if (this._isCaptured) {
            if (box) box[0] = this._capturedIndex;
            return true;
        }*/
    return false;
  }

  //-----------------------------------------------------------------------
  //driver
  //-----------------------------------------------------------------------
  /*public getDriver():OsDriver|null {
        return this._driver;
    }

    
    
    //-----------------------------------------------------------------------
    //calibration
    //-----------------------------------------------------------------------
    
    public canCalibrate():boolean {
        if (this._controller) {
            if (this._controller.canCalibrate()) {
                if (this._controller.isStillDownloading()) return false;
                if (this.getDefaultRenderer()) return true;
            }
        }
        return false;
    }


    //-----------------------------------------------------------------------
    //manual window level
    //-----------------------------------------------------------------------
   
    //-----------------------------------------------------------------------
    //cine
    //-----------------------------------------------------------------------
   
    public isPlaySupported():boolean {
        return this._cineSupport;
    }

    public isAutoPlaySupported():boolean {
        return this._autoPlaySupport;
    }

    public setPlaySupport(enable:boolean):void {
        this._cineSupport = enable;
        if (!enable && this._isPlaying)
            this.stopPlaying(true);
    }

    public setAutoPlaySupport(enable:boolean):void {
        this._autoPlaySupport = enable;
    }

    public canPlay():boolean {
        if (!this.isPlaySupported()) return false;
        if (this.getPageCount() > 1) return true;
        return false;
    }

    public isPlaying(synchro:[boolean]|null):boolean {
        let container:OsContainerWnd|null = this.getPlayingContainer();
        if (container == null) return false;
        if (synchro) synchro[0] = (container === this) ? false : true;
        return true;
    }

    public startPlaying(sendModifiedMessage:boolean):boolean {
        if (!this.canPlay()) return false;
        let container:OsContainerWnd|null = this.getPlayingContainer();
        if (container != null) return true;
        this._isPlaying = true;
        if (this._cineTimerId == null) {
            this._cineTimerId = setInterval(() => {
                this._onReceiveTimerEvent(this._cineTimerId);
            }, 1000/this.getPlaySpeed());
        }
        if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
        return true;
    }*/

  void stopPlaying(bool sendModifiedMessage) {
    /*if (this._isPlaying) {
            if (this._cineTimerId) clearInterval(this._cineTimerId);
            this._cineTimerId = null;
            this._isPlaying = false;
            if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
        }
        else {
            let container:OsContainerWnd|null = this.getPlayingContainer();
            if (container != null) container.stopPlaying(sendModifiedMessage);
        }*/
  }

  /*public setPlaySpeed(speed:number, sendModifiedMessage:boolean):boolean {
        let container:OsContainerWnd|null = this.getPlayingContainer();
        if (container == null || container === this) {
            let oldSpeed:number = this.getPlaySpeed();
            if (speed <= 0 || speed > 60) return false;
             this._cineSpeed = speed;
            if (container != null && oldSpeed != this._cineSpeed) {
                if (this._cineTimerId) clearInterval(this._cineTimerId);
                this._cineTimerId = setInterval(() => {
                    this._onReceiveTimerEvent(this._cineTimerId);
                }, 1000/this._cineSpeed);
            }
            if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
            return true;
        }
        else return container.setPlaySpeed(speed, sendModifiedMessage);
    }

    public getPlaySpeed():number {
        let container:OsContainerWnd|null = this.getPlayingContainer();
        if (container == null || container === this) {
           
            return this._cineSpeed;
            
        }
        else return container.getPlaySpeed();
    }

    public setPlayMode(mode:number, sendModifiedMessage:boolean):boolean {
        let container:OsContainerWnd|null = this.getPlayingContainer();
        if (container == null || container === this) {
            if (mode < 0 || mode > 2) return false;
             this._cineMode = mode;
            if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
            return true;
        }
        else return container.setPlayMode(mode, sendModifiedMessage);
    }

    public getPlayMode():number {
        let container:OsContainerWnd|null = this.getPlayingContainer();
        if (container == null || container === this) {
            
            return this._cineMode;
        }
        else return container.getPlayMode();
    }

    

    public getPlayingContainer():OsContainerWnd|null {
        if (this._isPlaying) return this;
        else {
            let synchro:IContainerSynchroItem|null = this.getSynchroItem();
            if (synchro != null) {
                if (synchro.shouldSynchronize(this)) {
                    let list:OsContainerWnd[] = [];
                    synchro.getListOfSynchronizedContainers(list);
                    for (let i=0; i<list.length; i++) 
                        if (list[i]._isPlaying) 
                            return list[i];
                }
            }
            return null;
        }
    }
        
    //-----------------------------------------------------------------------
    //Annotations
    //-----------------------------------------------------------------------

    public shouldAutoHideAnnotations():boolean {
        return this._shouldAutoHideAnnotations;
    }

    public shouldDisplayDicomAnnotations(set:[OsDbAnnotationSet|null]|null):boolean {
        if (set) {
            let currentSet:OsDbAnnotationSet|null = this._wannotationSet ? <OsDbAnnotationSet>this._wannotationSet.lock(false) : null;
            if (!currentSet) {
                let siteSet:[OsDbPreferenceSet|null] = [null];
                let userSet:OsDbPreferenceSet|null = this._viewer?this._viewer.getActivePreferenceSet(siteSet):null;
                for (let i:number=0; i<2; i++) {
                    let set:OsDbPreferenceSet|null = i == 0 ? userSet : siteSet[0];
                    if (set && 'AS' in set.items) {
                        let list:OsDbPreferenceItem[] = set.items['AS'];
                        if (list.length) {
                            let annotSet:OsDbAnnotationSet = <OsDbAnnotationSet>list[0];
                            if (annotSet) {
                                if (this._wannotationSet) this._wannotationSet.destroy();
                                this._wannotationSet = annotSet ? annotSet.getWeakObject() : null;
                                this._haveAnnotationSet = true;
                            }
                            break;
                        }
                    }
                }
            }
            set[0] = this._wannotationSet ? <OsDbAnnotationSet>this._wannotationSet.lock(false) : null;
        }
        return this._shouldDisplayDicom;
    }

    public shouldDisplayGraphicAnnotations():boolean {
        return this._shouldDisplayGraphics;
    }

    public shouldDisplayRuler():boolean {
        return this._shouldDisplayRuler;
    }

    public shouldDisplayDicomOverlays():boolean {
        return this._shouldDisplayOverlays;
    }

    public setShouldAutoHideAnnotations(value:boolean):void {
        this._shouldAutoHideAnnotations = value;
    }

    public setShouldDisplayDicomAnnotations(display:boolean, set:OsDbAnnotationSet|null, redraw:boolean, sendModifiedMessage:boolean):void {
        this._shouldDisplayDicom = display;
        let modified:boolean = false;
        if (this._haveAnnotationSet) {
            let current:OsStrongObject|null = this._wannotationSet?this._wannotationSet.lock(false):null;
            if (current !== set) {
                modified = true;
            }
        }
        else if (set) modified = true;
        if (modified) {
            this._haveAnnotationSet = false;
            if (this._wannotationSet) this._wannotationSet.destroy();
            if (set) {
                this._wannotationSet = set.getWeakObject();
                this._haveAnnotationSet= true; 
            }
            else this._wannotationSet = null;
            if (this._singleWindow) {
                this._driver.setCurrentContext(this._context);
                this._context.resetTexts();
            }
            else {
                
                let count:number = this._rowCnt * this._colCnt;
                for (let i:number=0; i<count; i++) {
                 
                    let box:OsContainerImageBoxInfo = this._imageBoxes[i];
                    let boxContext:OsDriverContext = box.getWindowContext();
                    if (boxContext) {
                        //box->get_driver()->set_current_context(box->get_window_context());
                        boxContext.resetTexts();
                    }
                    
                }
                
            }
            
        }
        if (redraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
    }

    public setShouldDisplayGraphicAnnotations(display:boolean, redraw:boolean, sendModifiedMessage:boolean):void {
        this._shouldDisplayGraphics = display;
        if (redraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
    }

    public setShouldDisplayRuler(display:boolean, redraw:boolean, sendModifiedMessage:boolean):void {
        this._shouldDisplayRuler = display;
        if (redraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
    }

    public setShouldDisplayDicomOverlays(display:boolean, redraw:boolean, sendModifiedMessage:boolean):void {
        this._shouldDisplayOverlays = display;
        if (redraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
    }


    
    //-----------------------------------------------------------------------
    //refresh timer
    //-----------------------------------------------------------------------

    public startLoadingRefreshTimer() {
        if (this._refreshTimerId == null) {
            this._refreshTimerId = setInterval(() => {
                this._onReceiveTimerEvent(this._refreshTimerId);
            }, 500);
        }
    }

    private _onReceiveTimerEvent(timerId:any) {

        
        if (timerId == this._cineTimerId) {
            let cineMode:number = this.getPlayMode();
            if (cineMode == 0) {
                let newPage:number = this._currentPage + 1;
                if (newPage >= this.getPageCount()) newPage = 0;
                
                    this.setCurrentPage(newPage, OsContDraw.OS_FORCE_REDRAW);
                    this.processSynchro();
                
            }
            else 
            if (cineMode == 1) {
                let newPage = this._currentPage - 1;
                if (newPage < 0) newPage = this.getPageCount()-1;
                
                    this.setCurrentPage(newPage, OsContDraw.OS_FORCE_REDRAW);
                    this.processSynchro();
                
            }
            else {
                let newPage:number = 0;
                if (this._cineSwingDirection == 0) {
                    newPage = this._currentPage + 1;
                    if (newPage >= this.getPageCount()) {
                        this._cineSwingDirection = 1;
                        newPage = this.getPageCount()-2;
                        if (newPage < 0) newPage = 0;
                    }
                }
                else {
                    newPage = this._currentPage - 1;
                    if (newPage < 0) {
                        this._cineSwingDirection = 0;
                        newPage = 1;
                        if (newPage >= this.getPageCount()) newPage = 0;
                    }
                }
                
                    this.setCurrentPage(newPage, OsContDraw.OS_FORCE_REDRAW);
                    this.processSynchro();
                
            }
        }
        else
        if (timerId == this._redrawAsapTimerId) {
            this._redrawAsapTimerId = null;
             this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
            
        }
        else
        if (timerId == this._refreshTimerId) {
            if (this._controller) {
                let stillDownloading:boolean = this._controller.isStillDownloading();
                let progression:number = this._controller.getLoadingProgression();
                //console.log("progression: " + progression);
                let timerKilled = false;
                if (!stillDownloading) {
                    if (progression == 1.0 || progression == -1.0) {
                        clearInterval(this._refreshTimerId);
                        this._refreshTimerId = null;
                        timerKilled = true;
                    }
                }
                let canDraw:boolean = false;
                if (!this._isPlaying) {
                    let tool:OsContainerTool|null = this.getRunningTool(null, false);
                    if (!tool) {
                        let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
                        if (!action) canDraw = true;
                    }
                }
                if (canDraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                if (timerKilled) {
                    if (canDraw) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                }
                this._controller.preloadRenderers();
            }
        }
    }


    //dynamic fonts:
    //void create_dynamics_fonts(driver_context_ptr &ctx);*/

  //-----------------------------------------------------------------------
  //mouse events
  //-----------------------------------------------------------------------

  /*public onLeftButtonDown(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {
        if (this.isPlaying(null)) return;
        let shouldCheckSlider:boolean = true;
        if (shiftKey || controlKey) shouldCheckSlider = false;

        //some annotations are relying on the viewport size, so we set it here:
        if (box != -1) {
            let boxRect:[number, number, number, number] = [0, 0, 0, 0];
            this.getImageBoxRect(box, boxRect);
            if (this._driver) this._driver.setViewport(boxRect[0], boxRect[1], boxRect[2], boxRect[3]);
        }

        //check if we clicked on the page slider.
        //if yes, we should not proceed the selection!
        let done:boolean = false;
        if (box != -1) {
            //Process the selection only if the clicked renderer is not currently selected:
            if (!this.isMouseCaptured(null)) {
                if (!shouldCheckSlider || !this.isMouseCursorInsidePageSlider(box, x, y)) {
                    this._selectionDone = false;
                    let render:OsRenderer|null = this.getImageBoxRenderer(box);
                    if (render != null) {
                        if (!render.isSelected()) {
                            this.processSelection(render, shiftKey, controlKey);
                            this._selectionDone = true;
                        }
                        else {
                            //the renderer is already selected.
                            //we may unselected it later
                            this._selectionDone = false;
                            //unselect_all_annotations(OSTRUE, OSTRUE, render);
                        }
                    }
                }
                else this._selectionDone = true;
            }
        }

        //Do we have a running item?
        let item:OsGraphicResponder|null = this.getRunningItem();
        if (item != null) {
            item.onLeftButtonDown(this, box, x, y, shiftKey, controlKey);
            done = true;
        }

        if (box != -1) {
            //Do we have a running tool?
            let tool:OsContainerTool|null = this.getRunningTool(null, false);
            if (tool != null) {
                tool.onLeftButtonDown(this, box, x, y, shiftKey, controlKey);
                done = true;
            }
            //Do we have a running annotation action?
            let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
            if (action != null) {

                if (action.isRunning()) {

                    action.onLeftButtonDown(this, box, x, y, shiftKey, controlKey);
                    done = true;

                }

            }

           
        }

        //does the cursor is above a toolbar?
        if (!done) {
            let toolbar:OsGraphicToolbar|null = this.getToolbarUnderCursor(box, x, y);
            if (toolbar) {
                if (toolbar == this._toolbar && box != -1) {
                    let rect:[number, number, number, number] = [0, 0, 0, 0];
                    this.getImageBoxRect(box, rect);
                    box = -1;
                    x += rect[0];
                    y += rect[1];
                }
                if (toolbar.canStart(this, box, 0)) {
                    this.setRunningItem(toolbar);
                    toolbar.start(this, box, x, y, shiftKey, controlKey, 0);
                }
                done = true;
            }
        }

        if (box != -1) {

            //Should we start a tool by shortcut?
            if (!done) {
                let tool:OsContainerTool|null = this.findCandidateToolByShortcut(box, OSSC.LEFT, shiftKey, controlKey, altKey);
                if (tool) {
                    if (tool.canStart(this, box, false, x, y, 0)) {
                        this.setRunningTool(tool, this._wtoolData ? this._wtoolData.lock(false):null);
                        tool.start(this, box, x, y, shiftKey, controlKey, 0);
                        let tool1:OsContainerTool|null = this.getRunningTool(null, false);
                        if (tool1 == null) {
                            //the tool was running but has already been stopped!
                            if (tool.didRun())
                                this._selectionDone = true;
                        }
                        done = true;
                    }
                }
            }

            //Did we click on the page slider?
            if (!done && shouldCheckSlider) {
                if (this._pageSlider) {
                    this.setPageSliderInfo(box);
                    this._pageSlider.box = box;
                    let rinfo:OsRenderInfo = new OsRenderInfo(null);
                    let rect:[number, number, number, number] = this._imageBoxes[box].rect;
                    rinfo.projMat.buildOrthographicProjectionMatrixRH(0.0, rect[2], 0.0, rect[3], -1.0, 1.0);
                    let supportSet:OsContainerSupportSet|null = this._wsupportSet?<OsContainerSupportSet>this._wsupportSet.lock(false):null;
                    if (supportSet) {
                        let tool:OsContainerTool|null = supportSet.findContainerTool('IMGTOOL_SLIDER', false);
                        if (tool) {
                            if (tool.canStart(this, box, false, x, y, 0)) {
                                this.setRunningTool(tool, this._wtoolData ? this._wtoolData.lock(false):null);
                                if (tool.start(this, box, x, y, shiftKey, controlKey, 0)) {
                                    this._selectionDone = true;
                                    done = true;
                                }
                                else this.setRunningTool(null, null);
                            }
                        }
                    }
                }
            }

            //Should we run a tool?
            if (!done) {
                let tool:OsContainerTool|null = this.getCurrentTool(null, false);
                if (tool != null) {
                    if (tool.canStart(this, box, false, x, y, 0)) {
                        this.setRunningTool(tool, this._wtoolData ? this._wtoolData.lock(false):null);
                        tool.start(this, box, x, y, shiftKey, controlKey, 0);
                        let tool1:OsContainerTool|null = this.getRunningTool(null, false);
                        if (tool1 == null) {
                            //the tool was running but has already been stopped!
                            if (tool.didRun())
                                this._selectionDone = true;
                        }
                        done = true;
                    }
                }
            }
        }
    }

    public onLeftButtonUp(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {
        if (this.isPlaying(null)) return;

        //some annotations are relying on the viewport size, so we set it here:
        if (box != -1) {
            let boxRect:[number, number, number, number] = [0, 0, 0, 0];
            this.getImageBoxRect(box, boxRect);
            if (this._driver) this._driver.setViewport(boxRect[0], boxRect[1], boxRect[2], boxRect[3]);
        }

        //Do we have a running item?
        let item:OsGraphicResponder|null = this.getRunningItem();
        if (item) item.onLeftButtonUp(this, box, x, y, shiftKey, controlKey);
        if (box != -1) {
            //Do we have a running tool?
            let tool:OsContainerTool|null = this.getRunningTool(null, false);
            if (tool != null) {
                tool.onLeftButtonUp(this, box, x, y, shiftKey, controlKey);
                if (!this._selectionDone) {
                    if (tool.didRun()) this._selectionDone = true;
                }
            }

            //Do we have a running annotation action?
            

            //Process the selection if it was not processed yet:
            if (!this._selectionDone) {
                let render:OsRenderer|null = this.getImageBoxRenderer(box);
                if (render != null) {
                    if (render.isSelected()) {
                        this.processSelection(render, shiftKey, controlKey);
                        this._selectionDone = true;
                    }
                }
            }
        }
    }

    public onLeftButtonDoubleClick(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {
        if (this.isPlaying(null)) return;
        let done:boolean = false;
        //some annotations are relying on the viewport size, so we set it here:
        if (box != -1) {
            let boxRect:[number, number, number, number] = [0, 0, 1, 1];
            this.getImageBoxRect(box, boxRect);
            let driver:OsDriver|null = this.getDriver();
            if (driver) driver.setViewport(boxRect[0], boxRect[1], boxRect[2], boxRect[3]);
        }
        
        //Do we have a running item?
        let item:OsGraphicResponder|null = this.getRunningItem();
        if (item) {
            item.onLeftButtonDoubleClick(this, box, x, y, shiftKey, controlKey);
            done = true;
        }

        if (box != -1) {

            //Do we have a running tool?
            let tool:OsContainerTool|null = this.getRunningTool(null, false);
            if (tool) {

                tool.onLeftButtonDoubleClick(this, box, x, y, shiftKey, controlKey);
                done = true;

            }

            //Do we have a running annotation action?
            let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
            if (action) {

                if (action.isRunning()) {

                    //action.onLef->on_left_button_double_click(std::static_pointer_cast<ocontainer_wnd>(shared_from_this()), box, x, y, shift_key, control_key);
                    done = true;

                }

            }

            if (!done) {

                let tool:OsContainerTool|null = this.getCurrentTool(null, false);
                if (tool) {

                    if (tool.canStart(this, box, false, x, y, 3)) {

                        this.setRunningTool(tool, this._wtoolData?this._wtoolData.lock(false):null);
                        tool.start(this, box, x, y, shiftKey, controlKey, 3);
                        if (this.getRunningTool(null, false) != null) done = true;

                    }

                }

            }

        }

        

        if (!done) {
            if (this._canZoom) {

                this.zoomImageBox(!this._zoomed, box);

            }

        }
    
    }

    public onRightButtonDown(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {
        if (this.isPlaying(null)) return;
        
        //some annotations are relying on the viewport size, so we set it here:
        if (box != -1) {
            let boxRect:[number, number, number, number] = [0, 0, 0, 0];
            this.getImageBoxRect(box, boxRect);
            if (this._driver) this._driver.setViewport(boxRect[0], boxRect[1], boxRect[2], boxRect[3]);
        }

        //Process the selection only if the clicked renderer is not currently selected:
       

        let done:boolean = false;
        //Do we have a running item?
        let item:OsGraphicResponder|null = this.getRunningItem();
        if (item != null) {
            item.onRightButtonDown(this, box, x, y, shiftKey, controlKey);
            done = true;
        }

        if (box != -1) {
            //Do we have a running tool?
            let tool:OsContainerTool|null = this.getRunningTool(null, false);
            if (tool) {
                tool.onRightButtonDown(this, box, x, y, shiftKey, controlKey);
                done = true;
            }
            //Do we have a running annotation action?
            
            //Should we start a tool by shortcut?
            if (!done) {
                let tool:OsContainerTool|null = this.findCandidateToolByShortcut(box, OSSC.RIGHT, shiftKey, controlKey, altKey);
                if (tool) {
                    this.setRunningTool(tool, this._wtoolData ? this._wtoolData.lock(false):null);
                    tool.start(this, box, x, y, shiftKey, controlKey, 1);
                    done = true;
                }
            }
        }
    }

    public onRightButtonUp(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {

        if (this.isPlaying(null)) return;;

        //some annotations are relying on the viewport size, so we set it here:
        if (box != -1) {
            let boxRect:[number, number, number, number] = [0, 0, 0, 0];
            this.getImageBoxRect(box, boxRect);
            if (this._driver) this._driver.setViewport(boxRect[0], boxRect[1], boxRect[2], boxRect[3]);
        }

        let run:boolean = false;
        //Do we have a running item?
        

        if (box != -1) {
            //Do we have a running tool?
            let tool:OsContainerTool|null = this.getRunningTool(null, false);
            if (tool != null) {
                tool.onRightButtonUp(this, box, x, y, shiftKey, controlKey);
                if (!this._selectionDone) {
                    if (tool.didRun()) this._selectionDone = true;
                }
                if (tool.didRun()) run = true;
            }
            //Do we have a running annotation action?
           

            //Process the selection if it was not processed yet:
            if (!this._selectionDone) {
                let render:OsRenderer|null = this.getImageBoxRenderer(box);
                if (render != null) {
                    if (render.isSelected()) {
                        this.processSelection(render, shiftKey, controlKey);
                        this._selectionDone = true;
                    }
                }
            }
        }

        //show menu
        
    }

    public onMiddleButtonDown(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {
        
    }

    public onMiddleButtonUp(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):void {
        
    }

    public onMouseWheel(delta:number):void {
        let inverse:boolean = false;
       
        if (inverse) delta = -delta;
        
        if (delta > 0) this.nextPage();
        else this.previousPage();
        
    }
    
    public onMouseMove(box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, altKey:boolean) {

        this.onSetCursor(box, x, y, shiftKey, controlKey);

        if (this.isPlaying(null)) return;
        //some annotations are relying on the viewport size, so we set it here:
        if (box != -1) {
            let boxRect:[number, number, number, number] = [0, 0, 0, 0];
            this.getImageBoxRect(box, boxRect);
            if (this._driver) this._driver.setViewport(boxRect[0], boxRect[1], boxRect[2], boxRect[3]);
        }

        //Do we have a running item?
        let item:OsGraphicResponder|null = this.getRunningItem();
        if (item) item.onMouseMove(this, box, x, y, shiftKey, controlKey);

        if (box != -1) {
            //Do we have a running tool?
            let tool:OsContainerTool|null = this.getRunningTool(null, false);
            if (tool != null) {
                tool.onMouseMove(this, box, x, y, shiftKey, controlKey);
            }
            
            
        }

        //Redraw the window:
        if (this._redrawAsapTimerId == null) 
            this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);

    }*/

  void abortTool() {
    /*ContainerTool? tool = runningTool;
    if (tool != null) {
      tool.abort(this);
      runningTool = null;
    }*/
  }

  bool onDragStart(RawPointerInfo pointer) {
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    /*if (runningTool == null) {
      ContainerTool? tool; // = supportSet?.findToolByShortcut(this, info);
      tool ??= currentTool;
      if (tool != null) {
        if (tool.canDrag(this, false, pointer)) {
          runningTool = tool;
          return tool.startDrag(this, pointer);
        }
      }
    }*/
    return false;
  }

  void onDragEnd(RawPointerInfo pointer) {
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    /*ContainerTool? tool = runningTool;
    //tool?.stop1(this, [pointer], false);
    tool?.endDrag(this, pointer, false);
    runningTool = null;*/
  }

  void onDragMove(RawPointerInfo pointer) {
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    /*ContainerTool? tool = runningTool;
    tool?.drag(this, pointer);*/
  }

  void onMouseWheel(RawPointerInfo pointer) {
    /*ContainerTool? tool = runningTool;
    if (tool == null) {
      if (currentTool != null &&
          currentTool!.supportMouseWheel(this, pointer)) {
        tool = currentTool;
      }
    }
    tool ??= supportSet?.findToolSupportMouseWheel1(this, pointer);
    tool?.onMouseWheel(this, pointer);*/
  }

  void onLongPress(RawPointerInfo pointer) {
    /*ContainerTool? tool = runningTool;
    tool ??= currentTool;*/
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    //tool?.onLongPress(this, pointer);
  }

  void onTap(RawPointerInfo pointer) {
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    /*ContainerTool? tool = runningTool;
    tool ??= currentTool;
    tool?.onTap(this, pointer);
    */
  }

  bool onMouseHover(RawPointerInfo pointer) {
    /*ContainerTool? tool = runningTool;
    tool ??= currentTool;*/
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    /* return tool != null ? tool.onMouseHover(this, pointer) : false;
    */
    return false;
  }

  bool onMouseExit() {
    _lastCursorPosition[0] = -1;
    _lastCursorPosition[1] = -1;
    //return render != null ? render!.onMouseExit() : false;
    return false;
  }

  bool canLongPress(RawPointerInfo pointer) {
    /*if (runningTool == null) {
      ContainerTool? tool = currentTool;
      if (tool != null) {
        return tool.canLongPress(this, pointer);
      }
    }*/
    return false;
  }

  void onPanZoomStart(List<RawPointerInfo> pointers, Offset pan, double scale) {
    /*if (runningTool == null) {
      ContainerTool? tool = currentTool;
      if (tool != null) {
        if (tool.canPanOrZoom(this, false, pointers)) {
          runningTool = tool;
          tool.startPanOrZoom(this, pointers, pan, scale);
        }
      }
    }*/
  }

  void onPanZoomUpdate(
      List<RawPointerInfo> pointers, Offset pan, double scale) {
    /*ContainerTool? tool = runningTool;
    tool?.panOrZoom(this, pointers, pan, scale);*/
  }

  void onPanZoomEnd() {
    /*ContainerTool? tool = runningTool;
    tool?.endPanOrZoom(this, false);
    runningTool = null;*/
  }

  //-----------------------------------------------------------------------
  //keyboard events
  //-----------------------------------------------------------------------
  /* public onKeyDown(box:number, key:number, shiftKey:boolean, controlKey:boolean, altKey:boolean) {
        if (box == -1) return;
        if (this.isPlaying(null)) return;
        //if (_on_key_handler != NULL) 
            //if (_on_key_handler(std::static_pointer_cast<ocontainer_wnd>(shared_from_this()), box, key, shift_key, control_key, OSTRUE, _wkey_handler_data.lock()))
                //return;
        let done:boolean = false;
        let tool:OsContainerTool|null = this.getRunningTool(null, false);
        if (tool) {
            tool.onKeyDown(this, box, key, shiftKey, controlKey);
            done = true;
        }
        let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
        if (!done && action) {
            if (action.isRunning()) {
                //action.onKeyDown(this, box, key, shiftKey, controlKey);
                done = true;
            }
        }
        if (!done) {
            let action:OsContainerAction|null = this.findCandidateImageActionByShortcut(key, shiftKey, controlKey, altKey);
            if (action) {
                if (action.canStart(this, null))
                    action.start(this, null);
                done = true;
            }
            else {
                let action:OsAnnotationAction|null = this.findCandidateAnnotationActionByShortcut(key, shiftKey, controlKey, altKey);
                if (action) {
                    if (action.canStart(this, box))
                        action.start(this, box);
                    done = true;
                }
            }
        }
        
        if (!done) {

            let item:OsDbPreferenceItem|null = this.findCandidateWindowLevelColorLutOpacityTableConvolutionFiterBySortcut(key, shiftKey, controlKey, altKey);
            if (item != null) {

                if (item.ptype == 'WL') this.setWindowLevel(<OsDbWindowLevel>item, true, true, true, null, true);
                else if (item.ptype == 'CL') this.setColorLut(<OsDbColorLut>item, true, true, null, true);
                else if (item.ptype == 'OT') this.setOpacityTable(<OsDbOpacityTable>item, true, true, null, true);
                else if (item.ptype == 'CF') this.setConvolutionFilter(<OsDbConvolutionFilter>item, true, true, null, true);
                this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                done = true;

            }

        }
    }

    public onKeyUp(box:number, key:number, shiftKey:boolean, controlKey:boolean, altKey:boolean) {
        if (box == -1) return;
        
    }

    

    public findCandidateImageActionByShortcut(key:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):OsContainerAction|null {
        if (!this.isPlaying(null)) {
            let supportSet:OsContainerSupportSet|null = this._wsupportSet?<OsContainerSupportSet>this._wsupportSet.lock(false):null;
            let list:OsContainerAction[]|null = supportSet?supportSet.getListOfContainerActions():null;
            if (list) {
                for (let i:number=0; i<list.length; i++) {
                    let sh:OsShortcut|null = list[i].getShortcut();
                    if (sh && sh.hit(true, key, shiftKey, controlKey, altKey)) return list[i];
                }
            }
        }
        return null;
    }

    public findCandidateToolByShortcut(box:number, button:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):OsContainerTool|null {
        if (!this.isPlaying(null)) {
            let supportSet:OsContainerSupportSet|null = this._wsupportSet?<OsContainerSupportSet>this._wsupportSet.lock(false):null;
            let list:OsContainerTool[]|null = supportSet?supportSet.getListOfContainerTools():null;
            if (list) {
                for (let i:number=0; i<list.length; i++) {
                    let sh:OsShortcut|null = list[i].getShortcut();
                    if (sh && sh.hit(false, button, shiftKey, controlKey, altKey)) return list[i];
                }
            }
        }
        return null;

        
    }
    


    public findCandidateWindowLevelColorLutOpacityTableConvolutionFiterBySortcut(button:number, shiftKey:boolean, controlKey:boolean, altKey:boolean):OsDbPreferenceItem|null {
        let siteSet:[OsDbPreferenceSet|null] = [null];
        let userSet:OsDbPreferenceSet|null = this._viewer?this._viewer.getActivePreferenceSet(siteSet):null;
        for (let j:number=0; j<2; j++) {
            let set:OsDbPreferenceSet|null = (j==0) ? userSet : siteSet[0];
            if (set == null) continue;
            //let pset:OsDbPropertySet = set.findPropertySet('PS_SHORTCUTS');
            //if (pset == null) continue;
            for (let i:number=0; i<4; i++) {
    
                let type:string='';
                switch(i) {
                    case 0: type = 'WL'; break;
                    case 1: type = 'CL'; break;
                    case 2: type = 'OT'; break;
                    case 3: type = 'CF'; break;
                    default: return null;
                };
                let list:OsDbPreferenceItem[] = type in set.items ? set.items[type] : null;
                if(list != null){
                    for (let  it:number = 0; it < list.length; it++) {
        
                        if (!list[it].status) continue;
                        let sh:OsShortcut = new OsShortcut;
                        sh.modifier = list[it].shortcutModifier;
                        sh.key = list[it].shortcutKey;
                        if (sh && sh.hit(true, button, shiftKey, controlKey, altKey)) return list[it];
                        
                       
        
                    }
                }
                
            }
    
        }
        return null;
    
    }

    

    

    //-----------------------------------------------------------------------
    //mouse cursor
    //-----------------------------------------------------------------------

    public setCursor(cursor:OsCursor):boolean {
        return this._component&&cursor?this._component.setCursor(cursor):false;
    }*/

  bool onSetCursor(RawPointerInfo pointer) {
    /*ContainerTool? tool = runningTool;
    tool ??= currentTool;*/
    _lastCursorPosition[0] = pointer.localPosition.dx;
    _lastCursorPosition[1] = pointer.localPosition.dy;
    /*if (tool != null) {
      return tool.onSetCursor(this, pointer);
    } else {
      return false;
    }*/
    return false;
  }
  /*public onSetCursor(box:number, x:number, y:number, shiftKey:boolean, ctrlKey:boolean):boolean {
        if (box == -1) return false;
        //is cursor over a toolbar?
       
        //is cursor over a slider?
        if (!this.isMouseCaptured(null)) {
            let shouldCheckSlider:boolean = (shiftKey || ctrlKey)?false:true;
            if (shouldCheckSlider) {
                if (this.isMouseCursorInsidePageSlider(box, x, y)) {
                    let cursor:OsCursor|null = this._viewer?this._viewer.findCursor('DEFAULT'):null;
                    return cursor?this._component.setCursor(cursor):false;
                }
            }
        }
        //Do we have a running tool?
        let tool:OsContainerTool|null = this.getCurrentTool(null, false);
        if (tool) return tool.onSetCursor(this, box, x, y, shiftKey, ctrlKey);
        //Do we have a running annotation action?
        let action:OsAnnotationAction|null = this.getCurrentAnnotationAction();
        if (action) return action.onSetCursor(this, box, x, y, shiftKey, ctrlKey);
        return false;
    }*/

  //-----------------------------------------------------------------------
  //drop opened entities
  //-----------------------------------------------------------------------

  bool canDropOpenedEntity(Object item) {
    if (item is entities.Study) {
      //final study = item;
      //let series:OsOpenedSeries[] = study.getSeries();
      //if (_controller && _controller.canAddSeries(series)) return true;
    } else if (item is entities.Series) {
      final series = item;
      final list = [series];
      if (_controller.canAddSeries(list)) return true;
    }
    return false;
  }

  void onDropOpenedEntity(Object item) {
    if (item is entities.Study) {
      /* let study:OsOpenedStudy = <OsOpenedStudy>obj;
            if (study != null) {

                let sortingSeries:number = 0;
                let set:OsDbPreferenceSet|null = this._viewer?this._viewer.getLocalPreferenceSet():null;
                
               let prop:OsDbPropertySet|null = set?set.findPropertySet('GENERAL'):null;
               if(prop != null){
                   let category:OsPropertyMap|null = prop.findCategory('VIEWER', false);
                   if(category != null){
                       sortingSeries = category.get('SORTSR');
                       if (sortingSeries  < 0 || sortingSeries > 1) sortingSeries = 0;
       
                   }
               }
               let ascending:boolean = false;
               if(sortingSeries == 0) sortingSeries = OS_SORT.SORT_BY_DATE;
               else{
                    sortingSeries = OS_SORT.SORT_BY_SERIESNUM;
                    ascending = true;
               }
                let seriesToOpen:Array<OsOpenedSeries> = [];
                study.getSortedSeries(seriesToOpen, sortingSeries, ascending);
                if (seriesToOpen.length > 0 && this._controller){
                    this._controller.resetContent(false, false, null);
                    for(let i:number = 0;i < seriesToOpen.length; i++){
                        this._controller.addSeries(seriesToOpen[i], true, false, null);
                    }
                    this.setCurrentPage(this._currentPage, OsContDraw.OS_FORCE_REDRAW);
                    setTimeout(() => {
                        let synchro:IContainerSynchroItem|null = this.getSynchroItem();
                        if (synchro != null) this.setSynchroItem(null);
                        this.makeFirstResponder();
                        this.becameFirstResponder();
                        if (synchro != null) {
                            this.setSynchroItem(synchro);
                            synchro.resolve(null, true, null);
                            let container:IContainerWnd|null = synchro.getMainContainer();
                            if (container != null) synchro.synchronize(container, null);
                        }
                        if (this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
                    }, 1);

                    //this._viewer.getDownloadManager().downloadImages();
                }

                
            }*/
    } else if (item is entities.Series) {
      final series = item;
      _controller.resetContent(false, null);
      _controller.addSeries(
          series: series, refresh: false, fromHangingProtocol: false);
      setCurrentPage(index: _currentPage, mode: OsContDraw.osForceRedraw);
      /*setTimeout(() => {
                        let synchro:IContainerSynchroItem|null = this.getSynchroItem();
                        if (synchro != null) this.setSynchroItem(null);
                        this.makeFirstResponder();
                        this.becameFirstResponder();
                        if (synchro != null) {
                            this.setSynchroItem(synchro);
                            synchro.resolve(null, true, null);
                            let container:IContainerWnd|null = synchro.getMainContainer();
                            if (container != null) synchro.synchronize(container, null);
                        }
                        if (this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
                    }, 1);*/
    }
  }

  //-----------------------------------------------------------------------
  //page slider
  //-----------------------------------------------------------------------

  /*public setPageSliderInfo(index:numbe):void {
        if (!this._pageSlider) this.getPageSlider();
        if (!this._pageSlider) return;
        let rect:[number, number, number, number] = this._imageBoxes[index].rect;
        this._pageSlider.setRange(0, this.getPageCount()-1);
        if (this._pageMode) this._pageSlider.setPosition(this.getPageCount() - 1 - this.getCurrentPage(), false);
        else this._pageSlider.setPosition(this.getPageCount() - 1 - this.getCurrentPage() - index, false);
        this._pageSlider.setLength(Math.floor(rect[3]*0.5));
        this._pageSlider.pos[0] = rect[2]-this._pageSlider.getThumbWidth()*0.5-5;
        this._pageSlider.pos[1] = rect[3]*0.5;
        this._pageSlider.validateMatrix();
    }

    public getPageSlider():OsGraphicSlider|null {
        if (this.isPageSliderEnable()) {
            if (!this._pageSlider) {
                this._pageSlider = new OsContainerPageSlider();
                this._pageSlider.setSliderData(this);
                this._pageSlider.setOrientation(true);
                this._pageSlider.setThumbWidth(15);
                this._pageSlider.setMinThumbLength(10);                
            }
        }
        else {
            if (this._pageSlider) {
                this._pageSlider.release();
                this._pageSlider = null;
            }
        }
        return this._pageSlider;
    }

    public isMouseCursorInsidePageSlider(box:number, x:number, y:number):boolean {
        if (this._pageSlider) {
            this.setPageSliderInfo(box);
            this._pageSlider.box = box;
            if (this._pageSlider.visible) {
                let minMax:[number, number] = [0, 0];
                this._pageSlider.getRange(minMax);
                if (minMax[0] < minMax[1]) {
                    let boxRect:[number, number, number, number] = [0, 0, 0 , 0];
                    this.getImageBoxRect(box, boxRect);
                    let y1:number = boxRect[3] - y - 1;
                    let x1:number = x - this._pageSlider.pos[0];
                    y1 -= this._pageSlider.pos[1];
                    let length:number = this._pageSlider.getLength();
                    let width:number = this._pageSlider.getThumbWidth();
                    if (x1 >= -width*0.5 && x1 <= width*0.5 &&
                        y1 >= -length*0.5 && y1 <= length*0.5) {
                        return true;
                    }
                }
            }
        }
        return false;

    }

    public enablePageSlider(enable:boolean) {
        this._pageSliderEnable = enable;
    }

    public isPageSliderEnable():boolean {
        if (this._drawTarget == OsContDrawTarget.OS_DRAW_TARGET_SCREEN) return this._pageSliderEnable;
        else return false;
    }
	

        
        //-----------------------------------------------------------------------
        //memory
        //-----------------------------------------------------------------------
        public shouldMinimizeMemoryUsage():boolean {
            return this._minimizeMemoryUsage;
        }
       
    
        //-----------------------------------------------------------------------
        //window level
        //-----------------------------------------------------------------------

        private _propagateHelp(label:string, refresh:boolean, renderers:OsRenderer[]|null, modifiedList:IContainerWnd[]|null, sendModifiedMessage:boolean):void {
            let containersToRefresh:OsContainerWnd[] = [];
            let propagation:IContainerPropagateItem|null = this.getPropagationItem();
            if (propagation) propagation.propagate2(this, renderers, label, false, containersToRefresh);
            if (containersToRefresh.length == 0) containersToRefresh.push(this);
            if (modifiedList != null)
                for (let i=0; i<containersToRefresh.length; i++)
                    modifiedList.push(containersToRefresh[i]);
            if (refresh)
                for (let i=0; i<containersToRefresh.length; i++)
                    containersToRefresh[i].setCurrentPage(containersToRefresh[i].getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
            if (sendModifiedMessage && this._viewer && this._viewer.messageService) this._viewer.messageService.sendMessage(MSG.IMGCONT_MODIFIED, this);
        }
        
        public setWindowLevelValues(center:number, width:number, propagate:boolean, refresh:boolean, modifiedList:OsContainerWnd[]|null, sendModifiedMessage:boolean):void {
            let renderers:OsRenderer[] = [];
            this.getActionRenderersForPropagation(renderers, "WL");
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) img.setWindowLevelValues(center, width);
            }
            this._propagateHelp("WL", refresh, renderers, modifiedList, sendModifiedMessage);
        }

        public getWindowLevelValues(centerWidth:[number, number]):boolean {
            centerWidth[0] = VALUE.F64_MAX;
            centerWidth[1] = VALUE.F64_MAX;
            let renderers:OsRenderer[] = [];
            this.getActionRenderers(renderers, true, 'WL');
            
            let first:boolean = true;
            let haveWindowLevel:boolean = false;
            let centerWidth1:[number, number] = [VALUE.F64_MAX, VALUE.F64_MAX];

            for (let it:number=0; it<renderers.length; it++) {
                let img:OsGraphicImage|null =  renderers[it].getPrimaryImageItem(false);
                if (img) {
                    let preset:OsDbWindowLevel|null = img.getWindowLevel();
                    if (first) {
                        first = false;
                        if (preset) {
                            haveWindowLevel = true;
                            centerWidth1[1] = preset.getWidth();
                            centerWidth1[0] = preset.getCenter();
                        }
                        else haveWindowLevel = img.getWindowLevelValues(centerWidth1);
                        if (!haveWindowLevel) return false;
                    }
                    else {
                        let centerWidth2:[number, number] = [VALUE.F64_MAX, VALUE.F64_MAX];
                        if (preset) {
                            centerWidth2[1] = preset.getWidth();
                            centerWidth2[0] = preset.getCenter();
                        }
                        else {
                            if (!img.getWindowLevelValues(centerWidth2)) return false;
                        }
                        if (centerWidth1[1] != centerWidth2[1]) return false;
                        if (centerWidth1[0] != centerWidth2[0]) return false;
                    }
                }
            }
            if (!first) {
                centerWidth[0] = centerWidth1[0];
                centerWidth[1] = centerWidth1[1];
                return true;
            }
            else return false;
        }

        public setWindowLevel(preset:OsDbWindowLevel|null, resetOriginal:boolean, propagate:boolean=true, refresh:boolean=true, modifiedList:IContainerWnd[]|null, sendModifiedMessage:boolean=false):void {
            let renderers:OsRenderer[] = [];
            this.getActionRenderersForPropagation(renderers, "WL");
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) img.setWindowLevel(preset, resetOriginal);
            }
            this._propagateHelp("WL", refresh, renderers, modifiedList, sendModifiedMessage);
        }

        public getWindowLevel(mixed:[boolean]):OsDbWindowLevel|null {
            let renderers:OsRenderer[] = [];
            this.getActionRenderers(renderers, true, "WL");
            let first:boolean = true;
            let present:boolean = false;
            let current:OsDbWindowLevel|null = null;
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) {
                    let tmp:OsDbWindowLevel|null = img.getWindowLevel();
                    if (tmp != null) present = true;
                    if (first) {
                        first = false;
                        current = tmp;
                    }
                    else if (current != tmp) current = null;
                }
            }
            if (mixed) mixed[0] = (present && current == null) ? true : false;
            return current;
        }

            
        //-----------------------------------------------------------------------
        //color Lut
        //-----------------------------------------------------------------------

        public setColorLut(preset:OsDbColorLut|null, propagate:boolean=true, refresh:boolean=true, modifiedList:IContainerWnd[]|null=null, sendModifiedMessage:boolean=false):void {
            let renderers:OsRenderer[] = [];
            this.getActionRenderersForPropagation(renderers, "CL");
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) img.setColorLut(preset);
            }
            this._propagateHelp("CL", refresh, renderers, modifiedList, sendModifiedMessage);
        }

        public getColorLut(mixed:[boolean]):OsDbColorLut|null {
            let renderers:OsRenderer[] = [];
            this.getActionRenderers(renderers, true, "CL");
            let first:boolean = true;
            let present:boolean = false;
            let current:OsDbColorLut|null = null;
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) {
                    let tmp:OsDbColorLut|null = img.getColorLut();
                    if (tmp != null) present = true;
                    if (first) {
                        first = false;
                        current = tmp;
                    }
                    else if (current != tmp) current = null;
                }
            }
            if (mixed) mixed[0] = (present && current == null) ? true : false;
            return current;
        }

        //-----------------------------------------------------------------------
        //opacity Table
        //-----------------------------------------------------------------------

        public setOpacityTable(preset:OsDbOpacityTable|null, propagate:boolean=true, refresh:boolean=true, modifiedList:IContainerWnd[]|null=null, sendModifiedMessage:boolean=false):void {
            let renderers:OsRenderer[] = [];
            this.getActionRenderersForPropagation(renderers, "OT");
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) img.setOpacityTable(preset);
            }
            this._propagateHelp("OT", refresh, renderers, modifiedList, sendModifiedMessage);
        }

        public getOpacityTable(mixed:[boolean]):OsDbOpacityTable|null {
            let renderers:OsRenderer[] = [];
            this.getActionRenderers(renderers, true, "OT");
            let first:boolean = true;
            let present:boolean = false;
            let current:OsDbOpacityTable|null = null;
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) {
                    let tmp:OsDbOpacityTable|null = img.getOpacityTable();
                    if (tmp != null) present = true;
                    if (first) {
                        first = false;
                        current = tmp;
                    }
                    else if (current != tmp) current = null;
                }
            }
            if (mixed) mixed[0] = (present && current == null) ? true : false;
            return current;
        }


        //-----------------------------------------------------------------------
        //convolution filter
        //-----------------------------------------------------------------------
        public setConvolutionFilter(preset:OsDbConvolutionFilter|null, propagate:boolean=true, refresh:boolean=true, modifiedList:IContainerWnd[]|null=null, sendModifiedMessage:boolean=false):void {
            let renderers:OsRenderer[] = [];
            this.getActionRenderersForPropagation(renderers, "CF");
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) img.setConvolutionFilter(preset);
            }
            this._propagateHelp("CF", refresh, renderers, modifiedList, sendModifiedMessage);
        }

        public getConvolutionFilter(mixed:[boolean]):OsDbConvolutionFilter|null {
            let renderers:OsRenderer[] = [];
            this.getActionRenderers(renderers, true, "CF");
            let first:boolean = true;
            let present:boolean = false;
            let current:OsDbConvolutionFilter|null = null;
            for (let i=0; i<renderers.length; i++) {
                let img:OsGraphicImage|null = renderers[i].getPrimaryImageItem(false);
                if (img != null) {
                    let tmp:OsDbConvolutionFilter|null = img.getConvolutionFilter();
                    if (tmp != null) present = true;
                    if (first) {
                        first = false;
                        current = tmp;
                    }
                    else if (current != tmp) current = null;
                }
            }
            if (mixed) mixed[0] = (present && current == null) ? true : false;
            return current;
        }

        //-----------------------------------------------------------------------
        //messages
        //-----------------------------------------------------------------------
        private _onReceivedMessage(id: number, data: any) {
            if (id == MSG.ANNOTATION_MODIFIED) {
                let annotationContainer:OsContainerWnd = <OsContainerWnd>data.container;
                if (annotationContainer === this) {
                    this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                }
            }
            else 
            if (id == MSG.CURRENT_PREF_SET_CHANGED || id == MSG.CURRENT_PREF_SET_MODIFIED) {
                let doIt:boolean = false;
                if (id == MSG.CURRENT_PREF_SET_MODIFIED) {
                    let set:OsDbPreferenceSet = <OsDbPreferenceSet>data[0];
                    let item:OsDbPreferenceItem = <OsDbPreferenceItem>data[1];
                    if (set && item && this._viewer && set === this._viewer.getLocalPreferenceSet()) {
                        if (item.ptype === 'PS') {
                            if (item.name === 'FONTS_COLORS') 
                                doIt = true;
                        }
                        else
                        if (item.ptype === 'WL' || item.ptype === 'CL' ||
                            item.ptype === 'OT' || item.ptype === 'CF') {
                            let needRefresh:boolean = false;
                            let controller:OsContainerController|null = this.getController();
                            if (controller) {
                                let renderers:OsRenderer[] = controller.getRendererElements();
                                if (renderers) {
                                    for (let it1:number=0; it1<renderers.length; it1++) {
                                        let images:OsGraphicImage[] = [];
                                        renderers[it1].getImageItems(images);
                                        for (let it2:number=0; it2<images.length; it2++) {
                                            let tmp:OsDbItem|null = null;
                                            if (item.ptype == 'WL') tmp = images[it2].getWindowLevel();
                                            else if (item.ptype == 'CL') tmp = images[it2].getColorLut();
                                            else if (item.ptype == 'OT') tmp = images[it2].getOpacityTable();
                                            else if (item.ptype == 'CF') tmp = images[it2].getConvolutionFilter();
                                            if (tmp === item) { 
                                                if (item.ptype === 'WL') images[it2].setWindowLevel(<OsDbWindowLevel>tmp, false);
                                                else images[it2].setDirty(true); 
                                                needRefresh = true; 
                                            }
                                        }
                                    }
                                }
                            }
                            if (needRefresh) this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                        }
                    }
                }
                else doIt = true;
                if (doIt) {
                    if (this._singleWindow) {
                        if (this._context && this._driver) {
                            this._driver.setCurrentContext(this._context);
                            if (!this._fonts[0].name.length || !this._fonts[1].name.length) {
                                this._context.resetTexts();
                                for (let i:number=0; i<2; i++) {
                                    if (this._fonts[i].name.length) continue;
                                    let info:any = this._viewer?this._viewer.getCurrentFont(i):null;
                                    let list:OsDriverCharacterList|null = this._context.findCharacterList(i?'ANNOT':'DICOM');
                                    if (list && info && info.name.length) list.setFont(info.name, info.size);
                                }
                                this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                            }
                        }
                    }
                    
                }
            }
            
            if (id === MSG.SERIES_CALIBRATED) {
                let list:OsOpenedSeries[] = data;
                if (list) {
                    let refresh:boolean = false;
                    let controller:OsContainerController|null = this.getController();
                    if (controller) {
                        for (let it:number=0; it<list.length; it++) {
                            if (controller.isSeriesDisplayed(list[it])) {
                                refresh = true;
                                break;
                            }
                        }
                    }
                    if (refresh) {
                        //this.unselectAllAnnotations(true, false);
                        let synchro:IContainerSynchroItem|null = this.getSynchroItem();
                        if (synchro) {
                            synchro.resolve(null, true, null);
                            synchro.synchronize(null, null);
                        }
                        let rect1:[number, number, number, number] = [0, 0, 0, 0];
                        this.getImageBoxRect(0, rect1);
                        let renderers:OsRenderer[] = controller?controller.getRendererElements():[];
                        for (let it:number=0; it!=renderers.length; it++) {
                            renderers[it].unselectAllAnnotations();
                            renderers[it].fitCamera(rect1[2], rect1[3]);
                            renderers[it].onCalibrationChanged();
                        }
                        this.setCurrentPage(this.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
                        for (let it:number=0; it<renderers.length; it++) 
                            renderers[it].regenerateAnnotationSegments();
                        if (this._viewer) this._viewer.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this);
                    }
                }
            }
        }


        //-----------------------------------------------------------------------
        //
        //-----------------------------------------------------------------------

        public getBoundingClientRect(rect:[number, number, number, number]):boolean {
            return this._component?this._component.getBoundingClientRect(rect):false;
        }

        //-----------------------------------------------------------------------
        //toolbars
        //-----------------------------------------------------------------------

        public getToolbarUnderCursor(box:number, x:number, y:number):OsGraphicToolbar|null {
            let toolbar:OsGraphicToolbar|null = null;
    
            if (!toolbar) {
                let render:OsRenderer|null = this.getImageBoxRenderer(box);
                if (render) {
                    let toolbars:OsGraphicToolbar[] = [];
                    render.getToolbars(toolbars, true);
                    if (toolbars.length > 0) {
                        let rect:[number, number, number, number] = [0, 0, 0, 0];
                        this.getImageBoxRect(box, rect);
                        let viewport:[number, number, number, number] = [0, 0, 0, 0];
                        viewport[0] = rect[0];
                        viewport[1] = rect[1];
                        viewport[2] = rect[2];
                        viewport[3] = rect[3];
                        let pos:[number, number] = [0, 0];
                        pos[0] = x;
                        pos[1] = y;
                        for (let i:number = toolbars.length-1; i >= 0; i--) {
                            if (toolbars[i].isMouseInsideToolbar(viewport, pos)) {
                                toolbar = toolbars[i];
                                break;
                            }
                        }
                    }
                }
            }
            return toolbar;
        }
    }    */
}
