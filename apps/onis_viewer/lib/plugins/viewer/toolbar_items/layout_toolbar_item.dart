import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/toolbar/toolbar_item.dart';
import 'package:onis_viewer/plugins/viewer/public/viewer_api.dart';

import '../../../core/constants.dart';

class OsLayoutToolbarItem extends OsToolbarItem {
  OsLayoutToolbarItem(super.id, super.name);

  @override
  Widget get widget => const LayoutToolbarWidget();
}

class LayoutToolbarWidget extends StatefulWidget {
  const LayoutToolbarWidget({
    super.key,
  });

  @override
  State<LayoutToolbarWidget> createState() => _LayoutToolbarWidgetState();
}

class _LayoutToolbarWidgetState extends State<LayoutToolbarWidget> {
  ViewLayout? get _layout =>
      OVApi().plugins.getPublicApi<ViewerApi>('onis_viewer_plugin')?.layout;

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    if (layout == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Layout grid: menu from 1x1 to 4x4
        IconButton(
          icon: const Icon(Icons.grid_view),
          tooltip: 'Layout (rows × columns)',
          color: OnisViewerConstants.textColor,
          onPressed: () => _showLayoutMenu(context, layout),
        ),
        // Zoom: zoom in on active cell or zoom out
        AnimatedBuilder(
          animation: layout,
          builder: (context, _) {
            final isZoomed = layout.zoomedNode != null;
            final canZoomOut = isZoomed;
            final canZoomIn = layout.canZoom();
            final enabled = canZoomIn || canZoomOut;
            return IconButton(
              icon: Icon(isZoomed ? Icons.fullscreen_exit : Icons.fullscreen),
              tooltip: isZoomed ? 'Zoom out' : 'Zoom to current view',
              color: enabled
                  ? OnisViewerConstants.textColor
                  : OnisViewerConstants.textSecondaryColor,
              onPressed: enabled ? () => _toggleZoom(layout) : null,
            );
          },
        ),
      ],
    );
  }

  void _showLayoutMenu(BuildContext context, ViewLayout layout) {
    final rowCol = <int>[1, 1];
    layout.getTiling(rowCol);
    final currentRows = rowCol[0];
    final currentCols = rowCol[1];

    showMenu<int>(
      context: context,
      position: _menuPosition(context),
      items: [
        for (int r = 1; r <= 4; r++)
          for (int c = 1; c <= 4; c++)
            PopupMenuItem<int>(
              value: r * 10 + c,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r == currentRows && c == currentCols)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.check, size: 20),
                    ),
                  Text('$r × $c'),
                ],
              ),
            ),
      ],
    ).then((value) {
      if (value != null && mounted) {
        final rows = value ~/ 10;
        final cols = value % 10;
        layout.setTiling(rows, cols);
        layout.notifyLayoutChanged();
      }
    });
  }

  RelativeRect _menuPosition(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return const RelativeRect.fromLTRB(0, 0, 100, 100);
    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;
    return RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + size.height,
      topLeft.dx + size.width,
      topLeft.dy + size.height + 8,
    );
  }

  void _toggleZoom(ViewLayout layout) {
    if (layout.zoomedNode != null) {
      layout.zoom(null);
    } else if (layout.canZoom() && layout.activeNode != null) {
      layout.zoom(layout.activeNode);
    }
    layout.notifyLayoutChanged();
  }
}
