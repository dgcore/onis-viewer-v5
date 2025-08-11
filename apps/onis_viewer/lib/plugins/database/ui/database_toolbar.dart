import 'package:flutter/material.dart';
import '../../../core/constants.dart';

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
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: OnisViewerConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Row(
              children: [
                _buildButton('Open', Icons.folder_open_outlined, canOpen ? onOpen : null, true),
                const SizedBox(width: 12),
                _buildButton('Import', Icons.download_outlined, canImport ? onImport : null),
                const SizedBox(width: 12),
                _buildButton('Export', Icons.upload_outlined, canExport ? onExport : null),
                const SizedBox(width: 12),
                _buildButton('Transfer', Icons.swap_horiz_outlined, canTransfer ? onTransfer : null),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildIconButton(Icons.search_outlined, canSearch ? onSearch : null),
                const SizedBox(width: 8),
                _buildIconButton(Icons.settings_outlined, onPreferences),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback? onPressed, [bool isPrimary = false]) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary && isEnabled ? OnisViewerConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isPrimary ? null : Border.all(color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade700),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isEnabled ? (isPrimary ? Colors.white : OnisViewerConstants.textColor) : OnisViewerConstants.textSecondaryColor.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isEnabled ? (isPrimary ? Colors.white : OnisViewerConstants.textColor) : OnisViewerConstants.textSecondaryColor.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onPressed) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Icon(icon, size: 20, color: isEnabled ? OnisViewerConstants.textSecondaryColor : OnisViewerConstants.textSecondaryColor.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
