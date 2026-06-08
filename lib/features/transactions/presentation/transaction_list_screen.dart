import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/extensions/currency_ext.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/error_display.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import 'add_transaction_screen.dart';
import 'widgets/transaction_tile.dart';

// Body widget embedded in the Finance screen's Transactions tab
class TransactionListBody extends ConsumerWidget {
  const TransactionListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    return Column(
      children: [
        txAsync.whenData((txs) => _SummaryBar(transactions: txs)).value ??
            const SizedBox.shrink(),
        Expanded(
          child: txAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.amber)),
            error: (e, _) => ErrorDisplay(
                error: e, onRetry: () => ref.invalidate(transactionsProvider)),
            data: (transactions) {
              if (transactions.isEmpty) return const _EmptyView();
              return _TransactionList(transactions: transactions, ref: ref);
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _SummaryBar({required this.transactions});

  @override
  Widget build(BuildContext context) {
    double income = 0, expense = 0;
    for (final tx in transactions) {
      if (tx.txType == TransactionType.income) income += tx.amount;
      if (tx.txType == TransactionType.expense) expense += tx.amount;
    }
    final net = income - expense;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad(context), 10, hPad(context), 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: context.colors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            _Stat(label: S.income, amount: income, color: AppColors.green, delay: 0),
            _Divider(),
            _Stat(label: S.expense, amount: expense, color: AppColors.red, delay: 80),
            _Divider(),
            _Stat(
              label: S.netSaved,
              amount: net,
              color: net >= 0 ? AppColors.green : AppColors.red,
              delay: 160,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.1, curve: Curves.easeOut);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final int delay;
  const _Stat({required this.label, required this.amount, required this.color, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: amount.abs()),
        duration: Duration(milliseconds: 600 + delay),
        curve: Curves.easeOut,
        builder: (context, val, child) {
          final display = amount < 0 ? -val : val;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                display.asCompactCurrency,
                style: AppTextStyles.titleMedium.copyWith(color: color, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(label,
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
            ],
          );
        },
      ).animate(delay: delay.ms).fadeIn(duration: 250.ms).slideY(begin: 0.15),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.divider);
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💸', style: TextStyle(fontSize: 56))
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 12),
          Text(S.noTransactions, style: AppTextStyles.titleMedium)
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 4),
          Text(S.noTransactionsHint, style: AppTextStyles.bodyMedium)
              .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => AddTransactionScreen.show(context),
            icon: const Icon(Icons.add),
            label: Text(S.addTransaction),
            style: FilledButton.styleFrom(backgroundColor: AppColors.amber),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final WidgetRef ref;
  const _TransactionList({required this.transactions, required this.ref});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      grouped.putIfAbsent(tx.date.fullDate, () => []).add(tx);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final date = keys[i];
        final dayTxs = grouped[date]!;
        final net = dayTxs.fold<double>(
            0, (s, tx) => s + (tx.txType == TransactionType.expense ? -tx.amount : tx.amount));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad(context), 10, hPad(context), 2),
              child: Row(
                children: [
                  Text(date, style: AppTextStyles.labelSmall),
                  const Spacer(),
                  Text(
                    net >= 0 ? '+${net.asCurrency}' : net.asCurrency,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: net >= 0 ? AppColors.green : AppColors.red),
                  ),
                ],
              ),
            ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms),
            ...dayTxs.mapIndexed((j, tx) => TransactionTile(
                  transaction: tx,
                  onTap: () => AddTransactionScreen.show(context, transaction: tx),
                  onDelete: () async {
                    // Invalidate immediately so the ListView (and the
                    // dismissed Dismissible) is torn down on this frame.
                    // Without this, anything that triggers a rebuild before
                    // the network call completes causes a Flutter assertion:
                    // "A dismissed Dismissible widget is still part of the tree."
                    ref.invalidate(transactionsProvider);
                    await ref
                        .read(transactionRepositoryProvider)
                        .deleteTransaction(tx.id);
                    ref.invalidate(transactionsProvider);
                  },
                ).animate(delay: (i * 30 + j * 20).ms)
                    .fadeIn(duration: 250.ms)
                    .slideX(begin: 0.04, curve: Curves.easeOut)),
          ],
        );
      },
    );
  }
}

extension _IndexedList<T> on Iterable<T> {
  Iterable<Widget> mapIndexed(Widget Function(int i, T e) f) =>
      toList().asMap().entries.map((e) => f(e.key, e.value));
}
