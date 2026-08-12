import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool connectivityIsOnline() {
  final navigator = globalContext.getProperty<JSObject>('navigator'.toJS);
  return navigator.getProperty<JSBoolean>('onLine'.toJS).toDart;
}

void connectivityListen(void Function(bool online) onChange) {
  globalContext.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'online'.toJS,
    ((JSAny _) => onChange(true)).toJS,
  );
  globalContext.callMethod<JSAny?>(
    'addEventListener'.toJS,
    'offline'.toJS,
    ((JSAny _) => onChange(false)).toJS,
  );
}
