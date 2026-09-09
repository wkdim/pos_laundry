import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_provider.dart';

class SecurityPermissionsScreen extends StatefulWidget {
  const SecurityPermissionsScreen({Key? key}) : super(key: key);

  @override
  State<SecurityPermissionsScreen> createState() =>
      _SecurityPermissionsScreenState();
}

class _SecurityPermissionsScreenState extends State<SecurityPermissionsScreen> {
  // Mock in-memory roles + permissions (keeps UI-only; adapt later to DB)
  final List<Map<String, dynamic>> _roles = [];

  final List<Map<String, String>> _availablePermissions = [
    {'key': 'manage_records', 'label': 'Manage Records'},
    {'key': 'finalize_payment', 'label': 'Finalize Payment'},
    {'key': 'view_reports', 'label': 'View Reports'},
    {'key': 'manage_models', 'label': 'Manage Models'},
    {'key': 'manage_users', 'label': 'Manage Users'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  void _loadDefaults() {
    _roles.clear();
    _roles.addAll([
      {
        'name': 'SuperAdmin',
        'permissions': {
          'manage_records': true,
          'finalize_payment': true,
          'view_reports': true,
          'manage_models': true,
          'manage_users': true,
        },
      },
      {
        'name': 'Admin',
        'permissions': {
          'manage_records': true,
          'finalize_payment': true,
          'view_reports': true,
          'manage_models': true,
          'manage_users': false,
        },
      },
      {
        'name': 'Clerk',
        'permissions': {
          'manage_records': true,
          'finalize_payment': true,
          'view_reports': false,
          'manage_models': false,
          'manage_users': false,
        },
      },
      {
        'name': 'Viewer',
        'permissions': {
          'manage_records': false,
          'finalize_payment': false,
          'view_reports': true,
          'manage_models': false,
          'manage_users': false,
        },
      },
    ]);
  }

  Future<void> _showRoleEditor({int? index}) async {
    final editing = index != null;
    final Map<String, dynamic> role = editing
        ? Map<String, dynamic>.from(_roles[index!])
        : {'name': '', 'permissions': <String, bool>{}};

    // ensure all permission keys exist
    final Map<String, bool> perms = {};
    for (final p in _availablePermissions) {
      final k = p['key']!;
      perms[k] = (role['permissions']?[k] as bool?) ?? false;
    }

    final nameCtrl = TextEditingController(text: role['name'] as String? ?? '');

    final bool isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) {
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
                  onPressed: () => Navigator.pop(ctx, false),
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
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      editing ? 'Edit Role' : 'Add Role',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors2.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [],
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Role name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Permissions',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._availablePermissions.map((p) {
                          final k = p['key']!;
                          return StatefulBuilder(
                            builder: (c, setSt) => SwitchListTile(
                              value: perms[k]!,
                              activeColor: AppColors2.blue,
                              title: Text(p['label']!),
                              dense: true,
                              onChanged: (v) => setSt(() => perms[k] = v),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) return;
                                role['name'] = name;
                                role['permissions'] = perms;
                                setState(() {
                                  if (editing)
                                    _roles[index!] = role;
                                  else
                                    _roles.add(role);
                                });
                                Navigator.pop(ctx, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors2.blue,
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editing ? 'Role updated' : 'Role added'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors2.surfaceHigh,
          ),
        );
      }

      return;
    }

    // Desktop / dialog fallback (styled)
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors2.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          editing ? 'Edit Role' : 'Add Role',
          style: const TextStyle(color: AppColors2.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Role name'),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Permissions',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              ..._availablePermissions.map((p) {
                final k = p['key']!;
                return StatefulBuilder(
                  builder: (c, setSt) => SwitchListTile(
                    value: perms[k]!,
                    activeColor: AppColors2.blue,
                    title: Text(p['label']!),
                    dense: true,
                    onChanged: (v) => setSt(() => perms[k] = v),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              role['name'] = name;
              role['permissions'] = perms;
              setState(() {
                if (editing)
                  _roles[index!] = role;
                else
                  _roles.add(role);
              });
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors2.blue),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editing ? 'Role updated' : 'Role added'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors2.surfaceHigh,
        ),
      );
    }
  }

  Future<void> _confirmDeleteRole(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Delete role "${_roles[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _roles.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role deleted')));
    }
  }

  Widget _roleTile(int index) {
    final r = _roles[index];
    final enabledCount = (r['permissions'] as Map).values
        .where((v) => v == true)
        .length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRoleEditor(index: index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors2.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors2.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors2.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors2.blueSoft,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name'] ?? 'Role',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors2.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$enabledCount permission${enabledCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors2.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors2.textMuted,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (v) {
                  if (v == 'edit') _showRoleEditor(index: index);
                  if (v == 'delete') _confirmDeleteRole(index);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionsOverviewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors2.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors2.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Permissions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors2.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePermissions
                .map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors2.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors2.border),
                    ),
                    child: Text(
                      p['label']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors2.textMuted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

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
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2196F3),
            ),
            onPressed: () => Navigator.pop(context),
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
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Security & Permissions',
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
              icon: const Icon(Icons.add, color: Color(0xFF2196F3)),
              onPressed: () => _showRoleEditor(),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors2.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors2.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Roles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors2.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Create roles and assign permissions to control access within the app.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors2.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_roles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors2.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors2.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_off_rounded,
                            size: 64,
                            color: AppColors2.textMuted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No roles defined',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors2.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add roles to control what users can see and do in the app.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors2.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showRoleEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add role'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors2.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(
                      _roles.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _roleTile(i),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _permissionsOverviewCard(),
                ]),
              ),
            ),
          ],
        ),
      );
    }

    // Desktop / large screens: card-like container
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A2332) : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
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
                        Icons.shield_outlined,
                        color: Color(0xFF2196F3),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Security & Permissions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showRoleEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_roles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors2.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors2.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_off_rounded,
                          size: 64,
                          color: AppColors2.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No roles defined',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors2.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add roles to control what users can see and do in the app.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors2.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(
                    _roles.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _roleTile(i),
                    ),
                  ),
                const SizedBox(height: 20),
                _permissionsOverviewCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
