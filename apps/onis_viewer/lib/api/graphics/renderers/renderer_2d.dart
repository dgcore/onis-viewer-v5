import 'dart:math' as math;

import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/graphics/managers/render_type_manager.dart';
import 'package:onis_viewer/core/dicom/dicom_frame.dart';
import 'package:onis_viewer/core/dicom/image_region.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/renderer/items/camera.dart';
import 'package:onis_viewer/core/graphics/renderer/items/group.dart';
import 'package:onis_viewer/core/graphics/renderer/items/image.dart';
import 'package:onis_viewer/core/graphics/renderer/items/item.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/models/database/color_lut.dart';
import 'package:onis_viewer/core/models/database/convolution_filter.dart';
import 'package:onis_viewer/core/models/database/opacity_table.dart';
import 'package:onis_viewer/core/models/database/window_level.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/result/result.dart';

///////////////////////////////////////////////////////////////////////
// renderer_2d_warning_message
///////////////////////////////////////////////////////////////////////

class OsRenderer2dWarningMessage {
  String text = '';
  bool haveData = false;
  WeakReference<Object>? wdata;

  OsRenderer2dWarningMessage(this.text, Object? data) {
    haveData = data != null;
    wdata = data != null ? WeakReference<Object>(data) : null;
  }
}

///////////////////////////////////////////////////////////////////////
// renderer_type
///////////////////////////////////////////////////////////////////////

class OsRenderer2DType extends OsRendererType {
  @override
  String get id => '2d';

  @override
  OsRenderer? createRenderer() {
    return OsRenderer2D(this);
  }
}

///////////////////////////////////////////////////////////////////////
// OsRenderer2D
///////////////////////////////////////////////////////////////////////

class OsRenderer2D extends OsRenderer {
  late final OsGraphicCamera _camera;
  double _saveFitCameraRot = double.infinity;
  double _saveFitCameraWidth = double.infinity;
  late final OsGraphicGroup _rootItem;
  WeakReference<OsGraphicGroup>? _wimageGroup;
  WeakReference<OsGraphicGroup>? _wannotationGroup;
  WeakReference<OsGraphicImage>? _wprimaryImg;
  WeakReference<OsGraphicImage>? _wactiveImg;
  final List<int> _backCol = [0, 0, 0, 255];
  final List<int> _selCol = [255, 255, 255, 255];
  final List<int> _keyCol = [255, 255, 0, 255];
  final bool _wantRefreshAsap = false;
  final OsRenderInfo _info = OsRenderInfo(null);
  bool _selected = false;
  bool _hidden = false;
  bool _isKey = false;
  final int _autoSizeHide = 0;
  bool _shouldAutoHideAnnotations = false;
  bool _shouldDisplayGraphics = true;
  bool _shouldDisplayDicom = true;
  bool _shouldDisplayRuler = true;
  bool _shouldDisplayOverlays = false;
  final double _drawFactor = 1.0;
  final OsContDrawTarget _drawTarget = OsContDrawTarget.osDrawTargetScreen;
  //private _wannotationSet:OsWeakObject|null;
  //private _dicomAnnotationBoxes:OsGraphicDicomAnnotationBox[];
  //private _fontInfo:any[] = [{name:'', size:12, color:'#ffffff'}, {name:'', size:12, color:'#ffffff'}];
  bool _showScope = false;
  double _scopeX = 0;
  double _scopeY = 0;
  double _scopeFactor = 4.0;
  int _filterType = 1;
  bool _drawLocalizer = false;
  WeakReference<entities.Study>? _wLocalizerStudy;
  WeakReference<entities.Series>? _wLocalizerSeries;
  final OsMatrix _localizerMat = OsMatrix();
  final List<double> _localizerSize = [0, 0];
  bool _initialized = false;
  bool _preloaded = false;
  //private _movieToolbar:OsMovieToolbar|null;
  //private _multiframePlayInfo:OsPlayRender2dInfo|null;
  //private _previousMousePosition:[number, number] = [0, 0];
  //private _showMoveControllerTime:number = Date.now();
  double _playSpeed = 0;
  final bool _autoStart = false;
  final List<OsRenderer2dWarningMessage> _warningMessages = [];

  OsRenderer2D(super.type) {
    /*this._multiframePlayInfo = null;
        this._movieToolbar = null;
        this._wtype = type.getWeakObject();
        this._info = new OsRenderInfo(null);
        
        
        
        */

    //_is_dirty = OSTRUE;

    //this._preloaded = false;

    _camera = OsGraphicCamera('');
    _camera.setOrthographicMode(true);
    _camera.setOrthoWidth(900);
    _camera.pos[0] = 0.0;
    _camera.pos[1] = 0.0;
    _camera.pos[2] = 100.0;
    _camera.setFarPlane(1000.0);
    _camera.setNearPlane(0.01);
    _camera.validateMatrix();

    _rootItem = OsGraphicGroup("ROOT");
    OsGraphicGroup grp = OsGraphicGroup("IMAGES");
    grp.setParent(_rootItem);

    _wimageGroup = WeakReference<OsGraphicGroup>(grp);

    /*this._wannotationSet = null;
    //_filter_type = 0;
    //_target_ruler_font_size = 10.0;
    //_printing_base_point = 0;
    this._dicomAnnotationBoxes = new Array<OsGraphicDicomAnnotationBox>(8);
    for (let i=0; i<this._dicomAnnotationBoxes.length; i++) this._dicomAnnotationBoxes[i] = new OsGraphicDicomAnnotationBox();
    //this._dicomAnnotations = new Array<OsGraphicRenderer2dDicomAnnotations>(8);
    //for (let i=0; i<this._dicom_annotations.length; i++) this._dicom_annotations[i] = new os_graphic_renderer_2d_dicom_annotations();
    */
  }

  void setInitialized() {
    _initialized = true;
  }

  @override
  bool isInitialized() {
    return _initialized;
  }

  //-----------------------------------------------------------------------
  //clone
  //-----------------------------------------------------------------------
  @override
  OsRenderer? clone() {
    OsRendererType? renderType = type;
    if (renderType == null) return null;
    OsRenderer2D? copy;
    copy = OsRenderer2D(renderType);
    /*for (let i=0; i<2; i++) {
      copy._fontInfo[i].name = this._fontInfo[i].name;
      copy._fontInfo[i].size = this._fontInfo[i].size;
      copy._fontInfo[i].color = this._fontInfo[i].color;
    }*/
    copy._camera.copyProperties(_camera);

    copy._backCol[0] = _backCol[0];
    copy._backCol[1] = _backCol[1];
    copy._backCol[2] = _backCol[2];
    copy._backCol[3] = _backCol[3];

    copy._selCol[0] = _selCol[0];
    copy._selCol[1] = _selCol[1];
    copy._selCol[2] = _selCol[2];
    copy._selCol[3] = _selCol[3];

    copy._keyCol[0] = _keyCol[0];
    copy._keyCol[1] = _keyCol[1];
    copy._keyCol[2] = _keyCol[2];
    copy._keyCol[3] = _keyCol[3];

    copy._selected = _selected;
    copy._hidden = _hidden;

    copy._isKey = _isKey;
    copy._filterType = _filterType;
    //copy._printing_base_point = _printing_base_point;
    //copy._preloaded = this._preloaded;

    copy._shouldAutoHideAnnotations = _shouldAutoHideAnnotations;
    copy._shouldDisplayRuler = _shouldDisplayRuler;
    copy._shouldDisplayGraphics = _shouldDisplayGraphics;
    copy._shouldDisplayOverlays = _shouldDisplayOverlays;
    copy._shouldDisplayDicom = _shouldDisplayDicom;
    /*let set:OsDbAnnotationSet|null = null;
    if(this._wannotationSet != null){
        set = <OsDbAnnotationSet>this._wannotationSet.lock(false);
        if (set != null){
            if(copy._wannotationSet != null) copy._wannotationSet.destroy();
            copy._wannotationSet = set.getWeakObject();
        }
    }*/
    copy._playSpeed = _playSpeed;
    //copy._play_offset = _play_offset;

    List<OsGraphicItem> list = copy._rootItem.getChildren();
    while (list.isNotEmpty) {
      list[0].setParent(null);
    }

    list = _rootItem.getChildren();

    for (int i = 0; i < list.length; i++) {
      OsGraphicItem? item2 = cloneItem(list[i]);
      item2?.setParent(copy._rootItem);
    }

    List<OsGraphicItem> list1 = [];
    List<OsGraphicItem> list2 = [];
    _rootItem.getChildrenByType(list1, OsRenderItemType.osImageItem, false);
    _rootItem.getChildrenByType(list2, OsRenderItemType.osImageItem, false);
    /* let viewer:Viewer|null = type?type.getViewer():null;
            if(viewer){
                let manager:OsGraphicManager = viewer.getGraphicManager();

                if(manager){
                    for(let i = 0;i < list1.length && i < list2.length; i++){
                    //onis::graphics::item_list::iterator it1, it2;
                    //for (it1 = list1.begin(), it2 = list2.begin(); it1 != list1.end() && it2 != list2.end(); it1++, it2++) {

                        let img1:OsGraphicImage = <OsGraphicImage>list1[i];
                        let img2:OsGraphicImage = <OsGraphicImage>list2[i];
                        let annotations:OsGraphicAnnotation[]=[];
                        img1.getAnnotationList(annotations);
                        if(annotations.length > 0){
                            
                            manager.copyAnnotations(annotations);
                            manager.pasteAnnotationsToImage(img2);

                        }
                    }
                }
            }

            let img1:OsGraphicImage|null = null;
            if(this._wprimaryImg != null){
                img1 = <OsGraphicImage>this._wprimaryImg.lock(false);
                if (img1 != null) {

                    let index:number = 0;
                    let found:boolean = false;
                    //onis::graphics::item_list::iterator it1;
                    //for (it1 = list1.begin(); it1 != list1.end(); it1++) 
                    for(let i = 0;i < list1.length; i++){
                        if ((<OsGraphicImage>list1[i]) == img1) { found = true; break; }
                        else index++;
                    }
                    if (found) {

                        if (index >= 0 && index < list2.length) {

                            //it1 = list2.begin();
                            //std::advance(it1, index);
                            copy.setPrimaryImageItem(<OsGraphicImage>list2[index]);

                        }

                    }

                }
            }

            if(this._wactiveImg != null){
                img1 = <OsGraphicImage>this._wactiveImg.lock(false);
                if (img1 != null) {

                    let index:number = 0;
                    let found:boolean = false;
                    //onis::graphics::item_list::iterator it1;
                    for(let i = 0;i < list1.length; i++){
                        if ((<OsGraphicImage>list1[i]) == img1) { found = true; break; }
                        else index++;
                    }
                    if (found) {

                        if (index >= 0 && index < list2.length) {

                            //it1 = list2.begin();
                            //std::advance(it1, index);
                            copy.setActiveImageItem(<OsGraphicImage>list2[index]);

                        }

                    }

                }
            }
            list1.splice(0,list1.length);
            list2.splice(0,list2.length);
            //list1.clear();
            //list2.clear();

            this._rootItem.getChildrenByType(list1, OS_RENDERITEM_TYPE.OS_GROUP_ITEM, false);
            copy._rootItem.getChildrenByType(list2, OS_RENDERITEM_TYPE.OS_GROUP_ITEM, false);
            let grp1:OsGraphicGroup|null = null;
            if(this._wimageGroup != null){
                grp1 = <OsGraphicGroup>this._wimageGroup.lock(false);
                if (grp1 != null) {

                    let index:number = 0;
                    let found:boolean = false;
                    //onis::graphics::item_list::iterator it1;
                    for(let i = 0;i < list1.length; i++){
                        if ((<OsGraphicGroup>list1[i]) == grp1) { found = true; break; }
                        else index++;
                    }
                    if (found) {

                        if (index >= 0 && index < list2.length) {

                            //it1 = list2.begin();
                            //std::advance(it1, index);
                            if(copy._wimageGroup != null) copy._wimageGroup.destroy();
                            copy._wimageGroup = (<OsGraphicGroup>list2[index]).getWeakObject();

                        }

                    }

                }
            }

            copy.regenerateAnnotationSegments();

            //copy._draw_target = _draw_target;
            //copy._draw_factor = _draw_factor;
            copy._saveFitCameraWidth = this._saveFitCameraWidth;
            copy._saveFitCameraRot = this._saveFitCameraRot;*/

    return copy;
  }

  OsGraphicItem? cloneItem(OsGraphicItem from) {
    OsGraphicItem? copy = from.clone();
    List<OsGraphicItem> list = from.getChildren();
    for (int i = 0; i < list.length; i++) {
      OsGraphicItem? item2 = cloneItem(list[i]);
      if (item2 != null) {
        item2.setParent(copy);
      }
    }
    return copy;
  }

  //-----------------------------------------------------------------------
  //visibility
  //-----------------------------------------------------------------------

  @override
  bool get hidden => _hidden;
  @override
  set hidden(bool value) {
    _hidden = value;
    pause(true);
  }

  //-----------------------------------------------------------------------
  //selection
  //-----------------------------------------------------------------------

  @override
  bool get selected => _selected;
  @override
  set selected(bool value) {
    _selected = value;
  }

  //-----------------------------------------------------------------------
  //fonts
  //-----------------------------------------------------------------------

  /*public getFont(target:number):any {
        if (target == 0 || target == 1) return this._fontInfo[target];
        return null;
    }

    public setFont(target:number, name:string, size:number, color:string) {
        if (target == 0 || target == 1) {
            this._fontInfo[target].name = name;
            this._fontInfo[target].size = size;
            this._fontInfo[target].color = color;
        }
    }*/

  //-----------------------------------------------------------------------
  //key
  //-----------------------------------------------------------------------

  bool isKey() {
    return _isKey;
  }

  void setKey(bool value) {
    _isKey = value;
  }

  //-----------------------------------------------------------------------
  //color lut
  //-----------------------------------------------------------------------

  void setColorLut(ColorLut? preset) {
    OsGraphicImage? item = getPrimaryImageItem();
    item?.setColorLut(preset);
  }

  ColorLut? getColorLut() {
    OsGraphicImage? item = getPrimaryImageItem();
    return item?.getColorLut();
  }

  //-----------------------------------------------------------------------
  //opacity table
  //-----------------------------------------------------------------------

  void setOpacityTable(OpacityTable? table) {
    OsGraphicImage? item = getPrimaryImageItem();
    item?.setOpacityTable(table);
  }

  OpacityTable? getOpacityTable() {
    OsGraphicImage? item = getPrimaryImageItem();
    return item?.getOpacityTable();
  }

  //-----------------------------------------------------------------------
  //window level
  //-----------------------------------------------------------------------

  void setWindowLevel(WindowLevel? preset, bool resetOriginal) {
    OsGraphicImage? item = getPrimaryImageItem();
    item?.setWindowLevel(preset, resetOriginal);
  }

  void setWindowLevelValues(double center, double width) {
    OsGraphicImage? item = getPrimaryImageItem();
    item?.setWindowLevelValues(center, width);
  }

