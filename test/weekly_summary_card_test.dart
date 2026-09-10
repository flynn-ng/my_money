import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manage/features/reports/data/reports_repository.dart';
import 'package:money_manage/features/reports/data/weekly_summary_repository.dart';
import 'package:money_manage/features/reports/presentation/widgets/weekly_summary_card.dart';

final _monday = DateTime(2026, 9, 7);

WeeklySummary _summary({
  double income = 18000000,
  double expense = 2400000,
  double previousExpense = 2000000,
  List<CategorySpending> categories = const [],
  List<CategorySpending> incomeCategories = const [],
  int elapsedDays = 7,
  Set<String> categoryFilters = const {},
}) =>
    WeeklySummary(
      weekStart: _monday,
      income: income,
      expense: expense,
      previousExpense: previousExpense,
      days: [
        for (var i = 0; i < 7; i++)
          DailyTotal(
            date: DateTime(2026, 9, 7 + i),
            income: i == 2 ? income : 0,
            expense: expense / 7 * (i + 1) / 4,
          ),
      ],
      categories: categories,
      incomeCategories: incomeCategories,
      elapsedDays: elapsedDays,
      categoryFilters: categoryFilters,
    );

const _categories = [
  CategorySpending(
      categoryId: 'food',
      categoryName: 'Ăn uống',
      categoryIcon: '🍜',
      categoryColor: '#DC2626',
      amount: 1200000),
  CategorySpending(
      categoryId: 'ride',
      categoryName: 'Đi lại',
      categoryIcon: '🛵',
      categoryColor: '#2563EB',
      amount: 800000),
  CategorySpending(
      categoryId: 'fun',
      categoryName: 'Giải trí',
      categoryIcon: '🎬',
      categoryColor: '#7C3AED',
      amount: 400000),
];

