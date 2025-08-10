import 'package:flutter/material.dart';

import '../../../../core/constants.dart';

class SiteServerConnectionPanel extends StatefulWidget {
  final String? initialUrl;
  final String? initialInstanceName;
  final ValueChanged<String>? onUrlChanged;
  final ValueChanged<String>? onInstanceNameChanged;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const SiteServerConnectionPanel({
    super.key,
    this.initialUrl,
    this.initialInstanceName,
    this.onUrlChanged,
    this.onInstanceNameChanged,
    this.onSave,
    this.onCancel,
  });

  @override
  State<SiteServerConnectionPanel> createState() =>
      _SiteServerConnectionPanelState();
}

class _SiteServerConnectionPanelState extends State<SiteServerConnectionPanel> {
  late final TextEditingController _urlController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _nameController =
        TextEditingController(text: widget.initialInstanceName ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth < 560 ? constraints.maxWidth - 48 : 520.0;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon + title (no cancel here)
              Row(
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: OnisViewerConstants.primaryColor
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: OnisViewerConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Connection settings',
                    style: TextStyle(
                      color: OnisViewerConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Connection URL',
                controller: _urlController,
                hintText: 'https://your-site-server.example',
                icon: Icons.link_outlined,
                onChanged: widget.onUrlChanged,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                label: 'Instance name',
                controller: _nameController,
                hintText: 'My Site Server',
                icon: Icons.badge_outlined,
                onChanged: widget.onInstanceNameChanged,
              ),
              const SizedBox(height: 18),
              // Bottom actions: Cancel (left) and Save (right)
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onCancel ?? () {},
                    style: TextButton.styleFrom(
                      foregroundColor: OnisViewerConstants.textSecondaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OnisViewerConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        elevation: 0,
                      ),
                      onPressed: widget.onSave ?? () {},
                      child: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: OnisViewerConstants.textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2A2B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon,
                  size: 18, color: OnisViewerConstants.textSecondaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: const TextStyle(
                        color: OnisViewerConstants.textSecondaryColor),
                  ),
                  style: const TextStyle(
                    color: OnisViewerConstants.textColor,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }
}
