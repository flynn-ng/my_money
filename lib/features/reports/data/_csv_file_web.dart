import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

// Web: wrap the CSV in a Blob and click a hidden anchor so the browser saves it
// as a normal download.
Future<void> saveCsvFile({
  required String fileName,
  required List<int> bytes,
  required String shareSubject,
}) async {
  final blobParts = <JSAny>[Uint8List.fromList(bytes).toJS].toJS;
  final blobOptions = JSObject()
    ..setProperty('type'.toJS, 'text/csv;charset=utf-8'.toJS);
  final blob = globalContext
      .getProperty<JSFunction>('Blob'.toJS)
      .callAsConstructor<JSObject>(blobParts, blobOptions);

  final urlApi = globalContext.getProperty<JSObject>('URL'.toJS);
  final url = urlApi.callMethod<JSString>('createObjectURL'.toJS, blob).toDart;

  final document = globalContext.getProperty<JSObject>('document'.toJS);
  final anchor = document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  anchor.setProperty('href'.toJS, url.toJS);
  anchor.setProperty('download'.toJS, fileName.toJS);

  // Firefox only downloads anchors that are attached to the document.
  final body = document.getProperty<JSObject>('body'.toJS);
  body.callMethod<JSAny?>('appendChild'.toJS, anchor);
  anchor.callMethod<JSAny?>('click'.toJS);
  body.callMethod<JSAny?>('removeChild'.toJS, anchor);

  // Revoking immediately can cancel a download that has not started yet.
  await Future<void>.delayed(const Duration(seconds: 1));
  urlApi.callMethod<JSAny?>('revokeObjectURL'.toJS, url.toJS);
}
