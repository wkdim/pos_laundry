import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback? onManageAdmins;
  final VoidCallback? onChangePassword;
  final VoidCallback? onViewAuditLog;

  const ActionButtonsRow({
    super.key,
    this.onManageAdmins,
    this.onChangePassword,
    this.onViewAuditLog,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    if (isMobilePlatform) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: onManageAdmins,
              icon: const Icon(Icons.admin_panel_settings),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'Manage Admins',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onChangePassword,
              icon: const Icon(Icons.lock),
              tooltip: 'Change Password',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onViewAuditLog,
              icon: const Icon(Icons.list_alt),
              tooltip: 'View Audit Log',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton.icon(
            onPressed: onManageAdmins,
            icon: const Icon(Icons.admin_panel_settings, size: 18),
            label: const Text('Manage Admins'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF184A90),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onChangePassword,
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Change Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF184A90),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onViewAuditLog,
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('View Audit Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF184A90),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
