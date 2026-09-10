import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../data/weekly_summary_repository.dart';

/// Seven expense bars, Monday to Sunday.
///
/// Hand-drawn rather than fl_chart: the strip is a single series with a fixed
/// seven slots, and doing it by hand is what makes today's bar and the days
/// that have not happened yet stylable.
class WeeklyDayBars extends StatelessWidget {
  final List<DailyTotal> days;
  final DateTime today;

  const WeeklyDayBars({super.key, required this.days, required this.today});

  static const _trackHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    final peak = days.fold<double>(0, (m, d) => d.expense > m ? d.expense : m);
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
              // Everything is measured against the busiest day, so a quiet week
              // still reads as a shape instead of seven flat stubs.
              fraction: peak <= 0 ? 0 : days[i].expense / peak,
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
  final double fraction;
  final bool isToday;
  final bool isFuture;

  const _DayBar({
    required this.day,
    required this.label,
    required this.fraction,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    // A day with any spending never collapses to nothing.
    final height = day.expense <= 0
        ? 4.0
        : (fraction * WeeklyDayBars._trackHeight).clamp(6.0, WeeklyDayBars._trackHeight).toDouble();

    // Today stands out in the ink colour (which flips with the theme); the rest
    // of the week keeps the expense red used everywhere else.
    final Color color;
    if (day.expense > 0) {
      color = isToday ? context.colors.textPrimary : AppColors.red;
    } else {
      color = context.colors.divider;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: WeeklyDayBars._trackHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 14,
              height: height,
              decoration: BoxDecoration(
                color: isFuture ? context.colors.divider : color,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
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
