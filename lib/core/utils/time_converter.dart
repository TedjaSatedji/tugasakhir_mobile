import 'package:intl/intl.dart';

class TimeConverter {
  static String getGlobalServerTime(String timezone) {
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm:ss dd/MM/yyyy');

    switch (timezone.toUpperCase()) {
      case 'GMT':
        return formatter.format(now.toUtc());
      case 'WIB':
        return formatter.format(now.add(const Duration(hours: 7)));
      case 'WITA':
        return formatter.format(now.add(const Duration(hours: 8)));
      case 'WIT':
        return formatter.format(now.add(const Duration(hours: 9)));
      default:
        return formatter.format(now);
    }
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String getTimeUntil(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) return 'Waktu berakhir';

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) return '${days}h ${hours}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}