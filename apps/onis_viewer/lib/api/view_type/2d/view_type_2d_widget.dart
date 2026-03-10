import 'package:flutter/material.dart';
import 'package:onis_viewer/api/view_type/2d/view_type_2d_wnd.dart';

class ViewType2dWidget extends StatefulWidget {
  final WeakReference<ViewType2DWnd> wViewType2DWnd;
  ViewType2dWidget({
    super.key,
    required ViewType2DWnd viewType2DWnd,
  }) : wViewType2DWnd = WeakReference(viewType2DWnd);

  @override
  State<ViewType2dWidget> createState() => _ViewType2dWidgetState();
}

class _ViewType2dWidgetState extends State<ViewType2dWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewWnd = widget.wViewType2DWnd.target;
    final container = viewWnd?.activeContainer;
    if (container == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          widget.wViewType2DWnd.target?.onTap(details.localPosition);
        },
        child: container.widget!,
      );
    }
  }
}
