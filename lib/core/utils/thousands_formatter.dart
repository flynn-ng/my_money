import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats amount input with thousand separators (dots for vi_VN locale).
/// Decimal part is separated by comma only — dot is always a thousands separator.
class ThousandsSeparatorFormatter extends TextInputFormatter {
  static final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    // Only comma is the decimal separator; dots are thousands separators and ignored.
    final commaIdx = raw.indexOf(',');
    final hasDecimal = commaIdx >= 0;

    final intRaw = (hasDecimal ? raw.substring(0, commaIdx) : raw)
        .replaceAll(RegExp(r'[^\d]'), '');
    final decPart = hasDecimal
        ? raw.substring(commaIdx + 1).replaceAll(RegExp(r'[^\d]'), '')
        : '';

    if (intRaw.isEmpty && !hasDecimal) return newValue.copyWith(text: '');

    final intFormatted =
        intRaw.isEmpty ? '0' : _fmt.format(int.parse(intRaw));
    final result = hasDecimal
        ? '$intFormatted,${decPart.substring(0, decPart.length.clamp(0, 2))}'
        : intFormatted;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  /// Parses the formatted string back to a double.
  static double? parse(String formatted) {
    final cleaned = formatted.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}
