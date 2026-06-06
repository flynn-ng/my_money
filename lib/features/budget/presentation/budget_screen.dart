import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/sheet_wrapper.dart';
import '../data/budget_repository.dart';
import 'set_budget_screen.dart';
import 'widgets/budget_progress_card.dart';

// Body widget embedded in the Finance screen's Budget tab
class BudgetBody extends ConsumerWidget {
  const BudgetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    return budgetsAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) =>
          ErrorDisplay(error: e, onRetry: () => ref.invalidate(budgetsProvider)),
      data: (budgets) {
        if (budgets.isEmpty) {
          return EmptyState(
            emoji: '🎯',
            title: S.noBudgets,
            subtitle: S.noBudgetsHint,
            action: FilledButton.icon(
              onPressed: () => _showSetBudget(context),
              icon: const Icon(Icons.add),
              label: const Text(S.setBudgetTitle),
              style: FilledButton.styleFrom(backgroundColor: AppColors.amber),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 88),
          itemCount: budgets.length,
          itemBuilder: (context, i) => BudgetProgressCard(
            budget: budgets[i],
            onEdit: () => _showSetBudget(context, existing: budgets[i]),
          ),
        );
      },
    );
  }

  void _showSetBudget(BuildContext context, {dynamic existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, _) => SheetWrapper(child: SetBudgetScreen(existing: existing)),
      ),
    );
  }
}
