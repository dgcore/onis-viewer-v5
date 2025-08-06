import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// A resizable source bar that can be dragged to resize
class ResizableSourceBar extends StatefulWidget {
  final Widget child;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const ResizableSourceBar({
    super.key,
    required this.child,
    this.initialWidth = 300.0,
    this.minWidth = 200.0,
    this.maxWidth = 600.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  State<ResizableSourceBar> createState() => _ResizableSourceBarState();
}

class _ResizableSourceBarState extends State<ResizableSourceBar> {
  late double _width;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Stack(
        children: [
          // Main content
          Container(
            width: _width,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? OnisViewerConstants.surfaceColor,
              border: Border(
                right: BorderSide(
                  color:
                      widget.borderColor ?? OnisViewerConstants.tabButtonColor,
                  width: widget.borderWidth,
                ),
              ),
            ),
            child: widget.child,
          ),

          // Resize handle
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _width = (_width + details.delta.dx).clamp(
                    widget.minWidth,
                    widget.maxWidth,
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  width: 8,
                  color: _isDragging
                      ? OnisViewerConstants.primaryColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? OnisViewerConstants.primaryColor
                            : OnisViewerConstants.tabButtonColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
