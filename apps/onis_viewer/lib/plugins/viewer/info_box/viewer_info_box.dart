import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// Resizable info box widget for the viewer page
/// Displayed on the right side, can be resized by the user
class ViewerInfoBox extends StatefulWidget {
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final Map<String, String> infoItems;

  const ViewerInfoBox({
    super.key,
    this.initialWidth = 300.0,
    this.minWidth = 200.0,
    this.maxWidth = 600.0,
    this.infoItems = const {},
  });

  @override
  State<ViewerInfoBox> createState() => _ViewerInfoBoxState();
}

class _ViewerInfoBoxState extends State<ViewerInfoBox> {
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
              color: OnisViewerConstants.surfaceColor,
              border: Border(
                left: BorderSide(
                  color: OnisViewerConstants.tabButtonColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: OnisViewerConstants.tabBarColor,
                    border: Border(
                      bottom: BorderSide(
                        color: OnisViewerConstants.tabButtonColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: OnisViewerConstants.textColor,
                      ),
                      SizedBox(width: OnisViewerConstants.marginMedium),
                      Text(
                        'Image Information',
                        style: TextStyle(
                          color: OnisViewerConstants.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Info items
                Expanded(
                  child: widget.infoItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outlined,
                                size: 48,
                                color: OnisViewerConstants.textSecondaryColor,
                              ),
                              const SizedBox(
                                  height: OnisViewerConstants.marginMedium),
                              Text(
                                'No information available',
                                style: TextStyle(
                                  color: OnisViewerConstants.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(
                              OnisViewerConstants.paddingMedium),
                          children: widget.infoItems.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: OnisViewerConstants.marginMedium,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: OnisViewerConstants.textSecondaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: OnisViewerConstants.marginSmall),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: OnisViewerConstants.textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),

          // Resize handle on the left side
          Positioned(
            left: 0,
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
                  _width = (_width - details.delta.dx).clamp(
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

