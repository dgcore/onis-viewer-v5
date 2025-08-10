import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import 'site_server_connection_panel.dart';

class SiteServerLoginPanel extends StatefulWidget {
  final VoidCallback? onLogin;
  final VoidCallback? onShowProperties; // deprecated in favor of inline panel
  final String? instanceName;
  final String? initialUrl;
  final String? initialUsername;
  final String? initialPassword;
  final bool initialRemember;
  final Future<void> Function(String username, String password, bool remember)?
      onSubmitAsync;
  final bool initialSubmitting;

  const SiteServerLoginPanel({
    super.key,
    this.onLogin,
    this.onShowProperties,
    this.instanceName,
    this.initialUrl,
    this.initialUsername,
    this.initialPassword,
    this.initialRemember = false,
    this.onSubmitAsync,
    this.initialSubmitting = false,
  });

  @override
  State<SiteServerLoginPanel> createState() => _SiteServerLoginPanelState();
}

class _SiteServerLoginPanelState extends State<SiteServerLoginPanel>
    with TickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _showSettings = false;
  bool _remember = false;
  bool _canSubmit = false;
  bool _isSubmitting = false;

  void _recomputeCanSubmit() {
    final can = _userController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (can != _canSubmit && mounted) {
      setState(() => _canSubmit = can);
    } else {
      _canSubmit = can;
    }
  }

  @override
  void initState() {
    super.initState();
    _userController.text = widget.initialUsername ?? '';
    _passwordController.text = widget.initialPassword ?? '';
    _remember = widget.initialRemember;
    _isSubmitting = widget.initialSubmitting;
    _recomputeCanSubmit();
    _userController.addListener(_recomputeCanSubmit);
    _passwordController.addListener(_recomputeCanSubmit);
  }

  @override
  void didUpdateWidget(covariant SiteServerLoginPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUsername != oldWidget.initialUsername ||
        widget.initialPassword != oldWidget.initialPassword ||
        widget.initialRemember != oldWidget.initialRemember) {
      _userController.text = widget.initialUsername ?? '';
      _passwordController.text = widget.initialPassword ?? '';
      _remember = widget.initialRemember;
      _recomputeCanSubmit();
    }
    if (widget.initialSubmitting != oldWidget.initialSubmitting) {
      _isSubmitting = widget.initialSubmitting;
    }
  }

  @override
  void dispose() {
    _userController.removeListener(_recomputeCanSubmit);
    _passwordController.removeListener(_recomputeCanSubmit);
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
              constraints.maxWidth < 440 ? constraints.maxWidth - 48 : 360.0;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    reverseDuration: const Duration(milliseconds: 250),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeOutCubic,
                    sizeCurve: Curves.decelerate,
                    firstChild: _buildHeaderLoginOnly(),
                    secondChild: _buildHeaderSettingsOnly(),
                    crossFadeState: _showSettings
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _showSettings
                        ? _buildConnectionSettings()
                            .withKey(const ValueKey('settings'))
                        : _buildLoginForm().withKey(const ValueKey('login')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Headers (separated for smooth cross-fade)
  Widget _buildHeaderSettingsOnly() {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: OnisViewerConstants.primaryColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderLoginOnly() {
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
                'Login',
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

  // Login form content
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            tooltip: _isPasswordHidden ? 'Show password' : 'Hide password',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              _isPasswordHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: OnisViewerConstants.textSecondaryColor,
            ),
            onPressed: () =>
                setState(() => _isPasswordHidden = !_isPasswordHidden),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildTonalButton(
              icon: Icons.settings_outlined,
              label: 'Connection settings',
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _showSettings = true),
            ),
            const Spacer(),
            _buildPrimaryButton(
              label: _isSubmitting ? 'Signing in...' : 'Sign in',
              isLoading: _isSubmitting,
              onPressed: (!_canSubmit || _isSubmitting)
                  ? null
                  : (widget.onSubmitAsync != null
                      ? () async {
                          setState(() => _isSubmitting = true);
                          try {
                            await widget.onSubmitAsync!.call(
                              _userController.text,
                              _passwordController.text,
                              _remember,
                            );
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        }
                      : (widget.onLogin ?? () {})),
            ),
          ],
        ),
      ],
    );
  }

  // Connection settings content
  Widget _buildConnectionSettings() {
    return SiteServerConnectionPanel(
      initialUrl: widget.initialUrl,
      initialInstanceName: widget.instanceName,
      onSave: () => setState(() => _showSettings = false),
      onCancel: () => setState(() => _showSettings = false),
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
                  enabled: !_isSubmitting,
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
        if (label == 'Password') ...[
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Remember me',
                  style: TextStyle(
                    color: OnisViewerConstants.textSecondaryColor,
                    fontSize: 13,
                  )),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton(
      {required String label,
      VoidCallback? onPressed,
      bool isLoading = false}) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
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

extension _WithKey on Widget {
  Widget withKey(Key key) => KeyedSubtree(key: key, child: this);
}
