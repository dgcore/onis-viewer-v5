import 'package:flutter/material.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/plugins/viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/plugins/viewer/public/layout_controller_interface.dart';

/// View area widget that builds widgets following the layout tree structure
class ViewArea extends StatefulWidget {
  final ILayoutController layoutController;
  const ViewArea({
    required this.layoutController,
    super.key,
  });

  @override
  State<ViewArea> createState() => _ViewAreaState();
}

class _ViewAreaState extends State<ViewArea> {
  @override
  void initState() {
    super.initState();
    // Listen to layout changes
    widget.layoutController.addListener(_onLayoutChanged);
  }

  @override
  void dispose() {
    widget.layoutController.removeListener(_onLayoutChanged);
    super.dispose();
  }

  void _onLayoutChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildNodeWidget(widget.layoutController.rootNode);
  }

  /// Recursively build widget from a layout node
  Widget _buildNodeWidget(ViewLayoutNode node) {
    // If it's a leaf node, build the leaf widget
    if (node.isLeaf) {
      return _buildLeafWidget(node);
    }

    // If it's a split node, build the split layout
    if (node.child1 != null && node.child2 != null) {
      return _buildSplitWidget(node);
    }

    // Fallback: empty container
    return Container(
      color: OnisViewerConstants.backgroundColor,
    );
  }

  /// Build a leaf widget (single view)
  Widget _buildLeafWidget(ViewLayoutNode node) {
    final leafWidget = node.leafWidget;
    if (leafWidget == null) {
      // Empty leaf - show placeholder
      return Container(
        color: OnisViewerConstants.backgroundColor,
        child: Center(
          child: Text(
            'Empty View',
            style: TextStyle(
              color: OnisViewerConstants.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // TODO: Build actual widget from ViewLayoutNodeWidget
    // For now, return a placeholder
    return Container(
      color: Colors.black, //OnisViewerConstants.viewAreaBackgroundColor,
      child: Center(
        child: Text(
          'View Widget',
          style: TextStyle(
            color: OnisViewerConstants.textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Build a split widget (two children with divider)
  Widget _buildSplitWidget(ViewLayoutNode node) {
    final ratio = node.ratio;
    final isVertical = node.isVerticalSplit;

    if (isVertical) {
      // Vertical split: children stacked vertically
      return Column(
        children: [
          // First child
          Expanded(
            flex: (ratio * 100).round(),
            child: _buildNodeWidget(node.child1!),
          ),
          // Divider
          //_buildDivider(isVertical: true),
          // Second child
          Expanded(
            flex: ((1.0 - ratio) * 100).round(),
            child: _buildNodeWidget(node.child2!),
          ),
        ],
      );
    } else {
      // Horizontal split: children side by side
      return Row(
        children: [
          // First child
          Expanded(
            flex: (ratio * 100).round(),
            child: _buildNodeWidget(node.child1!),
          ),
          // Divider
          //_buildDivider(isVertical: false),
          // Second child
          Expanded(
            flex: ((1.0 - ratio) * 100).round(),
            child: _buildNodeWidget(node.child2!),
          ),
        ],
      );
    }
  }

  /// Build a divider between split panes
  Widget _buildDivider({required bool isVertical}) {
    return GestureDetector(
      onPanUpdate: (details) {
        // TODO: Implement resize functionality
        // This would update the ratio in the layout node
      },
      child: MouseRegion(
        cursor: isVertical
            ? SystemMouseCursors.resizeUpDown
            : SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: isVertical ? double.infinity : 4.0,
          height: isVertical ? 4.0 : double.infinity,
          color: OnisViewerConstants.tabButtonColor,
          child: Center(
            child: Container(
              width: isVertical ? double.infinity : 2.0,
              height: isVertical ? 2.0 : 40.0,
              decoration: BoxDecoration(
                color: OnisViewerConstants.primaryColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
