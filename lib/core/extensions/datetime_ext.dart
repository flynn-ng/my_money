import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get monthYear => DateFormat('MMMM yyyy', 'vi').format(this);
  String get shortDate => DateFormat('d MMM', 'vi').format(this);
  String get fullDate => DateFormat('d MMM yyyy', 'vi').format(this);
  String get isoDate => DateFormat('yyyy-MM-dd').format(this);

  DateTime get firstOfMonth => DateTime(year, month, 1);

  /// Monday 00:00 of the week this date falls in — weeks start on Monday here,
  /// matching how the calendar is read in Vietnam.
  DateTime get weekStart =>
      DateTime(year, month, day - (weekday - DateTime.monday));

  /// Calendar-safe day arithmetic: `DateTime(y, m, d + n)` rolls over month and
  /// year ends on its own, and unlike adding a [Duration] it cannot drift by an
  /// hour across a daylight-saving change.
  DateTime addDays(int days) => DateTime(year, month, day + days);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  bool isSameWeek(DateTime other) => weekStart.isSameDay(other.weekStart);
}

extension StringDateExt on String {
  DateTime toDate() => DateTime.parse(this);
}
