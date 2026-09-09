class AuditLog {
  final int? logId;
  final int adminId;
  final String action;
  final int? recordId;
  final String? details;
  final DateTime timestamp;
  final String? adminUsername;
  final String? adminFullName;

  AuditLog({
    this.logId,
    required this.adminId,
    required this.action,
    this.recordId,
    this.details,
    required this.timestamp,
    this.adminUsername,
    this.adminFullName,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      logId: map['LogID'],
      adminId: map['AdminID'],
      action: map['Action'],
      recordId: map['RecordID'],
      details: map['Details'],
      timestamp: DateTime.parse(map['Timestamp']),
      adminUsername: map['Username'],
      adminFullName: map['FullName'],
    );
  }
}