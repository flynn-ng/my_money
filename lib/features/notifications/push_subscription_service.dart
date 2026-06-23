import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_provider.dart';
import '_push_helper_stub.dart'
    if (dart.library.js_interop) '_push_helper_web.dart';

// Safe to expose — VAPID public key is only used to subscribe, not to send.
const _kVapidPublicKey =
    'BJ7kCRqTOpcoY4wPBt87uRy7qlN5vMVIvmEpu5SiEBS2ZV5t4OTiAcipsGYCVTk0d9493J4B6p1ocO-njRtvjAE';

class PushSubscriptionService {
  final SupabaseClient _client;
  PushSubscriptionService(this._client);

  bool get isSupported => kIsWeb && pushIsSupported();

  Future<bool> isSubscribed() async {
    if (!isSupported) return false;
    try {
      return await pushGetSubscription() != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> subscribe({
    required String profileId,
    required String householdId,
  }) async {
    if (!isSupported) return false;
    try {
      final subJson = await pushSubscribe(_kVapidPublicKey);
      if (subJson == null) return false;

      final sub = jsonDecode(subJson) as Map<String, dynamic>;
      final keys = sub['keys'] as Map<String, dynamic>;

      await _client.from('push_subscriptions').upsert({
        'profile_id': profileId,
        'household_id': householdId,
        'endpoint': sub['endpoint'] as String,
        'p256dh': keys['p256dh'] as String,
        'auth': keys['auth'] as String,
      }, onConflict: 'profile_id,endpoint');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> unsubscribe({required String profileId}) async {
    if (!isSupported) return;
    try {
      final subJson = await pushGetSubscription();
      await pushUnsubscribe();
      if (subJson != null) {
        final sub = jsonDecode(subJson) as Map<String, dynamic>;
        await _client
            .from('push_subscriptions')
            .delete()
            .eq('profile_id', profileId)
            .eq('endpoint', sub['endpoint'] as String);
      }
    } catch (_) {}
  }
}

final pushSubscriptionServiceProvider = Provider<PushSubscriptionService>((ref) {
  return PushSubscriptionService(ref.watch(supabaseClientProvider));
});

final pushSubscribedProvider = FutureProvider<bool>((ref) {
  return ref.read(pushSubscriptionServiceProvider).isSubscribed();
});
