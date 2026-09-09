import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../admin/manage_models_screen.dart';
import '../admin/security_permissions_screen.dart';
import '../admin/widgets/change_password_dialog.dart';
import '../../core/utils/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  final Map<String, dynamic> admin;
  const SettingsScreen({Key? key, required this.admin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    void _confirmSignOut(BuildContext context) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors2.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors2.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: AppColors2.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors2.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors2.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    SnackBar _snackBar(String msg) => SnackBar(
      content: Text(msg),
      backgroundColor: AppColors2.surfaceHigh,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    void _showChangePassword(BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChangePasswordDialog(admin: admin)),
      );
    }

    // ── APP BAR ───────────────────────────────
    PreferredSizeWidget _buildAppBar() {
      return AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).dividerColor, height: 1),
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
                    color: AppColors2.blue.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      );
    }

    // ── BODY ──────────────────────────────────
    Widget _buildBody() {
      final username = admin['Username']?.toString() ?? 'Admin';
      final role = admin['Role']?.toString() ?? 'User';
      final bool isSuperAdmin = admin['Role'] == 'SuperAdmin';

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Profile Hero ───────────────
                _ProfileHero(username: username, role: role),
                const SizedBox(height: 28),

                // ── Appearance ─────────────────
                _SectionLabel(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                ),
                const SizedBox(height: 10),
                _DarkModeCard(
                  value: isDark,
                  onChanged: (v) {
                    themeProvider.toggleTheme();
                  },
                ),
                const SizedBox(height: 24),

                // ── Profile ────────────────────
                _SectionLabel(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                ),
                const SizedBox(height: 10),
                _SettingCard(
                  icon: Icons.badge_outlined,
                  iconColor: AppColors2.blue,
                  title: 'User Information',
                  subtitle: 'View and edit your profile details',
                  delay: const Duration(milliseconds: 60),
                  onTap: () => _showUserInfo(context),
                ),
                const SizedBox(height: 10),
                _SettingCard(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors2.amber,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  delay: const Duration(milliseconds: 100),
                  onTap: () => _showChangePassword(context),
                ),
                const SizedBox(height: 24),

                // ── System Settings (SuperAdmin) ─
                if (isSuperAdmin) ...[
                  _SectionLabel(
                    icon: Icons.tune_rounded,
                    title: 'System Settings',
                  ),
                  const SizedBox(height: 10),
                  _SettingCard(
                    icon: Icons.category_outlined,
                    iconColor: AppColors2.teal,
                    title: 'Manage Models',
                    subtitle: 'Manage service types and payment types',
                    delay: const Duration(milliseconds: 60),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageModelsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingCard(
                    icon: Icons.shield_outlined,
                    iconColor: AppColors2.blue,
                    title: 'Security & Permissions',
                    subtitle: 'Configure roles and access levels',
                    delay: const Duration(milliseconds: 100),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityPermissionsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // ── About ──────────────────────
                _SectionLabel(icon: Icons.info_outline_rounded, title: 'About'),
                const SizedBox(height: 10),
                _SettingCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors2.textMuted,
                  title: 'App Version',
                  subtitle: 'v1.0.0 · Build 2026',
                  delay: const Duration(milliseconds: 60),
                  showChevron: false,
                  onTap: null,
                ),
                const SizedBox(height: 10),
                _DangerCard(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Log out of your account',
                  delay: const Duration(milliseconds: 100),
                  onTap: () => _confirmSignOut(context),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    // ── Helpers ───────────────────────────────

    // Mobile: full-screen scaffold with AppBar and compact spacing
    if (isMobilePlatform) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        appBar: _buildAppBar(),
        body: _buildBody(),
        // bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Desktop / Windows: keep the card-like layout but show a small platform badge
    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        padding: const EdgeInsets.all(28),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF2196F3),
                      ),
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Color(0xFF2196F3),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // platform badge
                  ],
                ),
                const SizedBox(height: 40),

                // Appearance Section
                _buildSection(context, 'Appearance', Icons.palette, isDark, [
                  _buildDarkModeToggle(
                    context,
                    themeProvider,
                    isDark,
                    colorScheme,
                  ),
                ]),
                const SizedBox(height: 32),

                // Profile Section
                _buildSection(context, 'Profile', Icons.person, isDark, [
                  _buildSettingCard(
                    context,
                    'User Information',
                    'View and edit your profile details',
                    Icons.person_outline,
                    isDark,
                    colorScheme,
                    () {
                      _showUserInfo(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context,
                    'Change Password',
                    'Update your account password',
                    Icons.lock_outline,
                    isDark,
                    colorScheme,
                    () async {
                      await showDialog(
                        context: context,
                        builder: (_) => ChangePasswordDialog(admin: admin),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 32),

                // System Settings
                if (admin['Role'] == 'SuperAdmin')
                  _buildSection(
                    context,
                    'System Settings',
                    Icons.tune,
                    isDark,
                    [
                      _buildSettingCard(
                        context,
                        'Manage Models',
                        'Manage service types and payment types',
                        Icons.category_outlined,
                        isDark,
                        colorScheme,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageModelsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceVariant : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDark ? 'Switch to light theme' : 'Switch to dark theme',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceVariant : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2196F3), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _UserInfoScreen(admin: admin)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

// ── Profile Hero ──────────────────────────
class _ProfileHero extends StatelessWidget {
  final String username;
  final String role;
  const _ProfileHero({required this.username, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors2.blue.withOpacity(0.12),
            AppColors2.teal.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors2.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors2.blue, AppColors2.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors2.blue.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors2.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors2.blue.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors2.blue.withOpacity(0.25),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors2.blueSoft,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              // You can call the edit user info function here
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _UserInfoScreen(
                    admin: {'Username': username, 'Role': role},
                  ),
                ),
              );
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors2.surfaceHigh,
                border: Border.all(color: AppColors2.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors2.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors2.textMuted),
      const SizedBox(width: 6),
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors2.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

// ── Dark Mode Card ────────────────────────
class _DarkModeCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _DarkModeCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors2.surface,
        border: Border.all(color: AppColors2.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: value
                    ? [const Color(0xFF3D4BDF), const Color(0xFF2233C0)]
                    : [AppColors2.amber, const Color(0xFFE88F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (value ? AppColors2.blue : AppColors2.amber)
                      .withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              value ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors2.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Switch to light theme' : 'Switch to dark theme',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors2.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors2.blue,
            activeTrackColor: AppColors2.blue.withOpacity(0.3),
            inactiveThumbColor: AppColors2.textMuted,
            inactiveTrackColor: AppColors2.surfaceHigh,
          ),
        ],
      ),
    );
  }
}

// ── Setting Card ──────────────────────────
class _SettingCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Duration delay;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.delay = Duration.zero,
    this.showChevron = true,
    this.onTap,
  });

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _pressed ? AppColors2.surfaceHigh : AppColors2.surface,
              border: Border.all(
                color: _pressed
                    ? widget.iconColor.withOpacity(0.25)
                    : AppColors2.border,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.1),
                    border: Border.all(
                      color: widget.iconColor.withOpacity(0.18),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors2.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors2.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors2.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Danger Card (Sign Out) ────────────────
class _DangerCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Duration delay;
  final VoidCallback onTap;

  const _DangerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  State<_DangerCard> createState() => _DangerCardState();
}

class _DangerCardState extends State<_DangerCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _pressed
                  ? Colors.red.withOpacity(0.08)
                  : Colors.red.withOpacity(0.04),
              border: Border.all(
                color: _pressed
                    ? Colors.red.withOpacity(0.35)
                    : Colors.red.withOpacity(0.15),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.redAccent, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.red.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── User Info Bottom Sheet ─────────────────
class _UserInfoSheet extends StatelessWidget {
  final Map<String, dynamic> admin;
  const _UserInfoSheet({required this.admin});

  @override
  Widget build(BuildContext context) {
    final username = admin['Username']?.toString() ?? '—';
    final role = admin['Role']?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors2.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'User Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors2.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Username', value: username),
          const SizedBox(height: 12),
          _InfoRow(label: 'Role', value: role),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors2.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen User Info (matches app aesthetics) ─────────────────
class _UserInfoScreen extends StatelessWidget {
  final Map<String, dynamic> admin;
  const _UserInfoScreen({required this.admin});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: AppColors2.bg,
      appBar: AppBar(
        backgroundColor: AppColors2.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors2.border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2196F3)),
          onPressed: () => Navigator.pop(context),
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
                    color: AppColors2.blue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors2.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
            tooltip: 'Edit',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit user (not implemented)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileHero(
                  username: admin['FullName'] ?? admin['Username'] ?? 'User',
                  role: admin['Role'] ?? 'User',
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors2.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors2.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors2.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Full Name',
                        value: admin['FullName'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Username',
                        value: admin['Username'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Role', value: admin['Role'] ?? 'N/A'),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Status',
                        value: admin['IsActive'] == 1 ? 'Active' : 'Inactive',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors2.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset sent'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Send password reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors2.surface,
      border: Border.all(color: AppColors2.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors2.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors2.textPrimary,
          ),
        ),
      ],
    ),
  );
}
