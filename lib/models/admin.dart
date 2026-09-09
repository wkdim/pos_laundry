class Admin {
  final int? adminId;
  final String username;
  final String passwordHash;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  Admin({
    this.adminId,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.role = 'Admin',
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'AdminID': adminId,
      'Username': username,
      'PasswordHash': passwordHash,
      'FullName': fullName,
      'Role': role,
      'IsActive': isActive ? 1 : 0,
      'CreatedAt': createdAt?.toIso8601String(),
      'LastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      adminId: map['AdminID'],
      username: map['Username'],
      passwordHash: map['PasswordHash'],
      fullName: map['FullName'],
      role: map['Role'],
      isActive: map['IsActive'] == 1,
      createdAt: map['CreatedAt'] != null 
          ? DateTime.parse(map['CreatedAt']) 
          : null,
      lastLogin: map['LastLogin'] != null 
          ? DateTime.parse(map['LastLogin']) 
          : null,
    );
  }
}