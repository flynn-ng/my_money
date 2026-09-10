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
import 'weekly_transactions_sheet.dart';

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
            onRetry: () => ref.invalidate(weeklyTransactionsProvider),
          ),
          data: (summary) => WeeklySummaryCard(
            summary: summary,
            onCategoryTap: (categoryId) => ref
                .read(weekCategoryFilterProvider.notifier)
                .toggle(categoryId),
            onClearFilters: () =>
                ref.read(weekCategoryFilterProvider.notifier).clear(),
            onShowTransactions: () => WeeklyTransactionsSheet.show(context),
          ),
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

class WeeklySummaryCard extends StatefulWidget {
  final WeeklySummary summary;

  /// Called with the category ticked in the list. Null leaves the rows inert,
  /// which is what the widget tests want.
  final void Function(String categoryId)? onCategoryTap;

  /// Clears every selected category at once.
  final VoidCallback? onClearFilters;

  /// Opens the list of transactions the numbers are made of.
  final VoidCallback? onShowTransactions;

  const WeeklySummaryCard({
    super.key,
    required this.summary,
    this.onCategoryTap,
    this.onClearFilters,
    this.onShowTransactions,
  });

  @override
  State<WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<WeeklySummaryCard> {
  bool _expanded = false;

  WeeklySummary get summary => widget.summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad(context)),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      // A filtered week with nothing in those categories still needs its
      // category list on screen, otherwise there is no way back out.
      child: summary.isEmpty && !summary.isFiltered
          ? _empty(context)
          : _content(context),
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

    final filtered = summary.filteredCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isFiltered) ...[
          _FilterBar(
            selected: filtered,
            count: summary.categoryFilters.length,
            onClear: widget.onClearFilters,
          ),
          const SizedBox(height: 12),
        ],
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
        if (widget.onShowTransactions != null) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.divider),
          _ShowTransactionsRow(onTap: widget.onShowTransactions!),
        ],
        if (summary.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 12),
          _CategoryHeader(
            total: summary.categories.length,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          const SizedBox(height: 10),
          // Expanding the list is the one place the card changes height on its
          // own; animating it keeps the report below from jumping.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _visibleCategories.length; i++)
                  _CategoryRow(
                    spending: _visibleCategories[i],
                    // Shares are read against the week, not against the
                    // filtered total — otherwise a selected category would
                    // always show 100%.
                    total: _categoryTotal,
                    isLast: i == _visibleCategories.length - 1,
                    selected:
                        summary.isSelected(_visibleCategories[i].categoryId),
                    onTap: widget.onCategoryTap == null
                        ? null
                        : () => widget
                            .onCategoryTap!(_visibleCategories[i].categoryId),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<CategorySpending> get _visibleCategories => _expanded
      ? summary.categories
      : summary.categories
          .take(WeeklySummaryRepository.topCategoryCount)
          .toList();

  double get _categoryTotal =>
      summary.categories.fold<double>(0, (sum, c) => sum + c.amount);
}

/// Way into the transactions behind the numbers — the card shows totals for
/// income too, and without this there is nothing on screen explaining them.
class _ShowTransactionsRow extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowTransactionsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 16, color: context.colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(S.weekViewTransactions, style: context.tsBodyLarge),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final int total;
  final bool expanded;
  final VoidCallback onToggle;

  const _CategoryHeader({
    required this.total,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final canExpand = total > WeeklySummaryRepository.topCategoryCount;

    return Row(
      children: [
        Expanded(
          child: Text(
            expanded ? S.weekAllCategories : S.weekTopCategories,
            style: AppTextStyles.labelSmall,
          ),
        ),
        if (canExpand)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? S.weekShowLess : S.weekShowAll(total),
                    style: AppTextStyles.labelSmall
                        .copyWith(color: context.colors.textPrimary),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: context.colors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Says what the numbers below are counting, and offers one tap back out.
class _FilterBar extends StatelessWidget {
  final List<CategorySpending> selected;

  /// Selected ids, which can outnumber [selected] when a picked category has no
  /// spending in the week being shown.
  final int count;
  final VoidCallback? onClear;

  const _FilterBar({
    required this.selected,
    required this.count,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    // One category reads better by name; several would not fit, so they are
    // counted instead.
    final label = selected.length == 1
        ? '${selected.first.categoryIcon} ${selected.first.categoryName}'
        : S.weekFilterCount(count);

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.colors.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: context.colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            S.weekFilterHint,
            style: AppTextStyles.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onClear != null)
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close,
                      size: 14, color: context.colors.textSecondary),
                  const SizedBox(width: 2),
                  Text(S.weekFilterClear, style: AppTextStyles.labelSmall),
                ],
              ),
            ),
          ),
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
  final bool selected;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.spending,
    required this.total,
    required this.isLast,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final share =
        total <= 0 ? 0.0 : (spending.amount / total).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.textPrimary.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onTap != null) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: selected,
                    // The whole row is the tap target; the box just reflects it.
                    onChanged: (_) => onTap!(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: context.colors.textSecondary),
                    activeColor: context.colors.textPrimary,
                    checkColor: context.colors.background,
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
        ),
      ),
    );
  }
}
