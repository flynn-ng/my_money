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
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/widgets/error_display.dart';
import '../data/category_model.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import 'add_transaction_screen.dart';
import 'widgets/transaction_tile.dart';

// Body widget embedded in the Finance screen's Transactions tab
class TransactionListBody extends ConsumerWidget {
  const TransactionListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(transactionRealtimeProvider); // keep WS subscription alive
    final txAsync = ref.watch(filteredTransactionsProvider);
    return Column(
      children: [
        txAsync.when(
          data: (txs) => _SummaryBar(transactions: txs),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),
        const _FilterBar(),
        Expanded(
          child: txAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.amber)),
            error: (e, _) => ErrorDisplay(
                error: e, onRetry: () => ref.invalidate(transactionsProvider)),
            data: (transactions) {
              if (transactions.isEmpty) return const _EmptyView();
              return _TransactionList(transactions: transactions);
            },
          ),
        ),
      ],
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerStatefulWidget {
  const _FilterBar();

  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  bool _searchOpen = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _controller.clear();
      ref.read(transactionFilterProvider.notifier).setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search row
        Padding(
          padding: EdgeInsets.fromLTRB(hPad(context), 4, hPad(context), 0),
          child: Row(
            children: [
              if (_searchOpen)
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: S.searchTransactions,
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.textSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: context.colors.surface,
                      suffixIcon: filter.query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _controller.clear();
                                notifier.setQuery('');
                              },
                            )
                          : null,
                    ),
                    onChanged: notifier.setQuery,
                  ),
                )
              else
                const Spacer(),
              Badge(
                isLabelVisible: filter.isActive,
                backgroundColor: AppColors.amber,
                smallSize: 7,
                child: IconButton(
                  icon: Icon(
                    _searchOpen ? Icons.search_off : Icons.search,
                    size: 22,
                  ),
                  onPressed: _toggleSearch,
                ),
              ),
              if (filter.isActive)
                TextButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() => _searchOpen = false);
                    notifier.clear();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(S.clearFilter,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.amber)),
                ),
            ],
          ),
        ),

        // Chip row
        _ChipRow(
          filter: filter,
          categoriesAsync: categoriesAsync,
          onClearAll: () {
            _controller.clear();
            setState(() => _searchOpen = false);
            notifier.clear();
          },
          onTypeFilter: notifier.setType,
          onCategoryFilter: notifier.setCategory,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final TransactionFilter filter;
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final VoidCallback onClearAll;
  final void Function(TransactionType?) onTypeFilter;
  final void Function(String?) onCategoryFilter;

  const _ChipRow({
    required this.filter,
    required this.categoriesAsync,
    required this.onClearAll,
    required this.onTypeFilter,
    required this.onCategoryFilter,
  });

  List<Widget> _buildChips(BuildContext context) {
    final chips = <Widget>[
      _Chip(
        label: S.filterAll,
        selected: !filter.isActive,
        onTap: onClearAll,
      ),
      _Chip(
        label: S.income,
        selected: filter.typeFilter == TransactionType.income,
        onTap: () => onTypeFilter(
          filter.typeFilter == TransactionType.income ? null : TransactionType.income,
        ),
      ),
      _Chip(
        label: S.expense,
        selected: filter.typeFilter == TransactionType.expense,
        onTap: () => onTypeFilter(
          filter.typeFilter == TransactionType.expense ? null : TransactionType.expense,
        ),
      ),
      ...categoriesAsync.whenData((cats) {
        return cats.map((cat) {
          final isSelected = filter.categoryId == cat.id;
          return _Chip(
            label: cat.name,
            icon: cat.isEmoji ? cat.icon : null,
            selected: isSelected,
            onTap: () => onCategoryFilter(isSelected ? null : cat.id),
          );
        }).toList();
      }).value ?? [],
    ];
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb && MediaQuery.sizeOf(context).width >= kMaxContent;
    final chips = _buildChips(context);

    if (isWide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad(context), 4, hPad(context), 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips,
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad(context)),
        itemCount: chips.length,
        separatorBuilder: (context, i) => const SizedBox(width: 6),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? Colors.white : context.colors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

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
            _StatDivider(),
            _Stat(label: S.expense, amount: expense, color: AppColors.red, delay: 80),
            _StatDivider(),
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

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.divider);
}

// ── Empty state ───────────────────────────────────────────────────────────────

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

class _TransactionList extends ConsumerStatefulWidget {
  final List<TransactionModel> transactions;
  const _TransactionList({required this.transactions});

  @override
  ConsumerState<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<_TransactionList> {
  // IDs removed optimistically so the Dismissible is gone from the tree
  // synchronously — before any async work or scheduled rebuilds run.
  final Set<String> _deletedIds = {};
  late Map<String, List<TransactionModel>> _grouped;
  late List<String> _keys;

  @override
  void initState() {
    super.initState();
    _rebuildGroups();
  }

  @override
  void didUpdateWidget(_TransactionList old) {
    super.didUpdateWidget(old);
    if (_deletedIds.isNotEmpty) {
      final currentIds = widget.transactions.map((t) => t.id).toSet();
      _deletedIds.removeWhere((id) => !currentIds.contains(id));
    }
    if (!identical(widget.transactions, old.transactions)) {
      _rebuildGroups();
    }
  }

  void _rebuildGroups() {
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in widget.transactions) {
      if (!_deletedIds.contains(tx.id)) {
        grouped.putIfAbsent(tx.date.fullDate, () => []).add(tx);
      }
    }
    _grouped = grouped;
    _keys = grouped.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: _keys.length,
      itemBuilder: (context, i) {
        final date = _keys[i];
        final dayTxs = _grouped[date]!;
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
            ).animate(delay: Duration(milliseconds: (i * 30).clamp(0, 300)))
                .fadeIn(duration: 200.ms),
            ...dayTxs.mapIndexed((j, tx) => TransactionTile(
                  transaction: tx,
                  onTap: () => AddTransactionScreen.show(context, transaction: tx),
                  onDelete: () async {
                    // Synchronously remove from the rendered list so the
                    // Dismissible is gone from the tree before any scheduled
                    // rebuild (e.g. flutter_animate timers) can fire and trip
                    // the "dismissed Dismissible still in tree" assertion.
                    setState(() {
                      _deletedIds.add(tx.id);
                      _rebuildGroups();
                    });
                    await ref
                        .read(transactionRepositoryProvider)
                        .deleteTransaction(tx.id);
                    ref.invalidate(transactionsProvider);
                  },
                ).animate(delay: Duration(milliseconds: (i * 30 + j * 20).clamp(0, 400)))
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
