import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/math/matrix.dart';

///////////////////////////////////////////////////////////////////////
// OsPushedMatrix
///////////////////////////////////////////////////////////////////////

class OsPushedMatrix {
  OsMatrix worldMat = OsMatrix();
  final OsMatrix worldInvMat = OsMatrix();
  final OsMatrix worldViewMat = OsMatrix();
  final OsMatrix worldViewInvMat = OsMatrix();
  final OsMatrix worldInvTransposeMat = OsMatrix();
  final OsMatrix worldViewProjMat = OsMatrix();
}

///////////////////////////////////////////////////////////////////////
// OsRenderInfo
///////////////////////////////////////////////////////////////////////

class OsRenderInfo {
  final OsMatrix projMat = OsMatrix(); //Projection matrix
  final OsMatrix viewMat = OsMatrix(); //View matrix
  final OsMatrix viewInvMat = OsMatrix(); //View inverse matrix
  final OsMatrix worldMat = OsMatrix(); //World matrix
  final OsMatrix worldInvMat = OsMatrix(); //World inverse matrix
  final OsMatrix worldViewMat = OsMatrix(); //World * View matrix
  final OsMatrix worldViewInvMat = OsMatrix(); //[World * View] inverse matrix
  final OsMatrix worldInvTransposeMat =
      OsMatrix(); //World Inverse Transpose matrix
  final OsMatrix worldViewProjMat =
      OsMatrix(); //World * View * Projection matrix
  final List<double> camPos = [0, 0, 0, 0]; //Camera Absolute Position
  final List<double> objPos = [0, 0, 0, 0]; //Object Absolute Position
  final List<OsPushedMatrix> _pushedMatrices = [];
  OsRenderer? render;

  OsRenderInfo(OsRenderer? render) {
    render = render;
  }

  //operations:
  void reset() {
    projMat.identity();
    viewMat.identity();
    viewInvMat.identity();
    worldMat.identity();
    worldInvMat.identity();
    worldViewMat.identity();
    worldViewInvMat.identity();
    worldInvTransposeMat.identity();
    worldViewProjMat.identity();
    camPos[0] = camPos[1] = camPos[2] = camPos[3] = 0.0;
    objPos[0] = objPos[1] = objPos[2] = objPos[3] = 0.0;
  }

  void pushMatrix() {
    OsPushedMatrix info = OsPushedMatrix();
    info.worldMat.copyFrom(worldMat);
    info.worldInvMat.copyFrom(worldInvMat);
    info.worldViewMat.copyFrom(worldViewMat);
    info.worldViewInvMat.copyFrom(worldViewInvMat);
    info.worldInvTransposeMat.copyFrom(worldInvTransposeMat);
    info.worldViewProjMat.copyFrom(worldViewProjMat);
    _pushedMatrices.add(info);
  }

  void popMatrix() {
    OsPushedMatrix info = _pushedMatrices[_pushedMatrices.length - 1];
    _pushedMatrices.clear();
    worldMat.copyFrom(info.worldMat);
    worldInvMat.copyFrom(info.worldInvMat);
    worldViewMat.copyFrom(info.worldViewMat);
    worldViewInvMat.copyFrom(info.worldViewInvMat);
    worldInvTransposeMat.copyFrom(info.worldInvTransposeMat);
    worldViewProjMat.copyFrom(info.worldViewProjMat);
  }

  void applyWorldTransformation(OsMatrix mat) {
    worldMat.postMultiply(mat);
    worldMat.getInvert(worldInvMat);
    worldViewMat.postMultiply(mat);
    worldViewMat.getInvert(worldViewInvMat);
    worldInvMat.getTransposed(worldInvTransposeMat);
    worldViewProjMat.postMultiply(mat);
  }
}

///////////////////////////////////////////////////////////////////////
// OsWillDrawInfo
///////////////////////////////////////////////////////////////////////

class OsWillDrawInfo {
  OsDriverContext? context;
  OsRenderer? render;
  List<double> viewport = [0, 0, 0, 0];
  List<double> mouse = [0, 0];
}

///////////////////////////////////////////////////////////////////////
// renderer_type
///////////////////////////////////////////////////////////////////////

abstract class OsRendererType {
  String get id;
  OsRenderer? createRenderer();
}

