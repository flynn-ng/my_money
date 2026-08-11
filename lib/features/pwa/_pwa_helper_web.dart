import 'dart:js_interop';

@JS('meownyPwa.canInstall')
external bool _jsCanInstall();

@JS('meownyPwa.isStandalone')
external bool _jsIsStandalone();

@JS('meownyPwa.isIos')
external bool _jsIsIos();

@JS('meownyPwa.promptInstall')
external JSPromise<JSAny?> _jsPromptInstall();

bool pwaCanInstall() => _jsCanInstall();

bool pwaIsStandalone() => _jsIsStandalone();

bool pwaIsIos() => _jsIsIos();

Future<String> pwaPromptInstall() async {
  final result = await _jsPromptInstall().toDart;
  if (result == null) return 'unavailable';
  return (result as JSString).toDart;
}
