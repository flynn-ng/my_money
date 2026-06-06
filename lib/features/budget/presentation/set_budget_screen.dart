import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/thousands_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../../transactions/data/category_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/budget_model.dart';
import '../data/budget_repository.dart';

class SetBudgetScreen extends ConsumerStatefulWidget {
  final BudgetModel? existing;
  const SetBudgetScreen({super.key, this.existing});

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  CategoryModel? _selectedCategory;

  Future<void> _submit() async {
    if (_selectedCategory == null && widget.existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.selectCategory)),
      );
      return;
    }
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    setState(() => _loading = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      final selectedMonth = ref.read(selectedMonthProvider);
      await ref.read(budgetRepositoryProvider).setBudget(
            householdId: profile!.householdId!,
            categoryId: widget.existing?.categoryId ?? _selectedCategory!.id,
            month: selectedMonth,
            amount: (values['amount'] as num?)?.toDouble() ?? 0,
          );
      ref.invalidate(budgetsProvider);
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(S.setBudgetTitle, style: AppTextStyles.titleMedium),
        leading: CloseButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.existing == null)
              categoriesAsync.when(
                loading: () => const CircularProgressIndicator(color: AppColors.amber),
                error: (e, _) => Text(friendlyError(e)),
                data: (cats) {
                  final expenseCats = cats.where((c) => c.type != 'income').toList();
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: expenseCats.map((cat) {
                      final isSelected = _selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.colorValue.withValues(alpha: 0.18)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? cat.colorValue : AppColors.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 5),
                              Text(cat.name,
                                  style: AppTextStyles.bodyLarge.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            else
              Row(
                children: [
                  Text(widget.existing!.categoryIcon ?? '📦',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(widget.existing!.categoryName ?? '',
                      style: AppTextStyles.titleMedium),
                ],
              ),
            const Gap(16),
            FormBuilder(
              key: _formKey,
              child: FormBuilderTextField(
                name: 'amount',
                decoration: const InputDecoration(
                  labelText: S.monthlyLimit,
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                initialValue: widget.existing?.amount.toStringAsFixed(0),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorFormatter()],
                style: AppTextStyles.amountLarge,
                valueTransformer: (v) =>
                    ThousandsSeparatorFormatter.parse(v ?? ''),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.min(1),
                ]),
              ),
            ),
            const Gap(20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(S.save,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
