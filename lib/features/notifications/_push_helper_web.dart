import 'dart:js_interop';

@JS('meownyPush.isSupported')
external bool _jsIsSupported();

@JS('meownyPush.getPermission')
external String _jsGetPermission();

@JS('meownyPush.subscribe')
external JSPromise<JSAny?> _jsSubscribe(String vapidKey);

@JS('meownyPush.unsubscribe')
external JSPromise<JSAny?> _jsUnsubscribe();

@JS('meownyPush.getSubscription')
external JSPromise<JSAny?> _jsGetSubscription();

bool pushIsSupported() => _jsIsSupported();

String pushGetPermission() => _jsGetPermission();

Future<String?> pushSubscribe(String vapidKey) async {
  final result = await _jsSubscribe(vapidKey).toDart;
  if (result == null) return null;
  return (result as JSString).toDart;
}

Future<bool> pushUnsubscribe() async {
  await _jsUnsubscribe().toDart;
  return true;
}

Future<String?> pushGetSubscription() async {
  final result = await _jsGetSubscription().toDart;
  if (result == null) return null;
  return (result as JSString).toDart;
}
