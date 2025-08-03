import 'package:flutter/material.dart';

/// Widget that allows dragging the window by clicking and dragging on it
class WindowDragger extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const WindowDragger({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<WindowDragger> createState() => _WindowDraggerState();
}

class _WindowDraggerState extends State<WindowDragger> {
  bool _isDragging = false;
  Offset? _dragStartPosition;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: MouseRegion(
        cursor:
            _isDragging ? SystemMouseCursors.move : SystemMouseCursors.basic,
        child: widget.child,
      ),
    );
  }

  /// Handle pan start
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
    });

    // In a real implementation, this would start window dragging
    // For now, we'll just log the action
    debugPrint('Start window drag at ${details.globalPosition}');
  }

  /// Handle pan update
  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStartPosition != null) {
      final delta = details.globalPosition - _dragStartPosition!;

      // In a real implementation, this would move the window
      // For now, we'll just log the action
      debugPrint('Window drag delta: $delta');
    }
  }

  /// Handle pan end
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
    });

    // In a real implementation, this would end window dragging
    // For now, we'll just log the action
    debugPrint('End window drag');
  }
}
