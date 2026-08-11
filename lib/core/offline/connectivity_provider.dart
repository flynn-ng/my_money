import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '_connectivity_stub.dart'
    if (dart.library.js_interop) '_connectivity_web.dart';

/// Whether the app currently believes it can reach the network.
///
/// On the web this follows the browser's online/offline events. On iOS there
/// is no event source without an extra plugin, so the flag is driven by the
/// data layer: a request that fails with a transport error reports offline,
/// and the next successful one reports back online.
class ConnectivityNotifier extends Notifier<bool> {
  bool _listening = false;

  @override
  bool build() {
    if (!_listening) {
      _listening = true;
      connectivityListen((online) => state = online);
    }
    return connectivityIsOnline();
  }

  void reportOffline() {
    if (state) state = false;
  }

  void reportOnline() {
    if (!state) state = true;
  }
}

final isOnlineProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

/// Whether [error] means "the request never reached the server".
///
/// Anything the server answered — a Postgrest error, an auth rejection — is
/// not a connectivity problem and must not be masked by cached data.
bool isNetworkError(Object error) {
  if (error is PostgrestException) return false;
  if (error is AuthException) return false;

  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('failed host lookup') ||
      message.contains('failed to fetch') ||
      message.contains('xmlhttprequest') ||
      message.contains('connection refused') ||
      message.contains('connection closed') ||
      message.contains('network is unreachable') ||
      message.contains('retryable');
}
