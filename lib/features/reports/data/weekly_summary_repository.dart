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

  /// Every expense category of the week, largest first. The card shows a few
  /// and expands to the rest on demand, so nothing is dropped here.
  final List<CategorySpending> categories;

  /// Categories the totals above are restricted to; empty means the whole week.
  /// [categories] always covers the unfiltered week, so the list the user picks
  /// from does not collapse to what they picked.
  final Set<String> categoryFilters;

  /// Days of the week that have actually happened: 7 for a finished week,
  /// 1-7 for the running one, 0 for a week that has not started yet.
  final int elapsedDays;

  const WeeklySummary({
    required this.weekStart,
    required this.income,
    required this.expense,
    required this.previousExpense,
    required this.days,
    required this.categories,
    required this.elapsedDays,
    this.categoryFilters = const {},
  });

  bool get isFiltered => categoryFilters.isNotEmpty;

  /// The selected categories, in the same order as [categories], skipping any
  /// that had no spending this week.
  List<CategorySpending> get filteredCategories => [
        for (final category in categories)
          if (categoryFilters.contains(category.categoryId)) category,
      ];

  bool isSelected(String categoryId) => categoryFilters.contains(categoryId);

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

  /// How many categories the card lists before "show all".
  static const topCategoryCount = 3;

  /// Builds the summary for the week containing [weekStart].
  ///
  /// [transactions] is expected to cover that week *and* the one before it;
  /// anything else is ignored. [today] decides how much of the week has already
  /// happened.
  ///
  /// [categoryIds] narrows every total — the week's spend, the day bars, the
  /// income and the last-week baseline — to those categories, so the comparison
  /// stays like-for-like. Empty means the whole week. The category ranking
  /// itself is always computed from the whole week.
  WeeklySummary summarise({
    required List<TransactionModel> transactions,
    required DateTime weekStart,
    required DateTime today,
    Set<String> categoryIds = const {},
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

    bool matchesFilter(TransactionModel tx) =>
        categoryIds.isEmpty || categoryIds.contains(tx.categoryId);

    for (final tx in transactions) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final slot = slotOfDay[_dayKey(day)];
      if (slot == null) {
        // Outside the week: only last week's expenses matter, as the baseline.
        if (tx.txType == TransactionType.expense &&
            matchesFilter(tx) &&
            !day.isBefore(previousStart) &&
            day.isBefore(start)) {
          previousExpense += tx.amount;
        }
        continue;
      }
      // The ranking is built from the whole week even while a filter is on.
      thisWeek.add(tx);
      if (!matchesFilter(tx)) continue;
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
      categories: _reports.spendingByCategory(thisWeek),
      elapsedDays: _elapsedDays(start, today),
      categoryFilters: categoryIds,
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

/// Categories the week card is narrowed to. Empty means the whole week.
class WeekCategoryFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // A category that was busy this week may not exist in the next one, and a
    // card silently showing zeros reads as a bug — so moving weeks clears it.
    ref.listen(selectedWeekProvider, (_, _) => state = const {});
    return const {};
  }

  void toggle(String categoryId) => state = {
        for (final id in state)
          if (id != categoryId) id,
        if (!state.contains(categoryId)) categoryId,
      };

  void clear() => state = const {};
}

final weekCategoryFilterProvider =
    NotifierProvider<WeekCategoryFilterNotifier, Set<String>>(
        WeekCategoryFilterNotifier.new);

/// The two weeks of transactions the card is built from: the selected week and
/// the one before it, which is the baseline for the delta.
///
/// Deliberately unaware of the category filter — filtering is arithmetic over
/// rows already in memory, and rerunning this for a checkbox tap would put a
/// network round trip (and a loading spinner) behind every tick.
final weeklyTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final week = ref.watch(selectedWeekProvider);

  // A week can start in one month and end in the next, so this cannot ride on
  // the month-scoped transactionsProvider; the revision counter is what tells
  // it a transaction was written.
  ref.watch(transactionsRevisionProvider);

  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return const [];

  final householdId = profile!.householdId!;
  final txRepo = ref.watch(transactionRepositoryProvider);

  // The previous week rides along in the same query so the week-over-week
  // delta costs no extra round trip.
  final from = week.addDays(-7);
  final to = week.addDays(6);
  return fetchWithCache(
    ref: ref,
    key: 'tx_week_${householdId}_${from.isoDate}',
    fetch: () => txRepo.getTransactionRowsForDayRange(householdId, from, to),
    parse: TransactionModel.fromJson,
  );
});

/// Synchronous on purpose: ticking a category remaps rows already held in
/// memory, so the card updates within the same frame instead of dropping to a
/// loading state and back.
final weeklySummaryProvider = Provider<AsyncValue<WeeklySummary>>((ref) {
  final week = ref.watch(selectedWeekProvider);
  final categoryIds = ref.watch(weekCategoryFilterProvider);
  final repo = ref.watch(weeklySummaryRepositoryProvider);

  return ref.watch(weeklyTransactionsProvider).whenData(
        (transactions) => repo.summarise(
          transactions: transactions,
          weekStart: week,
          today: DateTime.now(),
          categoryIds: categoryIds,
        ),
      );
});
