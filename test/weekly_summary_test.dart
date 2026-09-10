import 'package:flutter_test/flutter_test.dart';
import 'package:money_manage/core/extensions/datetime_ext.dart';
import 'package:money_manage/features/reports/data/reports_repository.dart';
import 'package:money_manage/features/reports/data/weekly_summary_repository.dart';
import 'package:money_manage/features/transactions/data/transaction_model.dart';

// 2026-09-07 is a Monday, so this week runs Mon 7 → Sun 13 September.
final _monday = DateTime(2026, 9, 7);

TransactionModel _tx({
  required double amount,
  required DateTime date,
  String type = 'expense',
  String categoryId = 'c1',
  String? categoryName,
  String? categoryIcon,
  String? categoryColor,
}) =>
    TransactionModel(
      id: '${date.toIso8601String()}-$amount-$type-$categoryId',
      householdId: 'h1',
      paidById: 'p1',
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
    );

void main() {
  final repo = WeeklySummaryRepository(ReportsRepository());

  WeeklySummary summarise(
    List<TransactionModel> transactions, {
    DateTime? weekStart,
    DateTime? today,
    Set<String> categoryIds = const {},
  }) =>
      repo.summarise(
        transactions: transactions,
        weekStart: weekStart ?? _monday,
        // A finished week unless a test says otherwise.
        today: today ?? DateTime(2026, 9, 20),
        categoryIds: categoryIds,
      );

  group('week boundaries', () {
    test('weekStart snaps back to Monday from any day of the week', () {
      expect(DateTime(2026, 9, 7).weekStart, DateTime(2026, 9, 7)); // Mon
      expect(DateTime(2026, 9, 10).weekStart, DateTime(2026, 9, 7)); // Thu
      expect(DateTime(2026, 9, 13).weekStart, DateTime(2026, 9, 7)); // Sun
      expect(DateTime(2026, 9, 14).weekStart, DateTime(2026, 9, 14)); // next Mon
    });

    test('weekStart keeps the time of day out of it', () {
      expect(DateTime(2026, 9, 10, 23, 45).weekStart, DateTime(2026, 9, 7));
    });

    test('addDays rolls over month and year ends', () {
      expect(DateTime(2026, 8, 31).addDays(1), DateTime(2026, 9, 1));
      expect(DateTime(2026, 12, 28).addDays(7), DateTime(2027, 1, 4));
      expect(DateTime(2026, 9, 7).addDays(-7), DateTime(2026, 8, 31));
    });

    test('a summary always covers seven days, Monday first', () {
      final summary = summarise([]);
      expect(summary.days.length, 7);
      expect(summary.days.first.date, DateTime(2026, 9, 7));
      expect(summary.days.last.date, DateTime(2026, 9, 13));
      expect(summary.weekEnd, DateTime(2026, 9, 13));
    });

    test('a mid-week date is normalised to that week', () {
      final summary = summarise([], weekStart: DateTime(2026, 9, 10));
      expect(summary.weekStart, DateTime(2026, 9, 7));
    });

    test('a week straddling a month boundary keeps both months', () {
      final summary = summarise(
        [
          _tx(amount: 100, date: DateTime(2026, 8, 31)),
          _tx(amount: 50, date: DateTime(2026, 9, 1)),
        ],
        weekStart: DateTime(2026, 8, 31),
      );
      expect(summary.expense, 150);
      expect(summary.days[0].expense, 100);
      expect(summary.days[1].expense, 50);
    });
  });

  group('bucketing', () {
    test('splits income and expense per day', () {
      final summary = summarise([
        _tx(amount: 30000, date: DateTime(2026, 9, 7)),
        _tx(amount: 20000, date: DateTime(2026, 9, 7)),
        _tx(amount: 5000000, date: DateTime(2026, 9, 9), type: 'income'),
        _tx(amount: 70000, date: DateTime(2026, 9, 13)),
      ]);

      expect(summary.days[0].expense, 50000);
      expect(summary.days[2].income, 5000000);
      expect(summary.days[2].net, 5000000);
      expect(summary.days[6].expense, 70000);
      expect(summary.expense, 120000);
      expect(summary.income, 5000000);
      expect(summary.net, 4880000);
    });

    test('ignores the time of day when picking the bucket', () {
      final summary = summarise([
        _tx(amount: 1000, date: DateTime(2026, 9, 9, 23, 59)),
      ]);
      expect(summary.days[2].expense, 1000);
    });

    test('a week with no transactions is empty, not zero-filled noise', () {
      final summary = summarise([]);
      expect(summary.isEmpty, isTrue);
      expect(summary.days.every((d) => d.income == 0 && d.expense == 0), isTrue);
      expect(summary.categories, isEmpty);
    });

    test('income alone does not count as an empty week', () {
      final summary = summarise([
        _tx(amount: 100, date: DateTime(2026, 9, 8), type: 'income'),
      ]);
      expect(summary.isEmpty, isFalse);
    });
  });

  group('previous week baseline', () {
    test('last week is counted separately from this one', () {
      final summary = summarise([
        _tx(amount: 200000, date: DateTime(2026, 9, 8)),
        _tx(amount: 100000, date: DateTime(2026, 9, 1)), // last week
        _tx(amount: 60000, date: DateTime(2026, 8, 31)), // last week, Monday
      ]);

      expect(summary.expense, 200000);
      expect(summary.previousExpense, 160000);
      expect(summary.expenseChange, 40000);
      expect(summary.expenseChangePercent, closeTo(25, 0.001));
    });

    test('income from last week is not a spending baseline', () {
      final summary = summarise([
        _tx(amount: 9000000, date: DateTime(2026, 9, 2), type: 'income'),
      ]);
      expect(summary.previousExpense, 0);
    });

    test('anything older than last week is dropped', () {
      final summary = summarise([
        _tx(amount: 500000, date: DateTime(2026, 8, 30)), // two weeks back
      ]);
      expect(summary.expense, 0);
      expect(summary.previousExpense, 0);
    });

    test('transactions after the week are dropped', () {
      final summary = summarise([
        _tx(amount: 500000, date: DateTime(2026, 9, 14)),
      ]);
      expect(summary.expense, 0);
      expect(summary.previousExpense, 0);
    });

    test('no comparison when last week had no spending', () {
      final summary = summarise([
        _tx(amount: 200000, date: DateTime(2026, 9, 8)),
      ]);
      expect(summary.expenseChangePercent, isNull);
    });

    test('spending less than last week reads as a negative change', () {
      final summary = summarise([
        _tx(amount: 50000, date: DateTime(2026, 9, 8)),
        _tx(amount: 100000, date: DateTime(2026, 9, 1)),
      ]);
      expect(summary.expenseChange, -50000);
      expect(summary.expenseChangePercent, closeTo(-50, 0.001));
    });
  });

  group('elapsed days and daily average', () {
    test('a finished week counts all seven days', () {
      final summary = summarise(
        [_tx(amount: 700000, date: DateTime(2026, 9, 8))],
        today: DateTime(2026, 9, 30),
      );
      expect(summary.elapsedDays, 7);
      expect(summary.dailyAverage, 100000);
    });

    test('the running week only counts the days lived so far', () {
      final summary = summarise(
        [_tx(amount: 300000, date: DateTime(2026, 9, 8))],
        today: DateTime(2026, 9, 9, 14, 30), // Wednesday
      );
      expect(summary.elapsedDays, 3);
      expect(summary.dailyAverage, 100000);
    });

    test('Monday of the running week counts as one day', () {
      final summary = summarise(
        [_tx(amount: 45000, date: DateTime(2026, 9, 7))],
        today: DateTime(2026, 9, 7, 8),
      );
      expect(summary.elapsedDays, 1);
      expect(summary.dailyAverage, 45000);
    });

    test('the last day of the week counts as seven', () {
      final summary = summarise([], today: DateTime(2026, 9, 13));
      expect(summary.elapsedDays, 7);
    });

    test('a week that has not started yet averages nothing', () {
      final summary = summarise([], today: DateTime(2026, 9, 1));
      expect(summary.elapsedDays, 0);
      expect(summary.dailyAverage, 0);
    });
  });

  group('top categories', () {
    List<TransactionModel> spread() => [
          _tx(
              amount: 100,
              date: DateTime(2026, 9, 7),
              categoryId: 'food',
              categoryName: 'Ăn uống',
              categoryIcon: '🍜',
              categoryColor: '#DC2626'),
          _tx(
              amount: 500,
              date: DateTime(2026, 9, 8),
              categoryId: 'food',
              categoryName: 'Ăn uống'),
          _tx(
              amount: 400,
              date: DateTime(2026, 9, 9),
              categoryId: 'ride',
              categoryName: 'Đi lại'),
          _tx(
              amount: 300,
              date: DateTime(2026, 9, 10),
              categoryId: 'fun',
              categoryName: 'Giải trí'),
          _tx(
              amount: 200,
              date: DateTime(2026, 9, 11),
              categoryId: 'home',
              categoryName: 'Nhà cửa'),
        ];

    test('ranks every category by spend, largest first', () {
      final summary = summarise(spread());

      // All of them: the card decides how many to show, not the summary.
      expect(summary.categories.length, 4);
      expect(summary.categories.map((c) => c.categoryName).toList(),
          ['Ăn uống', 'Đi lại', 'Giải trí', 'Nhà cửa']);
      expect(summary.categories.first.amount, 600);
      expect(summary.categories.first.categoryIcon, '🍜');
    });

    test('only this week feeds the ranking', () {
      final summary = summarise([
        ...spread(),
        _tx(
            amount: 9999,
            date: DateTime(2026, 9, 1),
            categoryId: 'old',
            categoryName: 'Tuần trước'),
      ]);

      expect(summary.categories.map((c) => c.categoryName),
          isNot(contains('Tuần trước')));
    });

    test('income is never ranked as spending', () {
      final summary = summarise([
        _tx(
            amount: 9000000,
            date: DateTime(2026, 9, 8),
            type: 'income',
            categoryId: 'salary',
            categoryName: 'Lương'),
        ...spread(),
      ]);

      expect(summary.income, 9000000);
      expect(summary.categories.map((c) => c.categoryName),
          isNot(contains('Lương')));
    });

    group('category filter', () {
      test('narrows the week total to the chosen category', () {
        final summary = summarise(spread(), categoryIds: {'food'});

        expect(summary.expense, 600); // 100 + 500, not the 1500 of the week
      });

      test('keeps the full ranking so the filter can be changed or cleared', () {
        final summary = summarise(spread(), categoryIds: {'food'});

        expect(summary.categories.length, 4);
        expect(summary.categoryFilters, {'food'});
        expect(summary.isFiltered, isTrue);
        expect(summary.isSelected('food'), isTrue);
        expect(summary.isSelected('ride'), isFalse);
        expect(summary.filteredCategories.single.categoryName, 'Ăn uống');
      });

      test('several categories add up together', () {
        final summary = summarise(spread(), categoryIds: {'food', 'ride'});

        expect(summary.expense, 1000); // 600 food + 400 ride
        expect(summary.days[2].expense, 400); // the ride day now counts
        expect(summary.filteredCategories.map((c) => c.categoryName).toList(),
            ['Ăn uống', 'Đi lại']);
      });

      test('selecting every category matches the unfiltered week', () {
        final all = {'food', 'ride', 'fun', 'home'};
        final summary = summarise(spread(), categoryIds: all);

        expect(summary.expense, summarise(spread()).expense);
      });

      test('narrows the day bars too', () {
        final summary = summarise(spread(), categoryIds: {'food'});

        // Mon 100 and Tue 500 are the food days; the rest belong to others.
        expect(summary.days[0].expense, 100);
        expect(summary.days[1].expense, 500);
        expect(summary.days[2].expense, 0);
        expect(summary.days[3].expense, 0);
      });

      test('compares against the same category last week, not the whole week',
          () {
        final transactions = [
          ...spread(),
          _tx(
              amount: 250,
              date: DateTime(2026, 9, 3),
              categoryId: 'food',
              categoryName: 'Ăn uống'),
          _tx(
              amount: 9999,
              date: DateTime(2026, 9, 4),
              categoryId: 'ride',
              categoryName: 'Đi lại'),
        ];

        expect(summarise(transactions, categoryIds: {'food'}).previousExpense, 250);
        expect(summarise(transactions).previousExpense, 10249);
      });

      test('a category with nothing this week reports zero, not the week total',
          () {
        final summary = summarise(spread(), categoryIds: {'nothing-here'});

        expect(summary.expense, 0);
        expect(summary.isEmpty, isTrue);
        // Still listable, so the user can get back out of the filter.
        expect(summary.categories, isNotEmpty);
        expect(summary.isFiltered, isTrue);
        // Nothing to name in the bar, but the selection still stands.
        expect(summary.filteredCategories, isEmpty);
        expect(summary.categoryFilters, {'nothing-here'});
      });

      test('the transaction list follows the same filter', () {
        final list = repo.transactionsForWeek(
          transactions: spread(),
          weekStart: _monday,
          categoryIds: {'food'},
        );

        expect(list.length, 2);
        expect(list.every((tx) => tx.categoryId == 'food'), isTrue);
      });

      test('no filter leaves every total untouched', () {
        final summary = summarise(spread());

        expect(summary.expense, 1500);
        expect(summary.categoryFilters, isEmpty);
        expect(summary.isFiltered, isFalse);
        expect(summary.filteredCategories, isEmpty);
      });
    });
  });

  group('transactions behind the numbers', () {
    List<TransactionModel> around() => [
          _tx(amount: 100, date: DateTime(2026, 9, 7)), // Monday
          _tx(amount: 9000000, date: DateTime(2026, 9, 9), type: 'income'),
          _tx(amount: 300, date: DateTime(2026, 9, 13)), // Sunday
          _tx(amount: 500, date: DateTime(2026, 9, 6)), // last week
          _tx(amount: 700, date: DateTime(2026, 9, 14)), // next week
        ];

    test('keeps only the week, income and expense alike', () {
      final list = repo.transactionsForWeek(
        transactions: around(),
        weekStart: _monday,
      );

      expect(list.length, 3);
      expect(list.map((tx) => tx.amount).toSet(), {100, 9000000, 300});
    });

    test('newest first, matching the transaction list elsewhere', () {
      final list = repo.transactionsForWeek(
        transactions: around(),
        weekStart: _monday,
      );

      expect(list.map((tx) => tx.date).toList(), [
        DateTime(2026, 9, 13),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 7),
      ]);
    });

    test('same-day rows fall back to creation time, newest first', () {
      final earlier = TransactionModel(
        id: 'earlier',
        householdId: 'h1',
        paidById: 'p1',
        categoryId: 'c1',
        type: 'expense',
        amount: 1,
        date: DateTime(2026, 9, 9),
        createdAt: DateTime(2026, 9, 9, 8),
      );
      final later = TransactionModel(
        id: 'later',
        householdId: 'h1',
        paidById: 'p1',
        categoryId: 'c1',
        type: 'expense',
        amount: 2,
        date: DateTime(2026, 9, 9),
        createdAt: DateTime(2026, 9, 9, 20),
      );

      final list = repo.transactionsForWeek(
        transactions: [earlier, later],
        weekStart: _monday,
      );

      expect(list.map((tx) => tx.id).toList(), ['later', 'earlier']);
    });

    test('a mid-week date still resolves to its Monday', () {
      final list = repo.transactionsForWeek(
        transactions: around(),
        weekStart: DateTime(2026, 9, 10),
      );

      expect(list.length, 3);
    });
  });
}