  WindowLevel? getWindowLevel() {
    OsGraphicImage? item = getPrimaryImageItem();
    return item?.getWindowLevel();
  }

  ({double center, double width})? getWindowLevelValues() {
    OsGraphicImage? item = getPrimaryImageItem();
    return item?.getWindowLevelValues();
  }

  //-----------------------------------------------------------------------
  //convolution filter
  //-----------------------------------------------------------------------

  void setConvolutionFilter(ConvolutionFilter? preset) {
    OsGraphicImage? item = getPrimaryImageItem();
    item?.setConvolutionFilter(preset);
  }

  ConvolutionFilter? getConvolutionFilter() {
    OsGraphicImage? item = getPrimaryImageItem();
    return item?.getConvolutionFilter();
  }

  //-----------------------------------------------------------------------
  //camera
  //-----------------------------------------------------------------------

  OsGraphicCamera getCamera() {
    return _camera;
  }

  bool fitCamera(double cx, double cy) {
    OsGraphicImage? item = getPrimaryImageItem();
    if (item == null) return false;

    final List<double> realSize = [0, 0];
    if (!_calculateRealVisibleSizeAfterTransformation(item, realSize)) {
      return false;
    }
    final List<double> size = [0, 0];
    if (cx > cy) {
      //fit on Y Axis:
      size[1] = realSize[1];
      size[0] = (cx * size[1]) / cy;
      if (size[0] < realSize[0]) {
        //fit on X axis
        size[0] = realSize[0];
        size[1] = (cy * size[0]) / cx;
      }
    } else {
      //fit in X Axis:
      size[0] = realSize[0];
      size[1] = (cy * size[0]) / cx;
      if (size[1] < realSize[1]) {
        //fit on Y axis
        size[1] = realSize[1];
        size[0] = (cx * size[1]) / cy;
      }
    }
    _camera.pos[0] = 0.0;
    _camera.pos[1] = 0.0;
    _camera.pos[2] = 100.0;
    _camera.rot[0] = 0.0;
    _camera.rot[1] = 0.0;
    _camera.validateMatrix();
    _camera.setOrthoWidth(size[0]);
    _saveFitCameraRot = _camera.rot[2];
    _saveFitCameraWidth = _camera.getOrthoWidth();
    return true;
  }

  bool scaleCameraToOriginal(double cx, double cy) {
    OsGraphicImage? item = getPrimaryImageItem();
    entities.Image? image = item?.getImage();
    DicomFrame? frame = item?.getFrame(item.getCurrentFrame());
    if (image == null) return false;
    bool cameraValid = false;
    double orthoWidth = 0;
    //get the real size of the image:
    (int, int)? imageSize =
        frame == null ? image.getDimensions33() : frame.getDimensions();
    if (imageSize == null) return false;
    (double, double) realSize =
        (imageSize.$1.toDouble(), imageSize.$2.toDouble());

    ImageRegion? region;
    List<ImageRegion> regions = [];
    if (frame == null) {
      ImageRegionInfo? regionInfo = image.getRegionInfo();
      if (regionInfo != null) {
        for (ImageRegion region in regionInfo.regions) {
          regions.add(region);
        }
      }
    } else {
      image.getRegionsForFrame(frame, regions);
    }
    if (regions.length == 1) {
      ImageRegion tmp = regions[0];
      if (tmp.x0 == 0 &&
          tmp.y0 == 0 &&
          tmp.x1 == imageSize.$1 - 1 &&
          tmp.y1 == imageSize.$2 - 1 &&
          tmp.spatialFormat == OsRsf.twoDim &&
          tmp.calibratedUnit[0] == tmp.calibratedUnit[1]) {
        if (tmp.calibratedUnit[0] == OsUnit.cm ||
            tmp.calibratedUnit[0] == OsUnit.none) {
          region = tmp;
        }
      }
    }

    if (region != null) {
      realSize = (
        realSize.$1 * region.calibratedSpacing[0].abs(),
        realSize.$2 * region.calibratedSpacing[1].abs()
      );
    }

    List<double> pixelSpacing = [1.0, 1.0];
    if (region != null) {
      pixelSpacing[0] = realSize.$1 / imageSize.$1;
      pixelSpacing[1] = realSize.$2 / imageSize.$2;
    } else {
      pixelSpacing[0] = 1.0;
      pixelSpacing[1] = 1.0;
    }
    if (pixelSpacing[0] >= pixelSpacing[1]) {
      if (cx != 0) {
        orthoWidth = cx * pixelSpacing[0];
        cameraValid = true;
      }
    } else {
      if (cy != 0) {
        double tmp = cy * pixelSpacing[1];
        orthoWidth = cx * tmp / cy;
        cameraValid = true;
      }
    }
    if (!cameraValid) return false;
    _camera.pos[0] = 0.0;
    _camera.pos[1] = 0.0;
    _camera.pos[2] = 100.0;
    _camera.rot[0] = 0.0;
    _camera.rot[1] = 0.0;
    _camera.setOrthoWidth(orthoWidth);
    _camera.validateMatrix();
    return true;
  }

  void scaleCameraToRealSize(double cm, double cx, double cy, bool reset) {
    if (reset) {
      _camera.pos[0] = _camera.pos[1] = _camera.pos[2] = 0;
      _camera.rot[0] = _camera.rot[1] = _camera.rot[2] = 0;
      _camera.sca[0] = _camera.sca[1] = _camera.sca[2] = 1.0;
    }
    _camera.setOrthoWidth(cm);
    _camera.validateMatrix();
  }

  bool isFitCamera() {
    if (_saveFitCameraWidth != double.infinity) {
      if (sameF64(_camera.pos[0], 0.0) &&
          sameF64(_camera.pos[1], 0.0) &&
          sameF64(_camera.pos[2], 100.0) &&
          sameF64(_camera.rot[0], 0.0) &&
          sameF64(_camera.rot[1], 0.0) &&
          sameF64(_camera.rot[2], _saveFitCameraRot) &&
          sameF64(_camera.getOrthoWidth(), _saveFitCameraWidth)) {
        return true;
      }
    }
    return false;
  }

  bool resetCamera(double cx, double cy) {
    _camera.rot[0] = _camera.rot[1] = _camera.rot[2] = 0;
    _camera.sca[0] = _camera.sca[1] = _camera.sca[2] = 1.0;
    _camera.validateMatrix();
    return fitCamera(cx, cy);
  }

  //-----------------------------------------------------------------------
  //scope
  //-----------------------------------------------------------------------

  void showScope(double x, double y) {
    _showScope = true;
    _scopeX = x;
    _scopeY = y;
  }

  void hideScope() {
    _showScope = false;
  }

  bool isScopeHidden() {
    return !_showScope;
  }

  void setScopeFactor(double factor) {
    _scopeFactor = factor;
  }

  double getScopeFactor() {
    return _scopeFactor;
  }

  //-----------------------------------------------------------------------
  //render items
  //-----------------------------------------------------------------------
  void getImageItems(List<OsGraphicImage> list) {
    OsGraphicGroup? grp = getImageGroupItem();
    grp?.getChildrenByType(list, OsRenderItemType.osImageItem, true);
  }

  OsGraphicImage? getActiveImageItem() {
    return _wactiveImg?.target;
  }

  @override
  OsGraphicImage? getPrimaryImageItem() {
    return _wprimaryImg?.target;
  }

  OsGraphicGroup getRootItem() {
    return _rootItem;
  }

  OsGraphicGroup? getImageGroupItem() {
    return _wimageGroup?.target;
  }

  OsGraphicGroup? getAnnotationGroupItem() {
    return _wannotationGroup?.target;
  }

  void setPrimaryImageItem(OsGraphicImage? img) {
    _wprimaryImg = img != null ? WeakReference<OsGraphicImage>(img) : null;
  }

  void setActiveImageItem(OsGraphicImage? img) {
    _wactiveImg = img != null ? WeakReference<OsGraphicImage>(img) : null;
  }

  //-----------------------------------------------------------------------
  //loaded
  //-----------------------------------------------------------------------

  void setPreloaded(bool value) {
    _preloaded = value;
  }

  bool isPreloaded() {
    return _preloaded;
  }

  bool checkPreloaded() {
    bool ret = false;
    OsGraphicImage? img = getPrimaryImageItem();
    if (img != null) {
      if (img.getFrame(0) == null) {
        if (_preloaded) {
          _preloaded = false;
          ret = true;
        }
      } else {
        if (!_preloaded) {
          _preloaded = true;
          ret = true;
        }
      }
    }
    return ret;
  }

  //-----------------------------------------------------------------------
  //localizer
  //-----------------------------------------------------------------------

  bool setShouldDrawLocalizer(bool draw, entities.Study? study,
      entities.Series? series, OsMatrix? mat, List<double>? dimensions) {
    bool ret = false;
    if (_drawLocalizer != draw) ret = true;
    if (!ret && draw && mat != null) {
      if (_wLocalizerStudy == null ||
          _wLocalizerStudy?.target != study ||
          _wLocalizerSeries == null ||
          _wLocalizerSeries?.target != series ||
          dimensions == null ||
          _localizerSize[0] != dimensions[0] ||
          _localizerSize[1] != dimensions[1]) {
        ret = true;
      }
    }
    _drawLocalizer = draw;
    _wLocalizerStudy =
        study != null ? WeakReference<entities.Study>(study) : null;
    _wLocalizerSeries =
        series != null ? WeakReference<entities.Series>(series) : null;
    if (mat != null) _localizerMat.copyFrom(mat);
    if (dimensions != null) {
      _localizerSize[0] = dimensions[0];
      _localizerSize[1] = dimensions[1];
    }
    return ret;
  }

  //-----------------------------------------------------------------------
  //draw
  //-----------------------------------------------------------------------

  @override
  void willDraw(OsWillDrawInfo info) {
    /*_autoSizeHide = 0;
      if (_shouldAutoHideAnnotations) {
        
      }*/

    if (_saveFitCameraWidth != double.infinity) {
      if (sameF64(_camera.pos[0], 0.0) &&
          sameF64(_camera.pos[1], 0.0) &&
          sameF64(_camera.pos[2], 100.0) &&
          sameF64(_camera.rot[0], 0.0) &&
          sameF64(_camera.rot[1], 0.0) &&
          sameF64(_camera.rot[2], _saveFitCameraRot) &&
          sameF64(_camera.getOrthoWidth(), _saveFitCameraWidth)) {
        //we fit the camera!
        fitCamera(info.viewport[2], info.viewport[3]);
      }
    }

    _info.render = this;
    _rootItem.willDraw(info, true);

    /*let imageItems:OsGraphicImage[] = [];
        this.getImageItems(imageItems);
        

        //do we need to draw the movie controller?
        if (!this._movieToolbar) this._movieToolbar = new OsMovieToolbar("Movie controller");
        this._movieToolbar.visible = false;

        //get the frame count:
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let frameCount:number = item ? item.getFrameCount() : 0;
        if (info.mouse[0] != 0 || info.mouse[1] != 0) {

            if (this.isMpeg() || frameCount > 1) {

                let mouseHasMoved:boolean = false;
                let mouseIsInsideToolbar:boolean = false;
                if (info.mouse[0] >= 0 && info.mouse[0] < info.viewport[2] && 
                    info.mouse[1] >= 0 && info.mouse[1] < info.viewport[3]) {
                
                    //the mouse is inside the viewport:
                    if (info.mouse[0] != this._previousMousePosition[0] || info.mouse[1] != this._previousMousePosition[1]) 
                        mouseHasMoved = true;

                }
                if (!mouseHasMoved) {

                    if (this._movieToolbar.isMouseInsideToolbar(info.viewport, info.mouse)) {

                        mouseIsInsideToolbar = true;

                    }

                }
                if (mouseHasMoved || mouseIsInsideToolbar || this._movieToolbar.isRunning()) {
                    
                    
                    if (this._drawTarget != OsContDrawTarget.OS_DRAW_TARGET_PRINTER && this._drawTarget != OsContDrawTarget.OS_DRAW_TARGET_PRINT_PREVIEW_CONTAINER) {

                        this._movieToolbar.visible = true;
                        this._showMoveControllerTime = Date.now();
                        this._previousMousePosition[0] = info.mouse[0];
                        this._previousMousePosition[1] = info.mouse[1];

                    }

                }
                else {

                    if (Date.now() - this._showMoveControllerTime < 2000) 
                        this._movieToolbar.visible = true;
        
                }

                if (!this._multiframePlayInfo) {

                    if (this.isBuffering(null)) {

                        this._movieToolbar.visible = true;

                    }

                }
                else 
                if (this.isBuffering(null)) {
                    if (this._multiframePlayInfo.bufferingFrameDone < this._multiframePlayInfo.bufferingFrameCount) {
                        if (this.preloadFrameForPlay(this._multiframePlayInfo.bufferingFrameDone)) this._multiframePlayInfo.bufferingFrameDone++;
                        if (this._multiframePlayInfo.bufferingFrameCount == 0) this._multiframePlayInfo.bufferingProgress = 0.0;
                        else this._multiframePlayInfo.bufferingProgress = this._multiframePlayInfo.bufferingFrameDone / this._multiframePlayInfo.bufferingFrameCount;
                    }
                    else 
                    if (this._multiframePlayInfo.firstTime) {
                        this._multiframePlayInfo.firstTime = false;
                        this._multiframePlayInfo.playBaseTime = Date.now();//info->render->application()->get_time();
                        this._multiframePlayInfo.playOffset = 0;
                        if (item) this._multiframePlayInfo.playOffset = item.getCurrentFrame();
                    }
                    this._movieToolbar.visible = true;
                    this._showMoveControllerTime = Date.now() - 10000;
                }
                else 
                if (item && this._multiframePlayInfo.isPlaying) {
                    let speed:number = this.getPlaySpeed();
                    let currentFrame:number = item?item.getCurrentFrame():0;
                    let nextFrame:number = currentFrame;
                    if (this._multiframePlayInfo.playOffset == -1.0 || speed == -1.0) {
                        nextFrame++;
                        if (nextFrame >= (item?item.getFrameCount():0))
                            nextFrame = 0;
                    }
                    else 
                    if (this._multiframePlayInfo.firstTime) {
                        this._multiframePlayInfo.firstTime = false;
                        this._multiframePlayInfo.playBaseTime = Date.now();//info->render->application()->get_time();
                        this._multiframePlayInfo.playOffset = 0;
                        if (item) this._multiframePlayInfo.playOffset = item.getCurrentFrame();
                    }
                    else {
                        let ellapse:number = (Date.now() - this._multiframePlayInfo.playBaseTime) * 0.001;
                        let frameCount:number = Math.round(Math.floor(ellapse * this.getPlaySpeed() + this._multiframePlayInfo.playOffset));
                        nextFrame = frameCount % item.getFrameCount();
                    }
                    item.setCurrentFrame(nextFrame);
                }
                
                this._movieToolbar.visible = true;
                if (this._movieToolbar.visible) {
                    //onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
                    //_movie_toolbar->set_mpeg_decoder(decoder);
                    this._movieToolbar.setRenderer(info.render);
                }

            }

        }

        if (!this._preloaded) {
            this._preloaded = true;
            for (let i=0; i<imageItems.length; i++) {
                if (imageItems[i].getLoadStatus().status == RESULT.OSRSP_PENDING || 
                    imageItems[i].getLoadStatus().status == RESULT.OSRSP_WAITING) {
                    this._preloaded = false;
                    break;
                }
                else {
                    let count:number = imageItems[i].getFrameCount();
                    for (let j=0; j<count; j++) {
                        let frame:OsDicomFrame|null = imageItems[i].getFrame(i);
                        if (frame) {
                            let data:OsIntermediatePixelData|null = frame.getIntermediatePixelData();
                            if (!data) this._preloaded = false;
                            else if (!data.resCount) this._preloaded = false;
                            else if (data.resCount != data.resIndex+1) this._preloaded = false;
                            break;
                        }
                    }
                }
            }
        }

    
        //will_draw_streaming_information(info);
        this.willDrawDicomAnnotations(info);*/
    willDrawWarningMessages(info);
    /*this.willDrawRuler(info);
        this.willDrawMovieController(info);*/

    _info.render = null;
  }

