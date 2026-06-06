import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/l10n/app_strings.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../savings/presentation/savings_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_list_screen.dart';

// Tracks which Finance sub-tab is active so the shell FAB can react
class FinanceTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final financeTabProvider =
    NotifierProvider<FinanceTabNotifier, int>(FinanceTabNotifier.new);

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: ref.read(financeTabProvider));
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(financeTabProvider.notifier).setIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab bar ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.black,
                indicatorWeight: 2,
                labelStyle: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: const [
                  Tab(text: S.tabTransactions),
                  Tab(text: S.tabBudget),
                  Tab(text: S.tabSavings),
                ],
              ),
            ),
            // ── Tab content ───────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  TransactionListBody(),
                  BudgetBody(),
                  SavingsBody(),
                ],
              ),
            ),
            // ── Month navigator (bottom, thumb-friendly) ──────────
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: EdgeInsets.fromLTRB(hPad(context), 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(month.monthYear, style: AppTextStyles.titleMedium)
                        .animate(key: ValueKey(month))
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: -0.05),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () =>
                        ref.read(selectedMonthProvider.notifier).previousMonth(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: month.isSameMonth(DateTime.now())
                        ? null
                        : () =>
                            ref.read(selectedMonthProvider.notifier).nextMonth(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
