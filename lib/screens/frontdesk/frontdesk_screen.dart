import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/theme_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/action_buttons_row.dart';
import '../../widgets/modern_card_container.dart';
import '../auth/login_screen.dart';
import 'widgets/add_record_dialog.dart';
import 'widgets/stat_card.dart';

class FrontDeskScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  FrontDeskScreen({required this.admin});

  @override
  _FrontDeskScreenState createState() => _FrontDeskScreenState();
}

class _FrontDeskScreenState extends State<FrontDeskScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  bool _loading = false;
  String _lastAction = 'No recent actions';
  DateTime _auditTime = DateTime.now();

  Color _statusColor(String? s) {
    switch (s) {
      case 'Completed':
        return AppColors2.green;
      case 'Pending':
        return AppColors2.amber;
      case 'Cancelled':
        return AppColors2.red;
      default:
        return AppColors2.textMuted;
    }
  }

  Color _paymentColor(String? p) {
    switch (p) {
      case 'Cash':
        return AppColors2.green;
      case 'MTN':
        return AppColors2.blue;
      case 'Telecel':
        return AppColors2.orange;
      default:
        return AppColors2.purple;
    }
  }

  // ── Computed stats ────────────────────────
  double _sum(String? type) => _records
      .where((r) => type == null || r['PaymentType'] == type)
      .fold(0, (s, r) => s + (r['Amount'] as num).toDouble());

  int _count(String? status) => status == null
      ? _records.length
      : _records.where((r) => r['Status'] == status).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await DatabaseHelper.instance.searchRecords(_search.text);

    // compute screen-local "last action" from the most recent record (by CreatedAt)
    String last = 'No recent actions';
    DateTime at = DateTime.now();

    if (r.isNotEmpty) {
      // find most recent by CreatedAt (defensive parse)
      Map<String, dynamic> latest = r.reduce((a, b) {
        final aTs =
            DateTime.tryParse(a['CreatedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTs =
            DateTime.tryParse(b['CreatedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aTs.isAfter(bTs) ? a : b;
      });

      final name = (latest['CustomerName'] ?? '').toString();
      final status = (latest['Status'] ?? '').toString();
      final rid = latest['RecordID']?.toString() ?? '';

      if ((latest['IsSynced'] ?? 1) == 0) {
        last = 'Offline record for $name (pending sync)';
      } else if (status == 'Completed') {
        last = 'Finalized record #$rid for $name';
      } else {
        last = 'New record for $name';
      }

      at = DateTime.tryParse(latest['CreatedAt'] ?? '') ?? DateTime.now();
    }

    // reorder records for the UI: make a mutable copy (DB result may be read-only),
    // then sort: pending/unsynced first, then by status priority, then newest first
    final records = List<Map<String, dynamic>>.from(r);
    records.sort((a, b) {
      final aSync = (a['IsSynced'] ?? 1) as int;
      final bSync = (b['IsSynced'] ?? 1) as int;
      if (aSync != bSync) return aSync - bSync; // 0 (pending) first

      const statusPriority = {'Pending': 0, 'Processing': 1, 'Completed': 2};
      final aP = statusPriority[a['Status']] ?? 3;
      final bP = statusPriority[b['Status']] ?? 3;
      if (aP != bP) return aP - bP;

      final aTs =
          DateTime.tryParse(a['CreatedAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTs =
          DateTime.tryParse(b['CreatedAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTs.compareTo(aTs);
    });

    setState(() {
      _records = records;
      _lastAction = last;
      _auditTime = at;
      _loading = false;
    });
  }

  void _add() async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddRecordDialog(admin: widget.admin),
    );
    if (result == true) _load();
  }

  Future<void> _finalize(Map<String, dynamic> r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors2.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Finalize Payment',
          style: TextStyle(color: AppColors2.textPrimary),
        ),
        content: Text(
          'Finalize payment for ${r['CustomerName']}?\n\nAmount: ₹${r['Amount']}\n\nThis will lock the record.',
          style: const TextStyle(color: AppColors2.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors2.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors2.blue),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.finalizePayment(
        r['RecordID'],
        widget.admin['AdminID'],
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment finalized')));
      _load();
    }
  }

  Future<void> _unlock(Map<String, dynamic> r) async {
    await DatabaseHelper.instance.unlockRecord(
      r['RecordID'],
      widget.admin['AdminID'],
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Record unlocked')));
    _load();
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors2.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Record',
          style: TextStyle(color: AppColors2.textPrimary),
        ),
        content: Text(
          'Delete record for ${r['CustomerName']}?',
          style: const TextStyle(color: AppColors2.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors2.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteRecord(
        r['RecordID'],
        widget.admin['AdminID'],
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Record deleted')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // Platform detection (mobile if Android/iOS or narrow width)
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;
    final platformLabel = isMobilePlatform
        ? 'Mobile App'
        : (defaultTargetPlatform == TargetPlatform.windows
              ? 'Windows App'
              : defaultTargetPlatform.toString().split('.').last);

    final total = _records.length;
    final completed = _records.where((r) => r['Status'] == 'Completed').length;
    final pending = _records.where((r) => r['Status'] == 'Pending').length;
    final revenue = _records.fold<double>(
      0,
      (sum, r) => sum + (r['Amount'] as num).toDouble(),
    );

    // Calculate daily summary by payment type
    final cash = _records
        .where((r) => r['PaymentType'] == 'Cash')
        .fold<double>(0, (sum, r) => sum + (r['Amount'] as num).toDouble());
    final mtn = _records
        .where((r) => r['PaymentType'] == 'MTN')
        .fold<double>(0, (sum, r) => sum + (r['Amount'] as num).toDouble());
    final telecel = _records
        .where((r) => r['PaymentType'] == 'Telecel')
        .fold<double>(0, (sum, r) => sum + (r['Amount'] as num).toDouble());
    final other = _records
        .where((r) => r['PaymentType'] == 'Other')
        .fold<double>(0, (sum, r) => sum + (r['Amount'] as num).toDouble());

    PreferredSizeWidget _buildAppBar() {
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
                    color: AppColors2.blue.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.desk_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Front Desk',
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
          // connectivity + pending count indicator
          ValueListenableBuilder<bool>(
            valueListenable: SyncService.instance.isOnline,
            builder: (ctx, online, _) => Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: SyncService.instance.pendingCount,
                  builder: (c, pending, _) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Icon(
                        online
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: online ? AppColors2.blue : AppColors2.amber,
                      ),
                      if (pending > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors2.amber,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors2.surface),
                            ),
                            child: Text(
                              '$pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // _IconBtn(
          //   icon: Icons.logout_rounded,
          //   onTap: () {
          //     Navigator.of(context).pushAndRemoveUntil(
          //       MaterialPageRoute(builder: (_) => LoginScreen()),
          //       (r) => false,
          //     );
          //   },
          // ),
          const SizedBox(width: 8),
        ],
      );
    }

    // ── FAB ───────────────────────────────────
    Widget _buildFab() {
      return GestureDetector(
        onTap: _add,
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
                color: AppColors2.blue.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
    }

    // ── BODY ──────────────────────────────────
    Widget _buildBody() {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Daily Summary ──────────────
                _DailySummaryCard(
                  date: DateTime.now(),
                  cashSum: _sum('Cash'),
                  mtnSum: _sum('MTN'),
                  telecelSum: _sum('Telecel'),
                  otherSum: _sum('Other'),
                  totalRevenue: _sum(null),
                ),
                const SizedBox(height: 16),

                // ── Stat Cards ─────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Orders',
                        value: '${_count(null)}',
                        color: AppColors2.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Done',
                        value: '${_count('Completed')}',
                        color: AppColors2.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_outlined,
                        label: 'Pending',
                        value: '${_count('Pending')}',
                        color: AppColors2.amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Revenue',
                        value: '\n${_sum(null).toStringAsFixed(0)}',
                        color: AppColors2.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Search ─────────────────────
                _SearchBar(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // ── Records ────────────────────
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors2.blue),
                    ),
                  )
                else if (_records.isEmpty)
                  _EmptyState()
                else
                  ...List.generate(
                    _records.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecordCard(
                        record: _records[i],
                        statusColor: _statusColor(_records[i]['Status']),
                        paymentColor: _paymentColor(_records[i]['PaymentType']),
                        onFinalize: () => _finalize(_records[i]),
                        onUnlock: () => _unlock(_records[i]),
                        onDelete: () => _delete(_records[i]),
                        animationDelay: Duration(milliseconds: 50 * i),
                      ),
                    ),
                  ),

                // ── Footer ─────────────────────
                const SizedBox(height: 8),
                _FooterCard(lastAction: _lastAction, timestamp: _auditTime),
              ]),
            ),
          ),
        ],
      );
    }

    // Mobile layout: AppBar + FAB, compact paddings
    if (isMobilePlatform) {
      return Scaffold(
        backgroundColor: AppColors2.bg,
        extendBody: true,
        appBar: _buildAppBar(),
        floatingActionButton: _buildFab(),
        body: _buildBody(),
        // bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Desktop / original layout with a small platform badge
    return ModernCardContainer(
      maxHeight: MediaQuery.of(context).size.height - 64,
      child: Column(
        children: [
          AppHeader(
            title: 'Front Desk & Orders',
            userName: widget.admin['username'] ?? 'Admin',
            onLogout: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  platformLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildScrollableContent(isDark, false)),
          AppFooter(
            lastAction: 'Admin John unlocked Record #34',
            auditLogTime: DateTime(2024, 4, 24, 15, 32),
          ),
        ],
      ),
    );
  }

  // shared scrollable content used by both mobile and desktop variants
  Widget _buildScrollableContent(bool isDark, bool isMobile) {
    final horizontalPadding = isMobile ? 12.0 : 24.0;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Summary
            Row(
              children: [
                Text(
                  'Daily Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryCard(
                    'Cash',
                    _records
                        .where((r) => r['PaymentType'] == 'Cash')
                        .fold<double>(
                          0,
                          (s, r) => s + (r['Amount'] as num).toDouble(),
                        ),
                    Colors.red[400]!,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'MTN',
                    _records
                        .where((r) => r['PaymentType'] == 'MTN')
                        .fold<double>(
                          0,
                          (s, r) => s + (r['Amount'] as num).toDouble(),
                        ),
                    Colors.green[600]!,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'Telecel',
                    _records
                        .where((r) => r['PaymentType'] == 'Telecel')
                        .fold<double>(
                          0,
                          (s, r) => s + (r['Amount'] as num).toDouble(),
                        ),
                    Colors.orange[700]!,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'Other',
                    _records
                        .where((r) => r['PaymentType'] == 'Other')
                        .fold<double>(
                          0,
                          (s, r) => s + (r['Amount'] as num).toDouble(),
                        ),
                    Colors.blue[700]!,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total Revenue: GHS ${_records.fold<double>(0, (sum, r) => sum + (r['Amount'] as num).toDouble()).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Orders',
                    value: '${_records.length}',
                    icon: Icons.shopping_bag,
                    accentColor: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Completed',
                    value:
                        '${_records.where((r) => r['Status'] == 'Completed').length}',
                    icon: Icons.check_circle,
                    accentColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Pending',
                    value:
                        '${_records.where((r) => r['Status'] == 'Pending').length}',
                    icon: Icons.pending,
                    accentColor: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Revenue',
                    value:
                        '£${_records.fold<double>(0, (sum, r) => sum + (r['Amount'] as num).toDouble()).toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    accentColor: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: 'Search by name or phone',
                      labelStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey.shade900
                          : const Color(0xFFF8F9FC),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (_) => _load(),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_records.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: isDark
                            ? Colors.grey.shade700
                            : const Color(0xFFBDBDBD),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No records found',
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
              ..._records.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: _getStatusColor(r['Status']).withOpacity(0.18),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_laundry_service,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['CustomerName'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    r['PhoneNumber'] ?? 'N/A',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    r['CreatedAt'].toString().substring(0, 16),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r['ServiceType'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2196F3),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${r['Weight']} kg',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${r['Amount']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  r['Status'],
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(r['Status']),
                                ),
                              ),
                              child: Text(
                                r['Status'],
                                style: TextStyle(
                                  color: _getStatusColor(r['Status']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                          itemBuilder: (_) => [
                            if (r['IsLocked'] == 0 &&
                                r['Status'] != 'Completed')
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.check,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  title: const Text('Finalize'),
                                  dense: true,
                                ),
                                onTap: () => Future.delayed(
                                  Duration.zero,
                                  () => _finalize(r),
                                ),
                              ),
                            if (r['IsLocked'] == 1)
                              PopupMenuItem(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.lock_open,
                                    color: Color(0xFFFF9800),
                                  ),
                                  title: const Text('Unlock'),
                                  dense: true,
                                ),
                                onTap: () => Future.delayed(
                                  Duration.zero,
                                  () => _unlock(r),
                                ),
                              ),
                            PopupMenuItem(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFF44336),
                                ),
                                title: const Text('Delete'),
                                dense: true,
                              ),
                              onTap: () => Future.delayed(
                                Duration.zero,
                                () => _delete(r),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            if (isMobile)
              AppFooter(
                lastAction: 'Admin John unlocked Record #34',
                auditLogTime: DateTime(2024, 4, 24, 15, 32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: GHS ${value.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

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
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors2.surface,
        border: Border.all(color: AppColors2.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppColors2.textSecondary),
    ),
  );
}

// ── Daily Summary Card ────────────────────
class _DailySummaryCard extends StatelessWidget {
  final DateTime date;
  final double cashSum, mtnSum, telecelSum, otherSum, totalRevenue;

  const _DailySummaryCard({
    required this.date,
    required this.cashSum,
    required this.mtnSum,
    required this.telecelSum,
    required this.otherSum,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors2.blue.withOpacity(0.10),
            AppColors2.teal.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors2.blue.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Daily Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors2.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(date),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors2.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryPill(
                  label: 'Cash',
                  value: cashSum,
                  color: AppColors2.green,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'MTN',
                  value: mtnSum,
                  color: AppColors2.blue,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'Telecel',
                  value: telecelSum,
                  color: AppColors2.orange,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'Other',
                  value: otherSum,
                  color: AppColors2.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors2.surfaceHigh,
              border: Border.all(color: AppColors2.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors2.teal,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total Revenue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors2.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'GHS ${totalRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors2.teal,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      border: Border.all(color: color.withOpacity(0.25)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'GHS ${value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors2.textPrimary,
          ),
        ),
      ],
    ),
  );
}

// ── Stat Card ─────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors2.surface,
      border: Border.all(color: AppColors2.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors2.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors2.textMuted,
          ),
        ),
      ],
    ),
  );
}