  /*public willDrawMovieController(info:OsWillDrawInfo):void {
        if (this._movieToolbar)
            if (this._movieToolbar.visible) 
                this._movieToolbar.willDraw(info, true);
    }*/

  void willDrawWarningMessages(OsWillDrawInfo info) {
    if (info.context == null) return;
    OsGraphicImage? img = getPrimaryImageItem();
    if (img != null) {
      removeWarningMessage("", img);
      OsResult result = img.getDrawStatus();
      if (result.info.isNotEmpty) {
        addWarningMessage(result.info, img);
      } else {
        if (result.status == ResultStatus.waiting ||
            result.status == ResultStatus.pending) {
          addWarningMessage('Downloading...', img);
        } else if (result.status == ResultStatus.failure) {
          addWarningMessage('Error ${result.reason}', img);
        }
      }
    }

    if (_warningMessages.isEmpty) return;

    if (type == null) return;

    String fontName = '';
    int fontSize = 12;
    List<int> fontColor = [255, 255, 255];

    /*let fontInfo:any = this.getFont(0);
    if (fontInfo) {
      fontSize = fontInfo.size;
      fontName = fontInfo.name;
      fontColor = fontInfo.color;
    }*/
    //let driver:OsDriver|null = info.context ? info.context.getDriver() : null;
    //  if (driver) {

    OsDriver? driver = info.context?.driver;
    if (driver == null) return;

    for (int i = 0; i < _warningMessages.length; i++) {
      if (_warningMessages[i].haveData) {
        if (_warningMessages[i].wdata?.target == null) {
          _warningMessages.removeAt(i);
          i--;
          continue;
        }
      }
      if (_warningMessages[i].text.isNotEmpty) {
        OsDriverText? dtext = info.context
            ?.findText(type!, _warningMessages[i].text, fontName, fontSize);
        dtext ??=
            driver.createText(fontName, fontSize.toDouble(), "", false, null);

        if (dtext != null) {
          dtext.antialiasing = false;
          dtext.text = _warningMessages[i].text;
          bool valid = info.context!.registerText(dtext, type!);
          if (!valid) {
            dtext = null;
          }
          if (dtext != null) {
            dtext.setColor4i(255, 255, 255, 255);
            dtext.willDraw(info.context!);
          }
        }
      }
    }
  }

  /*public willDrawRuler(info:OsWillDrawInfo):void {
        let driver:OsDriver|null = null;
        if (info.context) driver = info.context.getDriver();
        if (!driver) return;
        let fontSize:number = 10;
        let fontName:string = '';
        let type:OsRendererType|null = this.getType();
        let viewer:Viewer|null = type?type.getViewer():null;
        if (!type || !viewer) return;
        let fontInfo:any = viewer?viewer.getCurrentFont(0):null;
        if (fontInfo) {
            fontSize = fontInfo.size;
            fontName = fontInfo.name;
            //driver.setColor3h(fontInfo.color);
        }
        let text:string[] = ["mm", "cm", "dm", "px"];
        for (let i=0; i<4; i++) {
            let dtext:OsDriverText|null = info.context?info.context.findText(type, text[i], fontName, fontSize, true):null;
            if (!dtext) {
                dtext = driver.createText(fontName, fontSize, "", false, null);
                if (dtext) {
                    dtext.useAntialiasing(false);
                    dtext.setText(text[i]);
                    let valid:boolean = info.context?info.context.registerText(dtext, type):false;
                    if (!valid) {
                        dtext.release();
                        dtext = null;
                    }
                }
            }
            if (dtext) {
                dtext.setColor3h(fontInfo?fontInfo.color:'#ffffff');
                dtext.setText(text[i]);
                if (info.context) dtext.willDraw(info.context);
            }
            if (dtext) dtext.release();
        }
    }

    public willDrawDicomAnnotations(info:OsWillDrawInfo):void {
        if (!this._shouldDisplayDicom) return;

        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image = img ? img.getImage() : null;        
        if (!image) return;

        let tmp:[OsDbAnnotationSet|null] = [null];
        this.shouldDisplayDicomAnnotations(tmp);
        let annotSet:OsDbAnnotationSet|null = tmp[0];

        if (!annotSet) return;
        
        let driver:OsDriver|null = null;
        if (info.context) driver = info.context.getDriver();
        if (!driver) return;
        
        let series:OsOpenedSeries|null = image.getParent(false);
        let dbseries:OsDbSeries|null = series ? series.getDatabaseInfo() : null;
        let modalityName:string = dbseries ? dbseries.modality : '';

        let dynamicList:OsDriverCharacterList|null = info.context?info.context.findCharacterList('DICOM'):null;
        let modality:OsAnnotationModality|null = annotSet.findModality(modalityName);
        if (!modality) modality = annotSet.getDefaultModality();
        else if (modality.sameAsDefault()) modality = annotSet.getDefaultModality();
        
        if (modality != null) {
            info.render = this;
            let type:OsRendererType|null = this.getType();
            let viewer:Viewer|null = type?type.getViewer():null;
            let fontSize:number = 12;
            let fontName:string = '';
            let fontColor:string = '#ffffff';
            let fontInfo:any = this.getFont(0);
            if (fontInfo) {
                fontSize = fontInfo.size;
                fontName = fontInfo.name;
                fontColor = fontInfo.color;
            }
            let additionalRows:number[] = [0, 0, 0, 0, 0, 0, 0, 0];
            let orientation:string[] = ['', '', '', '', '', '', '', ''];
            if (modality.shouldShowOrientation()) {
                let ltrb:string[] = ['', '', '', ''];
                if (this.getImageOrientationInView(info.viewport[2], info.viewport[3], ltrb)) {
                    orientation[OsAsContainer.asleft] = ltrb[0];
                    orientation[OsAsContainer.astop] = ltrb[1];
                    orientation[OsAsContainer.asright] = ltrb[2];
                    orientation[OsAsContainer.asbottom] = ltrb[3];
                    additionalRows[OsAsContainer.asleft] += 1;
                    additionalRows[OsAsContainer.astop] += 1;
                    additionalRows[OsAsContainer.asright] += 1;
                    additionalRows[OsAsContainer.asbottom] += 1;
                }
            }
            for (let i:number=0; i<8; i++) {
                let container:OsAnnotationContainer|null = modality.getContainer(i);
                if (container) {
                    let annotItems:OsAnnotationItem[] = container.getItems();
                    if (annotItems) {
                        let count:number = annotItems.length;
                        this._dicomAnnotationBoxes[i].setItemCount(count+additionalRows[i]);
                        let it2:number = 0;
                        if (additionalRows[i] > 0 && orientation[i].length) {
                            let to:OsGraphicDicomAnnotationText = this._dicomAnnotationBoxes[i].list[it2]; it2++;
                            this.willDrawDicomAnnotation(driver, info.context, type, to, orientation[i], false, fontName, fontSize, fontColor, null);
                        }
                        if (i == OsAsContainer.asbottom_left || i == OsAsContainer.asbottom || i == OsAsContainer.asright) {
                            let it1:number = annotItems.length-1;
                            while (it1 >= 0 && it2 != this._dicomAnnotationBoxes[i].list.length) {
                                let from:OsAnnotationItem = annotItems[it1];
                                let to:OsGraphicDicomAnnotationText = this._dicomAnnotationBoxes[i].list[it2];
                                it1--; it2++;
                                let dynamic:[boolean] = [false];
                                let textToRender:string = from.getRenderingText(info, dynamic);
                                this.willDrawDicomAnnotation(driver, info.context, from, to, textToRender, dynamic[0], fontName, fontSize, fontColor, dynamicList);
                            }
                        }
                        else {
                            let it1:number = 0;
                            while (it1 != annotItems.length && it2 != this._dicomAnnotationBoxes[i].list.length) {
                                let from:OsAnnotationItem = annotItems[it1];
                                let to:OsGraphicDicomAnnotationText = this._dicomAnnotationBoxes[i].list[it2];
                                it1++; it2++;
                                let dynamic:[boolean] = [false];
                                let textToRender:string = from.getRenderingText(info, dynamic);
                                this.willDrawDicomAnnotation(driver, info.context, from, to, textToRender, dynamic[0], fontName, fontSize, fontColor, dynamicList);
                            }
                        }
                    }
                }
            }
        }
    }
    
    public willDrawDicomAnnotation(driver:OsDriver, ctx:OsDriverContext|null, from:OsStrongObject|null, to:OsGraphicDicomAnnotationText, text:string, dynamic:boolean, fontName:string, fontSize:number, fontColor:string, dynamicList:OsDriverCharacterList|null):void {
        if (!ctx ||!from) return;
        let dtext:OsDriverText|null = ctx.findText(from, text, fontName, fontSize, true);
        if (!dtext) {
            if (dynamic) dtext = driver.createText(fontName, fontSize, '', true, dynamicList);
            else dtext = driver.createText(fontName, fontSize, '', false, null);
            if (dtext) {
                dtext.useAntialiasing(false);
                dtext.setText(text);
                let valid:boolean = ctx.registerText(dtext, from);
                if (!valid) {
                    dtext.release();
                    dtext = null;
                }
            }
        }
        if (dtext) {
            dtext.setColor3h(fontColor);
            if (!dynamic) dtext.setText(text);
            dtext.willDraw(ctx);
        }
        to.setDriverText(dtext);
        if (dtext) dtext.release();
        if (dynamic) to.dynamicText = text;
        else to.dynamicText = '';
    }*/

  @override
  void draw(OsDriver driver) {
    bool cameraValid = true;
    /*_wantRefreshAsSoonAsPossible = false;
        if (!this._camera) return;*/

    _info.render = this;

    //Get the viewport size:
    List<double> viewport = [0, 0, 0, 0];
    driver.getViewport(viewport);
    double ratio = (viewport[2] != 0) ? viewport[3] / viewport[2] : 1.0;

    List<double> originalClipArea = [0, 0, 0, 0];
    if (driver.isClippingEnabled()) {
      driver.getClipArea(originalClipArea);
    } else {
      for (int i = 0; i < 4; i++) {
        originalClipArea[i] = viewport[i];
      }
    }

    //if the renderer is selected, we need to leave a white border:
    if (_selected) {
      driver.setClearColor4i(_selCol[0], _selCol[1], _selCol[2], _selCol[3]);
      driver.clearBuffers();
      if (driver.isClippingEnabled()) {
        List<double> clipArea = [0, 0, 0, 0];
        driver.getClipArea(clipArea);
        clipArea[0] += 1.0;
        clipArea[1] += 1.0;
        clipArea[2] -= 2.0;
        clipArea[3] -= 2.0;
        driver.pushClipping(clipArea[0], clipArea[1], clipArea[2], clipArea[3]);
      } else {
        driver.pushClipping(
            viewport[0] + 1, viewport[1] + 1, viewport[2] - 2, viewport[3] - 2);
      }
    }

    if (_isKey && _drawTarget == OsContDrawTarget.osDrawTargetScreen) {
      driver.setClearColor4i(_keyCol[0], _keyCol[1], _keyCol[2], _keyCol[3]);
      driver.clearBuffers();
      if (driver.isClippingEnabled()) {
        List<double> clipArea = [0, 0, 0, 0];
        driver.getClipArea(clipArea);
        clipArea[0] += 2.0;
        clipArea[1] += 2.0;
        clipArea[2] -= 4.0;
        clipArea[3] -= 4.0;
        driver.pushClipping(clipArea[0], clipArea[1], clipArea[2], clipArea[3]);
      } else {
        driver.pushClipping(
            viewport[0] + 1, viewport[1] + 1, viewport[2] - 2, viewport[3] - 2);
      }
    }

    //Clear the buffers:
    driver.setClearColor4i(_backCol[0], _backCol[1], _backCol[2], _backCol[3]);
    driver.clearBuffers();

    if (cameraValid) {
      //Set the projection matrix:
      _info.projMat.copyFrom(_camera.getProjectionMatrix(ratio));
      _camera.getWorldInvertMatrix(_info.viewMat, null);

      //refresh World, WordInv, etc...
      _updateWorldMatrices();

      //ok, we can draw the scene now:
      _rootItem.draw(driver, _info);

      //draw the localizer:
      //this.drawLocalizer(driver, viewport);

      //draw the ruler:
      //this.drawRulers(driver, viewport);

      //draw the streaming information:
      //draw_streaming_information(driver, viewport);
      //now we draw the image annotations:
      /*if (this._shouldDisplayGraphics) {
                let images:OsGraphicImage[] = [];
                this.getImageItems(images);
                for (let i=0; i<images.length; i++) 
                    images[i].drawAnnotations(driver, this._info);
            }*/

      //Draw the dicom annotations:
      //this.drawDicomAnnotations(driver, viewport);

      //Draw the warning messages:
      drawWarningMessages(driver, viewport);

      //draw the movie controller:
      /*this.drawMovieController(driver, viewport);

            if (this._showScope) {
                driver.resetTransform();
                let cx:number = 250;
                let cy:number = 250;
                let scopeViewport:[number, number, number, number] = [0, 0, 0, 0];
                scopeViewport[0] = viewport[0]+this._scopeX-cx*0.5;
                scopeViewport[1] = originalClipArea[1] + this._scopeY - cy*0.5;
                scopeViewport[2] = cx;
                scopeViewport[3] = cy;
                let currentClipArea:[number, number, number, number] = [0, 0, 0, 0];
                driver.getClipArea(currentClipArea);
                let newClipArea:[number, number, number, number] = [0, 0, 100, 100];
                newClipArea[0] = viewport[0]+this._scopeX-cx*0.5;
                newClipArea[1] = originalClipArea[1] + this._scopeY - cy*0.5;
                newClipArea[2] = scopeViewport[2];
                newClipArea[3] = scopeViewport[3];
                if (newClipArea[0] < currentClipArea[0]) newClipArea[0] = currentClipArea[0];
                let right:number = scopeViewport[0] + scopeViewport[2];
                if (right > currentClipArea[0]+currentClipArea[2]) right = currentClipArea[0]+currentClipArea[2];
                newClipArea[2] = right - newClipArea[0];
                if (newClipArea[1] < currentClipArea[1]) newClipArea[1] = currentClipArea[1];
                let bottom:number = scopeViewport[1] + scopeViewport[3];
                if (bottom > currentClipArea[1]+currentClipArea[3]) bottom = currentClipArea[1]+currentClipArea[3];
                newClipArea[3] = bottom - newClipArea[1];
                if (newClipArea[2] > 0 && newClipArea[3] > 0) {
                    let prevViewport:[number, number, number, number] = [0, 0, 0, 0];
                    driver.getViewport(prevViewport);
                    driver.pushClipping(newClipArea[0], newClipArea[1], newClipArea[2], newClipArea[3]);
                    driver.setViewport(scopeViewport[0], scopeViewport[1], scopeViewport[2], scopeViewport[3]);
                    driver.setClearColor4i(this._backCol[0], this._backCol[1], this._backCol[2], this._backCol[3]);
                    driver.clearBuffers();
                    let saveOrtho:number = this._camera.getOrthoWidth();
                    let savePosx:number = this._camera.pos[0];
                    let savePosy:number = this._camera.pos[1];
                    //the screen pixel position should be the center of the camera!
                    let win:[number, number, number] = [0, 0, 0];
                    let obj:[number, number, number] = [0, 0, 0];
                    win[0] = this._scopeX;
                    win[1] = this._scopeY;
                    win[2] = 0.0;
                    let projection:OsMatrix = this._camera.getProjectionMatrix(ratio);
                    let modelView:OsMatrix = new OsMatrix();
                    this._camera.getWorldInvertMatrix(modelView, null);
                    if (OsVec3D.unproject(win, modelView, projection, viewport, obj)) {
                        ratio = scopeViewport[2] / viewport[2];
                        this._camera.setOrthoWidth(this._camera.getOrthoWidth()*ratio*(1.0/this._scopeFactor));
                        this._camera.pos[0] = obj[0];
                        this._camera.pos[1] = obj[1];
                        this._camera.validateMatrix();
                        ratio = (scopeViewport[2]) ? scopeViewport[3]/scopeViewport[2] : 1.0;
                        this._info.projMat.copyFrom(this._camera.getProjectionMatrix(ratio));
                        this._camera.getWorldInvertMatrix(this._info.viewMat, null);
                        //refresh World, WordInv, etc...
                        this._updateWorldMatrices();
                        //ok, we can draw the scene now:
                        if (this._rootItem) this._rootItem.draw(driver, this._info);
                        //now we draw the image annotations:
                        if (this._shouldDisplayGraphics) {
                            let images:OsGraphicImage[] = [];
                            this.getImageItems(images);
                            for (let i:number = 0; i < images.length; i++) 
                                images[i].drawAnnotations(driver, this._info);
                        }
                        this._camera.setOrthoWidth(saveOrtho);
                        this._camera.pos[0] = savePosx;
                        this._camera.pos[1] = savePosy;
                        this._camera.validateMatrix();
                    }
                    driver.popClipping();
                    driver.setViewport(prevViewport[0], prevViewport[1], prevViewport[2], prevViewport[3]);
                }*/
    }

    _info.render = null;

    /*if (isKey && _drawTarget == OsContDrawTarget.osDrawTargetScreen) {
      driver.popClipping();
    }*/

    if (selected) {
      driver.popClipping();
    }
  }

