import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/modern_card_container.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/theme_provider.dart';

class AuditLogScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  const AuditLogScreen({super.key, required this.admin});

  @override
  _AuditLogScreenState createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final l = await DatabaseHelper.instance.getAuditLogByPeriod(
      _startDate,
      _endDate,
    );
    setState(() {
      _logs = l;
      _loading = false;
    });
  }

  Color _actionColor(String? action) {
    if (action == null) return AppColors2.textMuted;
    if (action.contains('CREATE')) return AppColors2.green;
    if (action.contains('DELETE')) return AppColors2.red;
    if (action.contains('UPDATE') || action.contains('UNLOCK')) {
      return AppColors2.orange;
    }
    if (action.contains('FINALIZE')) return AppColors2.blue;
    if (action.contains('PASSWORD')) return AppColors2.amber;
    return AppColors2.textMuted;
  }

  IconData _actionIcon(String? action) {
    if (action == null) return Icons.info_outline_rounded;
    if (action.contains('CREATE')) return Icons.add_circle_outline_rounded;
    if (action.contains('DELETE')) return Icons.delete_outline_rounded;
    if (action.contains('UPDATE')) return Icons.edit_outlined;
    if (action.contains('UNLOCK')) return Icons.lock_open_rounded;
    if (action.contains('FINALIZE')) return Icons.check_circle_outline_rounded;
    if (action.contains('PASSWORD')) return Icons.key_rounded;
    return Icons.info_outline_rounded;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: isStart ? DateTime(2020) : (_startDate ?? DateTime(2020)),
      lastDate: isStart ? (_endDate ?? now) : now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors2.blue,
            surface: AppColors2.surfaceHigh,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

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
                Icons.history_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Audit Log',
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
          _IconBtn(icon: Icons.refresh_rounded, onTap: _loadLogs),
          const SizedBox(width: 8),
        ],
      );
    }

    // Body
    Widget buildBody() {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats bar
                _StatsBar(
                  count: _logs.length,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                const SizedBox(height: 16),

                // Date range pickers
                _DateRangeRow(
                  startDate: _startDate,
                  endDate: _endDate,
                  onPickStart: () => _pickDate(isStart: true),
                  onPickEnd: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: 24),

                // Section header
                const _SectionHeader(title: 'Activity Timeline'),
                const SizedBox(height: 12),

                // Content
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors2.blue),
                    ),
                  )
                else if (_logs.isEmpty)
                  _EmptyState()
                else
                  ...List.generate(
                    _logs.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LogCard(
                        log: _logs[i],
                        color: _actionColor(_logs[i]['Action']),
                        icon: _actionIcon(_logs[i]['Action']),
                        isLast: i == _logs.length - 1,
                        animationDelay: Duration(milliseconds: 50 * i),
                      ),
                    ),
                  ),

                // Footer audit card
                const SizedBox(height: 8),
                _FooterCard(
                  lastAction: _logs.isNotEmpty
                      ? '${_logs.first['Action']} by ${_logs.first['FullName']}'
                      : 'No recent activity',
                  timestamp: DateTime.now(),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    // Mobile: AppBar + compact layout
    if (isMobilePlatform) {
      return Scaffold(
        backgroundColor: AppColors2.bg,
        extendBody: true,
        appBar: buildAppBar(),
        body: buildBody(),
        // bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Desktop: original ModernCardContainer but add platform badge in header
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
                Expanded(
                  child: Text(
                    'Audit Log & System Panel Activity',
                    style: const TextStyle(
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
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'System Activity Log',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_logs.length} entries',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: Icon(
                            Icons.date_range,
                            color: isDark ? Colors.blue.shade300 : Colors.blue,
                          ),
                          label: Text(
                            _startDate == null
                                ? 'Start'
                                : _startDate!.toString().substring(0, 10),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: _endDate ?? DateTime.now(),
                            );
                            if (picked != null &&
                                (_endDate == null ||
                                    picked.isBefore(_endDate!) ||
                                    picked.isAtSameMomentAs(_endDate!))) {
                              setState(() => _startDate = picked);
                              await _loadLogs();
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'to',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(
                            Icons.date_range,
                            color: isDark ? Colors.blue.shade300 : Colors.blue,
                          ),
                          label: Text(
                            _endDate == null
                                ? 'End'
                                : _endDate!.toString().substring(0, 10),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: _startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null &&
                                (_startDate == null ||
                                    picked.isAfter(_startDate!) ||
                                    picked.isAtSameMomentAs(_startDate!))) {
                              setState(() => _endDate = picked);
                              await _loadLogs();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_logs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No audit logs found',
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
                      ..._logs.map(
                        (l) => Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.04,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: _actionColor(
                                l['Action'],
                              ).withValues(alpha: 0.18),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _actionColor(l['Action']),
                              child: Icon(
                                _actionIcon(l['Action']),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              '${l['Action']} by ${l['FullName']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              l['Details'] ?? '',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Text(
                              l['Timestamp'].toString().substring(0, 16),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey,
                              ),
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
          AppFooter(
            lastAction: _logs.isNotEmpty
                ? '${_logs.first['Action']} by ${_logs.first['FullName']}'
                : 'No recent activity',
            auditLogTime: DateTime.now(),
          ),
        ],
      ),
    );
  }

  // Add this method to DatabaseHelper:
  //
  // Future<List<Map<String, dynamic>>> getAuditLogByPeriod(DateTime? start, DateTime? end, {int limit = 100}) async {
  //   final db = await database;
  //   String where = '';
  //   List whereArgs = [];
  //   if (start != null && end != null) {
  //     where = 'WHERE a.Timestamp BETWEEN ? AND ?';
  //     whereArgs = [start.toIso8601String(), end.add(Duration(days: 1)).toIso8601String()];
  //   }
  //   return await db.rawQuery('''SELECT a.*, ad.Username, ad.FullName FROM AuditLog a JOIN Admins ad ON a.AdminID = ad.AdminID $where ORDER BY a.Timestamp DESC LIMIT ?''', [...whereArgs, limit]);
  // }
}

//  SUB-WIDGETS

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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

// Stats Bar
class _StatsBar extends StatelessWidget {
  final int count;
  final DateTime? startDate;
  final DateTime? endDate;
  const _StatsBar({required this.count, this.startDate, this.endDate});

  @override
  Widget build(BuildContext context) {
    final days = startDate != null && endDate != null
        ? endDate!.difference(startDate!).inDays + 1
        : 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors2.blue.withValues(alpha: 0.12),
            AppColors2.teal.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors2.blue.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _StatItem(value: '$count', label: 'Entries', color: AppColors2.blue),
          _Divider(),
          _StatItem(value: '$days', label: 'Days', color: AppColors2.teal),
          _Divider(),
          _StatItem(
            value: count > 0 ? (count / days).toStringAsFixed(1) : '0',
            label: 'Per Day',
            color: AppColors2.amber,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors2.textMuted,
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors2.border);
}

// Date Range Row
class _DateRangeRow extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _DateRangeRow({
    this.startDate,
    this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  String _fmt(DateTime? d) =>
      d == null ? '-' : '${d.year}-${_p(d.month)}-${_p(d.day)}';
  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateBtn(
            label: 'From',
            value: _fmt(startDate),
            onTap: onPickStart,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(width: 24, height: 1, color: AppColors2.border),
        ),
        Expanded(
          child: _DateBtn(label: 'To', value: _fmt(endDate), onTap: onPickEnd),
        ),
      ],
    );
  }
}

class _DateBtn extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateBtn({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  State<_DateBtn> createState() => _DateBtnState();
}

class _DateBtnState extends State<_DateBtn> {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed ? AppColors2.surfaceHigh : AppColors2.surface,
          border: Border.all(
            color: _pressed
                ? AppColors2.blue.withValues(alpha: 0.4)
                : AppColors2.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors2.blueSoft,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors2.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors2.textPrimary,
                    ),
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

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors2.textPrimary,
      letterSpacing: -0.3,
    ),
  );
}

