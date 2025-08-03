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

class _TabButtonState extends State<TabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: OnisViewerConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: OnisViewerConstants.tabButtonWidth,
                height: OnisViewerConstants.tabButtonHeight,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getBorderColor(),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.pageType.icon,
                      size: 16,
                      color: _getIconColor(),
                    ),
                    const SizedBox(width: OnisViewerConstants.marginSmall),
                    Text(
                      widget.pageType.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Get background color based on state
  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return OnisViewerConstants.tabButtonActiveColor;
    }
    if (_isHovered) {
      return OnisViewerConstants.tabButtonColor.withOpacity(0.8);
    }
    return OnisViewerConstants.tabButtonColor;
  }

  /// Get border color based on state
  Color _getBorderColor() {
    if (widget.isSelected) {
      return OnisViewerConstants.tabButtonActiveColor;
    }
    if (_isHovered) {
      return OnisViewerConstants.primaryColor.withOpacity(0.5);
    }
    return Colors.transparent;
  }

  /// Get icon color based on state
  Color _getIconColor() {
    if (widget.isSelected) {
      return OnisViewerConstants.textColor;
    }
    return widget.pageType.color ?? OnisViewerConstants.textSecondaryColor;
  }

  /// Get text color based on state
  Color _getTextColor() {
    if (widget.isSelected) {
      return OnisViewerConstants.textColor;
    }
    return OnisViewerConstants.textSecondaryColor;
  }
}
