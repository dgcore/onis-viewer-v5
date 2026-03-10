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
}

class _OsContainerWidgetState extends State<OsContainerWidget> {
  final redrawNotifier = ValueNotifier<int>(0);
  late final OsPainter _painter = OsPainter(redrawNotifier);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerWnd = widget.wContainerWnd.target;
    if (containerWnd == null) return const SizedBox.shrink();
    OsCanvas canvas = OsCanvas(_painter);
    _painter.container = containerWnd;
    redrawNotifier.value++;
    return canvas;
  }
}
