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
import '../../../../core/widgets/sheet_wrapper.dart';
import '../../../transactions/data/transaction_model.dart';
import '../../data/weekly_summary_repository.dart';

/// The rows behind the weekly card: every transaction of the week, income and
/// expense together, so a number on the card can always be traced to what made
/// it.
class WeeklyTransactionsSheet extends ConsumerWidget {
  const WeeklyTransactionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAppSheet(
      context: context,
      content: const WeeklyTransactionsSheet(),
      initialChildSize: 0.8,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(selectedWeekProvider);
    final listAsync = ref.watch(weekTransactionListProvider);
    final isFiltered = ref.watch(weekCategoryFilterProvider).isNotEmpty;

    return listAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => ErrorDisplay(
        error: e,
        onRetry: () => ref.invalidate(weeklyTransactionsProvider),
      ),
      data: (transactions) => WeeklyTransactionsList(
        transactions: transactions,
        weekStart: week,
        isFiltered: isFiltered,
      ),
    );
  }
}

/// Presentation half, kept free of providers so it can be pumped directly.
class WeeklyTransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final DateTime weekStart;

  /// Whether a category selection is narrowing the list, which is worth saying
  /// out loud — otherwise a short list looks like missing data.
  final bool isFiltered;

  const WeeklyTransactionsList({
    super.key,
    required this.transactions,
    required this.weekStart,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    var income = 0.0;
    var expense = 0.0;
    for (final tx in transactions) {
      if (tx.txType == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    // Already sorted newest first, so days come out in that order too.
    final byDay = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      byDay.putIfAbsent(_dayKey(tx.date), () => []).add(tx);
    }
    final days = byDay.keys.toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad(context), 8, hPad(context), 32),
      children: [
        Text(S.weekTransactionsTitle, style: AppTextStyles.titleLarge),
        const SizedBox(height: 2),
        Text(
          '${weekStart.shortDate} – ${weekStart.addDays(6).shortDate}'
          '${isFiltered ? ' • ${S.weekFilterHint}' : ''}',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Total(
                label: S.totalIncome,
                value: '+${income.asCompactCurrency}',
                color: AppColors.green,
              ),
            ),
            Expanded(
              child: _Total(
                label: S.totalExpense,
                value: '-${expense.asCompactCurrency}',
                color: AppColors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(S.weekNoSpending, style: context.tsBodyMedium),
            ),
          ),
        for (final day in days) ...[
          _DayHeader(
            date: byDay[day]!.first.date,
            transactions: byDay[day]!,
          ),
          for (final tx in byDay[day]!) _TransactionRow(transaction: tx),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
}

class _Total extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Total({required this.label, required this.value, required this.color});

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

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final List<TransactionModel> transactions;

  const _DayHeader({required this.date, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final net = transactions.fold<double>(
      0,
      (sum, tx) =>
          sum + (tx.txType == TransactionType.income ? tx.amount : -tx.amount),
    );
    final labels = S.weekdayShort;
    // DateTime.weekday is 1 for Monday, and the labels start there too.
    final weekday = labels[(date.weekday - 1).clamp(0, labels.length - 1)];

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        children: [
          Text('$weekday, ${date.shortDate}', style: AppTextStyles.labelSmall),
          const Spacer(),
          Text(
            net >= 0 ? '+${net.asCompactCurrency}' : net.asCompactCurrency,
            style: AppTextStyles.labelSmall.copyWith(
                color: net >= 0 ? AppColors.green : context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.txType == TransactionType.income;
    final notes = transaction.notes?.trim() ?? '';
    final person = transaction.paidByName?.trim() ?? '';
    // Notes say the most; the payer is the fallback when there are none.
    final subtitle = notes.isNotEmpty ? notes : person;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(transaction.categoryIcon ?? '📦',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.categoryName ?? S.otherCategory,
                  style: context.tsBodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isIncome
                ? '+${transaction.amount.asCompactCurrency}'
                : '-${transaction.amount.asCompactCurrency}',
            style: AppTextStyles.bodyLarge.copyWith(
              color: isIncome ? AppColors.green : AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
