import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../data/weekly_summary_repository.dart';

/// Seven day slots, Monday to Sunday, with the amount written above each bar.
///
/// Hand-drawn rather than fl_chart: the strip is a fixed seven slots, and doing
/// it by hand is what makes today's bar, the days that have not happened yet,
/// and the income series stylable.
class WeeklyDayBars extends StatelessWidget {
  final List<DailyTotal> days;
  final DateTime today;

  const WeeklyDayBars({super.key, required this.days, required this.today});

  static const _trackHeight = 84.0;

  /// The amount label rides on top of its bar, so the bar gets the rest.
  static const _labelHeight = 14.0;
  static const _maxBarHeight = _trackHeight - _labelHeight;

  @override
  Widget build(BuildContext context) {
    // One scale for both series, so a green bar and a red bar an inch apart
    // still mean the same thing.
    var peak = 0.0;
    for (final day in days) {
      if (day.expense > peak) peak = day.expense;
      if (day.income > peak) peak = day.income;
    }

    // Only make room for a second bar per slot when the week actually has
    // income — most weeks do not, and they keep the wider single bar.
    final showIncome = days.any((day) => day.income > 0);
    final labels = S.weekdayShort;
    final now = DateTime(today.year, today.month, today.day);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: _DayBar(
              day: days[i],
              label: i < labels.length ? labels[i] : '',
              peak: peak,
              showIncome: showIncome,
              isToday: days[i].date.isSameDay(now),
              isFuture: days[i].date.isAfter(now),
            ),
          ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  final DailyTotal day;
  final String label;
  final double peak;
  final bool showIncome;
  final bool isToday;
  final bool isFuture;

  const _DayBar({
    required this.day,
    required this.label,
    required this.peak,
    required this.showIncome,
    required this.isToday,
    required this.isFuture,
  });

  /// Everything is measured against the busiest day, so a quiet week still
  /// reads as a shape instead of seven flat stubs. A day with any movement
  /// never collapses to nothing.
  double _heightFor(double value) {
    if (value <= 0) return 4;
    if (peak <= 0) return 6;
    return (value / peak * WeeklyDayBars._maxBarHeight)
        .clamp(6.0, WeeklyDayBars._maxBarHeight)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Today stands out in the ink colour (which flips with the theme); the rest
    // of the week keeps the expense red used everywhere else.
    final Color expenseColor;
    if (isFuture || day.expense <= 0) {
      expenseColor = context.colors.divider;
    } else {
      expenseColor = isToday ? context.colors.textPrimary : AppColors.red;
    }

    // One number per slot, on whichever bar draws the eye — two would not fit
    // side by side on a phone.
    final labelsIncome = day.income > day.expense;
    final amount = labelsIncome ? day.income : day.expense;
    final barWidth = showIncome ? 10.0 : 14.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: WeeklyDayBars._trackHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: WeeklyDayBars._labelHeight,
                child: amount <= 0
                    ? null
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          amount.asChartLabel,
                          maxLines: 1,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9,
                            letterSpacing: 0,
                            color: labelsIncome
                                ? AppColors.green
                                : context.colors.textSecondary,
                          ),
                        ),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: barWidth,
                    height: _heightFor(day.expense),
                    decoration: BoxDecoration(
                      color: expenseColor,
                      borderRadius: BorderRadius.circular(barWidth / 2),
                    ),
                  ),
                  if (showIncome && day.income > 0) ...[
                    const SizedBox(width: 3),
                    Container(
                      width: barWidth,
                      height: _heightFor(day.income),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? context.colors.divider
                            : AppColors.green,
                        borderRadius: BorderRadius.circular(barWidth / 2),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          style: AppTextStyles.labelSmall.copyWith(
            color: isToday
                ? context.colors.textPrimary
                : context.colors.textSecondary,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
