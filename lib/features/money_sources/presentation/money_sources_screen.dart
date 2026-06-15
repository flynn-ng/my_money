import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/extensions/currency_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../data/money_source_model.dart';
import '../data/money_source_repository.dart';
import 'add_money_source_screen.dart';

class MoneySourcesBody extends ConsumerWidget {
  const MoneySourcesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(moneySourcesProvider);

    return sourcesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.amber, strokeWidth: 2)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(friendlyError(e), style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => ref.invalidate(moneySourcesProvider),
                child: Text(S.retry)),
          ],
        ),
      ),
      data: (sources) {
        if (sources.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💳', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                Text(S.noMoneySource,
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(S.noMoneySourceHint,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final total =
            sources.fold(0.0, (sum, s) => sum + s.currentBalance);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TotalCard(total: total),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _SourceCard(
                    source: sources[i],
                    index: i,
                    onEdited: () => ref.invalidate(moneySourcesProvider),
                  ),
                  childCount: sources.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.totalBalance,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    total.asCurrency,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: total >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.account_balance_wallet_outlined,
                size: 32, color: context.colors.textSecondary),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms),
    );
  }
}

class _SourceCard extends ConsumerWidget {
  final MoneySourceModel source;
  final int index;
  final VoidCallback onEdited;

  const _SourceCard({
    required this.source,
    required this.index,
    required this.onEdited,
  });

  String _typeLabel(String type) {
    switch (type) {
      case 'cash':
        return S.sourceTypeCash;
      case 'bank':
        return S.sourceTypeBank;
      case 'property':
        return S.sourceTypeProperty;
      case 'investment':
        return S.sourceTypeInvestment;
      default:
        return S.sourceTypeOther;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = source.colorValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () =>
            AddMoneySourceScreen.show(context, source: source)
                .then((_) => onEdited()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(source.icon,
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              // Name + type badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel(source.type),
                        style: TextStyle(
                          fontSize: 11,
                          color: c,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    source.currentBalance.asCurrency,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: source.currentBalance >= 0
                          ? AppColors.green
                          : AppColors.red,
                    ),
                  ),
                  if (source.initialBalance != source.currentBalance)
                    Text(
                      source.initialBalance.asCompactCurrency,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ).animate(delay: (index * 60).ms)
            .fadeIn(duration: 250.ms)
            .slideX(begin: 0.04),
      ),
    );
  }
}
