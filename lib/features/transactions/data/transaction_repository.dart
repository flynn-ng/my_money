import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../money_sources/data/money_source_repository.dart';
import 'category_model.dart';
import 'transaction_model.dart';

class TransactionRepository {
  final SupabaseClient _client;
  TransactionRepository(this._client);

  Future<List<TransactionModel>> getTransactionsForDateRange(
      String householdId, DateTime from, DateTime to) async {
    final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-01';
    final toStr = DateTime(to.year, to.month + 1, 0).toIso8601String().substring(0, 10);
    final data = await _client
        .from(tableTransactions)
        .select('*, categories(*), profiles(display_name), money_sources(name,icon,color)')
        .eq('household_id', householdId)
        .gte('date', fromStr)
        .lte('date', toStr)
        .order('date', ascending: false);
    return data.map((r) => TransactionModel.fromJson(r)).toList();
  }

  Future<List<TransactionModel>> getTransactionsForMonth(
      String householdId, DateTime month) async {
    final from = DateTime(month.year, month.month, 1).toIso8601String().substring(0, 10);
    final to = DateTime(month.year, month.month + 1, 0).toIso8601String().substring(0, 10);
    final data = await _client
        .from(tableTransactions)
        .select('*, categories(*), profiles(display_name), money_sources(name,icon,color)')
        .eq('household_id', householdId)
        .gte('date', from)
        .lte('date', to)
        .order('date', ascending: false);
    return data.map((r) => TransactionModel.fromJson(r)).toList();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _client.from(tableTransactions).insert(tx.toInsertJson());
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> updates) async {
    await _client.from(tableTransactions).update(updates).eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from(tableTransactions).delete().eq('id', id);
  }

  Future<List<CategoryModel>> getCategories(String householdId) async {
    final data = await _client
        .from(tableCategories)
        .select()
        .eq('household_id', householdId)
        .order('sort_order');
    return data.map((r) => CategoryModel.fromJson(r)).toList();
  }

  Future<CategoryModel> createCategory({
    required String householdId,
    required String name,
    required String icon,
    required String color,
    required String type,
    required int sortOrder,
  }) async {
    final data = await _client.from(tableCategories).insert({
      'household_id': householdId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'sort_order': sortOrder,
    }).select().single();
    return CategoryModel.fromJson(data);
  }

  Future<void> updateCategory(
    String id, {
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    await _client.from(tableCategories).update({
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
    }).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _client.from(tableCategories).delete().eq('id', id);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseClientProvider));
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  return ref
      .watch(transactionRepositoryProvider)
      .getCategories(profile!.householdId!);
});

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void previousMonth() => state = DateTime(state.year, state.month - 1);
  void nextMonth() => state = DateTime(state.year, state.month + 1);
  void set(DateTime month) => state = month;
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

final transactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .getTransactionsForMonth(profile!.householdId!, month);
});

// ── Realtime subscription ─────────────────────────────────────────────────────

// Subscribes to INSERT/UPDATE/DELETE on the transactions table for the active
// household and invalidates transactionsProvider on any change so both partners
// always see live data without manual refresh.
final transactionRealtimeProvider = Provider.autoDispose<void>((ref) {
  final profile = ref.watch(currentProfileProvider).value;
  if (profile?.householdId == null) return;

  final client = ref.watch(supabaseClientProvider);
  final householdId = profile!.householdId!;

  final channel = client
      .channel('transactions_rt_$householdId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tableTransactions,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'household_id',
          value: householdId,
        ),
        callback: (_) {
          ref.invalidate(transactionsProvider);
          ref.invalidate(moneySourcesProvider);
        },
      )
      .subscribe();

  ref.onDispose(() => client.removeChannel(channel));
});

// ── Filter state ──────────────────────────────────────────────────────────────

const _sentinel = Object();

class TransactionFilter {
  final String query;
  final TransactionType? typeFilter;
  final String? categoryId;
  final String? sourceId;

  const TransactionFilter({
    this.query = '',
    this.typeFilter,
    this.categoryId,
    this.sourceId,
  });

  bool get isActive =>
      query.isNotEmpty || typeFilter != null || categoryId != null || sourceId != null;

  TransactionFilter copyWith({
    String? query,
    Object? typeFilter = _sentinel,
    Object? categoryId = _sentinel,
    Object? sourceId = _sentinel,
  }) =>
      TransactionFilter(
        query: query ?? this.query,
        typeFilter: typeFilter == _sentinel
            ? this.typeFilter
            : typeFilter as TransactionType?,
        categoryId:
            categoryId == _sentinel ? this.categoryId : categoryId as String?,
        sourceId:
            sourceId == _sentinel ? this.sourceId : sourceId as String?,
      );
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setQuery(String q) => state = state.copyWith(query: q);
  void setType(TransactionType? t) => state = state.copyWith(typeFilter: t);
  void setCategory(String? id) => state = state.copyWith(categoryId: id);
  void setSource(String? id) => state = state.copyWith(sourceId: id);
  void clear() => state = const TransactionFilter();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
        TransactionFilterNotifier.new);

final filteredTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final all = await ref.watch(transactionsProvider.future);
  final filter = ref.watch(transactionFilterProvider);

  if (!filter.isActive) return all;

  final q = filter.query.toLowerCase();
  return all.where((tx) {
    if (filter.typeFilter != null && tx.txType != filter.typeFilter) {
      return false;
    }
    if (filter.categoryId != null && tx.categoryId != filter.categoryId) {
      return false;
    }
    if (filter.sourceId != null && tx.sourceId != filter.sourceId) {
      return false;
    }
    if (q.isNotEmpty) {
      return (tx.categoryName?.toLowerCase().contains(q) ?? false) ||
          (tx.notes?.toLowerCase().contains(q) ?? false) ||
          (tx.sourceName?.toLowerCase().contains(q) ?? false);
    }
    return true;
  }).toList();
});
