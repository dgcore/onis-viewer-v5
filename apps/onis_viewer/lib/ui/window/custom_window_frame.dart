import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'window_controls.dart';

/// Custom window frame that removes the default title bar
class CustomWindowFrame extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showWindowControls;
  final bool enableWindowDragging;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const CustomWindowFrame({
    super.key,
    required this.child,
    this.title,
    this.showWindowControls = true,
    this.enableWindowDragging = true,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? OnisViewerConstants.backgroundColor,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          children: [
            // Custom title bar with window controls
            if (showWindowControls)
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: OnisViewerConstants.surfaceColor,
                  border: Border(
                    bottom: BorderSide(
                      color: OnisViewerConstants.tabButtonColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Title
                    if (title != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            color: OnisViewerConstants.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    // Window controls
                    const WindowControls(),
                  ],
                ),
              ),
            // Main content
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Extension to add custom window frame to any widget
extension CustomWindowFrameExtension on Widget {
  Widget withCustomWindowFrame({
    String? title,
    bool showWindowControls = true,
    bool enableWindowDragging = true,
    Color? backgroundColor,
    EdgeInsets? padding,
  }) {
    return CustomWindowFrame(
      title: title,
      showWindowControls: showWindowControls,
      enableWindowDragging: enableWindowDragging,
      backgroundColor: backgroundColor,
      padding: padding,
      child: this,
    );
  }
}
