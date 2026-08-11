import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_provider.dart';

/// Last-known server rows, kept so the app still has something to show when a
/// request cannot reach Supabase.
///
/// Raw rows are stored rather than models: they are already JSON, they keep the
/// embedded joins (`categories`, `profiles`) intact, and they survive model
/// changes as long as the parser does.
class OfflineCache {
  const OfflineCache();

  static const _prefix = 'offline_cache_v1_';

  Future<void> writeRows(String key, List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode(rows));
    } catch (_) {
      // A cache write must never break a successful fetch.
    }
  }

  Future<List<Map<String, dynamic>>?> readRows(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final row in decoded) (row as Map).cast<String, dynamic>(),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Drops every cached row — called on sign-out so household data does not
  /// outlive the session on a shared device.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Best effort.
    }
  }
}

final offlineCacheProvider = Provider<OfflineCache>((ref) => const OfflineCache());

/// Fetches [fetch], caches what comes back, and falls back to the cached rows
/// when the request fails for connectivity reasons.
///
/// Errors that came from the server are rethrown untouched — showing stale data
/// in place of a real failure would hide bugs.
Future<List<T>> fetchWithCache<T>({
  required Ref ref,
  required String key,
  required Future<List<Map<String, dynamic>>> Function() fetch,
  required T Function(Map<String, dynamic>) parse,
}) async {
  final cache = ref.read(offlineCacheProvider);
  try {
    final rows = await fetch();
    await cache.writeRows(key, rows);
    ref.read(isOnlineProvider.notifier).reportOnline();
    return rows.map(parse).toList();
  } catch (e) {
    if (!isNetworkError(e)) rethrow;
    ref.read(isOnlineProvider.notifier).reportOffline();
    final cached = await cache.readRows(key);
    if (cached == null) rethrow;
    return cached.map(parse).toList();
  }
}
