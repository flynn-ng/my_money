import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get monthYear => DateFormat('MMMM yyyy', 'vi').format(this);
  String get shortDate => DateFormat('d MMM', 'vi').format(this);
  String get fullDate => DateFormat('d MMM yyyy', 'vi').format(this);
  String get isoDate => DateFormat('yyyy-MM-dd').format(this);

  DateTime get firstOfMonth => DateTime(year, month, 1);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;
}

extension StringDateExt on String {
  DateTime toDate() => DateTime.parse(this);
}
