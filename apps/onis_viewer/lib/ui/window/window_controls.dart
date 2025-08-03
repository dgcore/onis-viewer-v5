import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// Window control buttons (minimize, maximize, close)
class WindowControls extends StatelessWidget {
  final bool showMinimize;
  final bool showMaximize;
  final bool showClose;
  final Color? backgroundColor;
  final Color? hoverColor;

  const WindowControls({
    super.key,
    this.showMinimize = true,
    this.showMaximize = true,
    this.showClose = true,
    this.backgroundColor,
    this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMinimize)
          _buildControlButton(
            icon: Icons.remove,
            onPressed: _minimizeWindow,
            tooltip: 'Minimize',
          ),
        if (showMaximize)
          _buildControlButton(
            icon: Icons.crop_square,
            onPressed: _maximizeWindow,
            tooltip: 'Maximize',
          ),
        if (showClose)
          _buildControlButton(
            icon: Icons.close,
            onPressed: _closeWindow,
            tooltip: 'Close',
            isCloseButton: true,
          ),
      ],
    );
  }

  /// Build a control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isCloseButton = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: OnisViewerConstants.windowControlSize,
            height: OnisViewerConstants.windowControlSize,
            color: backgroundColor ?? Colors.transparent,
            child: Icon(
              icon,
              size: 16,
              color: isCloseButton
                  ? OnisViewerConstants.textColor
                  : OnisViewerConstants.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Minimize the window
  void _minimizeWindow() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    // In a real implementation, this would minimize the window
    // For now, we'll just log the action
    debugPrint('Minimize window');
  }

  /// Maximize the window
  void _maximizeWindow() {
    // In a real implementation, this would maximize/restore the window
    // For now, we'll just log the action
    debugPrint('Maximize window');
  }

  /// Close the window
  void _closeWindow() {
    // In a real implementation, this would close the application
    // For now, we'll just log the action
    debugPrint('Close window');
  }
}
