import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';

class RawPointerInfo {
  int id;
  PointerDeviceKind kind;
  Offset originalPosition = const Offset(0, 0);
  Offset originalLocalPosition = const Offset(0, 0);
  Offset delta = const Offset(0, 0);
  Offset position = const Offset(0, 0);
  Offset localDelta = const Offset(0, 0);
  Offset localPosition = const Offset(0, 0);
  RawPointerInfo(this.id, this.kind);
}

class OsPainter extends CustomPainter {
  final ValueNotifier<int> repaintNotifier;
  late OsContainerWnd container;
  final int _operation =
      -1; //0 -> for single drag, 1 -> for scale or pan, 2 -> for tap, 3 -> for long press

  OsPainter(this.repaintNotifier) : super(repaint: repaintNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    container.context.canvas = canvas;
    container.setRect(0, 0, size.width, size.height);
    container.redraw();
  }

  @override
  bool shouldRepaint(OsPainter oldDelegate) => false;
}

class OsCanvas extends StatefulWidget {
  final OsPainter painter;

  const OsCanvas(this.painter, {super.key});

  //@override
  @override
  State<OsCanvas> createState() => OsCanvasState();
}

class OsCanvasState extends State<OsCanvas> {
  final List<RawPointerInfo> _pointers = [];
  int _operation =
      -1; //0 -> for single drag, 1 -> for scale or pan, 2 -> for tap, 3 -> for long press
  Timer? _longPressTime;

  OsCanvasState() : super();

