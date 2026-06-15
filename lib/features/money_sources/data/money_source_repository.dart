import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/data/auth_repository.dart';
import 'money_source_model.dart';

class MoneySourceRepository {
  final SupabaseClient _client;
  MoneySourceRepository(this._client);

  Future<List<MoneySourceModel>> getSources(String householdId) async {
    final sources = await _client
        .from(tableMoneySource)
        .select()
        .eq('household_id', householdId)
        .eq('is_archived', false)
        .order('sort_order');

    if (sources.isEmpty) return [];

    // Fetch all source-linked transaction amounts to compute current balances
    final txData = await _client
        .from(tableTransactions)
        .select('source_id, type, amount')
        .eq('household_id', householdId)
        .not('source_id', 'is', null);

    final income = <String, double>{};
    final expense = <String, double>{};
    for (final row in txData) {
      final sid = row['source_id'] as String;
      final amt = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        income[sid] = (income[sid] ?? 0) + amt;
      } else {
        expense[sid] = (expense[sid] ?? 0) + amt;
      }
    }

    return sources.map((json) {
      final id = json['id'] as String;
      return MoneySourceModel.fromJson(
        json,
        income: income[id] ?? 0,
        expense: expense[id] ?? 0,
      );
    }).toList();
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
}

final moneySourceRepositoryProvider = Provider<MoneySourceRepository>((ref) {
  return MoneySourceRepository(ref.watch(supabaseClientProvider));
});

final moneySourcesProvider = FutureProvider<List<MoneySourceModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  return ref
      .watch(moneySourceRepositoryProvider)
      .getSources(profile!.householdId!);
});
