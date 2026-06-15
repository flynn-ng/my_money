import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/thousands_formatter.dart';
import '../../../core/widgets/sheet_wrapper.dart';
import '../../auth/data/auth_repository.dart';
import '../data/money_source_model.dart';
import '../data/money_source_repository.dart';

class AddMoneySourceScreen extends ConsumerStatefulWidget {
  final MoneySourceModel? source;
  const AddMoneySourceScreen({super.key, this.source});

  static Future<void> show(BuildContext context, {MoneySourceModel? source}) {
    return showAppSheet(
      context: context,
      content: AddMoneySourceScreen(source: source),
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.97,
    );
  }

  @override
  ConsumerState<AddMoneySourceScreen> createState() =>
      _AddMoneySourceScreenState();
}

class _AddMoneySourceScreenState extends ConsumerState<AddMoneySourceScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  bool _loading = false;
  String _type = 'cash';
  String _icon = '💵';
  String _color = '#2196F3';

  bool get _isEditing => widget.source != null;

  static const _types = [
    ('cash', '💵'),
    ('bank', '🏦'),
    ('property', '🏠'),
    ('investment', '📈'),
    ('other', '💼'),
  ];

  static const _presetIcons = [
    '💵', '💳', '🏦', '🏠', '🚗', '📈', '💰', '💼', '🪙', '💎', '🏧', '📊',
  ];

  static const _presetColors = [
    '#2196F3', '#4CAF50', '#FF9800', '#E91E63',
    '#9C27B0', '#00BCD4', '#607D8B', '#F44336',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.source!;
      _nameController.text = s.name;
      _type = s.type;
      _icon = s.icon;
      _color = s.color;
      if (s.initialBalance > 0) {
        final isWhole = s.initialBalance == s.initialBalance.truncateToDouble();
        final raw = isWhole
            ? s.initialBalance.toStringAsFixed(0)
            : s.initialBalance.toString();
        _balanceController.text = ThousandsSeparatorFormatter()
            .formatEditUpdate(
              const TextEditingValue(),
              TextEditingValue(text: raw),
            )
            .text;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final balance =
        ThousandsSeparatorFormatter.parse(_balanceController.text.trim()) ?? 0;

    setState(() => _loading = true);
    try {
      final repo = ref.read(moneySourceRepositoryProvider);
      if (_isEditing) {
        await repo.updateSource(
          widget.source!.id,
          name: name,
          type: _type,
          icon: _icon,
          color: _color,
          initialBalance: balance,
        );
      } else {
        final profile = await ref.read(currentProfileProvider.future);
        await repo.createSource(
          householdId: profile!.householdId!,
          name: name,
          type: _type,
          icon: _icon,
          color: _color,
          initialBalance: balance,
        );
      }
      ref.invalidate(moneySourcesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteSourceTitle),
        content: Text(S.deleteSourceContent(widget.source!.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.delete,
                  style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(moneySourceRepositoryProvider)
          .deleteSource(widget.source!.id);
      ref.invalidate(moneySourcesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _activeColor {
    try {
      final hex = _color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

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
  Widget build(BuildContext context) {
    final accent = _activeColor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
          child: Row(
            children: [
              Text(
                _isEditing ? S.editMoneySource : S.addMoneySource,
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.red,
                  onPressed: _loading ? null : _delete,
                ),
              IconButton(
                icon: const Icon(Icons.close),
                color: context.colors.textSecondary,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: S.sourceName,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Text(_icon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                        minWidth: 0, minHeight: 0),
                  ),
                  style: AppTextStyles.bodyMedium,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                // Type
                Text(S.sourceType,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((t) {
                      final selected = _type == t.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _type = t.$1;
                              _icon = t.$2;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent.withValues(alpha: 0.12)
                                  : context.colors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? accent
                                    : context.colors.divider,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.$2,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  _typeLabel(t.$1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? accent
                                        : context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Icon
                Text('Icon',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetIcons.map((emoji) {
                    final selected = _icon == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.12)
                              : context.colors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? accent : context.colors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Color
                Text(S.sourceColor,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _presetColors.map((hex) {
                    final selected = _color == hex;
                    final c = Color(
                        int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(
                                  color: context.colors.textPrimary, width: 3)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: c.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1)
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Initial balance
                TextField(
                  controller: _balanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorFormatter()],
                  decoration: InputDecoration(
                    labelText: S.sourceInitialBalance,
                    suffixText: '₫',
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 28),

                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEditing ? S.update : S.save,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
