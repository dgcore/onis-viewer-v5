import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/graphics/renderer/items/item.dart';

///////////////////////////////////////////////////////////////////////
// responder
///////////////////////////////////////////////////////////////////////

class OsGraphicResponder extends OsGraphicItem {
  bool _isRunning = false;
  bool _didRun = false;

  OsGraphicResponder({required super.type, required super.name});

  //-----------------------------------------------------------------------
  //start/stop
  //-----------------------------------------------------------------------

  bool canStart(
    OsContainerWnd container,
    int box,
    int mouseEvent,
  ) {
    return false;
  }

  bool start(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
    int mouseEvent,
  ) {
    _isRunning = true;
    _didRun = false;

    container.captureMouse(
      box,
      x,
      y,
      shiftKey,
      controlKey,
      mouseEvent,
    );

    return true;
  }

  void stop(
    OsContainerWnd container,
    int box,
    bool cancel,
  ) {
    _isRunning = false;
    container.releaseMouse(box);
  }

  bool isRunning() {
    return _isRunning;
  }

  bool didRun() {
    return _didRun;
  }

  //-----------------------------------------------------------------------
  // mouse events
  //-----------------------------------------------------------------------

  void onLeftButtonDown(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onLeftButtonUp(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onRightButtonDown(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onRightButtonUp(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onMiddleButtonDown(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onMiddleButtonUp(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onMouseMove(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onLeftButtonDoubleClick(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {}

  //-----------------------------------------------------------------------
  // keyboard events
  //-----------------------------------------------------------------------

  void onKeyDown(
    OsContainerWnd container,
    int box,
    int key,
    bool shiftKey,
    bool controlKey,
  ) {}

  void onKeyUp(
    OsContainerWnd container,
    int box,
    int key,
    bool shiftKey,
    bool controlKey,
  ) {}

  //-----------------------------------------------------------------------
  // mouse cursor
  //-----------------------------------------------------------------------

  bool onSetCursor(
    OsContainerWnd container,
    int box,
    double x,
    double y,
    bool shiftKey,
    bool controlKey,
  ) {
    return false;
  }
}
