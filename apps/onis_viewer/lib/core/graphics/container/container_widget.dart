import 'package:flutter/material.dart';
import 'package:onis_viewer/core/graphics/canvas/canvas.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';

class OsContainerWidget extends StatefulWidget {
  final WeakReference<OsContainerWnd> wContainerWnd;
  OsContainerWidget({
    super.key,
    required OsContainerWnd containerWnd,
  }) : wContainerWnd = WeakReference(containerWnd);

  @override
  State<OsContainerWidget> createState() => _OsContainerWidgetState();

  get containerWnd => wContainerWnd.target;
}

class _OsContainerWidgetState extends State<OsContainerWidget> {
  late final OsPainter? _painter;

  @override
  void initState() {
    super.initState();
    final containerWnd = widget.containerWnd;
    final redrawNotifier = containerWnd?.redrawNotifier;
    if (redrawNotifier != null) _painter = OsPainter(redrawNotifier!);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerWnd = widget.containerWnd;
    final redrawNotifier = containerWnd?.redrawNotifier;
    if (containerWnd == null || redrawNotifier == null || _painter == null) {
      return const SizedBox.shrink();
    }
    OsCanvas canvas = OsCanvas(_painter);
    _painter.container = containerWnd;
    redrawNotifier.value++;
    return canvas;
  }
}