  /*public setDrawTarget(target:number, factor:number):void {
        this._drawTarget = target;
        this._drawFactor = factor;
    }
    
    public getDrawTarget():number {
        return this._drawTarget;
    }
    
    public getDrawFactor():number {
        return this._drawFactor;
    }

    //virtual onis::bitmap_ptr draw_in_bitmap(s32 width, s32 height) = 0;

    public drawInBitmap(width:number, height:number):OsOffscreenCanvas|null {
        let type:OsRendererType|null = this.getType();
        let viewer:Viewer|null = type?type.getViewer():null;
        if (!viewer || width <= 0 || height <= 0) return null;
        let driver:OsDriver|null = viewer.getGraphicManager().findDriver('WEBCANVAS');
        if (driver) {
            let canvas:OsOffscreenCanvas = new OsOffscreenCanvas(width, height);
            let param:OsDriverContextParam = new OsDriverContextParam();
            //param.setOffscreenCanvas(canvas);
            let context:OsDriverContext|null = driver.createContext(param);
            if (context && canvas.attachContext(context)) {
                driver.setCurrentContext(context);
                driver.setViewport(0, 0, width, height);
                driver.setClearColor4i(0, 0, 0, 255);
                
                let rinfo:OsWillDrawInfo = new OsWillDrawInfo();
                rinfo.render = this;//clone();        
                rinfo.context = context;
                rinfo.viewport[0] = 0;
                rinfo.viewport[1] = 0;
                rinfo.viewport[2] = width;
                rinfo.viewport[3] = height;

                //driver. enable_clipping(OSFALSE);
                rinfo.render.willDraw(rinfo);
                rinfo.render.draw(driver);
                context.swappBuffers();
                driver.setCurrentContext(null);
                //rinfo.destroy();
                context.destroy();
                return canvas;
                
            }
        }
        return null;
    }

    public drawMovieController(driver:OsDriver, viewport:number[]) {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
    
            //onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            //if (decoder != NULL) {
    
              //  if (decoder->is_buffering(NULL) || !decoder->is_paused())
                //    _want_refresh_asap = OSTRUE;
    
            //}
            //else
            if (this._multiframePlayInfo)
                if (this._multiframePlayInfo.isPlaying)
                    this._wantRefreshAsap = true;
    
        }
    
        if (this._movieToolbar) {
    
            if (this._movieToolbar.visible) {
    
                let rinfo:OsRenderInfo = new OsRenderInfo(this);
                rinfo.projMat.buildOrthographicProjectionMatrixRH(0, viewport[2], 0, viewport[3], -100, 100);
                this._movieToolbar.draw(driver, rinfo);
                this._wantRefreshAsap = true;
    
            }
        
        }
        
    }

    public drawLocalizer(driver:OsDriver, viewport:[number, number, number, number]) {
	    if (!this._drawLocalizer) return;
        let localizerStudy:OsOpenedStudy|null = this._wLocalizerStudy?<OsOpenedStudy>this._wLocalizerStudy.lock(false):null;
        let localizerSeries:OsOpenedSeries|null = this._wLocalizerSeries?<OsOpenedSeries>this._wLocalizerSeries.lock(false):null;
        if (!localizerStudy || !localizerSeries) return;  
        let type:OsRendererType|null = this.getType();
        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image:OsOpenedImage|null = img?img.getImage():null;
        let series:OsOpenedSeries|null = image?image.getParent(false):null;
        let study:OsOpenedStudy|null = series?series.getParent(false):null;
        if (study === localizerStudy) {
            if (series !== localizerSeries) {
                let mat:OsMatrix = new OsMatrix();
                if (image && img) {
                    if (image.getImageOrientation(mat)) {
                        let matWorldToImage:OsMatrix = new OsMatrix();
                        matWorldToImage.copyFrom(mat);
                        matWorldToImage.invert();
                        let pd:number = OsVec3D.scalarProductWidthOffset(mat.mat, 8, this._localizerMat.mat, 8);                        
                        if (Math.abs(1.0-Math.abs(pd)) > 0.016) {
                            //we need to bring the 4 points of the localizer image into our image world:
                            let A:[number, number, number] = [0, 0, 0];
                            let B:[number, number, number] = [0, 0, 0];
                            let C:[number, number, number] = [0, 0, 0];
                            let D:[number, number, number] = [0, 0, 0];
                            let P:[number, number, number] = [0, 0, 0];
                            B[0] = this._localizerSize[0]; B[1] = 0.0; B[2] = 0.0;
                            C[0] = this._localizerSize[0]; C[1] = this._localizerSize[1]; C[2] = 0.0;
                            D[0] = 0.0; D[1] = this._localizerSize[1]; D[2] = 0.0;
                            OsVec3D.multiplyByMatrix(A, this._localizerMat, P);
                            OsVec3D.multiplyByMatrix(P, matWorldToImage, A);
                            OsVec3D.multiplyByMatrix(B, this._localizerMat, P);
                            OsVec3D.multiplyByMatrix(P, matWorldToImage, B);
                            OsVec3D.multiplyByMatrix(C, this._localizerMat, P);
                            OsVec3D.multiplyByMatrix(P, matWorldToImage, C);
                            OsVec3D.multiplyByMatrix(D, this._localizerMat, P);
                            OsVec3D.multiplyByMatrix(P, matWorldToImage, D);
                            //now, we need to calculate the intersections points of the 4 segments (AB, BC, CD, DA) with our image plane
                            //our plane equation is simply "z=0" because we are working in the image world!
                            let inter:[[number, number, number], [number, number, number], [number, number, number], [number, number, number]] = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
                            let valid:[boolean, boolean, boolean, boolean] = [false, false, false, false];
                            let P1:[number, number, number] = [0, 0, 0];
                            let P2:[number, number, number] = [0, 0, 0];
                            for (let i:number=0; i<4; i++) {
                                switch(i) {
                                case 0: P1[0] = A[0]; P1[1] = A[1]; P1[2] = A[2]; P2[0] = B[0]; P2[1] = B[1]; P2[2] = B[2]; break;
                                case 1: P1[0] = B[0]; P1[1] = B[1]; P1[2] = B[2]; P2[0] = C[0]; P2[1] = C[1]; P2[2] = C[2]; break;
                                case 2: P1[0] = C[0]; P1[1] = C[1]; P1[2] = C[2]; P2[0] = D[0]; P2[1] = D[1]; P2[2] = D[2]; break;
                                case 3: P1[0] = D[0]; P1[1] = D[1]; P1[2] = D[2]; P2[0] = A[0]; P2[1] = A[1]; P2[2] = A[2]; break;
                                default: break;
                                }
                                let k:number = 0;
                                let l:number = P2[2] - P1[2];
                                if (l != 0) { 
                                    k = -P1[2]/l; 
                                    if (k >= 0 && k <= 1) {
                                        inter[i][0] = k*(P2[0] - P1[0]) + P1[0];
                                        inter[i][1] = k*(P2[1] - P1[1]) + P1[1];
                                        inter[i][2] = k*(P2[2] - P1[2]) + P1[2];
                                        valid[i] = true;
                                    }
                                }
                            }
                            //we need two winner points:
                            let winner1:number = -1;
                            let winner2:number = -1;
                            for (let i:number=0; i<4; i++) {
                                if (!valid[i]) continue;
                                if (winner1 == -1) winner1 = i;
                                else if (winner2 == -1) winner2 = i;
                                else {
                                    winner1 = -1;
                                    winner2 = -1;
                                    break;
                                }
                            }
                            if (winner1 != -1 && winner2 != -1) {
                                //bring back the coordinates in the image world (-0.5, 0.5):
                                //for that, we need to get the real size of the image:
                                let info:OsImageRegionInfo|null = image.getRegionInfo();
                                if (info) {
                                    if (info.regions.length == 1) {
                                        let region:OsImageRegion = info.regions[0];
                                        if (region.spatialFormat == OS_RSF.NONE || region.spatialFormat == OS_RSF.TWO_DIM)
                                        if (region.calibratedUnit[0] == region.calibratedUnit[1]) {
                                            if (region.calibratedUnit[0] == OS_UNIT.CM) {
                                                let realSize:[number, number] = [0, 0];
                                                realSize[0] = info.dimensions[0] * Math.abs(region.calibratedSpacing[0]) * 10.0;
                                                realSize[1] = info.dimensions[1] * Math.abs(region.calibratedSpacing[1]) * 10.0;
                                                if (realSize[0] > 0 && realSize[1] > 0) {
                                                    //Get the coordinates in the range [-0.5, 0.5]:
                                                    A[0] = inter[winner1][0] / realSize[0] - 0.5;
                                                    A[1] = inter[winner1][1] / realSize[1] - 0.5;
                                                    A[2] = 0.0;
                                                    B[0] = inter[winner2][0] / realSize[0] - 0.5;
                                                    B[1] = inter[winner2][1] / realSize[1] - 0.5;
                                                    B[2] = 0.0;
                                                    A[1] = -A[1];
                                                    B[1] = -B[1];
                                                    //we project A and B on the screen:
                                                    let imageMatrix:OsMatrix = new OsMatrix();
                                                    img.getWorldMatrix(imageMatrix);
                                                    A[0] = imageMatrix.mat[0]*A[0] + imageMatrix.mat[4]*A[1] + imageMatrix.mat[8]*A[2] + imageMatrix.mat[12];
                                                    A[1] = imageMatrix.mat[1]*A[0] + imageMatrix.mat[5]*A[1] + imageMatrix.mat[9]*A[2] + imageMatrix.mat[13];
                                                    A[2] = imageMatrix.mat[2]*A[0] + imageMatrix.mat[6]*A[1] + imageMatrix.mat[10]*A[2] + imageMatrix.mat[14];
                                                    B[0] = imageMatrix.mat[0]*B[0] + imageMatrix.mat[4]*B[1] + imageMatrix.mat[8]*B[2] + imageMatrix.mat[12];
                                                    B[1] = imageMatrix.mat[1]*B[0] + imageMatrix.mat[5]*B[1] + imageMatrix.mat[9]*B[2] + imageMatrix.mat[13];
                                                    B[2] = imageMatrix.mat[2]*B[0] + imageMatrix.mat[6]*B[1] + imageMatrix.mat[10]*B[2] + imageMatrix.mat[14];
                                                    let win1:[number, number, number] = [0, 0, 0];
                                                    let win2:[number, number, number] = [0, 0, 0];
                                                    let modelView:OsMatrix = new OsMatrix();
                                                    this._camera.getWorldInvertMatrix(modelView, null);
                                                    if (viewport[2] != 0.0) {
                                                        let ratio = viewport[3]/viewport[2];
                                                        let proj:OsMatrix = this._camera.getProjectionMatrix(ratio);
                                                        if (OsVec3D.project(A, modelView, proj, viewport, win1) && 
                                                            OsVec3D.project(B, modelView, proj, viewport, win2)) {
                                                            win1[1] = viewport[3]-win1[1];
                                                            win2[1] = viewport[3]-win2[1];
                                                            win1[0] -= viewport[0];
                                                            win2[0] -= viewport[0];
                                                            win1[1] -= viewport[1];
                                                            win2[1] -= viewport[1];
                                                            let rinfo:OsRenderInfo = new OsRenderInfo(null);
                                                            rinfo.projMat.buildOrthographicProjectionMatrixRH(0, viewport[2], 0, viewport[3], -100, 100);
                                                            
                                                            let color:[number, number, number, number] = [0, 255, 0, 255];
                                                            let viewer:Viewer|null = type?type.getViewer():null;
                                                            let set:OsDbPreferenceSet|null = viewer?viewer.getLocalPreferenceSet():null;
                                                            let info:any = set?set.findProperty('FONTS_COLORS', 'VIEWER', 'SC'):null;
                                                            if (info && info.length == 3) color = [info[0], info[1], info[2], 255];
                                                            
                                                            driver.setColor4iv(color);
                                                            driver.setLineWidth(this._drawFactor);
                                                            
                                                            //check the intersection of this line with the window:
                                                            for (let i:number=0; i<4; i++) valid[i] = false;
                                                            //equation of the 2D line:
                                                            if (Math.abs(win2[0] - win1[0]) < 0.001) {
                                                                //equation of type x=b;
                                                                let b:number = win1[0];
                                                                //intersection with y = 0:
                                                                inter[0][0] = b;
                                                                inter[0][1] = 0.0;
                                                                if (inter[0][0] >= 0 && inter[0][0] <= viewport[2])
                                                                    valid[0] = true;
                                                                //intersection with y = viewport[3]:
                                                                inter[1][0] = b;
                                                                inter[1][1] = viewport[3];
                                                                if (inter[1][0] >= 0 && inter[1][0] <= viewport[2])
                                                                    valid[1] = true;
                                                            }
                                                            else {
                                                                //equation of type y = ax + b
                                                                let b:number = (win2[0]*win1[1] - win1[0]*win2[1]) / (win2[0]-win1[0]);
                                                                let maxVal:number = Math.max(Math.abs(win1[0]), Math.abs(win2[0]));
                                                                let a:number = 0;
                                                                if (maxVal == Math.abs(win1[0])) a = (win1[1]-b)/win1[0];
                                                                else a = (win2[1]-b)/win2[0];
                                                                //intersections with y = 0:
                                                                if (Math.abs(a) >= 0.001) {
                                                                    inter[0][0] = -b/a;
                                                                    inter[0][1] = 0.0;
                                                                    if (inter[0][0] >= 0 && inter[0][0] <= viewport[2])
                                                                        valid[0] = true;
                                                                }
                                                                //intersection with y = viewport[3]:
                                                                if (Math.abs(a) >= 0.001) {
                                                                    inter[1][0] = (viewport[3]-b)/a;
                                                                    inter[1][1] = viewport[3];
                                                                    if (inter[1][0] >= 0 && inter[1][0] <= viewport[2])
                                                                        valid[1] = true;
                                                                }
                                                                //intersection with x = 0:
                                                                inter[2][0] = 0.0;
                                                                inter[2][1] = b;
                                                                if (inter[2][1] >= 0 && inter[2][1] <= viewport[3])
                                                                    valid[2] = true;
                                                                //intersection with x = viewport[2]
                                                                inter[3][0] = viewport[2];
                                                                inter[3][1] = a*viewport[2] + b;
                                                                if (inter[3][1] >= 0 && inter[3][1] <= viewport[3])
                                                                    valid[3] = true;
                                                            }
                                                            //we need two winner points:
                                                            winner1 = -1;
                                                            winner2 = -1;
                                                            for (let i:number=0; i<4; i++) {
                                                                if (valid[i]) {
                                                                    if (winner1 == -1) winner1 = i;
                                                                    else if (winner2 == -1) winner2 = i;
                                                                    else {
                                                                        winner1 = -1;
                                                                        winner2 = -1;
                                                                        break;
                                                                    }
                                                                }
                                                            }
                                                            if (winner1 != -1 && winner2 != -1) {
                                                                A[0] = win1[0]; A[1] = win1[1];
                                                                B[0] = win2[0]; B[1] = win2[1];
                                                                if (driver.enableLineStipple(true)) {
                                                                    //draw up to 3 segments:
                                                                    C[0] = inter[winner1][0]; C[1] = inter[winner1][1];
                                                                    D[0] = inter[winner2][0]; D[1] = inter[winner2][1];
                                                                    //operation the C point:
                                                                    let dim:number = -1;
                                                                    if (Math.abs(B[0]-A[0]) > Math.abs(B[1]-A[1])) dim = 0;
                                                                    else dim = 1;
                                                                    if (Math.abs(B[dim]-A[dim]) > 0.001) {
                                                                        let k:number = (C[dim]-A[dim])/(B[dim]-A[dim]);
                                                                        if (k < 0) {
                                                                            //draw AC:
                                                                            driver.drawLine(rinfo, A[0], A[1], C[0], C[1]);
                                                                        }
                                                                        else 
                                                                        if (k > 1) {
                                                                            //draw BC:
                                                                            driver.drawLine(rinfo, B[0], B[1], C[0], C[1]);
                                                                        }
                                                                    }
                                                                    //operation the D point:
                                                                    if (Math.abs(B[dim]-A[dim]) > 0.001) {
                                                                        let k:number = (D[dim]-A[dim])/(B[dim]-A[dim]);
                                                                        if (k < 0) {
                                                                            //draw AD:
                                                                            driver.drawLine(rinfo, A[0], A[1], D[0], D[1]);
                                                                        }
                                                                        else 
                                                                        if (k > 1) {
                                                                            //draw BD:
                                                                            driver.drawLine(rinfo, B[0], B[1], D[0], D[1]);
                                                                        }
                                                                    }
                                                                    driver.enableLineStipple(false);
                                                                }
                                                                driver.drawLine(rinfo, A[0], A[1], B[0], B[1]);
                                                            }
                                                            else driver.drawLine(rinfo, win1[0], win1[1], win2[0], win2[1]);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }*/

