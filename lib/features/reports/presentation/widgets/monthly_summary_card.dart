import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../reports/data/reports_repository.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlyTotal totals;
  const MonthlySummaryCard({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.textPrimary,
            context.colors.textPrimary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
                label: S.totalIncome, amount: totals.income, icon: '📈'),
          ),
          Container(
              width: 1,
              height: 50,
              color: context.colors.surface.withValues(alpha: 0.3)),
          Expanded(
            child: _SummaryItem(
                label: S.totalExpense, amount: totals.expense, icon: '📉'),
          ),
          Container(
              width: 1,
              height: 50,
              color: context.colors.surface.withValues(alpha: 0.3)),
          Expanded(
            child: _SummaryItem(
                label: S.netSaved,
                amount: totals.net,
                icon: totals.net >= 0 ? '✨' : '⚠️'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final String icon;

  const _SummaryItem({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(amount.asCompactCurrency,
            style: AppTextStyles.titleMedium
                .copyWith(color: context.colors.surface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: context.colors.surface.withValues(alpha: 0.8))),
      ],
    );
  }
}
