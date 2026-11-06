import 'package:flutter_test/flutter_test.dart';
import 'package:pos_laundry/core/utils/password_hasher.dart';
import 'package:pos_laundry/models/admin.dart';
import 'package:pos_laundry/models/laundry_record.dart';

void main() {
  group('LaundryRecord', () {
    test('survives a round trip through the database map', () {
      final created = DateTime(2026, 11, 6, 9, 30);
      final record = LaundryRecord(
        recordId: 12,
        customerName: 'Ama Owusu',
        phoneNumber: '0240000000',
        serviceType: 'Wash & Iron',
        weight: 4.5,
        amount: 85,
        status: 'Completed',
        isLocked: true,
        createdBy: 1,
        createdAt: created,
        paymentType: 'MTN',
      );

      final copy = LaundryRecord.fromMap(record.toMap());

      expect(copy.recordId, 12);
      expect(copy.customerName, 'Ama Owusu');
      expect(copy.weight, 4.5);
      expect(copy.amount, 85.0);
      expect(copy.status, 'Completed');
      expect(copy.isLocked, isTrue);
      expect(copy.createdAt, created);
      expect(copy.completedAt, isNull);
      expect(copy.paymentType, 'MTN');
    });

    test('stores the lock flag as 1 or 0 for SQLite', () {
      final locked = LaundryRecord(customerName: 'A', serviceType: 'Wash', amount: 10, isLocked: true);
      final open = LaundryRecord(customerName: 'B', serviceType: 'Wash', amount: 10);
      expect(locked.toMap()['IsLocked'], 1);
      expect(open.toMap()['IsLocked'], 0);
    });

    test('falls back to sensible defaults for missing values', () {
      final record = LaundryRecord.fromMap({
        'CustomerName': 'Kofi',
        'ServiceType': 'Dry Clean',
        'Amount': 40,
      });
      expect(record.status, 'Pending');
      expect(record.weight, 0.0);
      expect(record.amount, 40.0);
      expect(record.isLocked, isFalse);
    });
  });

  group('Admin', () {
    test('survives a round trip through the database map', () {
      final admin = Admin(
        adminId: 1,
        username: 'frontdesk',
        passwordHash: PasswordHasher.hash('secret123'),
        fullName: 'Efua Mensah',
        role: 'Front Desk',
        isActive: false,
      );
      final copy = Admin.fromMap(admin.toMap());
      expect(copy.username, 'frontdesk');
      expect(copy.role, 'Front Desk');
      expect(copy.isActive, isFalse);
      expect(copy.passwordHash, admin.passwordHash);
    });
  });

  group('PasswordHasher', () {
    test('verifies the correct password and rejects a wrong one', () {
      final hash = PasswordHasher.hash('secret123');
      expect(hash, isNot('secret123'));
      expect(PasswordHasher.verify('secret123', hash), isTrue);
      expect(PasswordHasher.verify('Secret123', hash), isFalse);
    });
  });
}
