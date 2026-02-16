import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// Toolbar widget for the viewer page
/// Fixed height, full width, displayed at the top
class ViewerToolbar extends StatelessWidget {
  //final ViewerController controller;
  final double height;

  const ViewerToolbar({
    super.key,
    //required this.controller,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height,
        width: double.infinity,
        color: OnisViewerConstants.surfaceColor,
        padding: const EdgeInsets.symmetric(
          horizontal: OnisViewerConstants.paddingMedium,
        ),
        child: SizedBox());
  }
}