// ── Search Bar ────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors2.surface,
      border: Border.all(color: AppColors2.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors2.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Search by name or phone…',
        hintStyle: TextStyle(color: AppColors2.textMuted, fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors2.textMuted,
          size: 20,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

// ── Record Card ───────────────────────────
class _RecordCard extends StatefulWidget {
  final Map<String, dynamic> record;
  final Color statusColor;
  final Color paymentColor;
  final VoidCallback onFinalize;
  final VoidCallback onUnlock;
  final VoidCallback onDelete;
  final Duration animationDelay;

  const _RecordCard({
    required this.record,
    required this.statusColor,
    required this.paymentColor,
    required this.onFinalize,
    required this.onUnlock,
    required this.onDelete,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard>
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
    final r = widget.record;
    final name = r['CustomerName']?.toString() ?? '—';
    final phone = r['PhoneNumber']?.toString() ?? 'N/A';
    final service = r['ServiceType']?.toString() ?? '—';
    final weight = r['Weight']?.toString() ?? '0';
    final amount = (r['Amount'] as num?)?.toDouble() ?? 0.0;
    final status = r['Status']?.toString() ?? '—';
    final payment = r['PaymentType']?.toString() ?? '—';
    final createdAt = r['CreatedAt']?.toString() ?? '';
    final tsShort = createdAt.length >= 16
        ? createdAt.substring(0, 16)
        : createdAt;
    final isLocked = r['IsLocked'] == 1;
    final isCompleted = status == 'Completed';

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
                  // Status accent bar
                  Container(width: 3, color: widget.statusColor),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          // Top row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Service icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors2.blue.withOpacity(0.1),
                                  border: Border.all(
                                    color: AppColors2.blue.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.local_laundry_service_rounded,
                                  color: AppColors2.blue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name + meta
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors2.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 12,
                                          color: AppColors2.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors2.textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
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

                              // Amount + menu
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'GHS ${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors2.teal,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                      color: AppColors2.textMuted,
                                    ),
                                    color: AppColors2.surfaceHigh,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    itemBuilder: (_) => [
                                      if (!isLocked && !isCompleted)
                                        _menuItem(
                                          'Finalize',
                                          Icons.check_circle_outline_rounded,
                                          AppColors2.green,
                                        ),
                                      if (isLocked)
                                        _menuItem(
                                          'Unlock',
                                          Icons.lock_open_rounded,
                                          AppColors2.amber,
                                        ),
                                      _menuItem(
                                        'Delete',
                                        Icons.delete_outline_rounded,
                                        AppColors2.red,
                                      ),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'Finalize')
                                        widget.onFinalize();
                                      if (val == 'Unlock') widget.onUnlock();
                                      if (val == 'Delete') widget.onDelete();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Container(height: 1, color: AppColors2.border),
                          const SizedBox(height: 10),

                          // Bottom tags row
                          Row(
                            children: [
                              _Tag(label: service, color: AppColors2.blue),
                              const SizedBox(width: 7),
                              _Tag(
                                label: '$weight kg',
                                color: AppColors2.textMuted,
                              ),
                              const SizedBox(width: 7),
                              _Tag(label: payment, color: widget.paymentColor),
                              const Spacer(),

                              // Pending sync chip (shows when IsSynced == 0)
                              if ((r['IsSynced'] ?? 1) == 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors2.amber.withOpacity(0.08),
                                      border: Border.all(
                                        color: AppColors2.amber.withOpacity(
                                          0.18,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Text(
                                      'Pending sync',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors2.amber,
                                      ),
                                    ),
                                  ),
                                ),

                              // Status pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.statusColor.withOpacity(0.1),
                                  border: Border.all(
                                    color: widget.statusColor.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: widget.statusColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
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

  PopupMenuItem<String> _menuItem(String value, IconData icon, Color color) =>
      PopupMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color == AppColors2.textMuted ? AppColors2.textSecondary : color,
      ),
    ),
  );
}

// ── Empty State ───────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
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
            Icons.inbox_outlined,
            size: 36,
            color: AppColors2.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No records found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors2.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap + to add the first record',
          style: TextStyle(fontSize: 13, color: AppColors2.textMuted),
        ),
      ],
    ),
  );
}

// ── Footer Card ───────────────────────────
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

  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final t = widget.timestamp;
    final ts =
        '${t.year}-${_p(t.month)}-${_p(t.day)} ${_p(t.hour)}:${_p(t.minute)}';

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
}
