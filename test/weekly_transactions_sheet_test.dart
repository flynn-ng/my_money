import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_manage/features/reports/presentation/widgets/weekly_transactions_sheet.dart';
import 'package:money_manage/features/transactions/data/transaction_model.dart';

final _monday = DateTime(2026, 9, 7);

TransactionModel _tx({
  required String id,
  required double amount,
  required DateTime date,
  String type = 'expense',
  String? categoryName,
  String? categoryIcon,
  String? notes,
  String? paidByName,
}) =>
    TransactionModel(
      id: id,
      householdId: 'h1',
      paidById: 'p1',
      categoryId: 'c1',
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      notes: notes,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      paidByName: paidByName,
    );

Future<void> _pump(
  WidgetTester tester,
  List<TransactionModel> transactions, {
  double width = 390,
  bool isFiltered = false,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      body: WeeklyTransactionsList(
        transactions: transactions,
        weekStart: _monday,
        isFiltered: isFiltered,
      ),
    ),
  ));
}

void main() {
  // The sheet formats dates through DateFormat('d MMM', 'vi'), which needs its
  // locale data loaded — main.dart does this at startup.
  setUpAll(() => initializeDateFormatting('vi', null));

  final salary = _tx(
    id: 'salary',
    amount: 17000000,
    date: DateTime(2026, 9, 9),
    type: 'income',
    categoryName: 'Lương',
    categoryIcon: '💰',
    paidByName: 'Phong',
  );
  final coffee = _tx(
    id: 'coffee',
    amount: 188000,
    date: DateTime(2026, 9, 7),
    categoryName: 'Cafe',
    categoryIcon: '☕',
    notes: 'Highlands',
  );

  testWidgets('signs income positive and expense negative', (tester) async {
    await _pump(tester, [salary, coffee]);

    // Each amount appears twice: once in its day header's net, once on the row.
    expect(find.text('+17.0 triệu₫'), findsWidgets);
    expect(find.text('-188k₫'), findsWidgets);
  });

  testWidgets('colours the two directions apart', (tester) async {
    await _pump(tester, [salary, coffee]);

    // Rows come after their day header in the tree, so .last is the row.
    Color rowColorOf(String text) =>
        tester.widget<Text>(find.text(text).last).style!.color!;

    expect(rowColorOf('+17.0 triệu₫'), isNot(rowColorOf('-188k₫')));
  });

  testWidgets('groups by day with the weekday label', (tester) async {
    await _pump(tester, [salary, coffee]);

    // 9 Sep 2026 is a Wednesday, 7 Sep a Monday.
    expect(find.textContaining('T4,'), findsOneWidget);
    expect(find.textContaining('T2,'), findsOneWidget);
  });

  testWidgets('totals income and expense at the top', (tester) async {
    await _pump(tester, [salary, coffee]);

    expect(find.text('Thu nhập'), findsOneWidget);
    expect(find.text('Chi tiêu'), findsOneWidget);
  });

  testWidgets('notes win over the payer as the subtitle', (tester) async {
    await _pump(tester, [salary, coffee]);

    expect(find.text('Highlands'), findsOneWidget); // has notes
    expect(find.text('Phong'), findsOneWidget); // falls back to the payer
  });

  testWidgets('an empty week says so', (tester) async {
    await _pump(tester, const []);

    expect(find.text('Chưa có giao dịch tuần này'), findsOneWidget);
  });

  testWidgets('says when a category filter is narrowing the list',
      (tester) async {
    await _pump(tester, [coffee], isFiltered: true);

    expect(find.textContaining('Chỉ tính mục đã chọn'), findsOneWidget);
  });

  testWidgets('survives a narrow phone and dark mode', (tester) async {
    await _pump(tester, [salary, coffee], width: 320);
    expect(find.text('Cafe'), findsOneWidget);

    await _pump(tester, [salary, coffee], theme: ThemeData.dark());
    expect(find.text('Cafe'), findsOneWidget);
  });
}
