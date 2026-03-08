import 'package:flutter/material.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';

class OsContainerWidget extends StatefulWidget {
  final WeakReference<OsContainerWnd> wContainerWnd;
  OsContainerWidget({
    super.key,
    required OsContainerWnd containerWnd,
  }) : wContainerWnd = WeakReference(containerWnd);

  @override
  State<OsContainerWidget> createState() => _OsContainerWidgetState();
}

class _OsContainerWidgetState extends State<OsContainerWidget> {
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
    final containerWnd = widget.wContainerWnd.target;
    final imageMatrix = containerWnd?.getImageMatrix();
    if (imageMatrix == null) return const SizedBox.shrink();
    final rows = imageMatrix[0];
    final cols = imageMatrix[1];
    if (rows < 1 || cols < 1) return const SizedBox.shrink();

    final borderWidth = (containerWnd?.borderWidth ?? 1.0).toDouble();
    final borderInter = (containerWnd?.borderInter ?? 1.0).toDouble();
    const Color borderColor = Color(0xFF505050);

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: borderColor),
          ),
          Positioned(
            left: borderWidth,
            top: borderWidth,
            right: borderWidth,
            bottom: borderWidth,
            child: Column(
              children: [
                for (int r = 0; r < rows; r++) ...[
                  if (r > 0) SizedBox(height: borderInter),
                  Expanded(
                    child: Row(
                      children: [
                        for (int c = 0; c < cols; c++) ...[
                          if (c > 0) SizedBox(width: borderInter),
                          Expanded(
                            child: _buildGridCell(r, c),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One cell in the grid (override or replace for custom content).
  Widget _buildGridCell(int row, int col) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _CenterCirclePainter(),
          ),
        ),
      ],
    );
  }
}

/// Draws a small circle at the center of the canvas.
class _CenterCirclePainter extends CustomPainter {
  static const double _radius = 6.0;
  static const Color _color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, _radius, Paint()..color = _color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
