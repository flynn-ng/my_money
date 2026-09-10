import 'package:intl/intl.dart';

extension CurrencyExt on double {
  bool get _isWhole => this == truncateToDouble();

  String get asCurrency => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: _isWhole ? 0 : 2,
      ).format(this);

  /// Shortest readable form, for labels that sit inside a chart where a slot is
  /// barely wider than the number: no currency symbol, no space.
  String get asChartLabel {
    final abs = this.abs();
    if (abs >= 1000000000) return '${(this / 1000000000).toStringAsFixed(1)}tỷ';
    if (abs >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}tr';
    if (abs >= 1000) return '${(this / 1000).round()}k';
    return toStringAsFixed(0);
  }

  String get asCompactCurrency {
    final abs = this.abs();
    final decimals = _isWhole ? 1 : 2;
    if (abs >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(decimals)} tỷ₫';
    }
    if (abs >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(decimals)} triệu₫';
    }
    if (abs >= 1000) return '${(this / 1000).toStringAsFixed(_isWhole ? 0 : 1)}k₫';
    return asCurrency;
  }
}

