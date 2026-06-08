import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/sheet_wrapper.dart';
import '../data/savings_repository.dart';
import 'add_goal_screen.dart';
import 'contribute_screen.dart';
import 'widgets/goal_progress_card.dart';

// Body widget embedded in the Finance screen's Savings tab
class SavingsBody extends ConsumerWidget {
  const SavingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    return goalsAsync.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => ErrorDisplay(
          error: e, onRetry: () => ref.invalidate(savingsGoalsProvider)),
      data: (goals) {
        if (goals.isEmpty) {
          return EmptyState(
            emoji: '🐣',
            title: S.noGoals,
            subtitle: S.noGoalsHint,
            action: FilledButton.icon(
              onPressed: () => AddGoalScreen.show(context),
              icon: const Icon(Icons.add),
              label: Text(S.addGoal),
              style: FilledButton.styleFrom(backgroundColor: AppColors.amber),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 88),
          itemCount: goals.length,
          itemBuilder: (context, i) => GoalProgressCard(
            goal: goals[i],
            onContribute: () => showAppSheet(
              context: context,
              content: ContributeScreen(goal: goals[i]),
              initialChildSize: 0.62,
            ),
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                useRootNavigator: false,
                builder: (_) => AlertDialog(
                  title: Text(S.deleteGoalTitle),
                  content: Text(S.deleteGoalContent(goals[i].name)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.cancel)),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                      child: Text(S.delete),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(savingsRepositoryProvider).deleteGoal(goals[i].id);
                ref.invalidate(savingsGoalsProvider);
              }
            },
          ),
        );
      },
    );
  }
}
