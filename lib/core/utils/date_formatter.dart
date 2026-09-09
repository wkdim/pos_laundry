import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('hh:mm a').format(dateTime);
  }
}