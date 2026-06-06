import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/reports_repository.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/monthly_summary_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final spendingAsync = ref.watch(categorySpendingProvider);
    final last6Async = ref.watch(last6MonthsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.amber,
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
            ref.invalidate(categorySpendingProvider);
            ref.invalidate(monthlyTotalsProvider);
            ref.invalidate(last6MonthsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad(context), 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.tabReports, style: AppTextStyles.titleLarge),
                            Text(month.monthYear, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () =>
                            ref.read(selectedMonthProvider.notifier).previousMonth(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: month.isSameMonth(DateTime.now())
                            ? null
                            : () =>
                                ref.read(selectedMonthProvider.notifier).nextMonth(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: totalsAsync.when(
                  loading: () => const LoadingOverlay(),
                  error: (e, _) => ErrorDisplay(error: e),
                  data: (totals) => MonthlySummaryCard(totals: totals),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad(context), 16, hPad(context), 8),
                  child: Text(S.spendingByCategory, style: AppTextStyles.titleMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: hPad(context)),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: spendingAsync.when(
                    loading: () => const LoadingOverlay(),
                    error: (e, _) => ErrorDisplay(error: e),
                    data: (spending) => CategoryPieChart(data: spending),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad(context), 16, hPad(context), 8),
                  child: Text(S.last6Months, style: AppTextStyles.titleMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.fromLTRB(hPad(context), 0, hPad(context), 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: last6Async.when(
                    loading: () => const LoadingOverlay(),
                    error: (e, _) => ErrorDisplay(error: e),
                    data: (months) => Column(
                      children: [
                        MonthlyBarChart(data: months),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Legend(color: AppColors.green, label: S.totalIncome),
                            const SizedBox(width: 16),
                            _Legend(color: AppColors.red, label: S.totalExpense),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
