import 'package:flutter_test/flutter_test.dart';
import 'package:money_manage/features/reports/data/csv_export_service.dart';
import 'package:money_manage/features/transactions/data/transaction_model.dart';

TransactionModel _tx({
  required String id,
  required String type,
  required double amount,
  required DateTime date,
  DateTime? createdAt,
  String? categoryName,
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
      notes: notes,
      createdAt: createdAt ?? DateTime(2026, 8, 1),
      categoryName: categoryName,
      paidByName: paidByName,
    );

void main() {
  const service = CsvExportService();

  List<String> lines(String csv) =>
      csv.split('\r\n').where((l) => l.isNotEmpty).toList();

  test('writes a header row even with no transactions', () {
    final csv = service.buildMonthlyCsv([]);
    expect(lines(csv), ['Ngày,Loại,Danh mục,Số tiền,Ghi chú,Người chi']);
    expect(csv.endsWith('\r\n'), isTrue);
  });

  test('writes one row per transaction, oldest first', () {
    final csv = service.buildMonthlyCsv([
      _tx(
        id: '2',
        type: 'income',
        amount: 15000000,
        date: DateTime(2026, 8, 20),
        categoryName: 'Lương',
        paidByName: 'Phong',
      ),
      _tx(
        id: '1',
        type: 'expense',
        amount: 45000,
        date: DateTime(2026, 8, 3),
        categoryName: 'Ăn uống',
        notes: 'Cà phê',
        paidByName: 'Linh',
      ),
    ]);

    expect(lines(csv), [
      'Ngày,Loại,Danh mục,Số tiền,Ghi chú,Người chi',
      '2026-08-03,Chi tiêu,Ăn uống,45000,Cà phê,Linh',
      '2026-08-20,Thu nhập,Lương,15000000,,Phong',
    ]);
  });

  test('breaks same-day ties by creation time', () {
    final csv = service.buildMonthlyCsv([
      _tx(
        id: 'later',
        type: 'expense',
        amount: 2,
        date: DateTime(2026, 8, 5),
        createdAt: DateTime(2026, 8, 5, 18),
        notes: 'second',
      ),
      _tx(
        id: 'earlier',
        type: 'expense',
        amount: 1,
        date: DateTime(2026, 8, 5),
        createdAt: DateTime(2026, 8, 5, 9),
        notes: 'first',
      ),
    ]);

    expect(lines(csv)[1], contains('first'));
    expect(lines(csv)[2], contains('second'));
  });

  test('quotes fields containing commas, quotes or newlines', () {
    final csv = service.buildMonthlyCsv([
      _tx(
        id: '1',
        type: 'expense',
        amount: 1000,
        date: DateTime(2026, 8, 1),
        categoryName: 'Ăn uống, đồ ngọt',
        notes: 'Trà sữa "size L"\nmua 2 ly',
      ),
    ]);

    expect(
      lines(csv).skip(1).join('\r\n'),
      '2026-08-01,Chi tiêu,"Ăn uống, đồ ngọt",1000,'
      '"Trà sữa ""size L""\nmua 2 ly",',
    );
  });

  test('formats amounts as plain numbers', () {
    final csv = service.buildMonthlyCsv([
      _tx(id: '1', type: 'expense', amount: 1234567, date: DateTime(2026, 8, 1)),
      _tx(id: '2', type: 'expense', amount: 12.5, date: DateTime(2026, 8, 2)),
    ]);

    expect(lines(csv)[1].split(',')[3], '1234567');
    expect(lines(csv)[2].split(',')[3], '12.50');
  });

  test('falls back to a placeholder category when the join is missing', () {
    final csv = service.buildMonthlyCsv([
      _tx(id: '1', type: 'expense', amount: 100, date: DateTime(2026, 8, 1)),
    ]);

    expect(lines(csv)[1], '2026-08-01,Chi tiêu,Khác,100,,');
  });

  test('file name is derived from the exported month', () {
    expect(service.fileNameFor(DateTime(2026, 8, 1)), 'my-moneyyy-2026-08.csv');
    expect(service.fileNameFor(DateTime(2026, 12, 1)), 'my-moneyyy-2026-12.csv');
  });
}
