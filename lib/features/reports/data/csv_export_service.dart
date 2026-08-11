import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../transactions/data/transaction_model.dart';
import '_csv_file_stub.dart' if (dart.library.js_interop) '_csv_file_web.dart';

/// Builds a spreadsheet-friendly CSV of one month of transactions.
///
/// The output is a single flat table (RFC 4180, CRLF line endings) so it can be
/// dropped straight into Excel / Google Sheets and pivoted.
class CsvExportService {
  const CsvExportService();

  static const _eol = '\r\n';

  /// Byte-order mark — without it Excel opens UTF-8 CSVs as Latin-1 and
  /// mangles Vietnamese category names.
  static const _bom = '\u{FEFF}';

  String fileNameFor(DateTime month) =>
      'my-moneyyy-${month.year}-${month.month.toString().padLeft(2, '0')}.csv';

  String buildMonthlyCsv(List<TransactionModel> transactions) {
    final sorted = [...transactions]..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
    });

    final rows = <List<String>>[
      [
        S.csvDate,
        S.csvType,
        S.csvCategory,
        S.csvAmount,
        S.csvNotes,
        S.csvPaidBy,
      ],
      for (final tx in sorted)
        [
          tx.date.isoDate,
          tx.txType == TransactionType.income ? S.income : S.expense,
          tx.categoryName ?? S.otherCategory,
          _formatAmount(tx.amount),
          tx.notes ?? '',
          tx.paidByName ?? '',
        ],
    ];

    return '${rows.map((r) => r.map(_escape).join(',')).join(_eol)}$_eol';
  }

  /// Builds the CSV for [month] and hands it to the platform (share sheet on
  /// iOS, browser download on web).
  Future<void> exportMonth({
    required List<TransactionModel> transactions,
    required DateTime month,
  }) async {
    final csv = buildMonthlyCsv(transactions);
    await saveCsvFile(
      fileName: fileNameFor(month),
      bytes: utf8.encode('$_bom$csv'),
      shareSubject: S.exportShareSubject(month.monthYear),
    );
  }

  // Plain machine-readable numbers — no thousands separators, no currency sign.
  static String _formatAmount(double amount) =>
      amount == amount.truncateToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);

  static final _needsQuotes = RegExp(r'[",\r\n]');

  static String _escape(String value) {
    if (!_needsQuotes.hasMatch(value) && value.trim() == value) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}

final csvExportServiceProvider =
    Provider<CsvExportService>((ref) => const CsvExportService());
