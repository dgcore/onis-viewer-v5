import 'package:flutter/material.dart';
import 'database_theme.dart';

class DatabaseToolbar extends StatelessWidget {
  final VoidCallback? onPreferences;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onTransfer;
  final VoidCallback? onOpen;
  final String? selectedLocation;
  final VoidCallback? onSearch;

  final bool canOpen;
  final bool canImport;
  final bool canExport;
  final bool canTransfer;
  final bool canSearch;

  const DatabaseToolbar({
    super.key,
    this.onPreferences,
    this.onImport,
    this.onExport,
    this.onTransfer,
    this.onOpen,
    this.selectedLocation,
    this.onSearch,
    this.canOpen = false,
    this.canImport = false,
    this.canExport = false,
    this.canTransfer = false,
    this.canSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dbTheme = context.databaseTheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: dbTheme.appBarBg,
        border: Border(
          bottom: BorderSide(color: dbTheme.panelBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Row(
              children: [
                _buildButton('Open', Icons.folder_open_outlined,
                    canOpen ? onOpen : null, true, scheme, dbTheme),
                const SizedBox(width: 12),
                _buildButton('Import', Icons.download_outlined,
                    canImport ? onImport : null, false, scheme, dbTheme),
                const SizedBox(width: 12),
                _buildButton('Export', Icons.upload_outlined,
                    canExport ? onExport : null, false, scheme, dbTheme),
                const SizedBox(width: 12),
                _buildButton('Transfer', Icons.swap_horiz_outlined,
                    canTransfer ? onTransfer : null, false, scheme, dbTheme),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildIconButton(
                    Icons.search_outlined, canSearch ? onSearch : null, dbTheme, scheme),
                const SizedBox(width: 8),
                _buildIconButton(Icons.settings_outlined, onPreferences, dbTheme, scheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
    bool isPrimary,
    ColorScheme scheme,
    DatabaseTheme dbTheme,
  ) {
    final isEnabled = onPressed != null;
    final disabledColor = scheme.onSurface.withValues(alpha: 0.45);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary && isEnabled
                ? scheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isPrimary
                ? null
                : Border.all(
                    color: isEnabled
                        ? dbTheme.panelBorder
                        : dbTheme.panelBorder.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: isEnabled
                      ? (isPrimary
                          ? Colors.white
                          : scheme.onSurface)
                      : disabledColor),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: isEnabled
                          ? (isPrimary
                              ? Colors.white
                              : scheme.onSurface)
                          : disabledColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback? onPressed,
    DatabaseTheme dbTheme,
    ColorScheme scheme,
  ) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: dbTheme.mutedIconBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: dbTheme.panelBorder),
          ),
          child: Icon(icon,
              size: 20,
              color: isEnabled
                  ? scheme.onSurfaceVariant
                  : scheme.onSurface.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
