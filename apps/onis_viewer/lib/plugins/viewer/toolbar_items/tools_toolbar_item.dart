import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/graphics/container/container_tool.dart';
import 'package:onis_viewer/core/toolbar/toolbar_item.dart';
import 'package:onis_viewer/plugins/viewer/public/viewer_api.dart';

import '../../../core/constants.dart';

class OsToolsToolbarItem extends OsToolbarItem {
  OsToolsToolbarItem(super.id, super.name);

  @override
  Widget get widget => const ToolsToolbarWidget();
}

class ToolsToolbarWidget extends StatefulWidget {
  const ToolsToolbarWidget({
    super.key,
  });

  @override
  State<ToolsToolbarWidget> createState() => _ToolsToolbarWidgetState();
}

class _ToolsToolbarWidgetState extends State<ToolsToolbarWidget> {
  ViewerApi? get _viewerApi =>
      OVApi().plugins.getPublicApi<ViewerApi>('onis_viewer_plugin');
  static const String _noToolId = '__NO_TOOL__';

  /// Exactly one tool active; default matches legacy IMGTOOL behavior.
  String _activeToolId = 'IMGTOOL_WINDOW_LEVEL';

  List<OsContainerTool> get _tools {
    return OVApi()
            .containerSupportSets
            .get('2D')
            ?.getListOfContainerTools()
            .where((tool) => tool.visible)
            .toList() ??
        const <OsContainerTool>[];
  }

  @override
  Widget build(BuildContext context) {
    if (_viewerApi == null) {
      return const SizedBox.shrink();
    }

    final tools = _tools;
    if (tools.isEmpty) {
      return const SizedBox.shrink();
    }
    final effectiveActiveToolId = _activeToolId == _noToolId
        ? _noToolId
        : tools.any((tool) => tool.id == _activeToolId)
            ? _activeToolId
            : (tools.any((tool) => tool.id == 'IMGTOOL_WINDOW_LEVEL')
                ? 'IMGTOOL_WINDOW_LEVEL'
                : tools.first.id);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.mouse),
          tooltip: 'No tool',
          color: effectiveActiveToolId == _noToolId
              ? OnisViewerConstants.primaryColor
              : OnisViewerConstants.textColor,
          onPressed: () => setState(() => _activeToolId = _noToolId),
        ),
        for (final t in tools)
          IconButton(
            icon: Icon(t.icon),
            tooltip: t.tooltip,
            color: effectiveActiveToolId == t.id
                ? OnisViewerConstants.primaryColor
                : OnisViewerConstants.textColor,
            onPressed: () => setState(() => _activeToolId = t.id),
          ),
      ],
    );
  }
}
