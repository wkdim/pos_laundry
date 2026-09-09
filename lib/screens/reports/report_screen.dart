import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/excel_exporter.dart';
import '../../core/utils/theme_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/action_buttons_row.dart';
import '../../widgets/modern_card_container.dart';
import '../downloads/downloads_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../audit/audit_log_screen.dart';
import '../admin/widgets/change_password_dialog.dart';

class ReportsScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  const ReportsScreen({super.key, required this.admin});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _tab = 'Monthly';
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _reportData = {};
  Map<String, dynamic> _dailyData = {};
  bool _isLoading = false;
  bool _showDownloads = false;
  String _lastAction = 'No recent actions';
  DateTime _auditLogTime = DateTime.now();
  int _selectedTab = 0; // 0 = Monthly, 1 = Yearly

  String get _period {
    if (_tab == 'Monthly') {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    } else {
      return _selectedDate.year.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
    _loadDailyReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> report;
    try {
      if (_tab == 'Monthly') {
        report = await DatabaseHelper.instance.getMonthlyReport(
          _selectedDate.year,
          _selectedDate.month,
        );
      } else {
        report = await DatabaseHelper.instance.getYearlyReport(
          _selectedDate.year,
        );
      }
      if (mounted) {
        setState(() {
          _reportData = report;
          _isLoading = false;
          _lastAction = 'Generated report: $_period';
          _auditLogTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Report error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDailyReport() async {
    try {
      final daily = await DatabaseHelper.instance.getDailyReport(
        DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _dailyData = daily;
        });
      }
    } catch (e) {
      debugPrint('Daily report error: $e');
    }
  }

  Future<void> _exportToExcel() async {
    final raw = _reportData['records'] ?? [];
    if (raw.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data to export')));
      }
      return;
    }

    final records = (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    String path;
    try {
      path = await ExcelExporter.exportLaundryRecords(records, _period);
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        setState(() {
          _lastAction = 'Export failed';
          _auditLogTime = DateTime.now();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
      return;
    }

    final fileName = path.split(Platform.pathSeparator).last;
    if (mounted) {
      setState(() {
        _lastAction = 'Exported report: $fileName';
        _auditLogTime = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported → $fileName'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_showDownloads) {
      return DownloadsScreen(
        onBack: () => setState(() => _showDownloads = false),
      );
    }

    // platform detection (mobile fallback by width)
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    // Extract summary data from daily report (calculate from returned records so
    // summary includes ALL records regardless of Status — matches user expectation)
    final dailyRecordsRaw = (_dailyData['records'] as List?) ?? [];
    final dailyRecords = dailyRecordsRaw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    double cash = 0, mtn = 0, telecel = 0, other = 0;
    for (var r in dailyRecords) {
      final amt = (r['Amount'] as num?)?.toDouble() ?? 0.0;
      final method = (r['PaymentType'] as String?)?.toLowerCase() ?? 'other';
      if (method == 'cash')
        cash += amt;
      else if (method == 'mtn')
        mtn += amt;
      else if (method == 'telecel')
        telecel += amt;
      else
        other += amt;
    }

    final totalRevenue = cash + mtn + telecel + other;
    final summary = [
      {'label': 'Cash', 'value': cash, 'color': AppColors2.red},
      {'label': 'MTN', 'value': mtn, 'color': AppColors2.green},
      {'label': 'Telecel', 'value': telecel, 'color': AppColors2.orange},
      {'label': 'Other', 'value': other, 'color': AppColors2.purple},
    ];
    final Map<String, double> _cashSummary = {
      'Cash': cash,
      'MTN': mtn,
      'Telecel': telecel,
      'Other': other,
    };

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
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reports',
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
          // _IconBtn(icon: Icons.import_export_rounded, onTap: _exportToExcel),
          _IconBtn(
            icon: Icons.download_rounded,
            onTap: () => setState(() => _showDownloads = true),
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    // ── BODY ──────────────────────────────────
    Widget _buildBody() {
      final periodLabel = _selectedTab == 0
          ? DateFormat('MMMM yyyy').format(_selectedDate)
          : _selectedDate.year.toString();

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
                  cashSummary: _cashSummary,
                  totalRevenue: totalRevenue,
                ),
                const SizedBox(height: 20),

                // ── Controls Row ───────────────
                _ControlsRow(
                  selectedTab: _selectedTab,
                  selectedDate: _selectedDate,
                  onTabChange: (i) => setState(() => _selectedTab = i),
                  onDateChange: (d) => setState(() {
                    _selectedDate = d;
                    _loadReport();
                  }),
                  onGenerate: _loadReport,
                  onExport: _exportToExcel,
                ),
                const SizedBox(height: 20),

                // ── Report Table ───────────────
                // Build table from the returned `records` so mobile matches desktop/export
                _ReportTableCard(
                  loading: _isLoading,
                  periodLabel: periodLabel,
                  isMonthly: _selectedTab == 0,
                  rows: (() {
                    final raw = (_reportData['records'] as List?) ?? [];
                    final records = raw
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
                    var cashOrders = 0,
                        mtnOrders = 0,
                        telecelOrders = 0,
                        otherOrders = 0;
                    var cashAmt = 0.0,
                        mtnAmt = 0.0,
                        telecelAmt = 0.0,
                        otherAmt = 0.0;
                    for (var r in records) {
                      final amt = (r['Amount'] as num?)?.toDouble() ?? 0.0;
                      final method =
                          (r['PaymentType'] as String?)?.toLowerCase() ??
                          'other';
                      if (method == 'cash') {
                        cashOrders++;
                        cashAmt += amt;
                      } else if (method == 'mtn') {
                        mtnOrders++;
                        mtnAmt += amt;
                      } else if (method == 'telecel') {
                        telecelOrders++;
                        telecelAmt += amt;
                      } else {
                        otherOrders++;
                        otherAmt += amt;
                      }
                    }
                    return [
                      {
                        'method': 'Cash',
                        'orders': cashOrders,
                        'amount': cashAmt,
                      },
                      {'method': 'MTN', 'orders': mtnOrders, 'amount': mtnAmt},
                      {
                        'method': 'Telecel',
                        'orders': telecelOrders,
                        'amount': telecelAmt,
                      },
                      {
                        'method': 'Other',
                        'orders': otherOrders,
                        'amount': otherAmt,
                      },
                    ];
                  })(),
                  totalOrders: ((_reportData['records'] as List?) ?? []).length,
                  totalRevenue: ((_reportData['records'] as List?) ?? [])
                      .fold<double>(
                        0,
                        (s, e) => s + ((e['Amount'] as num?)?.toDouble() ?? 0),
                      ),
                ),
                const SizedBox(height: 16),

                // ── Footer ─────────────────────
                _FooterCard(lastAction: _lastAction, timestamp: _auditLogTime),
              ]),
            ),
          ),
        ],
      );
    }

    // Mobile-optimized layout
    if (isMobilePlatform) {
      return Scaffold(
        backgroundColor: AppColors2.bg,
        extendBody: true,
        appBar: _buildAppBar(),
        body: _buildBody(),
        // bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Extract summary data from daily report
    // final cash = (_dailyData['cash'] as num?)?.toDouble() ?? 0;
    // final mtn = (_dailyData['mtn'] as num?)?.toDouble() ?? 0;
    // final telecel = (_dailyData['telecel'] as num?)?.toDouble() ?? 0;
    // final other = (_dailyData['other'] as num?)?.toDouble() ?? 0;
    // final totalRevenue = cash + mtn + telecel + other;
    // final summary = [
    //   {'label': 'Cash', 'value': cash, 'color': Colors.red[400]},
    //   {'label': 'MTN', 'value': mtn, 'color': Colors.green[600]},
    //   {'label': 'Telecel', 'value': telecel, 'color': Colors.orange[700]},
    //   {'label': 'Other', 'value': other, 'color': Colors.blue[700]},
    // ];

    return ModernCardContainer(
      maxHeight: MediaQuery.of(context).size.height - 64,
      child: Column(
        children: [
          // Header Bar
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
                    'Reports & Admin Panel',
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
          // Top Action Buttons
          // ActionButtonsRow(
          //   onManageAdmins: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => AdminPanelScreen(admin: widget.admin),
          //       ),
          //     );
          //   },
          //   onChangePassword: () async {
          //     await showDialog(
          //       context: context,
          //       builder: (_) => ChangePasswordDialog(admin: widget.admin),
          //     );
          //   },
          //   onViewAuditLog: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => AuditLogScreen(admin: widget.admin),
          //       ),
          //     );
          //   },
          // ),
          SizedBox(height: 16),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Daily Summary Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...summary.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s['color'] as Color?,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${s['label']}: GHS ${s['value']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Total Revenue: GHS $totalRevenue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Tabbed Report Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                _buildTab('Monthly', isDark),
                                _buildTab('Yearly', isDark),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Month selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: DateFormat(
                                  'MMMM yyyy',
                                ).format(_selectedDate),
                                items: [
                                  for (int i = 0; i < 12; i++)
                                    DropdownMenuItem(
                                      value: DateFormat('MMMM yyyy').format(
                                        DateTime(_selectedDate.year, i + 1),
                                      ),
                                      child: Text(
                                        DateFormat('MMMM yyyy').format(
                                          DateTime(_selectedDate.year, i + 1),
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    final dt = DateFormat(
                                      'MMMM yyyy',
                                    ).parse(val);
                                    setState(() {
                                      _selectedDate = dt;
                                      _loadReport();
                                    });
                                  }
                                },
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                dropdownColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _loadReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF184A90),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Generate Report'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _exportToExcel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Export to Excel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Report Table
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: _buildReportTable(isDark),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Footer
          AppFooter(lastAction: _lastAction, auditLogTime: _auditLogTime),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isDark) {
    final selected = _tab == label;
    return InkWell(
      onTap: () {
        setState(() {
          _tab = label;
          _loadReport();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2196F3) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF184A90))
                : (isDark ? Colors.grey.shade400 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildReportTable(bool isDark) {
    // Compute payment totals from the returned records so the table matches exports
    final raw = (_reportData['records'] as List?) ?? [];
    final records = raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    int cashOrders = 0, mtnOrders = 0, telecelOrders = 0, otherOrders = 0;
    double cashAmount = 0, mtnAmount = 0, telecelAmount = 0, otherAmount = 0;

    for (var r in records) {
      final amt = (r['Amount'] as num?)?.toDouble() ?? 0.0;
      final method = (r['PaymentType'] as String?)?.toLowerCase() ?? 'other';
      switch (method) {
        case 'cash':
          cashOrders++;
          cashAmount += amt;
          break;
        case 'mtn':
          mtnOrders++;
          mtnAmount += amt;
          break;
        case 'telecel':
          telecelOrders++;
          telecelAmount += amt;
          break;
        default:
          otherOrders++;
          otherAmount += amt;
      }
    }

    final rows = [
      {'method': 'Cash', 'orders': cashOrders, 'amount': cashAmount.round()},
      {'method': 'MTN', 'orders': mtnOrders, 'amount': mtnAmount.round()},
      {
        'method': 'Telecel',
        'orders': telecelOrders,
        'amount': telecelAmount.round(),
      },
      {'method': 'Other', 'orders': otherOrders, 'amount': otherAmount.round()},
    ];
    final totalOrders = rows.fold<int>(
      0,
      (sum, r) => sum + (r['orders'] as int),
    );
    final totalAmount = rows.fold<int>(
      0,
      (sum, r) => sum + (r['amount'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Sales Report for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF184A90),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              columns: const [
                DataColumn(label: Text('Payment Method')),
                DataColumn(label: Text('Total Orders')),
                DataColumn(label: Text('Total Amount')),
              ],
              rows: [
                ...rows.map(
                  (r) => DataRow(
                    color: MaterialStateProperty.all(
                      isDark ? Colors.grey.shade900 : Colors.white,
                    ),
                    cells: [
                      DataCell(Text(r['method'].toString())),
                      DataCell(Text(r['orders'].toString())),
                      DataCell(Text('GHS ${r['amount']}')),
                    ],
                  ),
                ),
                DataRow(
                  color: MaterialStateProperty.all(
                    isDark ? Colors.grey.shade800 : Colors.grey[300],
                  ),
                  cells: [
                    DataCell(
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '$totalOrders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        'GHS $totalAmount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
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
    );
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
  final Map<String, double> cashSummary;
  final double totalRevenue;

  const _DailySummaryCard({
    required this.date,
    required this.cashSummary,
    required this.totalRevenue,
  });

  static const _pillColors = {
    'Cash': AppColors2.green,
    'MTN': AppColors2.blue,
    'Telecel': AppColors2.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors2.blue.withOpacity(0.1),
            AppColors2.teal.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors2.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Payment pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...cashSummary.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SummaryPill(
                      label: e.key,
                      value: e.value,
                      color: _pillColors[e.key] ?? AppColors2.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Total revenue row
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

// ── Controls Row ──────────────────────────
class _ControlsRow extends StatelessWidget {
  final int selectedTab;
  final DateTime selectedDate;
  final ValueChanged<int> onTabChange;
  final ValueChanged<DateTime> onDateChange;
  final VoidCallback onGenerate;
  final VoidCallback onExport;

  const _ControlsRow({
    required this.selectedTab,
    required this.selectedDate,
    required this.onTabChange,
    required this.onDateChange,
    required this.onGenerate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab switcher
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors2.surface,
                  border: Border.all(color: AppColors2.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _TabBtn(
                      label: 'Monthly',
                      active: selectedTab == 0,
                      onTap: () => onTabChange(0),
                    ),
                    _TabBtn(
                      label: 'Yearly',
                      active: selectedTab == 1,
                      onTap: () => onTabChange(1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Month/Year picker + action buttons
        Row(
          children: [
            // Date dropdown
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  if (context.mounted) {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      initialDatePickerMode: DatePickerMode.year,
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
                    if (picked != null) onDateChange(picked);
                  }
                },
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors2.surface,
                    border: Border.all(color: AppColors2.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: AppColors2.blueSoft,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors2.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.unfold_more_rounded,
                        size: 15,
                        color: AppColors2.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Generate button
            _ActionBtn(
              label: 'Generate',
              icon: Icons.play_arrow_rounded,
              color: AppColors2.blue,
              onTap: onGenerate,
            ),
            const SizedBox(width: 8),

            // Export button
            _ActionBtn(
              label: 'Export',
              icon: Icons.ios_share_rounded,
              color: AppColors2.green,
              onTap: onExport,
            ),
          ],
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active ? AppColors2.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors2.blue.withOpacity(0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors2.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _pressed
            ? widget.color.withOpacity(0.25)
            : widget.color.withOpacity(0.15),
        border: Border.all(color: widget.color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 15, color: widget.color),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Report Table Card ─────────────────────
class _ReportTableCard extends StatelessWidget {
  final bool loading;
  final String periodLabel;
  final bool isMonthly;
  final List<Map<String, dynamic>> rows;
  final int totalOrders;
  final double totalRevenue;

  const _ReportTableCard({
    required this.loading,
    required this.periodLabel,
    required this.isMonthly,
    required this.rows,
    required this.totalOrders,
    required this.totalRevenue,
  });

  static const _methodColors = {
    'Cash': AppColors2.green,
    'MTN': AppColors2.blue,
    'Telecel': AppColors2.orange,
    'Other': AppColors2.purple,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors2.surface,
        border: Border.all(color: AppColors2.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors2.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_chart_outlined,
                  size: 16,
                  color: AppColors2.blueSoft,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${isMonthly ? 'Monthly' : 'Yearly'} Sales · $periodLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors2.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors2.surfaceHigh,
            child: const Row(
              children: [
                Expanded(flex: 3, child: _ColHeader('Payment Method')),
                Expanded(flex: 2, child: _ColHeader('Orders', center: true)),
                Expanded(flex: 3, child: _ColHeader('Amount', right: true)),
              ],
            ),
          ),

          // Rows
          if (loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors2.blue),
              ),
            )
          else
            ...rows.map(
              (r) => _TableRow(
                method: r['method'] as String,
                orders: r['orders'] as int,
                amount: r['amount'] as double,
                color: _methodColors[r['method']] ?? AppColors2.textMuted,
                isLast: r == rows.last,
              ),
            ),

          // Grand total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors2.surfaceHigh,
              border: const Border(top: BorderSide(color: AppColors2.border)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Grand Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors2.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '$totalOrders',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors2.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'GHS ${totalRevenue.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors2.teal,
                    ),
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

class _ColHeader extends StatelessWidget {
  final String text;
  final bool center;
  final bool right;
  const _ColHeader(this.text, {this.center = false, this.right = false});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: right
        ? TextAlign.right
        : (center ? TextAlign.center : TextAlign.left),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors2.textMuted,
      letterSpacing: 0.5,
    ),
  );
}

class _TableRow extends StatelessWidget {
  final String method;
  final int orders;
  final double amount;
  final Color color;
  final bool isLast;

  const _TableRow({
    required this.method,
    required this.orders,
    required this.amount,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppColors2.border)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                method,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors2.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '$orders',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors2.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'GHS ${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors2.textSecondary,
            ),
          ),
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
