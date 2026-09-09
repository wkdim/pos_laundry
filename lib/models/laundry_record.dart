class LaundryRecord {
  final int? recordId;
  final String customerName;
  final String? phoneNumber;
  final String serviceType;
  final double weight;
  final double amount;
  final String status;
  final bool isLocked;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? notes;
  final String? paymentType;

  LaundryRecord({
    this.recordId,
    required this.customerName,
    this.phoneNumber,
    required this.serviceType,
    this.weight = 0.0,
    required this.amount,
    this.status = 'Pending',
    this.isLocked = false,
    this.createdBy,
    this.createdAt,
    this.completedAt,
    this.notes,
    this.paymentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'RecordID': recordId,
      'CustomerName': customerName,
      'PhoneNumber': phoneNumber,
      'ServiceType': serviceType,
      'Weight': weight,
      'Amount': amount,
      'Status': status,
      'IsLocked': isLocked ? 1 : 0,
      'CreatedBy': createdBy,
      'CreatedAt': createdAt?.toIso8601String(),
      'CompletedAt': completedAt?.toIso8601String(),
      'Notes': notes,
      'PaymentType': paymentType,
    };
  }

  factory LaundryRecord.fromMap(Map<String, dynamic> map) {
    return LaundryRecord(
      recordId: map['RecordID'],
      customerName: map['CustomerName'],
      phoneNumber: map['PhoneNumber'],
      serviceType: map['ServiceType'],
      weight: map['Weight']?.toDouble() ?? 0.0,
      amount: map['Amount']?.toDouble() ?? 0.0,
      status: map['Status'] ?? 'Pending',
      isLocked: map['IsLocked'] == 1,
      createdBy: map['CreatedBy'],
      createdAt: map['CreatedAt'] != null
          ? DateTime.parse(map['CreatedAt'])
          : null,
      completedAt: map['CompletedAt'] != null
          ? DateTime.parse(map['CompletedAt'])
          : null,
      notes: map['Notes'],
      paymentType: map['PaymentType'],
    );
  }
}
