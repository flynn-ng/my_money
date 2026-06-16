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
                          color: AppColors.textSecondary)),
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
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
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
                              ? AppColors.textSecondary.withValues(alpha: 0.4)
                              : Colors.transparent),
                      const SizedBox(width: 4),
                      Text(
                        _type == TransactionType.expense ? S.income : S.expense,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 14,
                          color: _type == TransactionType.expense
                              ? AppColors.textSecondary.withValues(alpha: 0.4)
                              : Colors.transparent),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),

            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.divider),

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
                                            color: AppColors.divider, width: 0.5)),
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
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textSecondary),
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

            Divider(height: 1, color: AppColors.divider),

            // Source picker (only shown when sources exist)
            _SourcePickerRow(
              selected: _selectedSource,
              onSelected: (s) => setState(() => _selectedSource = s),
            ),

            const SizedBox(height: 4),

            // Categories
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.black, strokeWidth: 2)),
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
                                : AppColors.cream,
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
                                      : AppColors.textSecondary,
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
        return SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: sources.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _SourceChip(
                    label: s.name,
                    icon: s.icon,
                    color: s.colorValue,
                    selected: selected?.id == s.id,
                    onTap: () => onSelected(s),
                  ),
                )).toList(),
          ),
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.textSecondary,
              ),
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
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
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
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
