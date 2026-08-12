import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/offline/offline_cache.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/data/auth_repository.dart';
import 'savings_model.dart';

class SavingsRepository {
  final SupabaseClient _client;
  SavingsRepository(this._client);

  Future<List<Map<String, dynamic>>> getGoalRows(String householdId) async {
    final data = await _client
        .from(tableSavingsGoals)
        .select()
        .eq('household_id', householdId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<SavingsGoalModel>> getGoals(String householdId) async {
    final rows = await getGoalRows(householdId);
    return rows.map(SavingsGoalModel.fromJson).toList();
  }

  Future<SavingsGoalModel> createGoal({
    required String householdId,
    required String name,
    required String icon,
    required double targetAmount,
    DateTime? deadline,
  }) async {
    final data = await _client.from(tableSavingsGoals).insert({
      'household_id': householdId,
      'name': name,
      'icon': icon,
      'target_amount': targetAmount,
      if (deadline != null) 'deadline': deadline.toIso8601String().substring(0, 10),
    }).select().single();
    return SavingsGoalModel.fromJson(data);
  }

  Future<void> contribute({
    required String goalId,
    required String addedById,
    required double amount,
    String? notes,
  }) async {
    // DB trigger on savings_contributions INSERT handles current_amount update atomically
    await _client.from(tableSavingsContributions).insert({
      'goal_id': goalId,
      'added_by': addedById,
      'amount': amount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _client.from(tableSavingsGoals).delete().eq('id', id);
  }
}

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository(ref.watch(supabaseClientProvider));
});

final savingsGoalsProvider = FutureProvider<List<SavingsGoalModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  final householdId = profile!.householdId!;
  final repo = ref.watch(savingsRepositoryProvider);
  return fetchWithCache(
    ref: ref,
    key: 'goals_$householdId',
    fetch: () => repo.getGoalRows(householdId),
    parse: SavingsGoalModel.fromJson,
  );
});
