import 'package:flutter/material.dart';

import '../../../../core/constants.dart';

class SiteServerLoginPanel extends StatefulWidget {
  final VoidCallback? onLogin;
  final VoidCallback? onShowProperties;
  final String? instanceName;

  const SiteServerLoginPanel({
    super.key,
    this.onLogin,
    this.onShowProperties,
    this.instanceName,
  });

  @override
  State<SiteServerLoginPanel> createState() => _SiteServerLoginPanelState();
}

class _SiteServerLoginPanelState extends State<SiteServerLoginPanel> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth < 640 ? constraints.maxWidth - 48 : 560.0;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: OnisViewerConstants.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'User name',
                    controller: _userController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    label: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscure: _isPasswordHidden,
                    trailing: IconButton(
                      tooltip:
                          _isPasswordHidden ? 'Show password' : 'Hide password',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: OnisViewerConstants.textSecondaryColor,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordHidden = !_isPasswordHidden),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildTonalButton(
                        icon: Icons.settings_outlined,
                        label: 'Connection settings',
                        onPressed: widget.onShowProperties,
                      ),
                      const Spacer(),
                      _buildPrimaryButton(
                        label: 'Sign in',
                        onPressed: widget.onLogin,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle =
        widget.instanceName != null && widget.instanceName!.isNotEmpty
            ? 'Sign in to ${widget.instanceName}'
            : 'Authentication required to access this source';
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: OnisViewerConstants.primaryColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lock_outline,
              color: OnisViewerConstants.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign in',
                style: TextStyle(
                  color: OnisViewerConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: OnisViewerConstants.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
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
                  obscureText: obscure,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '',
                  ),
                  style: const TextStyle(
                    color: OnisViewerConstants.textColor,
                    fontSize: 15,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: OnisViewerConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildTonalButton(
      {required IconData icon,
      required String label,
      VoidCallback? onPressed}) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: OnisViewerConstants.textColor,
          side: BorderSide(color: Colors.grey.shade800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: onPressed,
        icon:
            Icon(icon, size: 18, color: OnisViewerConstants.textSecondaryColor),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
