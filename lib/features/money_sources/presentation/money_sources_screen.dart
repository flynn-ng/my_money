import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class MoneySourcesBody extends ConsumerStatefulWidget {
  const MoneySourcesBody({super.key});

  @override
  ConsumerState<MoneySourcesBody> createState() => _MoneySourcesBodyState();
}

class _MoneySourcesBodyState extends ConsumerState<MoneySourcesBody> {
  List<MoneySourceModel>? _orderedSources;
  List<String>? _lastSourceIds;

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == 0) return; // total card is pinned
    if (newIndex == 0) newIndex = 1;

    final srcOld = oldIndex - 1;
    final srcNew = newIndex - 1;

    HapticFeedback.selectionClick();
    setState(() {
      final item = _orderedSources!.removeAt(srcOld);
      _orderedSources!.insert(srcNew, item);
    });

    final ids = _orderedSources!.map((s) => s.id).toList();
    ref
        .read(moneySourceRepositoryProvider)
        .updateSortOrders(ids)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(moneySourcesProvider);

    return sourcesAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.black, strokeWidth: 2)),
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

        final ids = sources.map((s) => s.id).toList();
        if (_lastSourceIds == null || !_listsEqual(_lastSourceIds!, ids)) {
          _orderedSources = List<MoneySourceModel>.from(sources);
          _lastSourceIds = ids;
        }

        final total =
            _orderedSources!.fold(0.0, (sum, s) => sum + s.currentBalance);

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          onReorderItem: _onReorder,
          itemCount: _orderedSources!.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                key: const ValueKey('__total__'),
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: _TotalCard(total: total),
              );
            }
            final s = _orderedSources![index - 1];
            return _SourceCard(
              key: ValueKey(s.id),
              source: s,
              dragIndex: index,
              onEdited: () => ref.invalidate(moneySourcesProvider),
            );
          },
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
          boxShadow: [
            BoxShadow(color: context.colors.cardShadow, blurRadius: 8, offset: Offset(0, 2))
          ],
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
  final int dragIndex;
  final VoidCallback onEdited;

  const _SourceCard({
    super.key,
    required this.source,
    required this.dragIndex,
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
        onTap: () => AddMoneySourceScreen.show(context, source: source)
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
                    S.sourceCurrentBalance,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.currentBalance.asCurrency,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: source.currentBalance >= 0
                          ? AppColors.green
                          : AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.sourceInitialBalance,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.initialBalance.asCurrency,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Drag handle
              ReorderableDragStartListener(
                index: dragIndex,
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: context.colors.textSecondary.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
