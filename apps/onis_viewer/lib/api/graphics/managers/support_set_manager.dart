import 'package:flutter/material.dart';
import 'package:onis_viewer/api/graphics/container/tools/container_tool_pan.dart';
import 'package:onis_viewer/api/graphics/container/tools/container_tool_rotate.dart';
import 'package:onis_viewer/api/graphics/container/tools/container_tool_scope.dart';
import 'package:onis_viewer/api/graphics/container/tools/container_tool_slider.dart';
import 'package:onis_viewer/api/graphics/container/tools/container_tool_wl.dart';
import 'package:onis_viewer/api/graphics/container/tools/container_tool_zoom.dart';
import 'package:onis_viewer/core/graphics/container/container_support_set.dart';
import 'package:onis_viewer/core/graphics/container/container_tool.dart';

class OsSContainerSupportSetManager {
  final List<OsContainerSupportSet> _containerSupportSets = [];

  OsSContainerSupportSetManager();

  void initialize() {
    final set = OsContainerSupportSet("2D", false);
    final tools = <OsContainerTool>[
      OsContainerToolWL(
        "IMGTOOL_WINDOW_LEVEL",
        "Window Level",
        Icons.contrast,
        "Window Level",
      ),
      OsContainerToolPan("IMGTOOL_PAN", "Pan", Icons.open_with, "Pan"),
      OsContainerToolRotate(
        "IMGTOOL_ROTATE",
        "Rotate",
        Icons.rotate_right,
        "Rotate",
      ),
      OsContainerToolZoom("IMGTOOL_ZOOM", "Zoom", Icons.zoom_in, "Zoom"),
      OsContainerToolScope(
        "IMGTOOL_SCOPE",
        "Scope",
        Icons.center_focus_strong_outlined,
        "Scope",
      ),
      OsContainerToolSlider(
          "IMGTOOL_SLIDER", "Slider", Icons.swap_vert, "Slider"),
    ];

    for (final tool in tools) {
      set.registerContainerTool(tool, true);
    }
    register(set);
  }

  void dispose() {
    _containerSupportSets.clear();
  }

  void register(OsContainerSupportSet set) {
    if (!_containerSupportSets.contains(set)) {
      _containerSupportSets.add(set);
    }
  }

  void unregister(OsContainerSupportSet set) {
    if (_containerSupportSets.contains(set)) {
      _containerSupportSets.remove(set);
    }
  }

  OsContainerSupportSet? get(String id) {
    final index = _containerSupportSets.indexWhere((r) => r.id == id);
    return index >= 0 ? _containerSupportSets[index] : null;
  }
}
