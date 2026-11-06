import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import 'manage_payment_types_screen.dart';
import 'manage_service_types_screen.dart';
import '../../core/utils/theme_provider.dart';

class ManageModelsScreen extends StatelessWidget {
  const ManageModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    // Mobile: match main app mobile header & spacing
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
                      color: AppColors2.blue.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manage Models',
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildModelCard(
                    context,
                    'Service Types',
                    'Manage laundry service types and pricing',
                    Icons.room_service_outlined,
                    isDark,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageServiceTypesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModelCard(
                    context,
                    'Payment Types',
                    'Manage available payment methods',
                    Icons.payment_outlined,
                    isDark,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManagePaymentTypesScreen(),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
    }

    // Desktop / original card layout with platform badge
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A2332) : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
                        color: Colors.blue.shade700.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Color(0xFF2196F3),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manage Models',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Service Types Card
                _buildModelCard(
                  context,
                  'Service Types',
                  'Manage laundry service types and pricing',
                  Icons.room_service_outlined,
                  isDark,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageServiceTypesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Payment Types Card
                _buildModelCard(
                  context,
                  'Payment Types',
                  'Manage available payment methods',
                  Icons.payment_outlined,
                  isDark,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManagePaymentTypesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    const iconColor = Color(0xFF2196F3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  color: iconColor.withValues(alpha: 0.1),
                  border: Border.all(color: iconColor.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors2.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors2.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors2.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
