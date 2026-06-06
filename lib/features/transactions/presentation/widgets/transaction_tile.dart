import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/extensions/currency_ext.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/transaction_model.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _pressed = false;

  Future<bool?> _showDeleteConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(S.deleteTransactionTitle),
        content: const Text(S.deleteTransactionContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.delete),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(TapUpDetails details) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx + 1,
        details.globalPosition.dy + 1,
      ),
      items: [
        const PopupMenuItem(value: 'edit', child: Text(S.editTransaction)),
        const PopupMenuItem(
          value: 'delete',
          child: Text(S.delete, style: TextStyle(color: AppColors.red)),
        ),
      ],
    );
    if (!mounted) return;
    if (result == 'edit') widget.onTap?.call();
    if (result == 'delete') {
      final confirmed = await _showDeleteConfirm();
      if (confirmed == true) widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isExpense = tx.txType == TransactionType.expense;
    final color = AppColors.fromHex(tx.categoryColor ?? '#9CA3AF');

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteConfirm(),
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onSecondaryTapUp: _showContextMenu,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _pressed
                      ? AppColors.cardShadow.withValues(alpha: 0.04)
                      : AppColors.cardShadow,
                  blurRadius: _pressed ? 2 : 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(tx.categoryIcon ?? '📦',
                        style: const TextStyle(fontSize: 20)),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      duration: 350.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 150.ms),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.categoryName ?? S.otherCategory,
                          style: AppTextStyles.bodyLarge),
                      if (tx.notes != null && tx.notes!.isNotEmpty)
                        Text(tx.notes!,
                            style: AppTextStyles.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      if (tx.paidByName != null && tx.paidByName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              tx.paidByName!,
                              style: AppTextStyles.labelSmall
                                  .copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 60.ms, duration: 200.ms),
                ),
                Text(
                  '${isExpense ? '-' : '+'}${tx.amount.asCurrency}',
                  style: AppTextStyles.titleMedium.copyWith(
                      color: isExpense ? AppColors.red : AppColors.green),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 200.ms)
                    .slideX(begin: 0.1, curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