///////////////////////////////////////////////////////////////////////
// OsRenderer
///////////////////////////////////////////////////////////////////////

abstract class OsRenderer {
  final WeakReference<OsRendererType>? _wtype;

  OsRenderer(OsRendererType type)
      : _wtype = WeakReference<OsRendererType>(type);

  OsRendererType? get type => _wtype?.target;

  void cleanup() {}

  //clone:
  OsRenderer? clone() {
    return null;
  }

  //type:
  //OsRendererType getType() { return OsRendererType.osRenderer; }

  bool isInitialized() {
    return false;
  }

  //background colors:
  void setBackgroundColor4d(
      double red, double green, double blue, double alpha) {}
  void setBackgroundColor4i(int red, int green, int blue, int alpha) {}

  //selection color:
  void setSelectionColor4d(
      double red, double green, double blue, double alpha) {}
  void setSelectionColor4i(int red, int green, int blue, int alpha) {}

  //visibility:
  bool get hidden;
  set hidden(bool value);

  //selection:
  bool get selected;
  set selected(bool value);

  //filter:
  int get filterType;
  set filterType(int value);

  //key:
  //bool isKey(List<double>? status = null) { return false; }
  //void setKey(bool value, int status = 1) {}

  //camera:
  //OsGraphicCamera? getCamera() { return null; }
  //bool fitCamera(double cx, double cy) { return false; }
  //bool scaleCameraToOriginal(double cx, double cy) { return false; }
  //  bool scaleCameraToRealSize(double cm, double cx, double cy, bool reset) { return false; }
  //bool isFitCamera() { return false; }
  //bool resetCamera(double cx, double cy) { return false; }

  //render items:
  //void getImageItems(List<OsGraphicImage> list) {}
  //OsGraphicImage? getActiveImageItem(bool retain) { return null; }
  //OsGraphicImage? getPrimaryImageItem(bool retain) { return null; }
  //OsGraphicGroup? getRootItem(bool retain) { return null; }
  //OsGraphicGroup? getImageGroupItem(bool retain) { return null; }
  //OsGraphicGroup? getAnnotationGroupItem(bool retain) { return null; }
  //void setPrimaryImageItem(OsGraphicImage img) {}
  //void setActiveImageItem(OsGraphicImage item) {}

  //localizer:
  //bool setShouldDrawLocalizer(bool draw, OsOpenedStudy? study, OsOpenedSeries? series, OsMatrix? mat, List<double>? dimensions) { return false; }

  //draw:
  //bool shouldAutoHideAnnotations() { return false; }
  //void setShouldAutoHideAnnotations(bool value) {}
  void willDraw(OsWillDrawInfo info) {}
  void draw(OsDriver driver) {}
  //void setDrawTarget(int target, double factor) {}
  //int getDrawTarget() { return 0; }
  //double getDrawFactor() { return 1.0; }
  //OsOffscreenCanvas? drawInBitmap(int width, int height) { return null; }

  //scope:
  //void showScope(double x, double y) {}
  //void hideScope() {}
  //bool isScopeHidden() { return false; }
  //void setScopeFactor(double factor) {}
  //double getScopeFactor() { return 2.0; }

  //loaded:
  //void setPreloaded(bool value) {}
  //bool isPreloaded() { return false; }
  //bool checkPreloaded() { return false; }

  //context:
  //virtual driver_context_ptr get_context() = 0;

  //dirty:
  bool get dirty => false;

  //pixel:
  //bool getPixelPosition(int width, int height, double x, double y, List<double> output, bool onlyInside) { return false; }
  //bool getPixelValue(int width, int height, double x, double y, List<double> position, List<bool> isMonochrome, List<double> value, List<double> rgb) { return false; }

