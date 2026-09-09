import 'dart:io';
import 'package:excel/excel.dart' as xl show Excel, TextCellValue;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

class ExcelExporter {
  static Future<String> exportLaundryRecords(
    List<Map<String, dynamic>> records,
    String type,
  ) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Report'];

    xl.TextCellValue cell(dynamic value) =>
        xl.TextCellValue(value?.toString() ?? '');

    sheet.appendRow([
      cell('ID'),
      cell('Customer'),
      cell('Phone'),
      cell('Service'),
      cell('Weight'),
      cell('Amount'),
      cell('Payment Type'),
      cell('Status'),
      cell('Created'),
      cell('Completed'),
      cell('Notes'),
    ]);

    for (var r in records) {
      sheet.appendRow([
        cell(r['RecordID']),
        cell(r['CustomerName']),
        cell(r['PhoneNumber']),
        cell(r['ServiceType']),
        cell(r['Weight']),
        cell(r['Amount']),
        cell(r['PaymentType']),
        cell(r['Status']),
        cell(r['CreatedAt']),
        cell(r['CompletedAt']),
        cell(r['Notes']),
      ]);
    }

    // Use a dedicated downloads folder inside the app documents directory (portable + writable)
    Directory appDir;
    try {
      appDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      // fallback to current directory if path_provider isn't available in the environment
      appDir = Directory.current;
    }

    final downloadsDir = Directory(join(appDir.path, 'downloads'));
    if (!downloadsDir.existsSync()) {
      try {
        downloadsDir.createSync(recursive: true);
      } catch (e) {
        // rethrow so callers can show a friendly error message
        rethrow;
      }
    }

    final fileName =
        'LaundryPOS_${type}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final path = join(downloadsDir.path, fileName);
    await File(path).writeAsBytes(excel.save()!);
    return path;
  }

  // You can add more export methods for other data types if needed
}
