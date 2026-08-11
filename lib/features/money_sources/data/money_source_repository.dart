import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/offline/offline_cache.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/data/auth_repository.dart';
import 'money_source_model.dart';

class MoneySourceRepository {
  final SupabaseClient _client;
  MoneySourceRepository(this._client);

  Future<List<Map<String, dynamic>>> getSourceRows(String householdId) async {
    final sources = await _client
        .from(tableMoneySource)
        .select()
        .eq('household_id', householdId)
        .eq('is_archived', false)
        .order('sort_order');

    return List<Map<String, dynamic>>.from(sources);
  }

  Future<List<MoneySourceModel>> getSources(String householdId) async {
    final rows = await getSourceRows(householdId);
    return rows.map(MoneySourceModel.fromJson).toList();
  }

  Future<MoneySourceModel> createSource({
    required String householdId,
    required String name,
    required String type,
    required String icon,
    required String color,
    required double initialBalance,
    int sortOrder = 0,
  }) async {
    final data = await _client.from(tableMoneySource).insert({
      'household_id': householdId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'initial_balance': initialBalance,
      'sort_order': sortOrder,
    }).select().single();
    return MoneySourceModel.fromJson(data);
  }

  Future<void> updateSource(
    String id, {
    required String name,
    required String type,
    required String icon,
    required String color,
    required double initialBalance,
  }) async {
    await _client.from(tableMoneySource).update({
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'initial_balance': initialBalance,
    }).eq('id', id);
  }

  Future<void> deleteSource(String id) async {
    await _client.from(tableMoneySource).delete().eq('id', id);
  }

  Future<void> updateSortOrders(List<String> orderedIds) async {
    await Future.wait([
      for (int i = 0; i < orderedIds.length; i++)
        _client
            .from(tableMoneySource)
            .update({'sort_order': i})
            .eq('id', orderedIds[i]),
    ]);
  }
}

final moneySourceRepositoryProvider = Provider<MoneySourceRepository>((ref) {
  return MoneySourceRepository(ref.watch(supabaseClientProvider));
});

final moneySourcesProvider = FutureProvider<List<MoneySourceModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  final householdId = profile!.householdId!;
  final repo = ref.watch(moneySourceRepositoryProvider);
  return fetchWithCache(
    ref: ref,
    key: 'sources_$householdId',
    fetch: () => repo.getSourceRows(householdId),
    parse: MoneySourceModel.fromJson,
  );
});
