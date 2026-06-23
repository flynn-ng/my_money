import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/thousands_formatter.dart';
import '../../../core/widgets/sheet_wrapper.dart';
import '../../auth/data/auth_repository.dart';
import '../data/category_model.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import '../../money_sources/data/money_source_model.dart';
import '../../money_sources/data/money_source_repository.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  static Future<void> show(BuildContext context, {TransactionModel? transaction}) {
    return showAppSheet(
      context: context,
      content: AddTransactionScreen(transaction: transaction),
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
    );
  }

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountFocus = FocusNode();
  bool _loading = false;
  TransactionType _type = TransactionType.expense;
  CategoryModel? _selectedCategory;
  MoneySourceModel? _selectedSource;
  DateTime _date = DateTime.now();
  bool _categoriesInitialized = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transaction!;
      _type = tx.txType;
      _date = tx.date;
      final isWhole = tx.amount == tx.amount.truncateToDouble();
      final rawText = isWhole
          ? tx.amount.toStringAsFixed(0)
          : tx.amount.toString();
      _amountController.text =
          ThousandsSeparatorFormatter().formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: rawText),
      ).text;
      _notesController.text = tx.notes ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing) _amountFocus.requestFocus();
      ref.read(moneySourcesProvider.future).then((sources) {
        if (!mounted || sources.isEmpty) return;
        setState(() {
          if (_isEditing) {
            final match = sources.where((s) => s.id == widget.transaction!.sourceId);
            if (match.isNotEmpty) _selectedSource = match.first;
          } else {
            _selectedSource = sources.first;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.selectCategory)),
      );
      return;
    }
    final amount = ThousandsSeparatorFormatter.parse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.invalidAmount)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      if (_isEditing) {
        await repo.updateTransaction(widget.transaction!.id, {
          'category_id': _selectedCategory!.id,
          'type': _type.name,
          'amount': amount,
          'date': _date.toIso8601String().substring(0, 10),
          'notes': notes,
          'source_id': _selectedSource?.id,
        });
      } else {
        final profile = await ref.read(currentProfileProvider.future);
        await repo.addTransaction(
          TransactionModel(
            id: const Uuid().v4(),
            householdId: profile!.householdId!,
            paidById: profile.id,
            categoryId: _selectedCategory!.id,
            type: _type.name,
            amount: amount,
            date: _date,
            notes: notes,
            createdAt: DateTime.now(),
            sourceId: _selectedSource?.id,
          ),
        );
      }
      ref.invalidate(transactionsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _typeColor => _type == TransactionType.expense ? AppColors.red : AppColors.green;

  void _switchType(TransactionType newType) {
    if (_type == newType) return;
    HapticFeedback.lightImpact();
    setState(() {
      _type = newType;
      _selectedCategory = null;
      _categoriesInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 400) _switchType(TransactionType.expense);
        if (v < -400) _switchType(TransactionType.income);
      },
      child: Column(
        children: [
          // Top bar
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
              child: Row(
                children: [
                  // Type toggle — minimal pills
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _Pill(
                          label: S.expense,
                          selected: _type == TransactionType.expense,
                          color: AppColors.red,
                          onTap: () => _switchType(TransactionType.expense),
                        ),
                        _Pill(
                          label: S.income,
                          selected: _type == TransactionType.income,
                          color: AppColors.green,
                          onTap: () => _switchType(TransactionType.income),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: context.colors.textSecondary,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),

            const SizedBox(height: 24),

            // Big amount display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(S.amount,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: context.colors.textSecondary)),
                  const SizedBox(height: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorFormatter()],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: _typeColor,
                        letterSpacing: -1,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textSecondary.withValues(alpha: 0.3),
                          letterSpacing: -1,
                        ),
                        suffixText: '₫',
                        suffixStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: _typeColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left,
                          size: 14,
                          color: _type == TransactionType.income
                              ? context.colors.textSecondary.withValues(alpha: 0.4)
                              : Colors.transparent),
                      const SizedBox(width: 4),
                      Text(
                        _type == TransactionType.expense ? S.income : S.expense,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 14,
                          color: _type == TransactionType.expense
                              ? context.colors.textSecondary.withValues(alpha: 0.4)
                              : Colors.transparent),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),

            const SizedBox(height: 12),
            Divider(height: 1, color: context.colors.divider),

            // Category + date row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Date button
                  GestureDetector(
                    onTap: () async {
                      DateTime temp = _date;
                      await showCupertinoModalPopup<void>(
                        context: context,
                        builder: (modalCtx) {
                          final today = DateTime.now();
                          final yesterday = today.subtract(const Duration(days: 1));
                          return Container(
                            color: CupertinoColors.systemBackground.resolveFrom(context),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Toolbar
                                Container(
                                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: context.colors.divider, width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        onPressed: () => Navigator.pop(modalCtx),
                                        child: Text(S.cancel,
                                            style: const TextStyle(
                                                color: CupertinoColors.systemGrey)),
                                      ),
                                      const Spacer(),
                                      _QuickDateChip(
                                        label: S.today,
                                        onTap: () {
                                          setState(() => _date = today);
                                          Navigator.pop(modalCtx);
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      _QuickDateChip(
                                        label: S.yesterday,
                                        onTap: () {
                                          setState(() => _date = yesterday);
                                          Navigator.pop(modalCtx);
                                        },
                                      ),
                                      const Spacer(),
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        onPressed: () {
                                          setState(() => _date = temp);
                                          Navigator.pop(modalCtx);
                                        },
                                        child: Text(S.done,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 216,
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: _date,
                                    maximumDate: today,
                                    minimumDate: DateTime(2020),
                                    onDateTimeChanged: (d) => temp = d,
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).padding.bottom),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 5),
                          Text(_date.shortDate,
                              style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Notes field inline
                  Expanded(
                    child: TextField(
                      controller: _notesController,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: S.notes,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            Divider(height: 1, color: context.colors.divider),

            // Source picker (only shown when sources exist)
            _SourcePickerRow(
              selected: _selectedSource,
              onSelected: (s) {
                HapticFeedback.selectionClick();
                setState(() => _selectedSource = s);
              },
            ),

            const SizedBox(height: 4),

            // Categories
            Expanded(
              child: categoriesAsync.when(
                loading: () => Center(
                    child: CircularProgressIndicator(
                        color: context.colors.textPrimary, strokeWidth: 2)),
                error: (e, st) => Center(child: Text(friendlyError(e))),
                data: (cats) {
                  if (_isEditing && !_categoriesInitialized) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final match = cats.where((c) => c.id == widget.transaction!.categoryId);
                      if (match.isNotEmpty) {
                        setState(() {
                          _selectedCategory = match.first;
                          _categoriesInitialized = true;
                        });
                      }
                    });
                  }
                  final filtered =
                      cats.where((c) => c.type == _type.name || c.type == 'both').toList();
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final cat = filtered[i];
                      final selected = _selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.colorValue.withValues(alpha: 0.15)
                                : context.colors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? cat.colorValue : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? cat.colorValue
                                      : context.colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: (i * 15).ms)
                          .fadeIn(duration: 200.ms)
                          .scale(
                            begin: const Offset(0.85, 0.85),
                            curve: Curves.easeOut,
                          );
                    },
                  );
                },
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? S.update : S.save,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            ),
          ],
        ),
    );
  }
}

class _SourcePickerRow extends ConsumerWidget {
  final MoneySourceModel? selected;
  final ValueChanged<MoneySourceModel?> onSelected;

  const _SourcePickerRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(moneySourcesProvider);
    return sourcesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (sources) {
        if (sources.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                S.selectSource,
                style: AppTextStyles.labelSmall.copyWith(
                    color: context.colors.textSecondary),
              ),
            ),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: sources.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = sources[i];
                  return _SourceCard(
                    source: s,
                    selected: selected?.id == s.id,
                    onTap: () => onSelected(s),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: context.colors.divider),
          ],
        );
      },
    );
  }
}

class _SourceCard extends StatelessWidget {
  final MoneySourceModel source;
  final bool selected;
  final VoidCallback onTap;

  const _SourceCard({
    required this.source,
    required this.selected,
    required this.onTap,
  });

  String _compactBalance(double amount) {
    final abs = amount.abs();
    String formatted;
    if (abs >= 1000000000) {
      formatted = '${(abs / 1000000000).toStringAsFixed(1)}tỷ';
    } else if (abs >= 1000000) {
      final v = abs / 1000000;
      formatted = v == v.truncateToDouble()
          ? '${v.toStringAsFixed(0)}tr'
          : '${v.toStringAsFixed(1)}tr';
    } else if (abs >= 1000) {
      formatted = '${(abs / 1000).toStringAsFixed(0)}k';
    } else {
      formatted = abs.toStringAsFixed(0);
    }
    return amount < 0 ? '-$formatted₫' : '$formatted₫';
  }

  @override
  Widget build(BuildContext context) {
    final color = source.colorValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : context.colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(source.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              source.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : context.colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              _compactBalance(source.currentBalance),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected
                    ? color.withValues(alpha: 0.8)
                    : context.colors.textSecondary.withValues(alpha: 0.55),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context), width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel.resolveFrom(context))),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
