import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/offline/offline_cache.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../reports/data/reports_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import 'budget_model.dart';

class BudgetRepository {
  final SupabaseClient _client;
  BudgetRepository(this._client);

  Future<List<Map<String, dynamic>>> getBudgetRowsForMonth(
      String householdId, DateTime month) async {
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    final data = await _client
        .from(tableBudgets)
        .select('*, categories(*)')
        .eq('household_id', householdId)
        .eq('month', monthStr);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<BudgetModel>> getBudgetsForMonth(
      String householdId, DateTime month) async {
    final rows = await getBudgetRowsForMonth(householdId, month);
    return rows.map(BudgetModel.fromJson).toList();
  }

  Future<void> setBudget({
    required String householdId,
    required String categoryId,
    required DateTime month,
    required double amount,
  }) async {
    final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
    await _client.from(tableBudgets).upsert({
      'household_id': householdId,
      'category_id': categoryId,
      'month': monthStr,
      'amount': amount,
    }, onConflict: 'household_id,category_id,month');
  }

  Future<void> deleteBudget(String id) async {
    await _client.from(tableBudgets).delete().eq('id', id);
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(supabaseClientProvider));
});

final budgetsProvider =
    FutureProvider<List<BudgetModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  final householdId = profile!.householdId!;
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(budgetRepositoryProvider);
  final budgets = await fetchWithCache(
    ref: ref,
    key: 'budgets_${householdId}_${month.year}-${month.month}',
    fetch: () => repo.getBudgetRowsForMonth(householdId, month),
    parse: BudgetModel.fromJson,
  );

  final spending = await ref.watch(categorySpendingProvider.future);
  final spendingByCategory = {for (final s in spending) s.categoryId: s.amount};
  for (final b in budgets) {
    b.spent = spendingByCategory[b.categoryId] ?? 0;
  }
  return budgets;
});