  //annotations:
  /*void regenerateAnnotationSegments() {}

    void getAnnotationList(List<OsGraphicAnnotation> list, int mode = 2) {
        List<OsGraphicImage> images = [];
        getImageItems(images);
        for (int i = 0; i < images.length; i++) 
            images[i].getAnnotationList(list, mode, this);
    }

    bool unselectAllAnnotations() { 
        let ret:boolean = false;
        let images:OsGraphicImage[] = [];
        this.getImageItems(images);
        for (let i=0; i<images.length; i++) 
            if (images[i].unselectAllAnnotations(this)) ret = true;
        return ret;   
    }

    public haveAnnotations(mode:number):boolean {
        let images:OsGraphicImage[] = [];
        this.getImageItems(images);
        for (let i=0; i<images.length; i++) {
            let annotations:OsGraphicAnnotation[] = [];
            images[i].getAnnotationList(annotations, mode, this);
            if (annotations.length) return true;
        }
        return false;
    }

    public deleteAnnotations(mode:number = 2):number {
        let ret:number = 0;
        let images:OsGraphicImage[] = [];
        this.getImageItems(images);
        for (let i=0; i<images.length; i++) {
            let annotations:OsGraphicAnnotation[] = [];
            images[i].getAnnotationList(annotations, mode, this);
            if (annotations.length > 0) {
                ret = 1;
                for (let j=0; j<annotations.length; j++) {
                    if (annotations[j].isSelected(this)) ret = 2;
                    images[i].removeAnnotation(annotations[j]);
                }
                this.regenerateAnnotationSegments();
            }
        }
        return ret;
    }

    //overlays:
    public shouldDisplayDicomAnnotations(set:[OsDbAnnotationSet|null]) { if (set && set.length) set[0] = null; return false; } 
    public shouldDisplayGraphicAnnotations() { return true; }
    public shouldDisplayRuler():boolean { return true; }
    public shouldDisplayDicomOverlays() { return true; }
    public setShouldDisplayDicomAnnotations(display:boolean, set:OsDbAnnotationSet|null) {}
    public setShouldDisplayGraphicAnnotations(display:boolean) {}
    public setShouldDisplayRuler(display:boolean) {}
    public setShouldDisplayDicomOverlays(display:boolean) {}

    //localizer:
    //virtual b32 set_should_draw_localizer(b32 draw, const onis::opened_study_ptr &study = onis::opened_study_ptr(), const onis::opened_series_ptr &series = onis::opened_series_ptr(), const onis::matrix4d &mat = onis::matrix4d(), f64 *dimensions = NULL) = 0;
    //virtual b32 should_draw_localizer(onis::opened_study_ptr &study, onis::opened_series_ptr &series, onis::matrix4d &mat, f64 *dimensions) const = 0;

    //fonts
    public getFont(target:number):any { return null; }
    public setFont(target:number, name:string, size:number, color:string) {}

    //memory:
    public releaseMemory(level:number):void {}

    //warning messages:
    //virtual void add_warning_message(const onis::object_ptr &data, const onis::string &text) = 0;
    //virtual b32 remove_warning_message(const onis::object_ptr &data, const onis::string &text) = 0;

    //cine:
    public isMpeg():boolean { return false; }
    public play(setAutoStart:boolean = true):boolean { return false; }
    public diaplayFirstFrame():boolean { return false; }
    public pause(cancelAutoStart:boolean = true):boolean { return false; }
    public isPlaying():boolean { return false; }
    public canPlay():boolean { return false; }
    public canMoveToNextFrame():boolean { return false; }
    public canMoveToPreviousFrame():boolean { return false; }
    public canSeek(ratio:number):boolean { return false; }
    public seek(ratio:number):boolean { return false; }
    public canSeekOffset(offset:number):boolean { return false; }
    public seekOffset(offset:number):boolean { return false; }
    public isBuffering(ratio:[number]):boolean { return false; }
    public getCurrentTime():number { return 0; }
    public getTotalTime():number { return 0; }
    public nextFrame():boolean { return false; }
    public previousFrame():boolean { return false; }
    //virtual b32 is_buffering(f64 *ratio) = 0;
    public isStreaming(receivedTotal:[number, number]):boolean { return false; }
    public getDefaultPlaySpeed():number { return 1; }
    public getPlaySpeed():number { return 1; }
    public set_play_speed(fps:number):void {}
    public enableAutoStart(enable:boolean):void {}
    public shouldAutoStart():boolean { return false; }

    //toolbars
    public getToolbars(list:OsGraphicToolbar[], onlyVisible:boolean):void {}*/

  //refresh:
  bool get wantRefreshAsSoonAsPossible => false;

  //events:
  /*public onCalibrationChanged():void {}*/
}
