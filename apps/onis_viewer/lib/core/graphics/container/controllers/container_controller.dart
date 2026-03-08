import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/onis_exception.dart';

class OsContainerController {
  WeakReference<OsContainerWnd>? _wcontainer;

  OsContainerController();

  OsContainerWnd? get container => _wcontainer?.target;
  set container(OsContainerWnd? container) {
    if (_wcontainer != null) {
      throw OnisException(
          OnisErrorCodes.logicError, 'The controller already has a container');
    }
    _wcontainer =
        container != null ? WeakReference<OsContainerWnd>(container) : null;
  }

  //renderer type:
  /*public createRenderer():OsRenderer|null { return null; }
    public getRendererElements():Array<OsRenderer> { return []; }

    //series:
    public canAddSeries(list =Array<OsOpenedSeries>):boolean { return false; }
    public addSeries(series =OsOpenedSeries, notify =boolean, fromHangingProtocol =boolean, modifiedContainers =Array<OsContainerWnd>|null):void;
    //virtual void remove_series(const onis::opened_series_ptr &series, b32 notify, container_wnd_list *modified_containers) = 0;
    public resetContent(notify =boolean, resetSynchro =boolean, modifiedContainers =OsContainerWnd[]|null) {}
    public isSeriesDisplayed(series =OsOpenedSeries):boolean { return false; }
    public getDisplayedSeries(list =OsOpenedSeries[]):void;
    public isStillDownloading():boolean { return false; }
    public getLoadingProgression():number { return 0; }
    public onPreloadedRenderer(render =OsRenderer):void;
    //virtual void preload_renderer(const renderer_ptr &render, const preload_renderer_info_ptr &info) = 0;
    public preloadRenderers():void;

    //study:
    public isStudyDisplayed(study =OsOpenedStudy):boolean { return false; }

    //patient:
    public isPatientDisplayed(study =OsOpenedPatient):boolean { return false; }

    //states:
    public setStateId(id =string):void;
    public getStateId():string { return ''; }
    public getSeriesState(series =OsOpenedSeries, forSaving =boolean):OsSeriesState|null { return null; }
    public setSeriesState(state =OsSeriesState):boolean { return false; }

    //-----------------------------------------------------------------------
    //annotations
    //-----------------------------------------------------------------------

    public haveAnnotations(inSelectedImageOnly =boolean):boolean {
        let list:IRenderer[] = this.getRendererElements();
        for (let itinnumber=0; it<list.length; it++) {
            if (list[it].isHidden()) continue;
            if (inSelectedImageOnly) 
                if (!list[it].isSelected())
                    continue;
            if (list[it].haveAnnotations(2)) return true;
        }
        return false;
    }

    public deleteSelectedAnnotations(message =boolean, redraw =boolean):number {
        let ret:number = 0;
        let list:IRenderer[] = this.getRendererElements();
        for (let itinnumber=0; it<list.length; it++) {
            if (list[it].isHidden()) continue;
            if (list[it].isSelected())
                if (list[it].deleteAnnotations(1) != 0) {
                    ret = 2;
                    break;
                }
        }
        if (message && ret != 0) {
            if (this._viewer) {
                this._viewer.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this.getWindow());
                this._viewer.sendMessage(MSG.ANNOTATION_DELETE, this.getWindow());
            }
        }
        if (ret != 0 && redraw) {
            let container:OsContainerWnd|null = this.getWindow();
        }
        return ret;
    }

    public deleteAnnotations(inSelectedImageOnly =boolean, message =boolean, redraw =boolean):number {
        let ret:number = 0;
        let list:IRenderer[] = this.getRendererElements();
        for (let itinnumber=0; it<list.length; it++) {
            if (list[it].isHidden()) continue;
            if (inSelectedImageOnly)
                if (!list[it].isSelected())
                    continue;
            let value:number = list[it].deleteAnnotations(2);
            if (value == 2) ret = 2;
            else if (value == 0) ret = value;
        }
        if ((ret != 0) && message && this._viewer) {
            if (ret == 2) this._viewer.sendMessage(MSG.ANNOTATION_SELECTION_CHANGED, this.getWindow());
            this._viewer.sendMessage(MSG.ANNOTATION_DELETE, this.getWindow());
        }
        if (ret != 0 && redraw) {
            let container:OsContainerWnd|null = this.getWindow();
            if (container) container.setCurrentPage(container.getCurrentPage(), OsContDraw.OS_FORCE_REDRAW);
        }
        return ret;
    }
    //Calibration:
    public canCalibrate():boolean { return false; }

    

    //Incoming image:
    public getIncomingImageProperties():OsIncomingImageProperties|null { return null; }

    //Reorder
    public canReorder():boolean { return false; }
    public getSupportedReorderId(ids =string[], names =string[]):void;
    public reorder(info =OsImageContainerSortingInfo):boolean { return false; }  */
}
