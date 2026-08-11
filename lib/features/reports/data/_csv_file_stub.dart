import 'dart:io';

import 'package:share_plus/share_plus.dart' show Share, XFile;

// Native (iOS): write the CSV to a temp file and hand it to the share sheet so
// the user can save it to Files, mail it, or send it to a spreadsheet app.
Future<void> saveCsvFile({
  required String fileName,
  required List<int> bytes,
  required String shareSubject,
}) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv', name: fileName)],
    subject: shareSubject,
  );
}
