import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/plugins/viewer/public/viewer_api.dart';

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
    final toolbar =
        OVApi().plugins.getPublicApi<ViewerApi>('onis_viewer_plugin')?.toolbar;
    if (toolbar == null) {
      return Container(
          height: height,
          width: double.infinity,
          color: OnisViewerConstants.surfaceColor,
          padding: const EdgeInsets.symmetric(
            horizontal: OnisViewerConstants.paddingMedium,
          ),
          child: SizedBox());
    }

    return AnimatedBuilder(
        animation: toolbar,
        builder: (context, child) {
          return Container(
              height: height,
              width: double.infinity,
              color: OnisViewerConstants.surfaceColor,
              padding: const EdgeInsets.symmetric(
                horizontal: OnisViewerConstants.paddingMedium,
              ),
              child: Row(
                children: toolbar.items.map((item) => item.widget).toList(),
              ));
        });
  }
}
