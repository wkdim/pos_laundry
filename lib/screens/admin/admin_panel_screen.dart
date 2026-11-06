import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/action_buttons_row.dart';
import '../../widgets/modern_card_container.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/theme_provider.dart';
import 'widgets/add_admin_dialog.dart';
import 'widgets/admin_menu_button.dart';
import 'widgets/change_password_dialog.dart';

class AdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  final VoidCallback? onShowAuditLog; // <-- Add this

  const AdminPanelScreen({
    super.key,
    required this.admin,
    this.onShowAuditLog,
  }); // <-- Update constructor

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  bool get isSuperAdmin => widget.admin['Role'] == 'SuperAdmin';
  List<Map<String, dynamic>> _admins = [];
  bool _loading = false;
  String _lastAction = 'No recent actions';
  DateTime _auditTime = DateTime.now();
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    // FAB animation (used on mobile)
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fabScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _loadAdmins();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() => _loading = true);
    final a = await DatabaseHelper.instance.getAllAdmins();
    setState(() {
      _admins = a;
      _loading = false;
    });
  }

  void _addAdmin() async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddAdminDialog(),
    );
    if (result == true) {
      await _loadAdmins();
      setState(() {
        _lastAction = 'Added new administrator';
        _auditTime = DateTime.now();
      });
    }
  }

  void _changePassword() async {
    final result = await showDialog(
      context: context,
      builder: (_) => ChangePasswordDialog(admin: widget.admin),
    );
    // reflect change in footer (best-effort)
    setState(() {
      _lastAction =
          'Changed password for ${widget.admin['FullName'] ?? 'admin'}';
      _auditTime = DateTime.now();
    });
  }

  void _toggleStatus(Map<String, dynamic> a) async {
    final newActive = a['IsActive'] == 0; // value we will set
    await DatabaseHelper.instance.toggleAdminStatus(a['AdminID'], newActive);
    await _loadAdmins();
    setState(() {
      _lastAction =
          '${newActive ? 'Activated' : 'Deactivated'} admin ${a['FullName'] ?? a['Username'] ?? ''}';
      _auditTime = DateTime.now();
    });
  }

  // SnackBar _styledSnackBar(String msg) => SnackBar(
  //     content: Text(msg),
  //     backgroundColor: AppColors2.surfaceHigh,
  //     behavior: SnackBarBehavior.floating,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //   );

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;
    final platformLabel = isMobilePlatform
        ? 'Mobile App'
        : (defaultTargetPlatform == TargetPlatform.windows
              ? 'Windows App'
              : defaultTargetPlatform.toString().split('.').last);

    // Mobile layout: AppBar + FAB, compact content

    PreferredSizeWidget buildAppBar() {
      return AppBar(
        backgroundColor: AppColors2.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors2.border, height: 1),
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
                    color: AppColors2.blue.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Admin Panel',
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
          _AppBarIconBtn(
            icon: Icons.refresh_rounded,
            onTap: () => setState(() {}),
          ),
          // _AppBarIconBtn(
          //   icon: Icons.history_rounded,
          //   onTap: widget.onShowAuditLog ?? () {},
          // ),
          const SizedBox(width: 8),
        ],
      );
    }

    Widget buildBody() {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _QuickActionsRow(
                  onAddAdmin: _addAdmin,
                  onChangePassword: _changePassword,
                  // onAuditLog: widget.onShowAuditLog ?? () {},
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'System Administrators',
                  badge: '${_admins.length} total',
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors2.blue),
                    ),
                  )
                else if (_admins.isEmpty)
                  _EmptyState()
                else
                  ...List.generate(
                    _admins.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AdminCard(
                        admin: _admins[i],
                        isSuperAdmin: isSuperAdmin,
                        onToggle: () => _toggleStatus(_admins[i]),
                        animationDelay: Duration(milliseconds: 60 * i),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 10),
                _AuditCard(
                  action: 'Admin added new user',
                  timestamp: DateTime.now(),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    Widget buildFab() {
      return GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) {
          _fabController.reverse();
          _addAdmin();
        },
        onTapCancel: () => _fabController.reverse(),
        child: ScaleTransition(
          scale: _fabScale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors2.blue, AppColors2.blueDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors2.blue.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      );
    }

    if (isMobilePlatform) {
      return Scaffold(
        backgroundColor: AppColors2.bg,
        extendBody: true,
        appBar: buildAppBar(),
        body: buildBody(),
        floatingActionButton: buildFab(),
        // bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Desktop / original layout with platform badge
    return ModernCardContainer(
      maxHeight: MediaQuery.of(context).size.height - 64,
      child: Column(
        children: [
          // Header Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF184A90) : const Color(0xFF184A90),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Admin Management Panel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    defaultTargetPlatform == TargetPlatform.windows
                        ? 'Windows App'
                        : defaultTargetPlatform.toString().split('.').last,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ActionButtonsRow(
            onManageAdmins: _addAdmin,
            onChangePassword: _changePassword,
            onViewAuditLog: () {
              if (widget.onShowAuditLog != null) {
                widget.onShowAuditLog!();
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Administrators',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_admins.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No administrators found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._admins.map(
                        (a) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.04,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: a['IsActive'] == 1
                                  ? Colors.green
                                  : Colors.grey,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              a['FullName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${a['Username']} • ${a['Role']}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    a['IsActive'] == 1 ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: a['IsActive'] == 1
                                          ? Colors.green.shade900
                                          : (isDark
                                                ? Colors.white
                                                : Colors.grey.shade700),
                                    ),
                                  ),
                                  backgroundColor: a['IsActive'] == 1
                                      ? Colors.green.shade100
                                      : (isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade300),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(
                                    a['IsActive'] == 1
                                        ? Icons.block
                                        : Icons.check_circle,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                  ),
                                  onPressed: () => _toggleStatus(a),
                                  tooltip: a['IsActive'] == 1
                                      ? 'Deactivate'
                                      : 'Activate',
                                ),
                                if (isSuperAdmin)
                                  AdminMenuButton(admin: widget.admin),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          AppFooter(lastAction: _lastAction, auditLogTime: _auditTime),
        ],
      ),
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors2.surface,
          border: Border.all(color: AppColors2.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors2.textSecondary),
      ),
    );
  }
}

// Quick Actions
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddAdmin;
  final VoidCallback onChangePassword;
  // final VoidCallback onAuditLog;

  const _QuickActionsRow({
    required this.onAddAdmin,
    required this.onChangePassword,
    // required this.onAuditLog,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.person_add_rounded,
            label: 'Add\nAdmin',
            gradientColors: [AppColors2.blue, AppColors2.blueDeep],
            glowColor: AppColors2.blue,
            onTap: onAddAdmin,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.lock_rounded,
            label: 'Change\nPassword',
            gradientColors: [AppColors2.amber, const Color(0xFFE88F00)],
            glowColor: AppColors2.amber,
            onTap: onChangePassword,
          ),
        ),
        const SizedBox(width: 10),
        // Expanded(
        //   child: _QuickActionCard(
        //     icon: Icons.list_alt_rounded,
        //     label: 'Audit\nLog',
        //     gradientColors: [AppColors2.teal, const Color(0xFF00997E)],
        //     glowColor: AppColors2.teal,
        //     // onTap: onAuditLog,
        //   ),
        // ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors2.surface,
            border: Border.all(color: AppColors2.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors2.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  const _SectionHeader({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors2.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors2.blue.withValues(alpha: 0.12),
              border: Border.all(color: AppColors2.blue.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors2.blueSoft,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }
}

// Admin Card
class _AdminCard extends StatefulWidget {
  final Map<String, dynamic> admin;
  final bool isSuperAdmin;
  final VoidCallback onToggle;
  final Duration animationDelay;

  const _AdminCard({
    required this.admin,
    required this.isSuperAdmin,
    required this.onToggle,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.admin;
    final bool isActive = (a['IsActive'] == 1);
    final String fullName =
        (a['FullName'] as String?) ?? (a['Username'] as String?) ?? '';
    final String username = (a['Username'] as String?) ?? '';
    final String role = (a['Role'] as String?) ?? '';

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors2.surface,
            border: Border.all(color: AppColors2.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Accent bar
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [AppColors2.blue, AppColors2.teal]
                            : [AppColors2.border, AppColors2.border],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Top row
                          Row(
                            children: [
                              _Avatar(isActive: isActive),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors2.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors2.textMuted,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusPill(isActive: isActive),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Divider
                          Container(height: 1, color: AppColors2.border),
                          const SizedBox(height: 12),
                          // Bottom row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _RoleTag(role: role),
                              Row(
                                children: [
                                  _MiniBtn(
                                    icon: isActive
                                        ? Icons.block_rounded
                                        : Icons.check_circle_outline_rounded,
                                    danger: isActive,
                                    onTap: widget.onToggle,
                                  ),
                                  const SizedBox(width: 6),
                                  if (widget.isSuperAdmin)
                                    _MiniBtn(
                                      icon: Icons.settings_rounded,
                                      onTap: () {},
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isActive;
  const _Avatar({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors2.blue, AppColors2.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : AppColors2.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors2.blue.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: isActive ? AppColors2.green : const Color(0xFF555555),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors2.surface, width: 2),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors2.green.withValues(alpha: 0.5),
                        blurRadius: 5,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors2.green.withValues(alpha: 0.1) : AppColors2.border,
        border: Border.all(
          color: isActive
              ? AppColors2.green.withValues(alpha: 0.25)
              : AppColors2.border,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors2.green : AppColors2.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  final String role;
  const _RoleTag({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors2.blue.withValues(alpha: 0.1),
        border: Border.all(color: AppColors2.blue.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(8),
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
    );
  }
}

class _MiniBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _MiniBtn({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  State<_MiniBtn> createState() => _MiniBtnState();
}

class _MiniBtnState extends State<_MiniBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _pressed
              ? (widget.danger
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors2.surfaceHigh)
              : AppColors2.surfaceHigh,
          border: Border.all(
            color: _pressed && widget.danger
                ? Colors.red.withValues(alpha: 0.3)
                : AppColors2.border,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          widget.icon,
          size: 15,
          color: _pressed && widget.danger
              ? Colors.red.shade400
              : AppColors2.textSecondary,
        ),
      ),
    );
  }
}

// Audit Card
class _AuditCard extends StatefulWidget {
  final String action;
  final DateTime timestamp;
  const _AuditCard({required this.action, required this.timestamp});

  @override
  State<_AuditCard> createState() => _AuditCardState();
}

class _AuditCardState extends State<_AuditCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${widget.timestamp.year}-${_pad(widget.timestamp.month)}-${_pad(widget.timestamp.day)} · '
        '${_pad(widget.timestamp.hour)}:${_pad(widget.timestamp.minute)}:${_pad(widget.timestamp.second)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors2.surface,
        border: Border.all(color: AppColors2.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors2.blue,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors2.blue, blurRadius: 6)],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors2.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors2.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// Empty State
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors2.surface,
              border: Border.all(color: AppColors2.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 36,
              color: AppColors2.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No administrators found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors2.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add the first admin',
            style: TextStyle(fontSize: 13, color: AppColors2.textMuted),
          ),
        ],
      ),
    );
  }
}