/// Pumps the card at a given screen width. Any overflow or layout assertion
/// fails the test on its own — that is most of what these are here for.
Future<void> _pump(
  WidgetTester tester,
  WeeklySummary summary, {
  double width = 390,
  ThemeData? theme,
  void Function(String categoryId)? onCategoryTap,
  VoidCallback? onClearFilters,
  VoidCallback? onShowTransactions,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: WeeklySummaryCard(
          summary: summary,
          onCategoryTap: onCategoryTap,
          onClearFilters: onClearFilters,
          onShowTransactions: onShowTransactions,
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('lays out spend, week bars, metrics and categories', (tester) async {
    await _pump(tester, _summary(categories: _categories));

    expect(find.text('Đã chi'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Giải trí'), findsOneWidget);
    // Seven weekday labels, Monday first.
    expect(find.text('T2'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);
    expect(find.text('TB mỗi ngày'), findsOneWidget);
  });

  testWidgets('shows the week-over-week delta when last week had spending',
      (tester) async {
    await _pump(tester, _summary(expense: 2400000, previousExpense: 2000000));

    expect(find.text('20%'), findsOneWidget);
    expect(find.text('so với tuần trước'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('drops the delta when there is nothing to compare against',
      (tester) async {
    await _pump(tester, _summary(previousExpense: 0));

    expect(find.text('Tuần trước không có chi tiêu'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });

  testWidgets('spending less than last week points down', (tester) async {
    await _pump(tester, _summary(expense: 1000000, previousExpense: 2000000));

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('an empty week says so instead of drawing a flat chart',
      (tester) async {
    await _pump(tester, _summary(income: 0, expense: 0, previousExpense: 0));

    expect(find.text('Chưa có giao dịch tuần này'), findsOneWidget);
    expect(find.text('Đã chi'), findsNothing);
  });

  testWidgets('survives a narrow phone', (tester) async {
    await _pump(tester, _summary(categories: _categories), width: 320);

    expect(find.text('Đã chi'), findsOneWidget);
  });

  testWidgets('renders in dark mode', (tester) async {
    await _pump(
      tester,
      _summary(categories: _categories),
      theme: ThemeData.dark(),
    );

    expect(find.text('Đã chi'), findsOneWidget);
  });

  group('transactions link', () {
    testWidgets('only appears when there is somewhere to go', (tester) async {
      await _pump(tester, _summary(categories: _categories));

      expect(find.text('Xem giao dịch trong tuần'), findsNothing);
    });

    testWidgets('opens the list of transactions behind the numbers',
        (tester) async {
      var opened = 0;
      await _pump(
        tester,
        _summary(categories: _categories),
        onShowTransactions: () => opened++,
      );

      await tester.tap(find.text('Xem giao dịch trong tuần'));
      await tester.pumpAndSettle();

      expect(opened, 1);
    });
  });

  group('income categories', () {
    const salary = CategorySpending(
        categoryId: 'salary',
        categoryName: 'Lương',
        categoryIcon: '💰',
        categoryColor: '#16A34A',
        amount: 17000000);

    testWidgets('are hidden until the list is opened', (tester) async {
      await _pump(
        tester,
        _summary(categories: _categories, incomeCategories: const [salary]),
      );

      expect(find.text('Lương'), findsNothing);
      // Three expense categories plus the income one.
      expect(find.text('Xem tất cả (4)'), findsOneWidget);

      await tester.tap(find.text('Xem tất cả (4)'));
      await tester.pumpAndSettle();

      expect(find.text('Lương'), findsOneWidget);
    });

    testWidgets('are signed and coloured as money in', (tester) async {
      await _pump(
        tester,
        _summary(categories: _categories, incomeCategories: const [salary]),
      );
      await tester.tap(find.text('Xem tất cả (4)'));
      await tester.pumpAndSettle();

      final amount = tester.widget<Text>(find.text('+17.0 triệu₫'));
      final expenseAmount = tester.widget<Text>(find.text('1.2 triệu₫'));
      expect(amount.style!.color, isNot(expenseAmount.style!.color));
    });

    testWidgets('can be selected like an expense category', (tester) async {
      final tapped = <String>[];
      await _pump(
        tester,
        _summary(categories: _categories, incomeCategories: const [salary]),
        onCategoryTap: tapped.add,
      );
      await tester.tap(find.text('Xem tất cả (4)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lương'));
      await tester.pumpAndSettle();

      expect(tapped, ['salary']);
    });

    testWidgets('a week with income but no spending shows them straight away',
        (tester) async {
      await _pump(
        tester,
        _summary(
          expense: 0,
          previousExpense: 0,
          categories: const [],
          incomeCategories: const [salary],
        ),
      );

      // Nothing to rank, so nothing to hide behind an expand button.
      expect(find.text('Lương'), findsOneWidget);
      expect(find.textContaining('Xem tất cả'), findsNothing);
      expect(find.text('Chi nhiều nhất'), findsNothing);
      expect(find.text('Thu nhập'), findsWidgets); // header + the metric above
    });
  });

  group('category list', () {
    const fourth = CategorySpending(
        categoryId: 'home',
        categoryName: 'Nhà cửa',
        categoryIcon: '🏠',
        categoryColor: '#16A34A',
        amount: 200000);

    testWidgets('shows only the top three until asked for all', (tester) async {
      await _pump(tester, _summary(categories: [..._categories, fourth]));

      expect(find.text('Nhà cửa'), findsNothing);
      expect(find.text('Xem tất cả (4)'), findsOneWidget);

      await tester.tap(find.text('Xem tất cả (4)'));
      await tester.pumpAndSettle();

      expect(find.text('Nhà cửa'), findsOneWidget);
      expect(find.text('Thu gọn'), findsOneWidget);
      expect(find.text('Tất cả danh mục'), findsOneWidget);
    });

    testWidgets('collapses again', (tester) async {
      await _pump(tester, _summary(categories: [..._categories, fourth]));

      await tester.tap(find.text('Xem tất cả (4)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu gọn'));
      await tester.pumpAndSettle();

      expect(find.text('Nhà cửa'), findsNothing);
    });

    testWidgets('no expand button when everything already fits',
        (tester) async {
      await _pump(tester, _summary(categories: _categories));

      expect(find.textContaining('Xem tất cả'), findsNothing);
    });

    testWidgets('tapping a category reports it', (tester) async {
      final tapped = <String>[];
      await _pump(
        tester,
        _summary(categories: _categories),
        onCategoryTap: tapped.add,
      );

      await tester.tap(find.text('Đi lại'));
      await tester.pumpAndSettle();

      expect(tapped, ['ride']);
    });

    testWidgets('rows carry a checkbox only when they can be selected',
        (tester) async {
      await _pump(tester, _summary(categories: _categories));
      expect(find.byType(Checkbox), findsNothing);

      await _pump(
        tester,
        _summary(categories: _categories),
        onCategoryTap: (_) {},
      );
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('the checkbox reflects what is selected', (tester) async {
      await _pump(
        tester,
        _summary(categories: _categories, categoryFilters: {'food', 'fun'}),
        onCategoryTap: (_) {},
      );

      final boxes = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((c) => c.value)
          .toList();
      expect(boxes, [true, false, true]); // Ăn uống, Đi lại, Giải trí
    });

    testWidgets('ticking the box reports the category', (tester) async {
      final tapped = <String>[];
      await _pump(
        tester,
        _summary(categories: _categories),
        onCategoryTap: tapped.add,
      );

      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      expect(tapped, ['fun']);
    });

    testWidgets('one selected category is named in the filter bar',
        (tester) async {
      await _pump(
        tester,
        _summary(categories: _categories, categoryFilters: {'food'}),
        onCategoryTap: (_) {},
      );

      expect(find.text('🍜 Ăn uống'), findsOneWidget);
      expect(find.text('Chỉ tính mục đã chọn'), findsOneWidget);
    });

    testWidgets('several selected categories are counted, and clear together',
        (tester) async {
      var cleared = 0;
      await _pump(
        tester,
        _summary(categories: _categories, categoryFilters: {'food', 'ride'}),
        onCategoryTap: (_) {},
        onClearFilters: () => cleared++,
      );

      expect(find.text('2 danh mục'), findsOneWidget);

      await tester.tap(find.text('Bỏ chọn'));
      await tester.pumpAndSettle();

      expect(cleared, 1);
    });

    testWidgets('an empty category filter still lists the categories',
        (tester) async {
      await _pump(
        tester,
        _summary(
          income: 0,
          expense: 0,
          previousExpense: 0,
          categories: _categories,
          categoryFilters: {'food'},
        ),
      );

      // The "no transactions" placeholder would strand the user in the filter.
      expect(find.text('Chưa có giao dịch tuần này'), findsNothing);
      expect(find.text('Ăn uống'), findsWidgets);
    });
  });
}
