import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

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
    final appTheme = context.appTheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: appTheme.appBarBg,
        border: Border(
          bottom: BorderSide(color: appTheme.panelBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Row(
              children: [
                _buildButton('Open', Icons.folder_open_outlined,
                    canOpen ? onOpen : null, true, scheme, appTheme),
                const SizedBox(width: 12),
                _buildButton('Import', Icons.download_outlined,
                    canImport ? onImport : null, false, scheme, appTheme),
                const SizedBox(width: 12),
                _buildButton('Export', Icons.upload_outlined,
                    canExport ? onExport : null, false, scheme, appTheme),
                const SizedBox(width: 12),
                _buildButton('Transfer', Icons.swap_horiz_outlined,
                    canTransfer ? onTransfer : null, false, scheme, appTheme),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildIconButton(
                    Icons.search_outlined, canSearch ? onSearch : null, appTheme, scheme),
                const SizedBox(width: 8),
                _buildIconButton(Icons.settings_outlined, onPreferences, appTheme, scheme),
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
    AppTheme appTheme,
  ) {
    final isEnabled = onPressed != null;
    final disabledColor = appTheme.textSecondary.withValues(alpha: 0.45);
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
                        ? appTheme.panelBorder
                        : appTheme.panelBorder.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: isEnabled
                      ? (isPrimary
                          ? Colors.white
                          : appTheme.textPrimary)
                      : disabledColor),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: isEnabled
                          ? (isPrimary
                              ? Colors.white
                              : appTheme.textPrimary)
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
    AppTheme appTheme,
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
            color: appTheme.mutedIconBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: appTheme.panelBorder),
          ),
          child: Icon(icon,
              size: 20,
              color: isEnabled
                  ? appTheme.textSecondary
                  : appTheme.textSecondary.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
