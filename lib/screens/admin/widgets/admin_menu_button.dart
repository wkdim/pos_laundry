import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../manage_models_screen.dart';

class AdminMenuButton extends StatelessWidget {
  final Map<String, dynamic> admin;
  const AdminMenuButton({super.key, required this.admin});

  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    if (isMobilePlatform) {
      return IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Manage Models',
        color: Theme.of(context).colorScheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageModelsScreen()),
          );
        },
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.settings),
      label: const Text('Manage Models'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageModelsScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
