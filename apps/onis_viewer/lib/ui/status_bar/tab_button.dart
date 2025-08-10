import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/page_type.dart';

/// Individual tab button widget
class TabButton extends StatefulWidget {
  final PageType pageType;
  final bool isSelected;
  final VoidCallback onPressed;

  const TabButton({
    super.key,
    required this.pageType,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border(
              bottom: BorderSide(
                color: _getBorderColor(),
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.pageType.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.normal,
                  color: _getTextColor(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get background color based on state
  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return Colors.transparent;
    }
    if (_isHovered) {
      return OnisViewerConstants.tabButtonColor.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  /// Get border color based on state
  Color _getBorderColor() {
    if (widget.isSelected) {
      return OnisViewerConstants.primaryColor;
    }
    return Colors.transparent;
  }

  /// Get text color based on state
  Color _getTextColor() {
    if (widget.isSelected) {
      return OnisViewerConstants.primaryColor;
    }
    return OnisViewerConstants.textSecondaryColor;
  }
}
