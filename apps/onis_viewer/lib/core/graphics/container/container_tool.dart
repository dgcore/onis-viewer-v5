import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/core/graphics/canvas/canvas.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';

class OsContainerTool {
  bool _visible = true;
  final String _id;
  final String _name;
  bool _isRunning = false;
  //protected _defaultShortcut:OsShortcut;
  bool _didRun = false;
  final int _restoreFilterType = 0;
  final IconData _icon;
  final String _tooltip;

  //-----------------------------------------------------------------------
  //constructor
  //-----------------------------------------------------------------------
  OsContainerTool(this._id, this._name, this._icon, this._tooltip);

  //-----------------------------------------------------------------------
  //properties
  //-----------------------------------------------------------------------

  String get id => _id;
  String get name => _name;
  bool get visible => _visible;
  bool get isRunning => _isRunning;
  bool get didRun => _didRun;
  IconData get icon => _icon;
  String get tooltip => _tooltip;

  //-----------------------------------------------------------------------
  //Operations
  //-----------------------------------------------------------------------

  void setVisibility({required bool value, required bool sendMessage}) {
    _visible = visible;
    if (sendMessage) {
      OVApi().messages.sendMessage(OSMSG.imageContainerToolVisibility, this);
    }
  }

  /*public getDefaultShortcut():OsShortcut {
        return this._defaultShortcut;
    }

    public getShortcut():OsShortcut|null {
        let set:OsDbPreferenceSet|null = this._viewer?this._viewer.getLocalPreferenceSet():null;
        let pset:OsDbPropertySet|null = set?set.findPropertySet('SHORTCUTS'):null;
        let cat:OsPropertyMap|null = pset?pset.findCategory('IMGTOOL'):null;
        return OsShortcut.fromArray(cat?cat.get(this._id):null);
    }*/

  //-----------------------------------------------------------------------
  //drag
  //-----------------------------------------------------------------------

  bool canDrag(
      OsContainerWnd container, bool byShortcut, RawPointerInfo pointer) {
    return false;
  }

  bool startDrag(OsContainerWnd container, RawPointerInfo pointer) {
    if (isRunning) return false;
    _isRunning = true;
    _didRun = true;
    /*if (_supportSnapshot) {
      _snapshot =
          container.render != null ? container.render!.createSnapshot() : null;
    }*/
    return true;
  }

  void drag(OsContainerWnd container, RawPointerInfo pointer) {}

  void endDrag(OsContainerWnd container, RawPointerInfo pointer, bool cancel) {
    /*if (container.render != null && _snapshot != null && didRun) {
      container.render!.pushSnapshot(_snapshot!);
      _snapshot = null;
    }*/
    _isRunning = false;
  }

  //-----------------------------------------------------------------------
  //pan / zoom
  //-----------------------------------------------------------------------

  bool canPanOrZoom(
      OsContainerWnd container, bool byShortcut, List<RawPointerInfo> info) {
    return false;
  }

  bool startPanOrZoom(OsContainerWnd container, List<RawPointerInfo> pointers,
      Offset pan, double scale) {
    if (isRunning) return false;
    _isRunning = true;
    _didRun = true;
    /*if (_supportSnapshot) {
      _snapshot =
          container.render != null ? container.render!.createSnapshot() : null;
    }*/
    return true;
  }

  void panOrZoom(OsContainerWnd container, List<RawPointerInfo> pointers,
      Offset pan, double scale) {}

  void endPanOrZoom(OsContainerWnd container, bool cancel) {
    /*if (container.render != null && _snapshot != null && didRun) {
      container.render!.pushSnapshot(_snapshot!);
      _snapshot = null;
    }*/
    _isRunning = false;
  }

  bool canLongPress(OsContainerWnd container, RawPointerInfo pointer) {
    if (_isRunning) return false;
    return true;
  }

  //-----------------------------------------------------------------------
  //mouse events
  //-----------------------------------------------------------------------

  bool onMouseHover(OsContainerWnd container, RawPointerInfo pointer) {
    return false;
  }

  void onTap(OsContainerWnd container, RawPointerInfo pointer) {}
  void onLongPress(OsContainerWnd container, RawPointerInfo pointer) {}
  bool supportMouseWheel(OsContainerWnd container, RawPointerInfo pointer) {
    return false;
  }

  void onMouseWheel(OsContainerWnd container, RawPointerInfo pointer) {}

  //-----------------------------------------------------------------------
  //abort
  //-----------------------------------------------------------------------

  void abort(OsContainerWnd container) {
    /*if (container.render != null && _snapshot != null && didRun) {
      container.render!.pushSnapshot(_snapshot!);
      _snapshot = null;
    }*/
    _isRunning = false;
  }

  //start/stop:
  /*public canStart(container:OsContainerWnd, box:number, byShortcut:boolean, x:number, y:number, flags:number):boolean { 
        return false; 
    }

    public start(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean, mouseEvent:number):boolean { 
        this._isRunning = true;
        this._didRun = false;
        this._restoreFilterType = -1;
     
        container.captureMouse(box, x, y, shiftKey, controlKey, mouseEvent);
        return true;
    }

    public stop(container:OsContainerWnd, box:number, cancel:boolean):void {
        this._isRunning = false;
        container.releaseMouse(box);
      
    }

    //Mouse events:
    public onLeftButtonDown(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onLeftButtonUp(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onRightButtonDown(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onRightButtonUp(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onMiddleButtonDown(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onMiddleButtonUp(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onMouseMove(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}
    public onLeftButtonDoubleClick(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):void {}

    //mouse cursor:
	public onSetCursor(container:OsContainerWnd, box:number, x:number, y:number, shiftKey:boolean, controlKey:boolean):boolean { return false; }
    
    //keyboard events:
    public onKeyDown(container:OsContainerWnd, box:number, key:number, shiftKey:boolean, controlKey:boolean):void {}
    public onKeyUp(container:OsContainerWnd, box:number, key:number, shiftKey:boolean, controlKey:boolean):void {}

    //drawing:
    public willDraw(container:OsContainerWnd, box:number, info:OsWillDrawInfo):void {}
    public draw(container:OsContainerWnd, box:number, driver:OsDriver):void {}*/
}
