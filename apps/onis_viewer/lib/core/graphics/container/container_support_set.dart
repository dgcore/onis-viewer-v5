import 'package:onis_viewer/core/graphics/container/container_tool.dart';

///////////////////////////////////////////////////////////////////////
// container_support_current_tool
///////////////////////////////////////////////////////////////////////

class OsContainerSupportCurrentTool {
  final String id;
  WeakReference<OsContainerTool>? _wTool;
  WeakReference<Object>? _wToolData;

  OsContainerSupportCurrentTool(this.id);

  ({OsContainerTool? tool, Object? data}) getTool() {
    Object? data = _wToolData?.target;
    OsContainerTool? tool = _wTool?.target;
    if (tool == null) return (tool: null, data: null);
    return (tool: tool, data: data);
  }

  void setTool(OsContainerTool? tool, Object? data) {
    _wToolData = data == null ? null : WeakReference(data);
    _wTool = tool == null ? null : WeakReference(tool);
  }
}

///////////////////////////////////////////////////////////////////////
// container_support_set
///////////////////////////////////////////////////////////////////////

class OsContainerSupportSet {
  final String _id;
  final bool _isPrivate;
  bool isCineSupported = false;
  final List<OsContainerTool> _containerTools = [];
  //private _containerActions:OsContainerAction[] = [];
  //private _annotationTypes:OsGraphicAnnotationType[] = [];
  //private _annotationActions:OsAnnotationAction[] = [];
  final List<OsContainerSupportCurrentTool> _currentTools = [];

  OsContainerSupportSet(this._id, this._isPrivate);

  //--------------------------------------------------------------
  //properties
  //--------------------------------------------------------------

  String get id => _id;
  bool get isPrivate => _isPrivate;

  //-----------------------------------------------------------------------
  //container tools
  //-----------------------------------------------------------------------

  bool registerContainerTool(OsContainerTool tool, bool reg) {
    if (reg) {
      if (findContainerTool(tool.id) != null) return false;
      _containerTools.add(tool);
    } else {
      for (final currentTool in _currentTools) {
        if (identical(currentTool.id, tool.id)) {
          currentTool.setTool(null, null);
        }
      }
      _containerTools.remove(tool);
    }
    return true;
  }

  OsContainerTool? findContainerTool(String id) {
    for (final element in _containerTools) {
      if (element.id == id) return element;
    }
    return null;
  }

  List<OsContainerTool> getListOfContainerTools() {
    return List.unmodifiable(_containerTools);
  }

  bool registerCurrentToolEntry(String id, bool reg) {
    if (reg) {
      for (final currentTool in _currentTools) {
        if (currentTool.id == id) {
          return false;
        }
      }
      _currentTools.add(OsContainerSupportCurrentTool(id));
    } else {
      for (int i = 0; i < _currentTools.length; i++) {
        if (_currentTools[i].id == id) {
          _currentTools.removeAt(i);
          break;
        }
      }
    }
    return true;
  }

  bool setCurrentTool(String id, OsContainerTool? tool, Object? data) {
    for (final currentTool in _currentTools) {
      if (currentTool.id == id) {
        currentTool.setTool(tool, data);
        return true;
      }
    }
    return false;
  }

  ({OsContainerTool? tool, Object? data}) getCurrentTool(String id) {
    for (final currentTool in _currentTools) {
      if (currentTool.id == id) {
        return currentTool.getTool();
      }
    }
    return (tool: null, data: null);
  }

  //-----------------------------------------------------------------------
  //container actions
  //-----------------------------------------------------------------------

  /*public registerContainerAction(action:OsContainerAction, reg:boolean):boolean {
        if (reg) {
            if (this.findContainerAction(action.getId())) return false;
            this._containerActions.push(action);
            action.retain();
            //if (_should_send_message()) _app->send_message(OSMSG_IMGCONT_ACTION_REGISTERED, WPARAM(this), LPARAM(action.get()));
        }
        else {
            let index:number = this._containerActions.indexOf(action);
            if (index >= 0) {
                action.release();
                this._containerActions.splice(index, 1);
            }
            //if (_should_send_message()) _app->send_message(OSMSG_IMGCONT_ACTION_UNREGISTERED, WPARAM(this), LPARAM(action.get()));
        }
        return true;
    }

    public findContainerAction(id:string):OsContainerAction|null {
        for (let i=0; i<this._containerActions.length; i++) 
            if (this._containerActions[i].getId() === id) 
                return this._containerActions[i];
        return null;
    }

    public getListOfContainerActions():OsContainerAction[] {
        return this._containerActions;
    }*/

  //-----------------------------------------------------------------------
  //annotation types
  //-----------------------------------------------------------------------

  /*public registerAnnotationType(type:OsGraphicAnnotationType, reg:boolean):boolean {
        if (reg) {
            if (this.findAnnotationType(type.getId()) != null) return false;
            this._annotationTypes.push(type);
            type.retain();
            //if (this._shouldSendMessage()) _app->send_message(OSMSG_ANNOTATION_TYPE_REGISTERED, WPARAM(this), WPARAM(type.get()));
        }
        else {
            type.retain();
            let index:number = this._annotationTypes.indexOf(type);
            if (index >= 0) {
                type.release();
                this._annotationTypes.splice(index, 1);
            }
            for (let i=0; i<this._currentTools.length; i++) {
                if (this._currentTools[i].getToolData(false) === type) {
                    this._currentTools[i].setTool(null, null);
                    break;
                }
            }
            //if (this._shouldSendMessage()) _app->send_message(OSMSG_ANNOTATION_TYPE_UNREGISTERED, WPARAM(this), LPARAM(type.get()));
            type.release();
        }
        return true;
    }

    public findAnnotationType(id:string):OsGraphicAnnotationType|null {
        for (let i=0; i<this._annotationTypes.length; i++) 
            if (this._annotationTypes[i].getId() === id) 
                return this._annotationTypes[i];
        return null;
    }

    public getListOfAnnotationTypes():OsGraphicAnnotationType[] {
        return this._annotationTypes;
    }*/

  //-----------------------------------------------------------------------
  //annotation actions
  //-----------------------------------------------------------------------

  /*public registerAnnotationAction(action:OsAnnotationAction, reg:boolean):boolean {
        if (reg) {
            if (this.findAnnotationAction(action.getId())) return false;
            this._annotationActions.push(action);
            action.retain();
            //if (_should_send_message()) _app->send_message(OSMSG_ANNOTATION_ACTION_REGISTERED, WPARAM(this), LPARAM(action.get()));
        }
        else {
            let index:number = this._annotationActions.indexOf(action);
            if (index >= 0) {
                action.release();
                this._annotationActions.splice(index, 1);
            }
            //if (_should_send_message()) _app->send_message(OSMSG_ANNOTATION_ACTION_UNREGISTERED, WPARAM(this), LPARAM(action.get()));
        }
        return true;
    }

    public findAnnotationAction(id:string):OsAnnotationAction|null {
        for (let i:number=0; i<this._annotationActions.length; i++) 
            if (this._annotationActions[i].getId() === id) 
                return this._annotationActions[i];
        return null;
    }

    public getListOfAnnotationActions():OsAnnotationAction[] {
        return this._annotationActions;
    }*/
}
