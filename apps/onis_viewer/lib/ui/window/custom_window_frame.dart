import 'package:flutter/material.dart';

import '../../core/constants.dart';

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
        child: child,
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
