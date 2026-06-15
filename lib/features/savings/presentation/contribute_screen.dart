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
import '../../../core/widgets/sheet_wrapper.dart';
import '../../auth/data/auth_repository.dart';
import '../data/savings_model.dart';
import '../data/savings_repository.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  final SavingsGoalModel goal;
  const ContributeScreen({super.key, required this.goal});

  static Future<void> show(BuildContext context, {required SavingsGoalModel goal}) {
    return showAppSheet(
      context: context,
      content: ContributeScreen(goal: goal),
      initialChildSize: 0.62,
    );
  }

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  bool _isWithdrawal = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final amount = (values['amount'] as num?)?.toDouble() ?? 0;
    if (_isWithdrawal && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.withdrawExceedsBalance), backgroundColor: AppColors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      await ref.read(savingsRepositoryProvider).contribute(
            goalId: widget.goal.id,
            addedById: profile!.id,
            amount: _isWithdrawal ? -amount : amount,
            notes: values['notes'] as String?,
          );
      ref.invalidate(savingsGoalsProvider);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Row(
            children: [
              Text('${widget.goal.icon}  ${widget.goal.name}',
                  style: AppTextStyles.titleMedium),
              const Spacer(),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: S.contribute,
                        icon: Icons.add_circle_outline,
                        selected: !_isWithdrawal,
                        color: AppColors.green,
                        onTap: () => setState(() => _isWithdrawal = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeButton(
                        label: S.withdraw,
                        icon: Icons.remove_circle_outline,
                        selected: _isWithdrawal,
                        color: AppColors.red,
                        onTap: () => setState(() => _isWithdrawal = true),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      FormBuilderTextField(
                        name: 'amount',
                        decoration: InputDecoration(
                          labelText: S.contributeAmount,
                          prefixIcon: const Icon(Icons.payments_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsSeparatorFormatter()],
                        style: AppTextStyles.amountLarge,
                        valueTransformer: (v) =>
                            ThousandsSeparatorFormatter.parse(v ?? ''),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.min(0.01),
                        ]),
                      ),
                      const Gap(12),
                      FormBuilderTextField(
                        name: 'notes',
                        decoration: InputDecoration(
                          labelText: S.notes,
                          prefixIcon: const Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                      backgroundColor: _isWithdrawal ? AppColors.red : AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isWithdrawal ? S.withdraw : S.contribute,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 16),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
