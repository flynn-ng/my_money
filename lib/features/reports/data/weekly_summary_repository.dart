import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/offline/offline_cache.dart';
import '../../auth/data/auth_repository.dart';
import '../../transactions/data/transaction_model.dart';
import '../../transactions/data/transaction_repository.dart';
import 'reports_repository.dart';

/// One day of a week.
class DailyTotal {
  final DateTime date;
  final double income;
  final double expense;

  const DailyTotal({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

/// Everything the weekly card shows, for one Monday-to-Sunday week.
class WeeklySummary {
  /// Monday 00:00 of the week.
  final DateTime weekStart;

  final double income;
  final double expense;

  /// Expense total of the week before — the baseline for the delta.
  final double previousExpense;

  /// Always seven entries, Monday first.
  final List<DailyTotal> days;

  /// Biggest expense categories of the week, largest first.
  final List<CategorySpending> topCategories;

  /// Days of the week that have actually happened: 7 for a finished week,
  /// 1-7 for the running one, 0 for a week that has not started yet.
  final int elapsedDays;

  const WeeklySummary({
    required this.weekStart,
    required this.income,
    required this.expense,
    required this.previousExpense,
    required this.days,
    required this.topCategories,
    required this.elapsedDays,
  });

  DateTime get weekEnd => weekStart.addDays(6);

  double get net => income - expense;

  bool get isEmpty => income == 0 && expense == 0;

  /// Averaged over the days lived so far — spreading a Monday's spending over
  /// seven days would make every week look thrifty until Friday.
  double get dailyAverage => elapsedDays == 0 ? 0 : expense / elapsedDays;

  double get expenseChange => expense - previousExpense;

  /// `null` when there is nothing to compare against: a jump from zero is not
  /// a percentage.
  double? get expenseChangePercent => previousExpense == 0
      ? null
      : (expense - previousExpense) / previousExpense * 100;
}

/// Turns a flat list of transactions into the week view.
///
/// Pure on purpose — the fetching lives in the providers below, so the bucketing
/// rules (which day, which week, what counts as elapsed) are unit-testable.
class WeeklySummaryRepository {
  final ReportsRepository _reports;
  const WeeklySummaryRepository(this._reports);

  /// How many categories the card lists.
  static const topCategoryCount = 3;

  /// Builds the summary for the week containing [weekStart].
  ///
  /// [transactions] is expected to cover that week *and* the one before it;
  /// anything else is ignored. [today] decides how much of the week has already
  /// happened.
  WeeklySummary summarise({
    required List<TransactionModel> transactions,
    required DateTime weekStart,
    required DateTime today,
  }) {
    final start = weekStart.weekStart;
    final previousStart = start.addDays(-7);
    final slotOfDay = <String, int>{
      for (var i = 0; i < 7; i++) _dayKey(start.addDays(i)): i,
    };

    final incomeByDay = List<double>.filled(7, 0);
    final expenseByDay = List<double>.filled(7, 0);
    final thisWeek = <TransactionModel>[];
    var previousExpense = 0.0;

    for (final tx in transactions) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final slot = slotOfDay[_dayKey(day)];
      if (slot == null) {
        // Outside the week: only last week's expenses matter, as the baseline.
        if (tx.txType == TransactionType.expense &&
            !day.isBefore(previousStart) &&
            day.isBefore(start)) {
          previousExpense += tx.amount;
        }
        continue;
      }
      thisWeek.add(tx);
      if (tx.txType == TransactionType.income) {
        incomeByDay[slot] += tx.amount;
      } else {
        expenseByDay[slot] += tx.amount;
      }
    }

    return WeeklySummary(
      weekStart: start,
      income: incomeByDay.fold<double>(0, (sum, v) => sum + v),
      expense: expenseByDay.fold<double>(0, (sum, v) => sum + v),
      previousExpense: previousExpense,
      days: [
        for (var i = 0; i < 7; i++)
          DailyTotal(
            date: start.addDays(i),
            income: incomeByDay[i],
            expense: expenseByDay[i],
          ),
      ],
      topCategories:
          _reports.spendingByCategory(thisWeek).take(topCategoryCount).toList(),
      elapsedDays: _elapsedDays(start, today),
    );
  }

  int _elapsedDays(DateTime start, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    if (day.isBefore(start)) return 0;
    for (var i = 0; i < 7; i++) {
      if (start.addDays(i).isSameDay(day)) return i + 1;
    }
    return 7;
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';
}

final weeklySummaryRepositoryProvider = Provider<WeeklySummaryRepository>(
  (ref) => WeeklySummaryRepository(ref.watch(reportsRepositoryProvider)),
);

/// The Monday of the week the reports screen is showing.
class SelectedWeekNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now().weekStart;

  void previousWeek() => state = state.addDays(-7);
  void nextWeek() => state = state.addDays(7);
  void set(DateTime day) => state = day.weekStart;
}

final selectedWeekProvider =
    NotifierProvider<SelectedWeekNotifier, DateTime>(SelectedWeekNotifier.new);

final weeklySummaryProvider = FutureProvider<WeeklySummary>((ref) async {
  final week = ref.watch(selectedWeekProvider);
  final repo = ref.watch(weeklySummaryRepositoryProvider);
  final now = DateTime.now();

  // A week can start in one month and end in the next, so this cannot ride on
  // the month-scoped transactionsProvider; the revision counter is what tells
  // it a transaction was written.
  ref.watch(transactionsRevisionProvider);

  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) {
    return repo.summarise(transactions: const [], weekStart: week, today: now);
  }
  final householdId = profile!.householdId!;
  final txRepo = ref.watch(transactionRepositoryProvider);

  // The previous week rides along in the same query so the week-over-week
  // delta costs no extra round trip.
  final from = week.addDays(-7);
  final to = week.addDays(6);
  final transactions = await fetchWithCache(
    ref: ref,
    key: 'tx_week_${householdId}_${from.isoDate}',
    fetch: () => txRepo.getTransactionRowsForDayRange(householdId, from, to),
    parse: TransactionModel.fromJson,
  );

  return repo.summarise(
    transactions: transactions,
    weekStart: week,
    today: now,
  );
});