  @override
  Widget build(BuildContext context) {
    return Focus(onKeyEvent: (FocusNode node, KeyEvent event) {
      /*if (widget.painter.container.onKeyPressed()) {
        widget.painter.repaintNotifier.value++;
      }*/
      return KeyEventResult.handled;
    }, child: Builder(builder: (context) {
      final FocusNode focusNode = Focus.of(context);
      return ClipRRect(
          child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Listener(
                onPointerHover: (event) {
                  RawPointerInfo pointer =
                      RawPointerInfo(event.pointer, event.kind);
                  _copyPointerData(event, pointer, true);
                  _handleMouseHoverEvent(pointer);
                },
                onPointerSignal: (PointerSignalEvent event) {
                  if (event is PointerScrollEvent) {
                    _handleScroll(event);
                  }
                },
                onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
                  if (_operation == -1) {
                    _operation = 1;
                    _handlePanZoomStart(_createDefaultTrackpadPointers(),
                        const Offset(0, 0), 1.0);
                  }
                },
                onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
                  if (_operation == 1) {
                    _handlePanZoomUpdate(_createDefaultTrackpadPointers(),
                        Offset(event.pan.dx, event.pan.dy), event.scale);
                  }
                },
                onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
                  _abort();
                },
                onPointerDown: (event) {
                  focusNode.requestFocus();
                  RawPointerInfo? pointer = _findRawPointer(event.pointer);
                  if (pointer != null) _pointers.remove(pointer);
                  pointer = RawPointerInfo(event.pointer, event.kind);
                  _copyPointerData(event, pointer, true);
                  if (_operation != -1 ||
                      _pointers.isNotEmpty &&
                          pointer.kind != _pointers[0].kind) {
                    _abort();
                  } else {
                    _pointers.add(pointer);
                  }
                  if (_pointers.length == 1) {
                    _longPressTime?.cancel();
                    _longPressTime = null;
                    if (widget.painter.container.canLongPress(_pointers[0])) {
                      _longPressTime = Timer(
                          Duration(
                              milliseconds: _pointers[0].kind ==
                                      PointerDeviceKind.trackpad
                                  ? 500
                                  : 500), () {
                        if (_pointers.length == 1 && _operation == -1) {
                          _operation = 3;
                          _handleLongPress();
                          _abort();
                        }
                      });
                    }
                  }
                },
                onPointerUp: (event) {
                  RawPointerInfo? pointer = _findRawPointer(event.pointer);
                  if (pointer != null) {
                    _copyPointerData(event, pointer, false);
                  }
                  if (_operation == -1 && _pointers.length == 1) {
                    _operation = 2;
                    _handleTap();
                  }
                  _abort();
                },
                onPointerCancel: (event) {
                  _abort();
                },
                onPointerMove: (event) {
                  RawPointerInfo? pointer = _findRawPointer(event.pointer);
                  if (pointer == null) {
                    _abort();
                  } else {
                    if (event.position.dx != pointer.position.dx ||
                        event.position.dy != pointer.position.dy) {
                      //the pointer really moved
                      _copyPointerData(event, pointer, false);
                      if (_operation == -1) {
                        //did it move enough to trigger a drag ?
                        double trigger = 15.0;
                        if ((pointer.position.dx - pointer.originalPosition.dx)
                                    .abs() >=
                                trigger ||
                            (pointer.position.dy - pointer.originalPosition.dy)
                                    .abs() >=
                                trigger) {
                          if (_operation == -1 && _pointers.length == 1) {
                            _operation = 0;
                            _handleDragStart();
                          } else if (_operation == -1 &&
                              _pointers.length == 2) {
                            double scale = _calculateScale();
                            Offset pan = _calculatePan();
                            //debugPrint(
                            //  'pan or zoom start  ..... $scale  ${pan.dx} ${pan.dy}');
                            _operation = 1;
                            _handlePanZoomStart(_pointers, pan, scale);
                          } else {
                            _abort();
                          }
                        }
                      } else if (_operation == 0) {
                        _handleDragUpdate();
                      } else if (_operation == 1) {
                        double scale = _calculateScale();
                        Offset pan = _calculatePan();
                        //debugPrint(
                        //  'pan or zoom move  ..... $scale  ${pan.dx} ${pan.dy}');
                        _handlePanZoomUpdate(_pointers, pan, scale);
                      }
                    }
                  }
                },
                child: MouseRegion(
                    //cursor: widget.painter.container.cursor,
                    onExit: (PointerExitEvent event) => _handleMouseExit(event),
                    child: Stack(children: [
                      SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: RepaintBoundary(
                              child: CustomPaint(
                            painter: widget.painter,
                          ))),
                    ])),
              )));
    }));
  }

  RawPointerInfo? _findRawPointer(int pointer) {
    var res = _pointers.where((element) => element.id == pointer);
    return res.isEmpty ? null : res.first;
  }

  List<RawPointerInfo> _createDefaultTrackpadPointers() {
    return [
      RawPointerInfo(0, PointerDeviceKind.trackpad),
      RawPointerInfo(0, PointerDeviceKind.trackpad)
    ];
  }

  void _copyPointerData(
      var event, RawPointerInfo pointer, bool includeOriginal) {
    if (includeOriginal) {
      pointer.originalPosition = Offset(event.position.dx, event.position.dy);
      pointer.originalLocalPosition =
          Offset(event.localPosition.dx, event.localPosition.dy);
    }
    pointer.delta = Offset(event.delta.dx, event.delta.dy);
    pointer.position = Offset(event.position.dx, event.position.dy);
    pointer.localDelta = Offset(event.localDelta.dx, event.localDelta.dy);
    pointer.localPosition =
        Offset(event.localPosition.dx, event.localPosition.dy);
  }

  Offset _calculatePan() {
    double originalCenterX = (_pointers[0].originalLocalPosition.dx +
            _pointers[1].originalLocalPosition.dx) *
        0.5;
    double originalCenterY = (_pointers[0].originalLocalPosition.dy +
            _pointers[1].originalLocalPosition.dy) *
        0.5;

    double newCenterX =
        (_pointers[0].localPosition.dx + _pointers[1].localPosition.dx) * 0.5;
    double newCenterY =
        (_pointers[0].localPosition.dy + _pointers[1].localPosition.dy) * 0.5;
    return Offset(newCenterX - originalCenterX, newCenterY - originalCenterY);
  }

  double _calculateScale() {
    double originalLength = sqrt(pow(
                _pointers[0].originalLocalPosition.dx -
                    _pointers[1].originalLocalPosition.dx,
                2)
            .toDouble() +
        pow(
                _pointers[0].originalLocalPosition.dy -
                    _pointers[1].originalLocalPosition.dy,
                2)
            .toDouble());

    double newLength = sqrt(pow(
                _pointers[0].localPosition.dx - _pointers[1].localPosition.dx,
                2)
            .toDouble() +
        pow(_pointers[0].localPosition.dy - _pointers[1].localPosition.dy, 2)
            .toDouble());
    return originalLength == 0 ? 1 : newLength / originalLength;
  }

  void _abort() {
    _longPressTime?.cancel();
    _longPressTime = null;
    if (_operation == 0) {
      _handleDragEnd();
    } else if (_operation == 1) {
      _handlePanZoomEnd();
    } else {
      widget.painter.container.abortTool();
      widget.painter.repaintNotifier.value++;
    }
    _pointers.clear();
    _operation = -1;
  }

  void _handleMouseHoverEvent(RawPointerInfo pointer) {
    if (widget.painter.container.onSetCursor(pointer)) setState(() {});
    if (widget.painter.container.onMouseHover(pointer)) {
      widget.painter.repaintNotifier.value++;
    }
  }

  void _handleDragStart() {
    if (widget.painter.container.onDragStart(_pointers[0])) {
      widget.painter.repaintNotifier.value++;
    } else {
      _abort();
    }
  }

  void _handleDragEnd() {
    widget.painter.container.onDragEnd(_pointers[0]);
    widget.painter.repaintNotifier.value++;
  }

  void _handleDragUpdate() {
    widget.painter.container.onDragMove(_pointers[0]);
    widget.painter.repaintNotifier.value++;
  }

  void _handleTap() {
    widget.painter.container.onTap(_pointers[0]);
    widget.painter.repaintNotifier.value++;
  }

  void _handleLongPress() {
    widget.painter.container.onLongPress(_pointers[0]);
    widget.painter.repaintNotifier.value++;
  }

  void _handleScroll(PointerSignalEvent details) {
    Offset offset = (details as dynamic).scrollDelta;
    RawPointerInfo pointer = RawPointerInfo(-1, PointerDeviceKind.mouse);
    pointer.localPosition =
        Offset(details.localPosition.dx, details.localPosition.dy);
    pointer.localDelta = Offset(0, offset.dy);
    widget.painter.container.onMouseWheel(pointer);
    widget.painter.repaintNotifier.value++;
  }

  void _handlePanZoomStart(
      List<RawPointerInfo> pointers, Offset pan, double scale) {
    widget.painter.container.onPanZoomStart(pointers, pan, scale);
    widget.painter.repaintNotifier.value++;
  }

  void _handlePanZoomUpdate(
      List<RawPointerInfo> pointers, Offset pan, double scale) {
    widget.painter.container.onPanZoomUpdate(pointers, pan, scale);
    widget.painter.repaintNotifier.value++;
  }

  void _handlePanZoomEnd() {
    widget.painter.container.onPanZoomEnd();
    widget.painter.repaintNotifier.value++;
  }

  void _handleMouseExit(PointerExitEvent details) {
    if (widget.painter.container.onMouseExit()) {
      widget.painter.repaintNotifier.value++;
    }
  }

  /*int _getMouseBoxIndex(RawPointerInfo pointer, List<double>? rect) {
    int index = widget.painter.container.findImageBoxIndexFromPoint(pointer);
    if (index != -1) {
      final boxRect = widget.painter.container.getImageBoxRect(index);
      if (rect != null) {
        rect[0] = boxRect.x;
        rect[1] = boxRect.y;
        rect[2] = boxRect.width;
        rect[3] = boxRect.height;
      }
    } else if (rect != null) {
      rect[0] = 0;
      rect[1] = 0;
      rect[2] = 100;
      rect[3] = 100;
    }
    return index;
  }*/
}
