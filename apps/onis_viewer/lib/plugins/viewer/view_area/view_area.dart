import 'package:flutter/material.dart';
import 'package:onis_viewer/plugins/viewer/public/layout_controller_interface.dart';

/// Resizable info box widget for the viewer page
/// Displayed on the right side, can be resized by the user
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity, height: double.infinity, color: Colors.red);
  }
}
