import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// Modern database toolbar widget with contemporary design
class DatabaseToolbar extends StatelessWidget {
  final VoidCallback? onPreferences;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onTransfer;
  final VoidCallback? onOpen;
  final String? selectedLocation;
  final List<String>? availableLocations;
  final ValueChanged<String>? onLocationChanged;
  final VoidCallback? onSearch;

  const DatabaseToolbar({
    super.key,
    this.onPreferences,
    this.onImport,
    this.onExport,
    this.onTransfer,
    this.onOpen,
    this.selectedLocation,
    this.availableLocations,
    this.onLocationChanged,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 800; // Single threshold

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: OnisViewerConstants.surfaceColor, // Use app's surface color
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade800, // Darker border for dark mode
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), // Darker shadow
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Left side - Primary actions
                Row(
                  children: [
                    if (!isVeryNarrow) ...[
                      // Full layout - all buttons with labels
                      _buildPrimaryButton(
                        icon: Icons.folder_open_outlined,
                        label: 'Open',
                        onPressed: onOpen,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 12),
                      _buildPrimaryButton(
                        icon: Icons.download_outlined,
                        label: 'Import',
                        onPressed: onImport,
                      ),
                      const SizedBox(width: 12),
                      _buildPrimaryButton(
                        icon: Icons.upload_outlined,
                        label: 'Export',
                        onPressed: onExport,
                      ),
                      const SizedBox(width: 12),
                      _buildPrimaryButton(
                        icon: Icons.swap_horiz_outlined,
                        label: 'Transfer',
                        onPressed: onTransfer,
                      ),
                    ] else ...[
                      // Very narrow layout - icon-only buttons
                      _buildIconOnlyButton(
                        icon: Icons.folder_open_outlined,
                        tooltip: 'Open',
                        onPressed: onOpen,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 8),
                      _buildIconOnlyButton(
                        icon: Icons.download_outlined,
                        tooltip: 'Import',
                        onPressed: onImport,
                      ),
                      const SizedBox(width: 8),
                      _buildIconOnlyButton(
                        icon: Icons.upload_outlined,
                        tooltip: 'Export',
                        onPressed: onExport,
                      ),
                      const SizedBox(width: 8),
                      _buildIconOnlyButton(
                        icon: Icons.swap_horiz_outlined,
                        tooltip: 'Transfer',
                        onPressed: onTransfer,
                      ),
                    ],
                  ],
                ),

                const Spacer(),

                // Right side - Controls and Settings
                Row(
                  children: [
                    // Location selector - hide if very narrow
                    if (!isVeryNarrow) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800, // Dark background
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey.shade700), // Dark border
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: OnisViewerConstants
                                  .textSecondaryColor, // Use app's text color
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedLocation ?? 'Local computer',
                              style: TextStyle(
                                color: OnisViewerConstants
                                    .textSecondaryColor, // Use app's text color
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: OnisViewerConstants
                                  .textSecondaryColor, // Use app's text color
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Search button
                    _buildControlButton(
                      icon: Icons.search_outlined,
                      onPressed: onSearch,
                      tooltip: 'Search',
                    ),
                    const SizedBox(width: 8),

                    // Settings button (far right)
                    _buildSecondaryButton(
                      icon: Icons.settings_outlined,
                      tooltip: 'Preferences',
                      onPressed: onPreferences,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a primary action button
  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary
                ? OnisViewerConstants.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey.shade600), // Dark border
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? Colors.white
                    : OnisViewerConstants.textColor, // Use app's text color
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : OnisViewerConstants.textColor, // Use app's text color
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a secondary action button (icon only)
  Widget _buildSecondaryButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade800, // Dark background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700), // Dark border
          ),
          child: Icon(
            icon,
            size: 20,
            color:
                OnisViewerConstants.textSecondaryColor, // Use app's text color
          ),
        ),
      ),
    );
  }

  /// Build a control button
  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onPressed,
    String? tooltip,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade800, // Dark background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700), // Dark border
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ??
                OnisViewerConstants.textSecondaryColor, // Use app's text color
          ),
        ),
      ),
    );
  }

  /// Build an icon-only button for very narrow layouts
  Widget _buildIconOnlyButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary
                ? OnisViewerConstants.primaryColor
                : Colors.grey.shade800, // Dark background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700), // Dark border
          ),
          child: Icon(
            icon,
            size: 20,
            color: isPrimary
                ? Colors.white
                : OnisViewerConstants
                    .textSecondaryColor, // Use app's text color
          ),
        ),
      ),
    );
  }
}

/// Extension to add database toolbar to any widget
extension DatabaseToolbarExtension on Widget {
  Widget withDatabaseToolbar({
    VoidCallback? onPreferences,
    VoidCallback? onImport,
    VoidCallback? onExport,
    VoidCallback? onTransfer,
    VoidCallback? onOpen,
    String? selectedLocation,
    List<String>? availableLocations,
    ValueChanged<String>? onLocationChanged,
    VoidCallback? onSearch,
  }) {
    return Column(
      children: [
        DatabaseToolbar(
          onPreferences: onPreferences,
          onImport: onImport,
          onExport: onExport,
          onTransfer: onTransfer,
          onOpen: onOpen,
          selectedLocation: selectedLocation,
          availableLocations: availableLocations,
          onLocationChanged: onLocationChanged,
          onSearch: onSearch,
        ),
        Expanded(child: this),
      ],
    );
  }
}
