import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../admin/admin_panel_screen.dart';
import '../audit/audit_log_screen.dart';
import '../frontdesk/frontdesk_screen.dart';
import '../reports/report_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/utils/theme_provider.dart';
import '../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> admin;

  const DashboardScreen({super.key, required this.admin});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _idx = 0;
  late List<Widget> _screens;
  bool _isSleepMode = false;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _screens = [
      FrontDeskScreen(admin: widget.admin),
      ReportsScreen(admin: widget.admin),
      AdminPanelScreen(
        admin: widget.admin,
        onShowAuditLog: () => setState(() => _idx = 3),
      ),
      AuditLogScreen(admin: widget.admin),
      SettingsScreen(admin: widget.admin),
    ];

    // Pulse animation for the icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Subtle rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Fade animation for text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Platform detection + width fallback for responsive behavior
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    // Ensure _idx is valid for the current _screens length (defensive fix for RangeError)
    final int safeIdx = (_idx < 0 || _idx >= _screens.length) ? 0 : _idx;

    // Mobile layout: top AppBar + BottomNavigationBar
    if (isMobilePlatform) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A1929)
            : const Color(0xFFF5F7FA),

        body: Stack(
          children: [
            _screens[safeIdx],
            if (_isSleepMode) _buildSleepMode(isDark),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
      );
    }

    // Desktop / Windows (original layout) with a small platform badge
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A1929)
          : const Color(
              0xFFF5F7FA,
            ), // Light grey-blue background for light mode
      body: Stack(
        children: [
          Row(
            children: [
              _buildModernSidebar(isDark),
              Expanded(child: _screens[_idx]),
            ],
          ),
          if (_isSleepMode) _buildSleepMode(isDark),
        ],
      ),
    );
  }

  Widget _buildModernSidebar(bool isDark) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : Colors.white,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo - Home button
          Tooltip(
            message: 'Sleep Mode',
            child: InkWell(
              onTap: () => setState(() => _isSleepMode = true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.bedtime, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox.shrink(),
          const SizedBox(height: 24),
          _buildNavItem(Icons.store_rounded, 0, 'Front Desk', isDark),
          _buildNavItem(Icons.bar_chart_rounded, 1, 'Reports', isDark),
          _buildNavItem(
            Icons.admin_panel_settings_rounded,
            2,
            'Admin Panel',
            isDark,
          ),
          _buildNavItem(Icons.history_rounded, 3, 'Audit Log', isDark),
          const Spacer(),
          // Settings
          _buildBottomNavItem(Icons.settings_rounded, 'Settings', isDark, () {
            // set safe index for Settings (defensive if _screens length changed)
            setState(
              () => _idx = (_screens.length > 4 ? 4 : _screens.length - 1),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String tooltip, bool isDark) {
    final isSelected = _idx == index;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _idx = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2196F3).withValues(alpha: isDark ? 0.15 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF2196F3)
                : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String tooltip,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Icon(
            icon,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Custom bottom navigation (mobile) - uses `_idx` as the selected index.
  Widget _buildBottomNav(bool isDark) {
    final items = [
      {'icon': Icons.store_rounded, 'label': 'Front Desk'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Reports'},
      {'icon': Icons.admin_panel_settings_rounded, 'label': 'Admin'},
      {'icon': Icons.history_rounded, 'label': 'Audit'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors2.border : const Color(0xFFE6ECEF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == _idx;
          final icon = items[i]['icon'] as IconData;
          final label = items[i]['label'] as String;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _idx = i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: active
                        ? AppColors.primary
                        : (isDark
                              ? AppColors2.textMuted
                              : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? AppColors.primary
                          : (isDark
                                ? AppColors2.textMuted
                                : Colors.grey.shade600),
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSleepMode(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _isSleepMode = false),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.4),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bedtime,
                          size: 80,
                          color: isDark
                              ? const Color(0xFF64B5F6)
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeController,
                  child: Text(
                    'Sleep Mode',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2196F3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap anywhere to wake up',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
