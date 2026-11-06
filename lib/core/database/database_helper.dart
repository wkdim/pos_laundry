import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import '../utils/excel_exporter.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('laundry_pos_pro.db');
    await _createFirstAdmin();
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // bump DB version to 2 to add offline sync column and migrations
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE Admins (
      AdminID INTEGER PRIMARY KEY AUTOINCREMENT, Username TEXT UNIQUE NOT NULL,
      PasswordHash TEXT NOT NULL, FullName TEXT NOT NULL, Role TEXT DEFAULT 'Admin',
      IsActive INTEGER DEFAULT 1, CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP, LastLogin TEXT)''',
    );
    // add IsSynced column (offline sync flag) - 1 = synced, 0 = pending
    await db.execute('''CREATE TABLE LaundryRecords (
      RecordID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerName TEXT NOT NULL, PhoneNumber TEXT,
      ServiceType TEXT NOT NULL, Weight REAL DEFAULT 0, Amount REAL NOT NULL,
      PaymentType TEXT,
      Status TEXT DEFAULT 'Pending', IsLocked INTEGER DEFAULT 0, CreatedBy INTEGER,
      CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP, CompletedAt TEXT, Notes TEXT,
      IsSynced INTEGER DEFAULT 1,
      FOREIGN KEY (CreatedBy) REFERENCES Admins(AdminID))''');
    await db.execute('''CREATE TABLE AuditLog (
      LogID INTEGER PRIMARY KEY AUTOINCREMENT, AdminID INTEGER, Action TEXT NOT NULL,
      RecordID INTEGER, Details TEXT, Timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (AdminID) REFERENCES Admins(AdminID))''');
    await db.execute('''CREATE TABLE ServiceTypes (
      ServiceID INTEGER PRIMARY KEY AUTOINCREMENT, ServiceName TEXT UNIQUE NOT NULL,
      DefaultPrice REAL, IsActive INTEGER DEFAULT 1)''');
    await db.execute('''CREATE TABLE PaymentTypes (
      PaymentTypeID INTEGER PRIMARY KEY AUTOINCREMENT, PaymentTypeName TEXT UNIQUE NOT NULL,
      IsActive INTEGER DEFAULT 1)''');
    await db.insert('ServiceTypes', {
      'ServiceName': 'Wash & Iron',
      'DefaultPrice': 50.0,
    });
    await db.insert('ServiceTypes', {
      'ServiceName': 'Dry Clean',
      'DefaultPrice': 150.0,
    });
    await db.insert('ServiceTypes', {
      'ServiceName': 'Iron Only',
      'DefaultPrice': 30.0,
    });
    await db.insert('ServiceTypes', {
      'ServiceName': 'Wash Only',
      'DefaultPrice': 40.0,
    });
    await db.insert('PaymentTypes', {'PaymentTypeName': 'Cash'});
    await db.insert('PaymentTypes', {'PaymentTypeName': 'MTN'});
    await db.insert('PaymentTypes', {'PaymentTypeName': 'TELECEL'});
    await db.insert('PaymentTypes', {'PaymentTypeName': 'Others'});
  }

  Future _createFirstAdmin() async {
    final db = await database;
    final admins = await db.query('Admins', limit: 1);
    if (admins.isEmpty) {
      final hash = sha256.convert(utf8.encode('admin123')).toString();
      await db.insert('Admins', {
        'Username': 'admin',
        'PasswordHash': hash,
        'FullName': 'System Administrator',
        'Role': 'SuperAdmin',
      });
    }
  }

  // Database schema migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // add IsSynced column to LaundryRecords (default to 1)
      try {
        await db.execute(
          'ALTER TABLE LaundryRecords ADD COLUMN IsSynced INTEGER DEFAULT 1',
        );
      } catch (e) {
        // ignore if column already exists
      }
    }
  }

  Future<Map<String, dynamic>?> login(String u, String p) async {
    final db = await database;
    final hash = sha256.convert(utf8.encode(p)).toString();
    final r = await db.query(
      'Admins',
      where: 'Username = ? AND PasswordHash = ? AND IsActive = 1',
      whereArgs: [u, hash],
    );
    if (r.isNotEmpty) {
      await db.update(
        'Admins',
        {'LastLogin': DateTime.now().toIso8601String()},
        where: 'AdminID = ?',
        whereArgs: [r.first['AdminID']],
      );
      return r.first;
    }
    return null;
  }

  Future<void> changePassword(int id, String old, String newP) async {
    final db = await database;
    final oldH = sha256.convert(utf8.encode(old)).toString();
    final a = await db.query(
      'Admins',
      where: 'AdminID = ? AND PasswordHash = ?',
      whereArgs: [id, oldH],
    );
    if (a.isEmpty) throw Exception('Current password incorrect');
    final newH = sha256.convert(utf8.encode(newP)).toString();
    await db.update(
      'Admins',
      {'PasswordHash': newH},
      where: 'AdminID = ?',
      whereArgs: [id],
    );
    await logAction(id, 'CHANGE_PASSWORD', null, 'Password changed');
  }

  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    final db = await database;
    return await db.query('Admins', orderBy: 'CreatedAt DESC');
  }

  Future<int> createAdmin(Map<String, dynamic> a) async {
    final db = await database;
    final hash = sha256.convert(utf8.encode(a['password'])).toString();
    return await db.insert('Admins', {
      'Username': a['username'],
      'PasswordHash': hash,
      'FullName': a['fullName'],
      'Role': a['role'] ?? 'Admin',
    });
  }

  Future<void> toggleAdminStatus(int id, bool active) async {
    final db = await database;
    await db.update(
      'Admins',
      {'IsActive': active ? 1 : 0},
      where: 'AdminID = ?',
      whereArgs: [id],
    );
  }

  Future<int> addRecord(Map<String, dynamic> r) async {
    final db = await database;
    // allow caller to pass IsSynced (1 or 0). default to 1 (synced)
    final id = await db.insert('LaundryRecords', {
      ...r,
      'IsSynced': r.containsKey('IsSynced') ? r['IsSynced'] : 1,
      'CreatedAt': DateTime.now().toIso8601String(),
    });
    await logAction(
      r['CreatedBy'],
      'CREATE_RECORD',
      id,
      'New record for ${r['CustomerName']}',
    );
    return id;
  }

  Future<List<Map<String, dynamic>>> searchRecords(String q) async {
    final db = await database;
    if (q.isEmpty) {
      return await db.query(
        'LaundryRecords',
        orderBy: 'CreatedAt DESC',
        limit: 200,
      );
    }
    return await db.query(
      'LaundryRecords',
      where: 'CustomerName LIKE ? OR PhoneNumber LIKE ?',
      whereArgs: ['%$q%', '%$q%'],
      orderBy: 'CreatedAt DESC',
    );
  }

  // --- Offline sync helpers ---
  Future<List<Map<String, dynamic>>> getPendingSyncRecords() async {
    final db = await database;
    return await db.query(
      'LaundryRecords',
      where: 'IsSynced = ?',
      whereArgs: [0],
      orderBy: 'CreatedAt ASC',
    );
  }

  Future<void> markRecordSynced(int recordId) async {
    final db = await database;
    await db.update(
      'LaundryRecords',
      {'IsSynced': 1},
      where: 'RecordID = ?',
      whereArgs: [recordId],
    );
  }

  Future<void> updateRecord(int id, Map<String, dynamic> u, int adminId) async {
    final db = await database;
    await db.update(
      'LaundryRecords',
      u,
      where: 'RecordID = ?',
      whereArgs: [id],
    );
    await logAction(adminId, 'UPDATE_RECORD', id, 'Record updated');
  }

  Future<void> deleteRecord(int id, int adminId) async {
    final db = await database;
    await db.delete('LaundryRecords', where: 'RecordID = ?', whereArgs: [id]);
    await logAction(adminId, 'DELETE_RECORD', id, 'Record deleted');
  }

  Future<void> finalizePayment(int id, int adminId) async {
    final db = await database;
    await db.update(
      'LaundryRecords',
      {
        'Status': 'Completed',
        'CompletedAt': DateTime.now().toIso8601String(),
        'IsLocked': 1,
      },
      where: 'RecordID = ?',
      whereArgs: [id],
    );
    await logAction(adminId, 'FINALIZE_PAYMENT', id, 'Payment completed');
  }

  Future<void> unlockRecord(int id, int adminId) async {
    final db = await database;
    await db.update(
      'LaundryRecords',
      {'IsLocked': 0, 'Status': 'Pending'},
      where: 'RecordID = ?',
      whereArgs: [id],
    );
    await logAction(adminId, 'UNLOCK_RECORD', id, 'Record unlocked');
  }

  Future<Map<String, dynamic>> getDailyReport(DateTime d) async {
    final db = await database;
    final s = DateTime(d.year, d.month, d.day).toIso8601String();
    final e = DateTime(d.year, d.month, d.day, 23, 59, 59).toIso8601String();
    final r = await db.rawQuery(
      '''SELECT COUNT(*) as total, SUM(Amount) as revenue,
      SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) as completed
      FROM LaundryRecords WHERE CreatedAt BETWEEN ? AND ?''',
      [s, e],
    );
    final records = await db.query(
      'LaundryRecords',
      where: 'CreatedAt BETWEEN ? AND ?',
      whereArgs: [s, e],
    );

    // Aggregate by payment type
    final paymentBreakdown = await db.rawQuery(
      '''SELECT PaymentType,
      COUNT(*) as orderCount,
      SUM(Amount) as totalAmount
      FROM LaundryRecords
      WHERE CreatedAt BETWEEN ? AND ? AND Status = 'Completed'
      GROUP BY PaymentType''',
      [s, e],
    );

    // Calculate payment type totals
    double cash = 0, mtn = 0, telecel = 0, other = 0;
    for (var item in paymentBreakdown) {
      final type = (item['PaymentType'] as String?)?.toUpperCase() ?? '';
      final amount = (item['totalAmount'] as num?)?.toDouble() ?? 0;
      if (type == 'CASH') {
        cash = amount;
      } else if (type == 'MTN') {
        mtn = amount;
      } else if (type == 'TELECEL') {
        telecel = amount;
      } else {
        other += amount;
      }
    }

    return {
      ...r.first,
      'records': records,
      'paymentBreakdown': paymentBreakdown,
      'cash': cash,
      'mtn': mtn,
      'telecel': telecel,
      'other': other,
    };
  }

  Future<Map<String, dynamic>> getMonthlyReport(int y, int m) async {
    final db = await database;
    final s = DateTime(y, m, 1).toIso8601String();
    final e = DateTime(y, m + 1, 0, 23, 59, 59).toIso8601String();
    final r = await db.rawQuery(
      '''SELECT COUNT(*) as total, SUM(Amount) as revenue, AVG(Amount) as average
      FROM LaundryRecords WHERE CreatedAt BETWEEN ? AND ?''',
      [s, e],
    );
    final daily = await db.rawQuery(
      '''SELECT DATE(CreatedAt) as date, COUNT(*) as orders, SUM(Amount) as revenue
      FROM LaundryRecords WHERE CreatedAt BETWEEN ? AND ?
      GROUP BY DATE(CreatedAt) ORDER BY date''',
      [s, e],
    );
    final records = await db.query(
      'LaundryRecords',
      where: 'CreatedAt BETWEEN ? AND ?',
      whereArgs: [s, e],
    );

    // Aggregate by payment type
    final paymentBreakdown = await db.rawQuery(
      '''SELECT PaymentType,
      COUNT(*) as orderCount,
      SUM(Amount) as totalAmount
      FROM LaundryRecords
      WHERE CreatedAt BETWEEN ? AND ? AND Status = 'Completed'
      GROUP BY PaymentType''',
      [s, e],
    );

    // Calculate payment type totals
    double cash = 0, mtn = 0, telecel = 0, other = 0;
    int cashOrders = 0, mtnOrders = 0, telecelOrders = 0, otherOrders = 0;

    for (var item in paymentBreakdown) {
      final type = (item['PaymentType'] as String?)?.toUpperCase() ?? '';
      final amount = (item['totalAmount'] as num?)?.toDouble() ?? 0;
      final count = (item['orderCount'] as int?) ?? 0;

      if (type == 'CASH') {
        cash = amount;
        cashOrders = count;
      } else if (type == 'MTN') {
        mtn = amount;
        mtnOrders = count;
      } else if (type == 'TELECEL') {
        telecel = amount;
        telecelOrders = count;
      } else {
        other += amount;
        otherOrders += count;
      }
    }

    return {
      ...r.first,
      'dailyBreakdown': daily,
      'records': records,
      'paymentBreakdown': paymentBreakdown,
      'cash': cash,
      'mtn': mtn,
      'telecel': telecel,
      'other': other,
      'cashOrders': cashOrders,
      'mtnOrders': mtnOrders,
      'telecelOrders': telecelOrders,
      'otherOrders': otherOrders,
    };
  }

  Future<Map<String, dynamic>> getYearlyReport(int y) async {
    final db = await database;
    final s = DateTime(y, 1, 1).toIso8601String();
    final e = DateTime(y, 12, 31, 23, 59, 59).toIso8601String();
    final r = await db.rawQuery(
      '''SELECT COUNT(*) as total, SUM(Amount) as revenue
      FROM LaundryRecords WHERE CreatedAt BETWEEN ? AND ?''',
      [s, e],
    );
    final monthly = await db.rawQuery(
      '''SELECT strftime('%m', CreatedAt) as month,
      COUNT(*) as orders, SUM(Amount) as revenue FROM LaundryRecords
      WHERE CreatedAt BETWEEN ? AND ? GROUP BY strftime('%m', CreatedAt) ORDER BY month''',
      [s, e],
    );
    final records = await db.query(
      'LaundryRecords',
      where: 'CreatedAt BETWEEN ? AND ?',
      whereArgs: [s, e],
    );

    // Aggregate by payment type
    final paymentBreakdown = await db.rawQuery(
      '''SELECT PaymentType,
      COUNT(*) as orderCount,
      SUM(Amount) as totalAmount
      FROM LaundryRecords
      WHERE CreatedAt BETWEEN ? AND ? AND Status = 'Completed'
      GROUP BY PaymentType''',
      [s, e],
    );

    // Calculate payment type totals
    double cash = 0, mtn = 0, telecel = 0, other = 0;
    int cashOrders = 0, mtnOrders = 0, telecelOrders = 0, otherOrders = 0;

    for (var item in paymentBreakdown) {
      final type = (item['PaymentType'] as String?)?.toUpperCase() ?? '';
      final amount = (item['totalAmount'] as num?)?.toDouble() ?? 0;
      final count = (item['orderCount'] as int?) ?? 0;

      if (type == 'CASH') {
        cash = amount;
        cashOrders = count;
      } else if (type == 'MTN') {
        mtn = amount;
        mtnOrders = count;
      } else if (type == 'TELECEL') {
        telecel = amount;
        telecelOrders = count;
      } else {
        other += amount;
        otherOrders += count;
      }
    }

    return {
      ...r.first,
      'monthlyBreakdown': monthly,
      'records': records,
      'paymentBreakdown': paymentBreakdown,
      'cash': cash,
      'mtn': mtn,
      'telecel': telecel,
      'other': other,
      'cashOrders': cashOrders,
      'mtnOrders': mtnOrders,
      'telecelOrders': telecelOrders,
      'otherOrders': otherOrders,
    };
  }

  Future<String> exportToExcel(
    List<Map<String, dynamic>> records,
    String type,
  ) async {
    return await ExcelExporter.exportLaundryRecords(records, type);
  }

  Future<void> logAction(
    int adminId,
    String action,
    int? recordId,
    String details,
  ) async {
    final db = await database;
    await db.insert('AuditLog', {
      'AdminID': adminId,
      'Action': action,
      'RecordID': recordId,
      'Details': details,
      'Timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLog({int limit = 100}) async {
    final db = await database;
    return await db.rawQuery(
      '''SELECT a.*, ad.Username, ad.FullName FROM AuditLog a
      JOIN Admins ad ON a.AdminID = ad.AdminID ORDER BY a.Timestamp DESC LIMIT ?''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getServiceTypes() async {
    final db = await database;
    return await db.query(
      'ServiceTypes',
      where: 'IsActive = 1',
      orderBy: 'ServiceName',
    );
  }

  Future<List<Map<String, dynamic>>> getAuditLogByPeriod(
    DateTime? start,
    DateTime? end, {
    int limit = 100,
  }) async {
    final db = await database;
    String where = '';
    List whereArgs = [];
    if (start != null && end != null) {
      // Add 1 day to end to make the range inclusive for the end date
      where = 'WHERE a.Timestamp BETWEEN ? AND ?';
      whereArgs = [
        start.toIso8601String(),
        end.add(Duration(days: 1)).toIso8601String(),
      ];
    }
    return await db.rawQuery(
      '''SELECT a.*, ad.Username, ad.FullName FROM AuditLog a JOIN Admins ad ON a.AdminID = ad.AdminID $where ORDER BY a.Timestamp DESC LIMIT ?''',
      [...whereArgs, limit],
    );
  }

  Future<int> addServiceType(
    String name,
    double? price, {
    String? description,
  }) async {
    final db = await database;
    return await db.insert('ServiceTypes', {
      'ServiceName': name,
      'DefaultPrice': price,
      'IsActive': 1,
      // Optionally add 'Description': description if you add this column to the table
    });
  }

  Future<int> updateServiceType(
    int id,
    String name,
    double? price, {
    String? description,
  }) async {
    final db = await database;
    return await db.update(
      'ServiceTypes',
      {
        'ServiceName': name,
        'DefaultPrice': price,
        // Optionally add 'Description': description if you add this column to the table
      },
      where: 'ServiceID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteServiceType(int id) async {
    final db = await database;
    // Soft delete: set IsActive = 0
    return await db.update(
      'ServiceTypes',
      {'IsActive': 0},
      where: 'ServiceID = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentTypes() async {
    final db = await database;
    return await db.query(
      'PaymentTypes',
      where: 'IsActive = 1',
      orderBy: 'PaymentTypeName',
    );
  }

  Future<int> addPaymentType(String name) async {
    final db = await database;
    return await db.insert('PaymentTypes', {
      'PaymentTypeName': name,
      'IsActive': 1,
    });
  }

  Future<int> updatePaymentType(int id, String name) async {
    final db = await database;
    return await db.update(
      'PaymentTypes',
      {'PaymentTypeName': name},
      where: 'PaymentTypeID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePaymentType(int id) async {
    final db = await database;
    // Soft delete: set IsActive = 0
    return await db.update(
      'PaymentTypes',
      {'IsActive': 0},
      where: 'PaymentTypeID = ?',
      whereArgs: [id],
    );
  }
}
