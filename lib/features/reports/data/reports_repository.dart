import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../transactions/data/transaction_model.dart';
import '../../transactions/data/transaction_repository.dart';

class CategorySpending {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double amount;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
  });
}

class MonthlyTotal {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyTotal({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
}

class ReportsRepository {
  List<CategorySpending> spendingByCategory(List<TransactionModel> transactions) {
    final map = <String, CategorySpending>{};
    for (final tx in transactions) {
      if (tx.txType != TransactionType.expense) continue;
      if (map.containsKey(tx.categoryId)) {
        final existing = map[tx.categoryId]!;
        map[tx.categoryId] = CategorySpending(
          categoryId: existing.categoryId,
          categoryName: existing.categoryName,
          categoryIcon: existing.categoryIcon,
          categoryColor: existing.categoryColor,
          amount: existing.amount + tx.amount,
        );
      } else {
        map[tx.categoryId] = CategorySpending(
          categoryId: tx.categoryId,
          categoryName: tx.categoryName ?? 'Unknown',
          categoryIcon: tx.categoryIcon ?? '📦',
          categoryColor: tx.categoryColor ?? '#78716C',
          amount: tx.amount,
        );
      }
    }
    final result = map.values.toList();
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  MonthlyTotal monthlyTotals(List<TransactionModel> transactions, DateTime month) {
    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.txType == TransactionType.income) income += tx.amount;
      if (tx.txType == TransactionType.expense) expense += tx.amount;
    }
    return MonthlyTotal(month: month, income: income, expense: expense);
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

final categorySpendingProvider =
    FutureProvider<List<CategorySpending>>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  return ref.watch(reportsRepositoryProvider).spendingByCategory(transactions);
});

final monthlyTotalsProvider = FutureProvider<MonthlyTotal>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(reportsRepositoryProvider).monthlyTotals(transactions, month);
});

final last6MonthsProvider = FutureProvider<List<MonthlyTotal>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.householdId == null) return [];
  final repo = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month - 5, 1);
  final to = DateTime(now.year, now.month, 1);
  final allTxs = await repo.getTransactionsForDateRange(profile!.householdId!, from, to);

  // Group by year-month
  final byMonth = <String, (double, double)>{};
  for (int i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    byMonth['${m.year}-${m.month}'] = (0, 0);
  }
  for (final tx in allTxs) {
    final key = '${tx.date.year}-${tx.date.month}';
    if (!byMonth.containsKey(key)) continue;
    final (inc, exp) = byMonth[key]!;
    if (tx.txType == TransactionType.income) {
      byMonth[key] = (inc + tx.amount, exp);
    } else if (tx.txType == TransactionType.expense) {
      byMonth[key] = (inc, exp + tx.amount);
    }
  }

  return [
    for (int i = 5; i >= 0; i--)
      () {
        final m = DateTime(now.year, now.month - i, 1);
        final (inc, exp) = byMonth['${m.year}-${m.month}']!;
        return MonthlyTotal(month: m, income: inc, expense: exp);
      }(),
  ];
});
