import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _displayFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _fullFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Today's service date in college timezone
  /// shortcut: uses device clock; use server time for production-critical cases
  static String get todayServiceDate => _dateFormat.format(DateTime.now());

  static String formatDate(DateTime dt) => _displayFormat.format(dt);
  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatFull(DateTime dt) => _fullFormat.format(dt);

  static String formatDateStr(String iso) {
    try {
      return formatDate(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
