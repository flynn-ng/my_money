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
  List<CategorySpending> topCategories = const [],
  int elapsedDays = 7,
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
      topCategories: topCategories,
      elapsedDays: elapsedDays,
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
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      body: SingleChildScrollView(child: WeeklySummaryCard(summary: summary)),
    ),
  ));
}

void main() {
  testWidgets('lays out spend, week bars, metrics and categories', (tester) async {
    await _pump(tester, _summary(topCategories: _categories));

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
    await _pump(tester, _summary(topCategories: _categories), width: 320);

    expect(find.text('Đã chi'), findsOneWidget);
  });

  testWidgets('renders in dark mode', (tester) async {
    await _pump(
      tester,
      _summary(topCategories: _categories),
      theme: ThemeData.dark(),
    );

    expect(find.text('Đã chi'), findsOneWidget);
  });
}
