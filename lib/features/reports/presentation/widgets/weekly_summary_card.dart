import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/error_display.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/reports_repository.dart';
import '../../data/weekly_summary_repository.dart';
import 'weekly_day_bars.dart';

/// The "Theo tuần" block on the reports screen: its own week navigator plus the
/// card below it.
///
/// The week moves independently of the month picker at the top of the screen —
/// a week that straddles a month boundary is still one week — so the header
/// always spells out the date range it is showing.
class WeeklySummarySection extends ConsumerWidget {
  const WeeklySummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(selectedWeekProvider);
    final summaryAsync = ref.watch(weeklySummaryProvider);
    final isCurrentWeek = week.isSameWeek(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad(context), 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(S.weeklyTitle,
                              style: context.tsTitleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isCurrentWeek) ...[
                          const SizedBox(width: 8),
                          const _ThisWeekPill(),
                        ],
                      ],
                    ),
                    Text(
                      '${week.shortDate} – ${week.addDays(6).shortDate}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    ref.read(selectedWeekProvider.notifier).previousWeek(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: isCurrentWeek
                    ? null
                    : () => ref.read(selectedWeekProvider.notifier).nextWeek(),
              ),
            ],
          ),
        ),
        summaryAsync.when(
          // Fixed height: stepping through weeks would otherwise collapse the
          // section and yank the rest of the report up the screen.
          loading: () => const SizedBox(height: 260, child: LoadingOverlay()),
          error: (e, _) => ErrorDisplay(
            error: e,
            onRetry: () => ref.invalidate(weeklySummaryProvider),
          ),
          data: (summary) => WeeklySummaryCard(summary: summary),
        ),
      ],
    );
  }
}

class _ThisWeekPill extends StatelessWidget {
  const _ThisWeekPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(S.weekThis,
          style: AppTextStyles.labelSmall
              .copyWith(color: context.colors.textSecondary)),
    );
  }
}

class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  const WeeklySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad(context)),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: summary.isEmpty ? _empty(context) : _content(context),
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(S.weekNoSpending, style: context.tsBodyMedium),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final percent = summary.expenseChangePercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.weekSpent, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                summary.expense.asCompactCurrency,
                style: context.tsAmountLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (percent != null) ...[
              const SizedBox(width: 10),
              _DeltaChip(percent: percent),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          percent == null ? S.weekNoComparison : S.weekVsLastWeek,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        WeeklyDayBars(days: summary.days, today: DateTime.now()),
        const SizedBox(height: 16),
        Divider(height: 1, color: context.colors.divider),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: S.totalIncome,
                value: summary.income.asCompactCurrency,
                color: AppColors.green,
              ),
            ),
            Expanded(
              child: _Metric(
                label: S.netSaved,
                value: summary.net.asCompactCurrency,
                color: summary.net >= 0
                    ? context.colors.textPrimary
                    : AppColors.red,
              ),
            ),
            Expanded(
              child: _Metric(
                label: S.weekDailyAvg,
                value: summary.dailyAverage.asCompactCurrency,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
        if (summary.topCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 12),
          Text(S.weekTopCategories, style: AppTextStyles.labelSmall),
          const SizedBox(height: 10),
          for (var i = 0; i < summary.topCategories.length; i++)
            _CategoryRow(
              spending: summary.topCategories[i],
              total: summary.expense,
              isLast: i == summary.topCategories.length - 1,
            ),
        ],
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  /// Signed percentage change against last week.
  final double percent;
  const _DeltaChip({required this.percent});

  @override
  Widget build(BuildContext context) {
    // Spending more than last week is the bad direction, so up is red.
    final color = percent == 0
        ? context.colors.textSecondary
        : (percent > 0 ? AppColors.red : AppColors.green);
    final magnitude = percent.abs();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percent == 0
                ? Icons.remove
                : (percent > 0 ? Icons.arrow_upward : Icons.arrow_downward),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            // A tenfold jump off a tiny baseline is noise, not information.
            magnitude >= 999 ? '>999%' : '${magnitude.toStringAsFixed(0)}%',
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: AppTextStyles.labelSmall, maxLines: 1),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySpending spending;
  final double total;
  final bool isLast;

  const _CategoryRow({
    required this.spending,
    required this.total,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final share =
        total <= 0 ? 0.0 : (spending.amount / total).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spending.categoryIcon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spending.categoryName,
                        style: context.tsBodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      spending.amount.asCompactCurrency,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: context.colors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    backgroundColor: context.colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.fromHex(spending.categoryColor)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
