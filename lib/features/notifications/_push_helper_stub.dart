bool pushIsSupported() => false;
String pushGetPermission() => 'denied';
Future<String?> pushSubscribe(String vapidKey) async => null;
Future<bool> pushUnsubscribe() async => false;
Future<String?> pushGetSubscription() async => null;
