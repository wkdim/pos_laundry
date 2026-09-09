import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/sync_service.dart';

class AddRecordDialog extends StatefulWidget {
  final Map<String, dynamic> admin;
  AddRecordDialog({required this.admin});

  @override
  _AddRecordDialogState createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _weight = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _service;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;
  String? _paymentType;
  List<Map<String, dynamic>> _paymentTypesDb = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadPaymentTypes();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _weight.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    final s = await DatabaseHelper.instance.getServiceTypes();
    setState(() {
      _services = s;
      _service = s.isNotEmpty ? null : null;
    });
  }

  Future<void> _loadPaymentTypes() async {
    final p = await DatabaseHelper.instance.getPaymentTypes();
    setState(() {
      _paymentTypesDb = p;
      _paymentType = p.isNotEmpty ? null : null;
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isOnline = SyncService.instance.isOnline.value;
      final id = await DatabaseHelper.instance.addRecord({
        'CustomerName': _name.text,
        'PhoneNumber': _phone.text,
        'ServiceType': _service,
        'Weight': double.tryParse(_weight.text) ?? 0,
        'Amount': double.parse(_amount.text),
        'Notes': _notes.text,
        'PaymentType': _paymentType,
        'CreatedBy': widget.admin['AdminID'],
        'IsSynced': isOnline ? 1 : 0,
      });

      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOnline ? Icons.check_circle : Icons.cloud_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  isOnline
                      ? 'Record added'
                      : 'Saved offline — will sync when online',
                ),
              ],
            ),
            backgroundColor: isOnline
                ? Colors.green.shade600
                : Colors.amber.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding record: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _onServiceChanged(String? newService) {
    if (newService != null) {
      setState(() {
        _service = newService;
        final selected = _services.firstWhere(
          (s) => s['ServiceName'] == newService,
          orElse: () => {},
        );
        if (selected.isNotEmpty && selected['DefaultPrice'] != null) {
          _amount.text = selected['DefaultPrice'].toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    // shared form content
    final formContent = SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Information Section
            _SectionHeader(
              icon: Icons.person_outline,
              title: 'Customer Information',
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _name,
              decoration: _inputDecoration(
                context: context,
                label: 'Customer Name',
                hint: 'Enter full name',
                icon: Icons.person,
                required: true,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _phone,
              decoration: _inputDecoration(
                context: context,
                label: 'Phone Number',
                hint: 'Enter contact number',
                icon: Icons.phone,
              ),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 24),

            // Service Details Section
            _SectionHeader(
              icon: Icons.business_center_outlined,
              title: 'Service Details',
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _service,
              decoration: _inputDecoration(
                context: context,
                label: 'Service Type',
                icon: Icons.local_laundry_service,
              ),
              items: _services
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s['ServiceName'] as String,
                      child: Text(s['ServiceName'] as String),
                    ),
                  )
                  .toList(),
              onChanged: _onServiceChanged,
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    decoration: _inputDecoration(
                      context: context,
                      label: 'Weight',
                      hint: '0.0',
                      icon: Icons.monitor_weight,
                      suffix: 'kg',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    decoration: _inputDecoration(
                      context: context,
                      label: 'Amount',
                      hint: '0.00',
                      icon: Icons.payments,
                      prefix: '£',
                      required: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Amount is required' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _paymentType,
              decoration: _inputDecoration(
                context: context,
                label: 'Payment Type',
                icon: Icons.payment,
              ),
              items: _paymentTypesDb
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p['PaymentTypeName'] as String,
                      child: Text(p['PaymentTypeName'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _paymentType = v);
              },
            ),
            SizedBox(height: 16),

            // Additional Notes Section
            _SectionHeader(
              icon: Icons.note_outlined,
              title: 'Additional Notes',
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _notes,
              decoration: _inputDecoration(
                context: context,
                label: 'Notes',
                hint: 'Add any special instructions or comments...',
                icon: Icons.edit_note,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );

    final footerActions = Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? colorScheme.outline.withOpacity(0.2)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: colorScheme.outline),
              foregroundColor: colorScheme.onSurface,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.check_circle_outline),
            label: Text(_isLoading ? 'Saving...' : 'Save Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );

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
            icon: const Icon(Icons.close, color: Color(0xFF2196F3)),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors2.blue, AppColors2.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors2.blue.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_business,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'New Customer Record',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors2.textPrimary,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: formContent),
              footerActions,
            ],
          ),
        ),
      );
    }

    // Desktop: original dialog with header
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: colorScheme.surface,
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_business,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Customer Record',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add laundry service details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(child: formContent),

            // Footer Actions
            footerActions,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    String? hint,
    required IconData icon,
    String? prefix,
    String? suffix,
    bool required = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
      prefixText: prefix,
      suffixText: suffix,
      filled: true,
      fillColor: isDark ? colorScheme.surfaceVariant : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: isDark
                ? colorScheme.outline.withOpacity(0.2)
                : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