// Log Card
class _LogCard extends StatefulWidget {
  final Map<String, dynamic> log;
  final Color color;
  final IconData icon;
  final bool isLast;
  final Duration animationDelay;

  const _LogCard({
    required this.log,
    required this.color,
    required this.icon,
    this.isLast = false,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.animationDelay, () {
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
    final l = widget.log;
    final action = (l['Action'] ?? 'UNKNOWN').toString();
    final fullName = (l['FullName'] ?? '').toString();
    final details = (l['Details'] ?? '').toString();
    final timestamp = l['Timestamp']?.toString() ?? '';
    final tsShort = timestamp.length >= 16
        ? timestamp.substring(0, 16)
        : timestamp;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors2.surface,
            border: Border.all(color: AppColors2.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Accent bar
                  Container(width: 3, color: widget.color),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon circle
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.12),
                              border: Border.all(
                                color: widget.color.withValues(alpha: 0.22),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$action by $fullName',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors2.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (details.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    details,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors2.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11,
                                      color: AppColors2.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tsShort,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors2.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
              Icons.history_toggle_off_rounded,
              size: 36,
              color: AppColors2.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors2.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting the date range',
            style: TextStyle(fontSize: 13, color: AppColors2.textMuted),
          ),
        ],
      ),
    );
  }
}

// Footer / Last Action Card
class _FooterCard extends StatefulWidget {
  final String lastAction;
  final DateTime timestamp;
  const _FooterCard({required this.lastAction, required this.timestamp});

  @override
  State<_FooterCard> createState() => _FooterCardState();
}

class _FooterCardState extends State<_FooterCard>
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
    final t = widget.timestamp;
    final ts =
        '${t.year}-${_p(t.month)}-${_p(t.day)} ${_p(t.hour)}:${_p(t.minute)}:${_p(t.second)}';

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
                  'Last Action: ${widget.lastAction}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors2.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Audit Log: $ts',
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

  String _p(int n) => n.toString().padLeft(2, '0');
}
