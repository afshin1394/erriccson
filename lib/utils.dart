import 'package:intl/intl.dart';
class DateUtil {
  static late DateTime now;

  static void init() {
    now = DateTime.now();
  }

  static String getCurrentDateTime() {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    return dateFormat.format(now);
  }

  static String getCurrentDateTimeLKF() {
    DateFormat dateFormat = DateFormat("yyyyMMdd_HHmmss");
    return dateFormat.format(now);
  }
}