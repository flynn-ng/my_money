import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manage/features/reports/data/weekly_summary_repository.dart';
import 'package:money_manage/features/reports/presentation/widgets/weekly_day_bars.dart';

final _monday = DateTime(2026, 9, 7);

List<DailyTotal> _week({
  Map<int, double> expense = const {},
  Map<int, double> income = const {},
}) =>
    [
      for (var i = 0; i < 7; i++)
        DailyTotal(
          date: _monday.add(Duration(days: i)),
          income: income[i] ?? 0,
          expense: expense[i] ?? 0,
        ),
    ];

Future<void> _pump(
  WidgetTester tester,
  List<DailyTotal> days, {
  double width = 390,
  DateTime? today,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: WeeklyDayBars(
          days: days,
          today: today ?? DateTime(2026, 9, 10),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('labels every weekday, Monday first', (tester) async {
    await _pump(tester, _week());

    expect(find.text('T2'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);
  });

  testWidgets('writes each day\'s amount above its bar', (tester) async {
    await _pump(tester, _week(expense: {0: 458000, 2: 1200000}));

    expect(find.text('458k'), findsOneWidget);
    expect(find.text('1.2tr'), findsOneWidget);
  });

  testWidgets('a day with nothing gets no number', (tester) async {
    await _pump(tester, _week(expense: {0: 458000}));

    // Six quiet days, so exactly one label.
    expect(find.text('458k'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('income shows up on the chart, not just in the totals',
      (tester) async {
    await _pump(tester, _week(income: {2: 17000000}));

    expect(find.text('17.0tr'), findsOneWidget);
  });

  testWidgets('the number follows the taller bar of the day', (tester) async {
    await _pump(
      tester,
      _week(expense: {2: 45000}, income: {2: 17000000}),
    );

    // Income dwarfs the coffee that day, so it is the one worth naming.
    expect(find.text('17.0tr'), findsOneWidget);
    expect(find.text('45k'), findsNothing);
  });

  testWidgets('income and expense share one scale', (tester) async {
    await _pump(
      tester,
      _week(expense: {0: 1000000}, income: {2: 2000000}),
    );

    // Bars are the only fixed-height boxes in the strip; stubs are 4px.
    final bars = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.constraints?.maxHeight ?? double.infinity)
        .where((h) => h.isFinite && h > 4)
        .toList();
    expect(bars.length, 2);

    // The 2tr bar is the peak; the 1tr bar must come out near half of it.
    final tallest = bars.reduce((a, b) => a > b ? a : b);
    final other = bars.where((h) => h != tallest).reduce((a, b) => a > b ? a : b);
    expect(other / tallest, closeTo(0.5, 0.05));
  });

  testWidgets('an empty week draws stubs instead of dividing by zero',
      (tester) async {
    await _pump(tester, _week());

    expect(tester.takeException(), isNull);
    expect(find.text('T5'), findsOneWidget);
  });

  testWidgets('survives a narrow phone with both series', (tester) async {
    await _pump(
      tester,
      _week(expense: {0: 458000, 1: 176000, 3: 20000}, income: {2: 17000000}),
      width: 320,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('17.0tr'), findsOneWidget);
  });

  testWidgets('renders in dark mode', (tester) async {
    await _pump(
      tester,
      _week(expense: {0: 458000}, income: {2: 17000000}),
      theme: ThemeData.dark(),
    );

    expect(find.text('458k'), findsOneWidget);
  });
}
