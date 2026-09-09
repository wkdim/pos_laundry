import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';

class ChangePasswordDialog extends StatefulWidget {
  final Map<String, dynamic> admin;
  const ChangePasswordDialog({super.key, required this.admin});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.changePassword(
        widget.admin['Username'],
        _oldCtrl.text,
        _newCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Password changed successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on Exception catch (e) {
      String message = 'Failed to change password.';
      if (e.toString().contains('incorrect') ||
          e.toString().contains('wrong')) {
        message = 'Current password is incorrect.';
      } else if (e.toString().contains('database') ||
          e.toString().contains('sql')) {
        message = 'Database error. Please try again later.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) return 'Current password is required';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _newCtrl.text) return 'Passwords do not match';
    return null;
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: isDark ? colorScheme.surfaceVariant : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildMobileBody(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _oldCtrl,
              decoration: _fieldDecoration(
                label: 'Current Password',
                icon: Icons.lock_outline,
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              obscureText: _obscureOld,
              validator: _validateCurrentPassword,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _newCtrl,
              decoration: _fieldDecoration(
                label: 'New Password',
                icon: Icons.vpn_key,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              obscureText: _obscureNew,
              validator: _validateNewPassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_confirmCtrl.text.isNotEmpty)
                  _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _confirmCtrl,
              decoration: _fieldDecoration(
                label: 'Confirm New Password',
                icon: Icons.check_circle_outline,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              obscureText: _obscureConfirm,
              validator: _validateConfirmPassword,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors2.amber.withOpacity(0.12)
                    : AppColors2.amber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors2.amber.withOpacity(0.22)
                      : AppColors2.amber.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: AppColors2.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Strong password recommendations',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors2.amber.withOpacity(0.95)
                              : AppColors2.amber.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Tip('At least 8 characters'),
                  _Tip('Include uppercase & lowercase letters'),
                  _Tip('Include at least one number'),
                  _Tip('Avoid names, dates or common words'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final actions = Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: AppColors2.textPrimary,
              side: BorderSide(color: AppColors2.border),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_reset),
            label: Text(_loading ? 'Changing...' : 'Change Password'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors2.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors2.bg,
      appBar: AppBar(
        backgroundColor: AppColors2.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors2.border, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF2196F3)),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors2.blue, AppColors2.blueDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors2.blue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors2.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: form),
            actions,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    if (isMobilePlatform) return _buildMobileBody(context, isDark);

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.deepPurple.shade700, Colors.deepPurple.shade500]
                      : [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade200,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep your account secure',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _oldCtrl,
                        decoration: _fieldDecoration(
                          label: 'Current Password',
                          icon: Icons.lock_outline,
                          obscure: _obscureOld,
                          onToggle: () =>
                              setState(() => _obscureOld = !_obscureOld),
                        ),
                        obscureText: _obscureOld,
                        validator: _validateCurrentPassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _newCtrl,
                        decoration: _fieldDecoration(
                          label: 'New Password',
                          icon: Icons.vpn_key,
                          obscure: _obscureNew,
                          onToggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        obscureText: _obscureNew,
                        validator: _validateNewPassword,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          // Re-validate confirm field when new password changes
                          if (_confirmCtrl.text.isNotEmpty) {
                            _formKey.currentState?.validate();
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _confirmCtrl,
                        decoration: _fieldDecoration(
                          label: 'Confirm New Password',
                          icon: Icons.check_circle_outline,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        obscureText: _obscureConfirm,
                        validator: _validateConfirmPassword,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),

                      // Password strength hint
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.amber.shade900.withOpacity(0.12)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.amber.shade700
                                : Colors.amber.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Strong password recommendations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.amber.shade200
                                        : Colors.amberAccent[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _Tip('At least 8 characters'),
                            _Tip('Include uppercase & lowercase letters'),
                            _Tip('Include at least one number'),
                            _Tip('Avoid names, dates or common words'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outline),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_reset),
                    label: Text(_loading ? 'Changing...' : 'Change Password'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;

  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: isDark ? Colors.greenAccent : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
