import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';

class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({super.key});

  @override
  _AddAdminDialogState createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'Admin';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _user.dispose();
    _name.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await DatabaseHelper.instance.createAdmin({
        'username': _user.text,
        'fullName': _name.text,
        'password': _pass.text,
        'role': _role,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Admin account created successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Error creating admin: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    // Shared form (headerless) used inside mobile Scaffold and desktop Dialog
    final formContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Content (account credentials + personal info)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Credentials Section
                  _SectionHeader(
                    icon: Icons.lock_person,
                    title: 'Account Credentials',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _user,
                    decoration: _inputDecoration(
                      context: context,
                      label: 'Username',
                      hint: 'Enter unique username',
                      icon: Icons.person_outline,
                      required: true,
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Username is required';
                      if (v!.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pass,
                    decoration:
                        _inputDecoration(
                          context: context,
                          label: 'Password',
                          hint: 'Create a strong password',
                          icon: Icons.lock_outline,
                          required: true,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                          ),
                        ),
                    obscureText: _obscurePassword,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Password is required';
                      if (v!.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Personal Information Section
                  _SectionHeader(
                    icon: Icons.badge_outlined,
                    title: 'Personal Information',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _name,
                    decoration: _inputDecoration(
                      context: context,
                      label: 'Full Name',
                      hint: 'Enter full name',
                      icon: Icons.account_circle_outlined,
                      required: true,
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: _inputDecoration(
                      context: context,
                      label: 'Role',
                      icon: Icons.work_outline,
                    ),
                    onChanged: (v) => setState(() => _role = v!),
                    isExpanded: true,
                    menuMaxHeight: 300,
                    items: [
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(Standard access)',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'SuperAdmin',
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Super Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(Full system access)',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blueGrey.shade900.withValues(alpha: 0.18)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.blueGrey.shade700
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ensure the password is strong and keep credentials secure.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.blue.shade100
                                  : Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? colorScheme.outline : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? colorScheme.outline
                          : Colors.grey.shade400,
                    ),
                    foregroundColor: colorScheme.onSurface,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isLoading ? 'Creating...' : 'Create Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // Mobile: full-screen scaffold so form fields have a Material ancestor
    if (isMobilePlatform) {
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
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors2.blue, AppColors2.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors2.blue.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Administrator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors2.textPrimary,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(child: formContent),
      );
    }

    // Desktop / larger screens: show as dialog
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: formContent,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    String? hint,
    required IconData icon,
    bool required = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
      filled: true,
      fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? colorScheme.outline : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? colorScheme.outline : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? Colors.deepPurple.shade200
        : Colors.deepPurple.shade700;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
      ],
    );
  }
}