  void drawWarningMessages(OsDriver driver, List<double> viewport) {
    if (_warningMessages.isEmpty) return;

    OsRenderTypeManager manager = OVApi().renderTypes;

    if (type == null) return;
    OsDriverContext? context = driver.currentContext;
    if (context == null) return;

    String fontName = '';
    int fontSize = 12;
    /*let fontColor:string = '#ffffff';
        let fontInfo:any = this.getFont(0);
        if (fontInfo) {
            fontSize = fontInfo.size;
            fontName = fontInfo.name;
            fontColor = fontInfo.color;
        }*/
    OsMultiTextDrawInfo textInfo = OsMultiTextDrawInfo();
    for (int i = 0; i < _warningMessages.length; i++) {
      if (_warningMessages[i].text.isEmpty) continue;
      OsDriverText? dtext =
          context.findText(type!, _warningMessages[i].text, fontName, fontSize);
      if (dtext != null) textInfo.texts.add(WeakReference(dtext));
    }

    OsRenderInfo rinfo = OsRenderInfo(null);
    rinfo.projMat.buildOrthographicProjectionMatrixRH(
        0, viewport[2], 0, viewport[3], -100, 100);

    textInfo.drawBackground = true;
    textInfo.setBackColor4i(0, 0, 0, 180);
    textInfo.setTextColor4i(255, 255, 255, 255);
    textInfo.alignment = OsDriverText.alignCenter;
    rinfo.worldMat.mat[12] = viewport[2] * 0.5;
    rinfo.worldMat.mat[13] = viewport[3] * 0.5;
    textInfo.calculateFrameSize(driver);
    textInfo.draw(driver, rinfo);
  }

  /*public drawRulers(driver:OsDriver, viewport:[number, number, number, number]):void {
        if (!this._shouldDisplayRuler) return;
        if (viewport[2] <= 0 || viewport[3] <= 0) return;
        if (viewport[2] < this._autoSizeHide || viewport[3] < this._autoSizeHide) 
            return ;

        let context:OsDriverContext|null = driver.getCurrentContext();
        if (!context) return;

        let type:OsRendererType|null = this.getType();
        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image:OsOpenedImage|null = img ? img.getImage() : null;
        let frame:OsDicomFrame|null = img ? img.getFrame(img.getCurrentFrame()) : null;
        if (!type || !image || !frame) return;

        //get the camera:
        let cam:OsGraphicCamera = this.getCamera();
        if (!cam) return;

        //get the regions:
        let regions:OsImageRegion[] = [];
        image.getRegionsForFrame(frame, regions);
        if (!regions.length) return;

        //select the region for the ruler:
        //if we change this and want to take the first available region, we need to take about the fact
        //that the image matrix have 1 for scaled values and not the calibrated pixel spacing!
        let region:OsImageRegion|null = null;
        if (regions.length == 1) {
            let widthHeight:[number, number] = [0, 0];
            if (frame.getDimensions(widthHeight)) {
                let tmp:OsImageRegion = regions[0];
                if (tmp.x0 == 0 && tmp.y0 == 0 && tmp.x1 == widthHeight[0]-1 && tmp.y1 == widthHeight[1]-1) 
                    if (tmp.spatialFormat == OS_RSF.TWO_DIM)
                        if (tmp.calibratedUnit[0] == tmp.calibratedUnit[1])
                            if (tmp.calibratedUnit[0] == OS_UNIT.CM) {
                                region = tmp;
                            }
            }
        }
        if (!region) return;
       
        let rinfo:OsRenderInfo = new OsRenderInfo(null);
        rinfo.projMat.buildOrthographicProjectionMatrixRH(0, viewport[2], 0, viewport[3], -100, 100);
        
        //s32 font_size;
        //onis::color font_color;
        //onis::string font_name = _app->get_current_dicom_font(&font_size, &font_color);
        //onis::string font_name = get_font(0, &font_size, &font_color);
        //driver->set_color_4i(font_color.get_red(), font_color.get_green(), font_color.get_blue(), 255);
        let fontSize:number = 10;
        let fontName:string = '';
        let viewer:Viewer|null = type.getViewer();
        let fontInfo:any = viewer?viewer.getCurrentFont(0):null;
        if (fontInfo) {
            fontSize = fontInfo.size;
            fontName = fontInfo.name;
            driver.setColor3h(fontInfo.color);
        }
        else driver.setColor4i(255, 255, 255, 255);
        driver.setLineWidth(this._drawFactor);
        
        let realSizeViewport:number[] = [0, 0];
        realSizeViewport[0] = cam.getOrthoWidth()*10;
        realSizeViewport[1] = realSizeViewport[0] * (viewport[3]/viewport[2]);
        let realPixelSize:number = realSizeViewport[0] / viewport[2];
        let realPixelSizeInvert = 1.0 / realPixelSize;

        for (let i=0; i<2; i++) {
            let realSizeRuler:number = realSizeViewport[i]*0.4;
            let stmp:string = Math.round(realSizeRuler).toString();
            let realSizeGraduation:number = 0;
            if (stmp.length >= 4) realSizeGraduation = 100;
            else realSizeGraduation = Math.pow(10.0, stmp.length-1);
            if (realSizeGraduation == 0) continue;
            let graduationCount = Math.round(realSizeRuler / realSizeGraduation);
            if (realSizeGraduation != 1 && graduationCount == 1) { graduationCount = 10; realSizeGraduation /= 10; }
            realSizeRuler = graduationCount * realSizeGraduation;
            let startPos:number = realSizeViewport[i]*0.5-realSizeRuler*0.5;
            let endPos:number = realSizeViewport[i]*0.5+realSizeRuler*0.5;
            if (realSizeGraduation == 100 && graduationCount > 20) continue;

            let text:string = '';
            if (realSizeGraduation == 1) text = "mm";
            else if (realSizeGraduation == 10) text = "cm";
            else if (realSizeGraduation == 100) text = "dm";

            if (i == 0) {
                //draw the base line:
                driver.drawLine(rinfo, startPos*realPixelSizeInvert, 6*this._drawFactor, endPos*realPixelSizeInvert, 6*this._drawFactor);
                //draw the graduation:
                for (let j=0; j<=graduationCount; j++) 
                    driver.drawLine(rinfo, (startPos+j*realSizeGraduation)*realPixelSizeInvert, 6*this._drawFactor, (startPos+j*realSizeGraduation)*realPixelSizeInvert, 16*this._drawFactor);
            }
            else {
                //draw the base line:
                driver.drawLine(rinfo, 6*this._drawFactor, startPos*realPixelSizeInvert, 6*this._drawFactor, endPos*realPixelSizeInvert);
                //draw the graduation:
                for (let j=0; j<=graduationCount; j++) 
                    driver.drawLine(rinfo, 6*this._drawFactor, (startPos+j*realSizeGraduation)*realPixelSizeInvert, 16*this._drawFactor, (startPos+j*realSizeGraduation)*realPixelSizeInvert);
            }
            
            let dtext:OsDriverText|null = context.findText(type, text, fontName, fontSize, false);
            if (dtext) {
                let widthHeight:[number, number] = [0, 0];
                dtext.getFrameSize(driver, widthHeight);
                if (i == 0) {
                    rinfo.worldMat.mat[12] = endPos*realPixelSizeInvert+7*this._drawFactor + widthHeight[0]*this._drawFactor*0.5;
                    rinfo.worldMat.mat[13] = 3*this._drawFactor + widthHeight[1]*this._drawFactor*0.5;
                }
                else {
                    rinfo.worldMat.mat[12] = 5*this._drawFactor + widthHeight[0]*this._drawFactor*0.5;
                    rinfo.worldMat.mat[13] = startPos*realPixelSizeInvert-(7*this._drawFactor) - widthHeight[1]*this._drawFactor*0.5;
                }
                dtext.draw(driver, rinfo);
                rinfo.worldMat.mat[12] = 0;
                rinfo.worldMat.mat[13] = 0;
            }
        }
    }

    public drawDicomAnnotations(driver:OsDriver, viewport:[number, number, number, number]) {
        if (!this._shouldDisplayDicom) return;
        if (viewport[2] < this._autoSizeHide || viewport[3] < this._autoSizeHide) 
            return ;
        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image:OsOpenedImage|null = img ? img.getImage() : null;
        if (!image) return;
        driver.startDrawingMultipleTexts();
        this._info.reset();
        this._info.projMat.buildOrthographicProjectionMatrixRH(0.0, viewport[2], 0.0, viewport[3], -1.0, 1.0);
        let borderX:number = 25.0*this._drawFactor;
        let borderY:number = 20.0*this._drawFactor;
        for (let i:number=0; i<8; i++) {
            let offsetY:number = 0.0;
            let middle:number = 10000000;
            for (let j:number = 0; j<this._dicomAnnotationBoxes[i].list.length; j++) {
                let item:OsGraphicDicomAnnotationText = this._dicomAnnotationBoxes[i].list[j];
                let dtext:OsDriverText|null = item.getDriverText();
                if (dtext) {
                    if (item.dynamicText.length) dtext.setText(item.dynamicText);
                    let widthHeight:[number, number] = [0, 0];
                    dtext.getFrameSize(driver, widthHeight);
                    switch(i) {
                        case OsAsContainer.astop_left:
                            this._info.worldMat.mat[12] = borderX + widthHeight[0]*0.5; 
                            this._info.worldMat.mat[13] = viewport[3] - widthHeight[1]*0.5 - offsetY - borderY;
                            offsetY += widthHeight[1];
                            break;
                            
                        case OsAsContainer.astop_right:    
                            this._info.worldMat.mat[12] = viewport[2] - widthHeight[0]*0.5 - borderX; 
                            this._info.worldMat.mat[13] = viewport[3] - widthHeight[1]*0.5 - offsetY - borderY;
                            offsetY += widthHeight[1];
                            break;
                            
                        case OsAsContainer.asbottom_left:  
                            this._info.worldMat.mat[12] = borderX + widthHeight[0]*0.5;
                            this._info.worldMat.mat[13] = widthHeight[1]*0.5 - offsetY + borderY;
                            offsetY -= widthHeight[1];
                            break;
    
                        case OsAsContainer.asbottom_right:
                            this._info.worldMat.mat[12] = viewport[2] - widthHeight[0]*0.5 - borderX; 
                            this._info.worldMat.mat[13] = widthHeight[1]*0.5 - offsetY + borderY;
                            offsetY -= widthHeight[1];
                            break;
                            
                        case OsAsContainer.astop:          
                            this._info.worldMat.mat[12] = viewport[2]*0.5;
                            this._info.worldMat.mat[13] = viewport[3] - widthHeight[1]*0.5 - offsetY - borderY;
                            offsetY += widthHeight[1];
                            break;
                        
                        case OsAsContainer.asbottom:       
                            this._info.worldMat.mat[12] = viewport[2]*0.5;
                            this._info.worldMat.mat[13] = widthHeight[1]*0.5 - offsetY + borderY;
                            offsetY -= widthHeight[1];
                            break;
                            
                        case OsAsContainer.asleft:         
                            this._info.worldMat.mat[12] = borderX + widthHeight[0]*0.5;
                            if (middle == 10000000) middle = viewport[3]*0.5 + widthHeight[1] * this._dicomAnnotationBoxes[i].list.length * 0.5;
                            this._info.worldMat.mat[13] = middle - widthHeight[1]*0.5 - offsetY;
                            offsetY += widthHeight[1];
                            break;
                            
                        case OsAsContainer.asright:        
                            this._info.worldMat.mat[12] = viewport[2] - widthHeight[0]*0.5 - borderX; 
                            if (middle == 10000000) middle = viewport[3]*0.5 + widthHeight[1] * this._dicomAnnotationBoxes[i].list.length * 0.5;
                            this._info.worldMat.mat[13] = middle - widthHeight[1]*0.5 - offsetY;
                            offsetY += widthHeight[1];
                            break;
                        default: break;
                    };
                    dtext.draw(driver, this._info);
                }
            }
        }
        driver.stopDrawingMultipleTexts();
    }*/

