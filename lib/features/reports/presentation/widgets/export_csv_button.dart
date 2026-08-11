import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../data/csv_export_service.dart';

/// Exports the selected month's transactions as a CSV file.
class ExportCsvButton extends ConsumerStatefulWidget {
  const ExportCsvButton({super.key});

  @override
  ConsumerState<ExportCsvButton> createState() => _ExportCsvButtonState();
}

class _ExportCsvButtonState extends ConsumerState<ExportCsvButton> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final transactions = await ref.read(transactionsProvider.future);
      if (transactions.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(S.exportNoData)));
        return;
      }
      await ref.read(csvExportServiceProvider).exportMonth(
            transactions: transactions,
            month: ref.read(selectedMonthProvider),
          );
      // On native the share sheet is its own confirmation; on web the download
      // happens silently, so say so.
      if (kIsWeb) {
        messenger.showSnackBar(SnackBar(content: Text(S.exportDone)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('${S.exportFailed}: ${friendlyError(e)}'),
        backgroundColor: AppColors.red,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: S.exportCsv,
      onPressed: _busy ? null : _export,
      icon: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download_outlined),
    );
  }
}
