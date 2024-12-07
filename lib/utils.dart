import 'package:intl/intl.dart';
String getCurrentDateTime() {
  DateTime now = DateTime.now();
  DateFormat dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  return dateFormat.format(now);
}
String getCurrentDateTimeLKF() {
  DateTime now = DateTime.now();
  DateFormat dateFormat = DateFormat("yyyyMMdd_HHmmss");  // Full year and 24-hour time
  return dateFormat.format(now);
}