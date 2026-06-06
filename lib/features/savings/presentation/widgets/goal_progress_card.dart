import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/savings_model.dart';

class GoalProgressCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback? onContribute;
  final VoidCallback? onDelete;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onContribute,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final daysLeft = goal.daysLeft;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: context.colors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: AppTextStyles.titleMedium),
                    if (daysLeft != null)
                      Text(
                        daysLeft > 0
                            ? '$daysLeft ${S.goalDaysLeft}'
                            : daysLeft == 0
                                ? S.goalDueToday
                                : '${-daysLeft} ${S.goalOverdueDays}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: daysLeft <= 0
                              ? AppColors.red
                              : daysLeft <= 7
                                  ? Colors.orange
                                  : context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!goal.isCompleted)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.amber),
                  onPressed: onContribute,
                ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: context.colors.textSecondary, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.currentAmount.asCurrency,
                  style: AppTextStyles.titleMedium.copyWith(
                      color: goal.isCompleted ? AppColors.green : AppColors.amber)),
              Text('${S.budgetOf} ${goal.targetAmount.asCurrency}',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: context.colors.divider,
                  valueColor: AlwaysStoppedAnimation(
                      goal.isCompleted ? AppColors.green : AppColors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (goal.isCompleted)
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.green, size: 16),
                const SizedBox(width: 4),
                Text(S.goalReached,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.green)),
              ],
            )
          else
            Text(
              '${(progress * 100).toStringAsFixed(0)}${S.goalSavedProgress} · ${(goal.targetAmount - goal.currentAmount).asCurrency} ${S.goalToGo}',
              style: AppTextStyles.labelSmall,
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}
