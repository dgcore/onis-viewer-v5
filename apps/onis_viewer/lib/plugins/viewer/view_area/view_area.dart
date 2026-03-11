import 'package:flutter/material.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

/// Border widths for view area leaf widgets (in logical pixels).
class ViewAreaBorderWidth {
  const ViewAreaBorderWidth({
    this.separator = 1.0,
    this.active = 3.0,
    this.dragHighlight = 3.0,
  });

  /// Border width for the separator between leaf widgets.
  final double separator;

  /// Border width for the active leaf widget (blue border).
  final double active;

  /// Border width when a drag is over the leaf (drop target highlight).
  final double dragHighlight;
}

/// View area widget that builds widgets following the layout tree structure
class ViewArea extends StatefulWidget {
  final ViewLayout layout;

  /// Called when a series is dropped from the history bar onto a view cell.
  /// [node] is the layout node (view cell) that received the drop.
  final void Function(ViewLayoutNode node, entities.Series series)?
      onSeriesDropped;

  /// Border widths for leaf widgets. Omit to use defaults.
  final ViewAreaBorderWidth borderWidth;

  const ViewArea({
    required this.layout,
    this.onSeriesDropped,
    this.borderWidth = const ViewAreaBorderWidth(),
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
    //widget.layout.addListener(_onLayoutChanged);
  }

  @override
  void dispose() {
    //widget.layout.removeListener(_onLayoutChanged);
    super.dispose();
  }

  //void _onLayoutChanged() {
  //if (mounted) {
  //setState(() {});
  //}
  //}

  @override
  Widget build(BuildContext context) {
    ViewLayoutNode? zoomedNode = widget.layout.zoomedNode;
    if (zoomedNode != null) {
      return _buildNodeWidget(zoomedNode);
    }
    return _buildNodeWidget(widget.layout.rootNode);
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

  /// Build a leaf widget (single view); wraps content in DragTarget for series drop
  Widget _buildLeafWidget(ViewLayoutNode node) {
    final leafWidget = node.leafWidget;
    //final viewWnd = leafWidget?.currentViewWindow;
    //final container = viewWnd?.activeContainer;

    Widget? content = leafWidget?.currentViewWindow?.widget;
    content ??= Container(
      color: Colors.black,
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

    final container = leafWidget?.currentViewWindow?.activeContainer;

    //node.containerWnd.canDropOpenedEntity(item);

    return DragTarget<entities.Series>(
      onWillAcceptWithDetails: (details) {
        return container == null
            ? false
            : container.canDropOpenedEntity(details.data);
      },
      onAcceptWithDetails: (details) {
        if (container == null) return;
        container.onDropOpenedEntity(details.data);
        //widget.onSeriesDropped?.call(node, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isActive = node.isActive;
        // Separator border for all leaves; blue border when active or when drag-over
        final double width;
        final Color color;
        if (isHighlighted) {
          width = widget.borderWidth.dragHighlight;
          color = OnisViewerConstants.primaryColor;
        } else if (isActive) {
          width = widget.borderWidth.active;
          color = OnisViewerConstants.primaryColor;
        } else {
          width = widget.borderWidth.separator;
          color = OnisViewerConstants.tabButtonColor;
        }
        final border = Border.all(color: color, width: width);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: border,
          ),
          child: content!,
        );
      },
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