  //-----------------------------------------------------------------------
  //dirty
  //-----------------------------------------------------------------------

  @override
  bool get dirty {
    //if (this._rootItem != null) return this._rootItem.isDirty(true);
    return false;
  }

  //-----------------------------------------------------------------------
  //refresh
  //-----------------------------------------------------------------------

  @override
  bool get wantRefreshAsSoonAsPossible => _wantRefreshAsap;

  //-----------------------------------------------------------------------
  //pixel
  //-----------------------------------------------------------------------

  /*public getPixelPosition(width =number, height =number, x =number, y =number, output =[number,number,number], onlyInside =boolean):boolean{
    
        if (this._camera == null) return false;
        if (!this._camera.isOrthographicMode()) return false;

        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image:OsOpenedImage|null = null;
        let frame:OsDicomFrame|null = null;
        if (img == null || frame == null || image == null) return false;

        let imageWidthHeight:[number,number] = [0, 0];
        if (!frame.getDimensions(imageWidthHeight)) return false;

        let region:OsImageRegion|null = null;
        let regions:OsImageRegion[] = [];
        image.getRegionsForFrame(frame, regions);
        if (regions.length == 1) {

            let tmp:OsImageRegion = regions[0];
            if (tmp.x0 == 0 && tmp.y0 == 0 && tmp.x1 == imageWidthHeight[0]-1 && tmp.y1 == imageWidthHeight[1]-1) 
                if (tmp.spatialFormat == OS_RSF.TWO_DIM)
                    if (tmp.calibratedUnit[0] == tmp.calibratedUnit[1])
                        if (tmp.calibratedUnit[0] == OS_UNIT.CM) 
                            region = tmp;

        }

        if (region == null) return false;

        let pixelSpacing:[number,number] = [0, 0];
        pixelSpacing[0] = Math.abs(region.calibratedSpacing[0]);
        pixelSpacing[1] = Math.abs(region.calibratedSpacing[1]);

        let realDimensions:[number,number] = [0, 0];
        realDimensions[0] = imageWidthHeight[0] * pixelSpacing[0];
        realDimensions[1] = imageWidthHeight[1] * pixelSpacing[1];

        let imageOrientation:OsMatrix = OsMatrix();    
        if (!image.getImageOrientation(imageOrientation)) return false;
                
        let win:[number,number,number] = [0, 0, 0];
        win[0] = x;
        win[1] = y;
        win[2] = 0.0;
        
        let modelView:OsMatrix = OsMatrix();  
        this._camera.getWorldInvertMatrix(modelView, null);
        
        let proj:OsMatrix = OsMatrix();
        let viewport:[number,number,number,number] = [0, 0, 0, 0];  
        viewport[0] = 0;
        viewport[1] = 0;
        viewport[2] = width;
        viewport[3] = height;
        
        if (viewport[2] == 0.0) return false;
        
        let ratio:number = (width) ? height/width : 1.0;
        proj = this._camera.getProjectionMatrix(ratio)
 
        let world:[number,number,number] = [0, 0, 0];
        if (OsVec3D.unproject(win, modelView, proj, viewport, world)) {
            
            let imagePos:[number,number,number] = [0, 0, 0];
            
            let imageMatrixInv:OsMatrix = OsMatrix();
            img.getWorldInvertMatrix(imageMatrixInv,null);
            imagePos[0] = imageMatrixInv.mat[0]*world[0] + imageMatrixInv.mat[4]*world[1] + imageMatrixInv.mat[8]*world[2] + imageMatrixInv.mat[12];
            imagePos[1] = imageMatrixInv.mat[1]*world[0] + imageMatrixInv.mat[5]*world[1] + imageMatrixInv.mat[9]*world[2] + imageMatrixInv.mat[13];
            imagePos[2] = imageMatrixInv.mat[2]*world[0] + imageMatrixInv.mat[6]*world[1] + imageMatrixInv.mat[10]*world[2] + imageMatrixInv.mat[14];
            
            let inside:boolean = true;
            if (imagePos[0] < -0.5 || imagePos[0] > 0.5) inside = false;
            if (imagePos[1] < -0.5 || imagePos[1] > 0.5) inside = false;
            
            if (onlyInside && !inside)  return false;
            
            imagePos[0] += 0.5;
            imagePos[1] += 0.5;
            imagePos[1] = 1.0 - imagePos[1];
            
            imagePos[0] *= realDimensions[0];
            imagePos[1] *= realDimensions[1];
            
            //Add an offset to set the origin at the center of the pixel:
            //image_pos[0] -= pixel_spacing[0]*0.5;
            //image_pos[1] -= pixel_spacing[1]*0.5;

            //bring to millimiters:
            imagePos[0] *= 10.0;
            imagePos[1] *= 10.0;
            imagePos[2] = 0;

            output[0] = imageOrientation.mat[12] + imagePos[0]*imageOrientation.mat[0] + imagePos[1]*imageOrientation.mat[4] + imagePos[2]*imageOrientation.mat[8];
            output[1] = imageOrientation.mat[13] + imagePos[0]*imageOrientation.mat[1] + imagePos[1]*imageOrientation.mat[5] + imagePos[2]*imageOrientation.mat[9];
            output[2] = imageOrientation.mat[14] + imagePos[0]*imageOrientation.mat[2] + imagePos[1]*imageOrientation.mat[6] + imagePos[2]*imageOrientation.mat[10];


            //CString convert;
            //convert.Format(_T("%lf %lf %lf   %lf %lf  %lf"), image_pos[0], image_pos[1], image_pos[2], output[0], output[1], output[2]);
            //AfxGetApp()->m_pMainWnd->SetWindowText(convert);


            //back to centimeters:
            //output[0] /= 10.0;
            //output[1] /= 10.0;
            //output[2] /= 10.0;

            //output[2] = image_orientation[14];

            //onis::matrix4d mat5 = image_orientation;
            //onis::matrix4d mat6 = mat5;
            //mat6.invert();
            //f64 in[3] = { 110, 110, 0 };
            //f64 out1[3], out2[3];
            //onis::vec3d::multiply_by_matrix(in, mat5, out1);
            //onis::vec3d::multiply_by_matrix(in, mat6, out2);
            return true;
            
        }

        return false;

    }

    public getPixelValue(width =number, height =number, x =number, y =number, position =[number,number,number], isMonochrome =[boolean], value =[number], rgb =[number,number,number]):boolean{
     
        if (!this._camera) return false;
        if (!this._camera.isOrthographicMode()) return false;
        position[2] = VALUE.S32_MAX;
        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image:OsOpenedImage|null = null;
        if (img == null ||image == null) return false;

        let frame:OsDicomFrame|null = img.getFrame(img.getCurrentFrame());
        return false;
        
        let dimensions:[number,number] = [0, 0];
        if (!frame.getDimensions(dimensions)) return false;
        
        let win:[number,number,number] = [0, 0, 0];
        win[0] = x;
        win[1] = y;
        win[2] = 0.0;
        
        let modelView:OsMatrix = OsMatrix();  
        this._camera.getWorldInvertMatrix(modelView, null);
        
        let proj:OsMatrix = OsMatrix();
        let viewport:[number,number,number,number] = [0, 0, 0, 0]; 
        viewport[0] = 0;
        viewport[1] = 0;
        viewport[2] = width;
        viewport[3] = height;
        
        if (viewport[2] == 0.0) return false;
        
        let ratio:number = (width) ? height/width : 1.0;
        proj = this._camera.getProjectionMatrix(ratio);
        
        let world:[number,number,number] = [0, 0, 0]; 
        if (OsVec3D.unproject(win, modelView, proj, viewport, world)) {
            
            let imagePos:[number,number,number] = [0, 0, 0];
            
            let imageMatrixInv:OsMatrix = OsMatrix();  
            img.getWorldInvertMatrix(imageMatrixInv,null);
            imagePos[0] = imageMatrixInv.mat[0]*world[0] + imageMatrixInv.mat[4]*world[1] + imageMatrixInv.mat[8]*world[2] + imageMatrixInv.mat[12];
            imagePos[1] = imageMatrixInv.mat[1]*world[0] + imageMatrixInv.mat[5]*world[1] + imageMatrixInv.mat[9]*world[2] + imageMatrixInv.mat[13];
            imagePos[2] = imageMatrixInv.mat[2]*world[0] + imageMatrixInv.mat[6]*world[1] + imageMatrixInv.mat[10]*world[2] + imageMatrixInv.mat[14];
            
            let inside:boolean = true;
            if (imagePos[0] < -0.5 || imagePos[0] > 0.5) inside = false;
            if (imagePos[1] < -0.5 || imagePos[1] > 0.5) inside = false;
            
            if (inside) {
            
                imagePos[0] += 0.5;
                imagePos[1] += 0.5;
                imagePos[1] = 1.0 - imagePos[1];
                position[0] = Math.floor(dimensions[0] * imagePos[0]);
                position[1] = Math.floor(dimensions[1] * imagePos[1]);

                if (position[0] < 0) position[0] = 0;
                if (position[1] < 0) position[1] = 0;
                if (position[0] >= dimensions[0]) position[0] = dimensions[0]-1;
                if (position[1] >= dimensions[1]) position[1] = dimensions[1]-1;
                            
                //Retrieve the pixel data:
                let interData:OsIntermediatePixelData|null = null;
                let rescaleIntercept:[number,number] = [0, 0];
                if (frame.isMonochrome() && !frame.havePalette()) {
                    
                    isMonochrome[0] = true;
                    
                    let frameWidthHeight:[number, number] = [0,0];
                    if (!frame.getDimensions(frameWidthHeight)) return false;
                    
                    interData = frame.getIntermediatePixelData();
                    if (!interData || !interData.intermediatePixelData) return false;
                    if (!frame.getRescaleAndIntercept(rescaleIntercept)) {
                        rescaleIntercept[0] = 1.0;
                        rescaleIntercept[1] = 0.0;
                    }
                    if (rescaleIntercept[0] == 0.0) return false;
                    
                    let representation = interData.bits;
                    let isSigned:boolean = interData.isSigned;

                    let sourceStride = frameWidthHeight[0];
                    let sourceIndex:number = Math.floor(position[0] + sourceStride * position[1]);

                    if (representation == 32) {
                        let interSource = (isSigned) ? Int32Array(interData.intermediatePixelData.buffer) : Uint32Array(interData.intermediatePixelData.buffer);
                        let realValue:number = interSource[sourceIndex];
                        realValue = realValue*rescaleIntercept[0] + rescaleIntercept[1];
                        value[0] = realValue;
                        
                        
                        //u32 *inter_source = (u32 *)inter_data;
                        //s32 source_stride = frame_width;
                        //u32 *source = &inter_source[position[0] + source_stride * position[1]];
                        //f64 real_value = (is_signed) ? *((s32 *)source) : *source;
                        //real_value = real_value*rescale + intercept;
                        // *value = real_value;
                        
                    }
                    else
                    if (representation == 16) {
                        
                        let interSource = (isSigned) ? Int16Array(interData.intermediatePixelData.buffer) : Uint16Array(interData.intermediatePixelData.buffer);
                        let realValue:number = interSource[sourceIndex];
                        realValue = realValue*rescaleIntercept[0] + rescaleIntercept[1];
                        value[0] = realValue;

                        //u16 *inter_source = (u16 *)inter_data;
                        ///s32 source_stride = frame_width;
                        //u16 *source = &inter_source[position[0] + source_stride * position[1]];
                        //f64 real_value = (is_signed) ? *((s16 *)source) : *source;
                        //real_value = real_value*rescale + intercept;
                        // *value = real_value;
                        
                    }
                    else 
                    if (representation == 8) {
                        
                        let interSource = (isSigned) ? Int8Array(interData.intermediatePixelData.buffer) : Uint8Array(interData.intermediatePixelData.buffer);
                        let realValue:number = interSource[sourceIndex];
                        realValue = realValue*rescaleIntercept[0] + rescaleIntercept[1];
                        value[0] = realValue;

                        //u8 *inter_source = (u8 *)inter_data;
                        //s32 source_stride = frame_width;
                        //u8 *source = &inter_source[position[0] + source_stride * position[1]];
                        //f64 real_value = (is_signed) ? *((s8 *)source) : *source;
                        //real_value = real_value*rescale + intercept;
                        // *value = real_value;
                        
                    }
                    
                }
                else {
                    
                    isMonochrome[0] = false;
                    
                    return false;

                    /*let havePalette:boolean = frame.havePalette();
                    let bitsPerPixel:number = (havePalette) ? 24 : frame.getBitsPerPixel();
                    
                    inter_data = (u8 *)frame->get_intermediate_pixel_data(NULL);
                    if (!inter_data) return OSFALSE;
                    
                    if (bits_per_pixel == 24 || bits_per_pixel == 32) {
                        
                        s32 frame_width;
                        s32 frame_height;
                        if (!frame->get_dimensions(&frame_width, &frame_height)) return OSFALSE;
                        
                        if (have_palette) {
                            
                            if (!frame->get_rescale_and_intercept(&rescale, &intercept)) {
                                rescale = 1.0;
                                intercept = 0.0;
                            }
                            if (rescale == 0.0) return OSFALSE;
                            
                            b32 is_signed;
                            s32 representation = frame->get_representation(&is_signed);
                            
                            onis::dicom_palette *red = frame->get_palette(OSRED);
                            onis::dicom_palette *green = frame->get_palette(OSGREEN);
                            onis::dicom_palette *blue = frame->get_palette(OSBLUE);
                            
                            if (!red || !green || !blue) return OSFALSE;

                            if (representation == 16) {
                                
                                u16 *palette_data[3];
                                palette_data[0] = (u16 *)red->data;
                                palette_data[1] = (u16 *)green->data;
                                palette_data[2] = (u16 *)blue->data;
                                s32 max_entries[3];
                                max_entries[0] = red->count;
                                max_entries[1] = green->count;
                                max_entries[2] = blue->count;
                                
                                u16 *inter_source = (u16 *)inter_data;
                                s32 source_stride = frame_width;
                                u16 *source = &inter_source[position[0] + source_stride * position[1]];
                                s32 index = 0;
                                if (is_signed) index = *(s16 *)source;
                                else index = *source;
                                
                                for (s32 i=0; i<3; i++) {
                                    
                                    u16 tmp_value = (index < 0) ? palette_data[i][0] : (index >= max_entries[i]) ? palette_data[i][max_entries[i]-1] : palette_data[i][index];
                                    rgb[i] = (u8)((tmp_value*255)/65535);
                                    
                                }
                                
                            }
                            else
                            if (representation == 8) {
                                
                                u8 *palette_data[3];
                                palette_data[0] = (u8 *)red->data;
                                palette_data[1] = (u8 *)green->data;
                                palette_data[2] = (u8 *)blue->data;
                                s32 max_entries[3];
                                max_entries[0] = red->count;
                                max_entries[1] = green->count;
                                max_entries[2] = blue->count;
                                
                                u8 *inter_source = (u8 *)inter_data;
                                s32 source_stride = frame_width;
                                u8 *source = &inter_source[position[0] + source_stride * position[1]];
                                s32 index = 0;
                                if (is_signed) index = *(u8 *)source;
                                else index = *source;
                                
                                for (s32 i=0; i<3; i++) {
                                    
                                    rgb[i] = (index < 0) ? palette_data[i][0] : (index >= max_entries[i]) ? palette_data[i][max_entries[i]-1] : palette_data[i][index];
                                    
                                }
                                
                            }
                            else return OSFALSE;

                        }
                        else {
                            
                            u8 *source[3];
                            source[0] = ((u8 **)inter_data)[0];
                            source[1] = ((u8 **)inter_data)[1];
                            source[2] = ((u8 **)inter_data)[2];
                            
                            s32 source_stride = frame_width;
                            
                            rgb[0] = source[0][position[0] + source_stride * position[1]];
                            rgb[1] = source[1][position[0] + source_stride * position[1]];
                            rgb[2] = source[2][position[0] + source_stride * position[1]];
                            
                        }
                        
                    }
                    else return false;*/
                
                }
                return true;

            }
            
            return false;
            
        }
        
        return false;

    }


    //-----------------------------------------------------------------------
    //overlays
    //-----------------------------------------------------------------------

    public shouldDisplayDicomAnnotations(set =[OsDbAnnotationSet|null]):boolean {
        if (set) {
            let tmp:OsDbAnnotationSet|null = this._wannotationSet ? <OsDbAnnotationSet>this._wannotationSet.lock(false) : null;
            let type:OsRendererType|null = this.getType();
            let viewer:Viewer|null = type?type.getViewer():null;
            if (!tmp && type && viewer) {
                
                let siteSet:[OsDbPreferenceSet|null] = [null];
                let userSet:OsDbPreferenceSet|null = viewer.getActivePreferenceSet(siteSet);
                for (let iinnumber=0; i<2; i++) {
                    let currentSet = i == 0 ? userSet : siteSet[0];
                    if (currentSet && 'AS' in currentSet.items) {
                        let items:OsDbPreferenceItem[] = currentSet.items['AS']; 
                        if (items.length) {
                            let winner:OsDbAnnotationSet = <OsDbAnnotationSet>items[0];
                            if (this._wannotationSet) this._wannotationSet.destroy();
                            this._wannotationSet = winner ? winner.getWeakObject() : null;
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

    public setShouldDisplayDicomAnnotations(display =boolean, set =OsDbAnnotationSet) {
        this._shouldDisplayDicom = display;
        if (set) {
            let modified:boolean = false;
            let currentSet:OsDbAnnotationSet|null = this._wannotationSet ? <OsDbAnnotationSet>this._wannotationSet.lock(false) : null;
            if (currentSet !== set) 
                modified = true;
            if (modified) {
                if (this._wannotationSet) this._wannotationSet.destroy();
                this._wannotationSet = set ? set.getWeakObject() : null;
            }
        }
    }
  
    public setShouldDisplayGraphicAnnotations(display =boolean) {
        this._shouldDisplayGraphics = display;
    }

    public setShouldDisplayRuler(display =boolean) {
        this._shouldDisplayRuler = display;
    }*/

  //-----------------------------------------------------------------------
  //warning messages
  //-----------------------------------------------------------------------

  void addWarningMessage(String text, Object? data) {
    if (data == null || text.isEmpty) return;
    for (int i = 0; i < _warningMessages.length; i++) {
      if (_warningMessages[i].haveData) {
        if (_warningMessages[i].wdata!.target == data &&
            _warningMessages[i].text == text) {
          return;
        }
      } else {
        if (_warningMessages[i].text == text) {
          return;
        }
      }
    }
    OsRenderer2dWarningMessage message = OsRenderer2dWarningMessage(text, data);
    _warningMessages.add(message);
  }

  bool removeWarningMessage(String text, Object? data) {
    bool ret = false;
    if (data != null) {
      for (int i = 0; i < _warningMessages.length; i++) {
        if (_warningMessages[i].haveData &&
            _warningMessages[i].wdata?.target == data) {
          if (text.isEmpty || text == _warningMessages[i].text) {
            ret = true;
            _warningMessages.removeAt(i);
            i--;
            if (text.isNotEmpty) break;
          }
        }
      }
    } else {
      if (text.isNotEmpty) {
        for (int i = 0; i < _warningMessages.length; i++) {
          if (!_warningMessages[i].haveData) {
            if (text == _warningMessages[i].text) {
              ret = true;
              _warningMessages.removeAt(i);
              i--;
              break;
            }
          }
        }
      } else {
        ret = _warningMessages.isNotEmpty ? true : false;
        _warningMessages.clear();
      }
    }
    return ret;
  }

  //-----------------------------------------------------------------------
  //memory
  //-----------------------------------------------------------------------
  /*public releaseMemory(level =number):void {
        if (this._rootItem) this._rootItem.releaseMemory(this, level, true);
    }
    
    //-----------------------------------------------------------------------
    //annotations
    //-----------------------------------------------------------------------

    public regenerateAnnotationSegments():void {
        let images:OsGraphicImage[] = [];
        this.getImageItems(images);
        let list:OsGraphicAnnotation[] = [];
        for (let i=0; i<images.length; i++) {
            images[i].getAnnotationList(list);
        }
        //Search all the intersections:
        let intersections:OsAnnotationIntersection[] = [];
        calculateAnnotationIntersections(list, intersections);
        //Regenerate the segment for each annotations:
        for (let i=0; i<list.length; i++) 
            list[i].regenerateSegments(this, intersections);
        //cleanup: 
        for (let i=0; i<intersections.length; i++) 
            if (intersections[i]) 
                intersections[i].release();
    }

    public calculateAnnotationIntersections(list =OsGraphicAnnotation[], intersections =OsAnnotationIntersection[]) {
        for (let i=0; i<list.length; i++) {
            for (let j=i+1; j<list.length; j++) {
                list[i].calculateIntersections(this, list[j], intersections);
            }
        }
    }*/

  //-----------------------------------------------------------------------
  //filter
  //-----------------------------------------------------------------------

  @override
  int get filterType => _filterType;
  @override
  set filterType(int value) {
    _filterType = value;
  }

  //-----------------------------------------------------------------------
  //orientation
  //-----------------------------------------------------------------------

  /*public getImageOrientationInView(width:number, height:number, ltrb:string[]):boolean {

        let winO:number[] = [0, 0 , 0];
        let winX:number[] = [100, 0 , 0];
        let winY:number[] = [0, 100 , 0];
        let imgO:[number, number, number] = [0, 0 , 0];
        let imgX:[number, number, number] = [0, 0 , 0];
        let imgY:[number, number, number] = [0, 0 , 0];
        let worldO:[number, number, number] = [0, 0 , 0];
        let worldX:[number, number, number] = [0, 0 , 0];
        let worldY:[number, number, number] = [0, 0 , 0];

        let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
        let image:OsOpenedImage|null = img ? img.getImage() : null;
        if (!img || !image) return false;

        let orientationMatrix:OsMatrix = new OsMatrix();
        if (!image.getImageOrientation(orientationMatrix)) return false;

        if (!this._camera.convertMouseCursorToWorld(winO[0], winO[1], width, height, worldO)) return false;
        if (!this._camera.convertMouseCursorToWorld(winX[0], winX[1], width, height, worldX)) return false;
        if (!this._camera.convertMouseCursorToWorld(winY[0], winY[1], width, height, worldY)) return false;
        
        img.convertFromWorld(worldO, imgO);
        img.convertFromWorld(worldX, imgX);
        img.convertFromWorld(worldY, imgY);
        
        //normally, the origin of the image world should be at the upper left corner, not at the lower left corner.
        //we correct it here, since we are now in the image world:
        imgO[1] = -imgO[1];
        imgX[1] = -imgX[1];
        imgY[1] = -imgY[1];
        
        //In the true world:
        OsVec3D.multiplyByMatrix(imgX, orientationMatrix, worldX);
        OsVec3D.multiplyByMatrix(imgY, orientationMatrix, worldY);
        OsVec3D.multiplyByMatrix(imgO, orientationMatrix, worldO);
        
        worldX[0] -= worldO[0];
        worldX[1] -= worldO[1];
        worldX[2] -= worldO[2];
        
        worldY[0] -= worldO[0];
        worldY[1] -= worldO[1];
        worldY[2] -= worldO[2];
        
        OsVec3D.normalize(worldX);
        OsVec3D.normalize(worldY);
        
        let L:[number, number, number] = [1, 0, 0];
        let R:[number, number, number] = [-1, 0, 0];
        let A:[number, number, number] = [0, -1, 0];
        let P:[number, number, number] = [0, 1, 0];
        let H:[number, number, number] = [0, 0, 1];
        let F:[number, number, number] = [0, 0, -1];
        
        ltrb[2] = 'L';
        let maxVal:number = OsVec3D.scalarProduct(worldX, L);
        let tmp:number = OsVec3D.scalarProduct(worldX, R);
        if (tmp > maxVal) { maxVal = tmp; ltrb[2] = "R"; }
        tmp = OsVec3D.scalarProduct(worldX, A);
        if (tmp > maxVal) { maxVal = tmp; ltrb[2] = "A"; }
        tmp = OsVec3D.scalarProduct(worldX, P);
        if (tmp > maxVal) { maxVal = tmp; ltrb[2] = "P"; }
        tmp = OsVec3D.scalarProduct(worldX, F);
        if (tmp > maxVal) { maxVal = tmp; ltrb[2] = "F"; }
        tmp = OsVec3D.scalarProduct(worldX, H);
        if (tmp > maxVal) { maxVal = tmp; ltrb[2] = "H"; }
        
        ltrb[3] = 'L';
        maxVal = OsVec3D.scalarProduct(worldY, L);
        tmp = OsVec3D.scalarProduct(worldY, R);
        if (tmp > maxVal) { maxVal = tmp; ltrb[3] = "R"; }
        tmp = OsVec3D.scalarProduct(worldY, A);
        if (tmp > maxVal) { maxVal = tmp; ltrb[3] = "A"; }
        tmp = OsVec3D.scalarProduct(worldY, P);
        if (tmp > maxVal) { maxVal = tmp; ltrb[3] = "P"; }
        tmp = OsVec3D.scalarProduct(worldY, F);
        if (tmp > maxVal) { maxVal = tmp; ltrb[3] = "F"; }
        tmp = OsVec3D.scalarProduct(worldY, H);
        if (tmp > maxVal) { maxVal = tmp; ltrb[3] = "H"; }
        
        if (ltrb[2] === "L") ltrb[0] = "R";
        else if (ltrb[2] === "R") ltrb[0] = "L";
        else if (ltrb[2] === "A") ltrb[0] = "P";
        else if (ltrb[2] === "P") ltrb[0] = "A";
        else if (ltrb[2] === "H") ltrb[0] = "F";
        else ltrb[0] = "H";
        
        if (ltrb[3] === "L") ltrb[1] = "R";
        else if (ltrb[3] === "R") ltrb[1] = "L";
        else if (ltrb[3] === "A") ltrb[1] = "P";
        else if (ltrb[3] === "P") ltrb[1] = "A";
        else if (ltrb[3] === "H") ltrb[1] = "F";
        else ltrb[1] = "H";
        
        return true;

    }

    //-----------------------------------------------------------------------
    //cine
    //-----------------------------------------------------------------------

    /*b32 renderer_2d::is_mpeg() {

        onis::graphics::image_ptr item = get_primary_image_item();
        if (item != NULL) {

            s32 frame_count = item->get_frame_count();
            if (frame_count == 1) {

                onis::dicom_image_ptr frame = item->get_frame(0, NULL);
                if (frame != NULL) return frame->is_mpeg_frame();
                else {

                    //no frame yet, need to check if this is a mepg file:
                    onis::opened_image_ptr image = item->get_image();
                    if (image != NULL) {

                        onis::dicom_file_ptr dcm = image->get_dicom_file(NULL);
                        if (dcm != NULL) {

                            onis::astring transfer_syntax;
                            dcm->get_string_element(transfer_syntax, TAG_TRANSFER_SYNTAX_UID, "UI");
                            if (transfer_syntax == "1.2.840.10008.1.2.4.100" || transfer_syntax == "1.2.840.10008.1.2.4.101" ||
                                transfer_syntax == "1.2.840.10008.1.2.4.102" || transfer_syntax == "1.2.840.10008.1.2.4.103") {

                                return OSTRUE;

                            }

                        }

                    }

                }

            }

        }
        return OSFALSE;

    }*/

    public canPlay():boolean {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            let frameCount:number = item.getFrameCount();
            if (frameCount > 1) return true;
            //else return is_mpeg();
        }
        return false;
    }*/

  bool pause(bool cancelAutoStart) {
    /*if (cancelAutoStart) this._autoStart = false;
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            /*onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                
                if (!decoder->is_buffering(NULL)) {

                    decoder->pause();
                    return OSTRUE;

                }

            }
            else*/
            if (this._multiframePlayInfo) 
                this._multiframePlayInfo.isPlaying = false;
        }*/
    return false;
  }

  /*public play(setAutoStart:boolean):boolean {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            /*if (is_mpeg()) {

                //maybe we need to send a request to the server to start streaming the data:
                if (std::this_thread::get_id() == _app->get_thread_id()) {

                    onis::opened_image_ptr image = item->get_image();
                    if (image != NULL) _app->add_image_to_streaming_queue(image, OSTRUE);

                }

                onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
                if (decoder != NULL) {
                
                    if (!decoder->is_buffering(NULL)) {

                        if(set_auto_start) _auto_start = OSTRUE;
                        decoder->play();
                        return OSTRUE;

                    }
                    
                }

            }
            else {*/
                let count:number = item.getFrameCount();
                if (count > 1) {
                    //do we need buffering?
                    if (!this._multiframePlayInfo) {
                        this._multiframePlayInfo = new OsPlayRender2dInfo(this);
                        this._multiframePlayInfo.bufferingProgress = 0;
                        this._multiframePlayInfo.bufferingFrameCount = count;
                    }
                    else this._multiframePlayInfo.firstTime = true;
                    let loaded:number = 0;
                    for (let i:number = 0; i < count; i++) {
                        if (item.getFrame(i)) 
                            loaded++;
                    }
                    this._multiframePlayInfo.bufferingFrameDone = loaded;
                    this._multiframePlayInfo.isPlaying = true;
                    let type:OsRendererType|null = this.getType();
                    let viewer:Viewer|null = type?type.getViewer():null;
                    let manager:OsDownloadManager|null = viewer?viewer.getDownloadManager():null;
                    let img:OsGraphicImage|null = this.getPrimaryImageItem(false);
                    let image:OsOpenedImage|null = img?img.getImage():null;
                    if (manager && image) manager.addMultiFrameImageToLoadingQueue(image, true);

                }
            //}
        }
        return false;
    }

    public isPlaying():boolean {
        let item:OsGraphicItem|null = this.getPrimaryImageItem(false);
        if (item) {
            /*onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                
                if (decoder->is_paused() == 0) 
                    return OSTRUE;
                
            }
            else */
            if (this._multiframePlayInfo) 
                return this._multiframePlayInfo.isPlaying;
        }
        return false;
    }

    public canMoveToNextFrame():boolean { 
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            /*onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {

                if (decoder->is_ready() && !decoder->is_buffering(NULL)) {

                    if (decoder->is_paused()) 
                        return OSTRUE;

                }

            }
            else*/
            if (this._multiframePlayInfo) {
                if (item.getCurrentFrame() != this._multiframePlayInfo.bufferingFrameCount-1)
                    return true;
            }
        }
        return false;
    }
    public canMoveToPreviousFrame():boolean { 
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            if (this._multiframePlayInfo) {
                if (item.getCurrentFrame() > 0)
                    return true;
            }
        }
        return false;
    }

    public canSeek(ratio:number):boolean { 
        /*let item:OsGraphicImage = this.getPrimaryImageItem(false);
        if (item) {
            onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                
                if (decoder->is_ready() && !decoder->is_buffering(NULL)) 
                    return OSTRUE;

            }
        }*/
        return false;
    }

    public seek(ratio:number):boolean {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            /*onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                
                if (decoder->is_ready() && !decoder->is_buffering(NULL)) {

                    decoder->seek(ratio);
                    return OSTRUE;

                }
                
            }
            else {*/
                if (!this.isBuffering(null)) {
                    let frameCount:number = item.getFrameCount();
                    if (frameCount > 1) {
                        let index:number = Math.round(Math.floor(ratio*frameCount));
                        if (this._multiframePlayInfo) {
                            this._multiframePlayInfo.playBaseTime = Date.now();
                            this._multiframePlayInfo.playOffset = index;
                            if (!this.isPlaying()) {
                                let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
                                if (item) item.setCurrentFrame(index);
                            }
                        }
                        else {
                            let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
                            if (item) item.setCurrentFrame(index);
                        }
                    }
                }
            //}
        }
        return false;
    }

    public canSeekOffset(offset:number):boolean { 
        /*let item:OsGraphicImage = this.getPrimaryImageItem(false);
        if (item) {
            onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                if (decoder->is_ready() && !decoder->is_buffering(NULL)) 
                    return OSTRUE;
            }
        }*/
        return false;
    }
    public seekOffset(offset:number):boolean { 
        /*let item:OsGraphicImage = this.getPrimaryImageItem(false);
        if (item) {
            onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                if (decoder->is_ready() && !decoder->is_buffering(NULL)) {
                    decoder->seek_offset(offset);
                    return OSTRUE;
                }
            }
        }*/
        return false;
    }

    
    /*

    

    
    

    b32 renderer_2d::seek_offset(f64 offset) {

        onis::graphics::image_ptr item = get_primary_image_item();
        if (item != NULL) {

            onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            if (decoder != NULL) {
                
                if (decoder->is_ready() && !decoder->is_buffering(NULL)) {

                    decoder->seek_offset(offset);
                    return OSTRUE;

                }
                
            }

        }
        return OSFALSE;

    }*/

    public getCurrentTime():number {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            //onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            //if (decoder != NULL) return decoder->get_current_time();
            //else {
                let count:number = item.getFrameCount();
                let speed:number = this.getPlaySpeed();
                if (speed > 0 && count > 1) {
                    let index:number = item.getCurrentFrame();
                    if (index != -1) {
                        let ratio = index / count;
                        return ratio *this.getTotalTime();
                    }
                }
            //}
        }
        return 0;
    }

    public getTotalTime():number {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            //onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            //if (decoder != NULL) return decoder->get_total_time();
            //else {
                let count:number = item.getFrameCount();
                let speed:number = this.getPlaySpeed();
                if (speed > 0 && count > 1) return count/speed;
            //}
        }
        return 0;
    }
        
    public isBuffering(ratio:[number]|null):boolean {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            //onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            //if (decoder != NULL) return decoder->is_buffering(ratio);
            //else 
            if (this._multiframePlayInfo) {
                if (this._multiframePlayInfo.isPlaying) {
                    if (ratio) ratio[0] = this._multiframePlayInfo.bufferingProgress;
                    if (this._multiframePlayInfo.bufferingFrameCount != this._multiframePlayInfo.bufferingFrameDone)
                        return true;
                }
            }
        }
        return false;
    }

    public isStreaming(receivedTotal:[number, number]):boolean {
        receivedTotal[0] = 0;
        receivedTotal[1] = 0;
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);        
        let image:OsOpenedImage|null = item ? item.getImage() : null;
        let dcm:OsDicomFile|null = image ? image.getDicomFile() : null;
        if (dcm) {

            let type:OsRendererType|null = this.getType();
            let viewer:Viewer|null = type?type.getViewer():null;
            let manager:OsDownloadManager|null = viewer?viewer.getDownloadManager():null;
            if (image && manager && manager.isBuffering(image) > 0) {

                receivedTotal[0] = dcm.getFrameCount(true);
                receivedTotal[1] = dcm.getFrameCount(false);
                return true;

            }
            //onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
            //if (decoder != NULL) return decoder->is_streaming(received, total);

        }
        return false;

    }

    public getDefaultPlaySpeed():number {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (item) {
            let image:OsOpenedImage|null = item.getImage();
            if (image) {
                let dcm:OsDicomFile|null = image.getDicomFile();
                if (dcm) {
                    let frameRate:string = dcm.getStringElement(TAGS.TAG_RECOMMENDED_DISPLAY_FRAME_RATE, null, null);
                    if (frameRate.length > 0) {
                        let value:number = parseInt(frameRate);
                        if (value <= 0 || value >= 300) value = 1.0;
                        return value;
                    }
                }
            }
        }
        return -1.0;
    }

    public getPlaySpeed():number {

        if (this._playSpeed == 0.0) this._playSpeed = this.getDefaultPlaySpeed();
        return this._playSpeed;

    }

    public setPlaySpeed(fps:number):void {

        this._playSpeed = fps;

    }

    /*void renderer_2d::enable_auto_start(b32 enable) {

        _auto_start = enable;

    }

    b32 renderer_2d::should_auto_start() {

        return _auto_start;

    }*/

    public preloadFrameForPlay(index:number):boolean {
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (!item) return false;
        if (!item.getFrame(index)) {
            let image:OsOpenedImage|null = item.getImage();
            if (image) {
                let widthHeight:[number, number] = [0, 0];
                if (image.getDimensions33(widthHeight)) {
                    if (widthHeight[0] <= 1024 && widthHeight[1] <= 1024) {
                        let result:OsResult = new OsResult();
                        let frame:OsDicomFrame|null = image.extractFrame(index, result);
                        if (frame) {
                            item.setFrame(index, frame);
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    public nextFrame():boolean { 
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (!item) return false;
        /*onis::graphics::mpeg_decoder_ptr decoder = item->get_mpeg_decoder();
        if (decoder != NULL) {

            if (can_move_to_next_frame())
                decoder->step_to_next_frame();

        }
        else {*/
        
            let currentFrame:number = item.getCurrentFrame();
            if (currentFrame < item.getFrameCount()) {
                currentFrame++;
                item.setCurrentFrame(currentFrame);
                return true;
            }

        //}
        return false;    
    }

    public previousFrame():boolean { 
        let item:OsGraphicImage|null = this.getPrimaryImageItem(false);
        if (!item) return false;
        let currentFrame:number = item.getCurrentFrame();
        if (currentFrame > 0) {
            currentFrame--;
            item.setCurrentFrame(currentFrame);
            return true;
        }
        return false; 
    }

    //-----------------------------------------------------------------------
    //events
    //-----------------------------------------------------------------------

    public onCalibrationChanged():void {

        let annotations:OsGraphicAnnotation[] = [];
        this.getAnnotationList(annotations);
        for (let i=0; i<annotations.length; i++) {
            annotations[i].onCalibrationChanged(this);
        }
        
    }

    //-----------------------------------------------------------------------
    //toolbars
    //-----------------------------------------------------------------------

    public getToolbars(list:OsGraphicToolbar[], onlyVisible:boolean):void {
        if (!this._movieToolbar) this._movieToolbar = new OsMovieToolbar("Movie controller");
        if (onlyVisible) {
            if (this._movieToolbar.visible) 
                list.push(this._movieToolbar);
        }
        else list.push(this._movieToolbar);
    }*/

  //-----------------------------------------------------------------------
  //utilities
  //-----------------------------------------------------------------------

  bool sameF64(double v1, double v2) {
    if (v1.abs() - v2.abs() < 0.000000001) return true;
    return false;
  }

  void _updateWorldMatrices() {
    //set the view matrix:
    _info.viewInvMat.copyFrom(_info.viewMat);
    _info.viewInvMat.invert();

    //set the world matrix:
    _info.worldMat.identity();
    _info.worldInvMat.identity();
    _info.worldInvTransposeMat.identity();

    //set the world view matrix:
    _info.worldViewMat.copyFrom(_info.viewMat);
    _info.worldViewInvMat.copyFrom(_info.viewInvMat);

    //set the word view proj matrix:
    _info.worldViewProjMat.copyFrom(_info.worldMat);
    _info.worldViewProjMat.postMultiply(_info.viewMat);
    _info.worldViewProjMat.preMultiply(_info.projMat);
  }

  bool _calculateRealVisibleSizeAfterTransformation(
      OsGraphicImage img, List<double> realSize) {
    entities.Image? image = img.getImage();
    if (image == null) return false;
    List<ImageRegion> regions = [];
    ImageRegionInfo? regionInfo = image.getRegionInfo();

    if (regionInfo != null) {
      for (int i = 0; i < regionInfo.regions.length; i++) {
        regions.add(regionInfo.regions[i]);
      }
    }

    //get the real size of the image:
    (int width, int height)? widthHeight = image.getDimensions33();
    if (widthHeight == null) return false;

    double w = widthHeight.$1.toDouble();
    double h = widthHeight.$2.toDouble();

    if (regions.length == 1) {
      ImageRegion tmp = regions[0];
      if ((tmp.x0 == 0 &&
              tmp.y0 == 0 &&
              tmp.x1 == widthHeight.$1 - 1 &&
              tmp.y1 == widthHeight.$2 - 1) &&
          (tmp.spatialFormat == OsRsf.twoDim) &&
          (tmp.calibratedUnit[0] == tmp.calibratedUnit[1]) &&
          (tmp.calibratedUnit[0] == OsUnit.cm ||
              tmp.calibratedUnit[0] == OsUnit.none)) {
        w = widthHeight.$1 * tmp.calibratedSpacing[0].abs();
        h = widthHeight.$2 * tmp.calibratedSpacing[1].abs();
      }
    }

    double rot = _camera.rot[2];
    List<double> B = [0, 0, 0];
    List<double> C = [0, 0, 0];
    List<double> D = [0, 0, 0];

    //apply the rotation (normalized):
    B[0] = math.cos(rot * math.pi / 180.0);
    B[1] = math.sin(rot * math.pi / 180.0);

    //Normalize B:
    double length = math.sqrt(B[0] * B[0] + B[1] * B[1]);
    if (length != 0) {
      B[0] /= length;
      B[1] /= length;
    }

    //get our D point (vectorial product):
    List<double> z = [0.0, 0.0, 1.0];
    D[0] = z[1] * B[2] - z[2] * B[1];
    D[1] = z[2] * B[0] - z[0] * B[2];
    D[2] = z[0] * B[1] - z[1] * B[0];

    //Normalize D:
    length = math.sqrt(D[0] * D[0] + D[1] * D[1]);
    if (length != 0) {
      D[0] /= length;
      D[1] /= length;
    }

    //apply the length:
    B[0] *= w;
    B[1] *= w;
    D[0] *= h;
    D[1] *= h;

    //get our C point:
    C[0] = B[0] + D[0];
    C[1] = B[1] + D[1];

    double xmin = math.min(0, math.min(B[0], math.min(C[0], D[0])));
    double ymin = math.min(0, math.min(B[1], math.min(C[1], D[1])));
    double xmax = math.max(0, math.max(B[0], math.max(C[0], D[0])));
    double ymax = math.max(0, math.max(B[1], math.max(C[1], D[1])));

    realSize[0] = xmax - xmin;
    realSize[1] = ymax - ymin;
    return true;
  }
}
