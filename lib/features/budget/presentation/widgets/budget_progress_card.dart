import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/budget_model.dart';

class BudgetProgressCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onEdit;

  const BudgetProgressCard({super.key, required this.budget, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final progress = budget.progress;
    final color = _progressColor(progress);
    final catColor = AppColors.fromHex(budget.categoryColor ?? '#78716C');

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(budget.categoryIcon ?? '📦',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(budget.categoryName ?? '',
                      style: AppTextStyles.bodyLarge),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(budget.spent.asCurrency,
                        style: AppTextStyles.titleMedium.copyWith(color: color)),
                    Text('${S.budgetOf} ${budget.amount.asCurrency}',
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}${S.budgetPercentUsed}',
                    style: AppTextStyles.labelSmall),
                Text(
                  budget.remaining >= 0
                      ? '${budget.remaining.asCurrency} ${S.budgetLeft}'
                      : '${(-budget.remaining).asCurrency} ${S.budgetOver}',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: budget.remaining >= 0
                          ? AppColors.textSecondary
                          : AppColors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Color _progressColor(double progress) {
    if (progress >= 1.0) return AppColors.red;
    if (progress >= 0.8) return Colors.orange;
    return AppColors.green;
  }

}
