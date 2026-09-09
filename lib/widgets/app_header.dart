import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../screens/auth/login_screen.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String userName;
  final VoidCallback? onLogout;

  const AppHeader({
    super.key,
    required this.title,
    this.userName = 'Admin',
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    // Mobile-optimized header (compact, shows platform badge)
    if (isMobilePlatform) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics, color: colorScheme.onPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox.shrink(),
            const SizedBox(width: 8),
            IconButton(
              onPressed:
                  onLogout ??
                  () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  },
              icon: Icon(Icons.logout, color: colorScheme.onPrimary),
              tooltip: 'Logout',
            ),
          ],
        ),
      );
    }

    // Desktop/header (theme-aware)
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: colorScheme.onPrimary, size: 24),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(), // This pushes the next Row to the far right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome, $userName',
                style: TextStyle(color: colorScheme.onPrimary, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed:
                    onLogout ??
                    () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onPrimary,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: const Text('Logout', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
