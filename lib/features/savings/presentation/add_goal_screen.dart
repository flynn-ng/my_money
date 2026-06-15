import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/thousands_formatter.dart';
import '../../../core/widgets/sheet_wrapper.dart';
import '../../auth/data/auth_repository.dart';
import '../data/savings_repository.dart';

const _goalIcons = [
  '🏠', '🚗', '✈️', '💍', '🎓', '💻', '🏦', '🎉', '🌊', '🍼', '🐕', '🏋️'
];

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showAppSheet(
      context: context,
      content: const AddGoalScreen(),
      initialChildSize: 0.78,
    );
  }

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  String _icon = '🏦';
  DateTime? _deadline;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    setState(() => _loading = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      await ref.read(savingsRepositoryProvider).createGoal(
            householdId: profile!.householdId!,
            name: values['name'] as String,
            icon: _icon,
            targetAmount: (values['target'] as num?)?.toDouble() ?? 0,
            deadline: _deadline,
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
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(S.addGoal, style: AppTextStyles.titleMedium),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalIcons.map((icon) {
                final isSelected = _icon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.amberLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.amber : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(16),
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'name',
                    decoration: InputDecoration(
                      labelText: S.goalName,
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                  const Gap(12),
                  FormBuilderTextField(
                    name: 'target',
                    decoration: InputDecoration(
                      labelText: S.targetAmount,
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
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
                  const Gap(12),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      DateTime temp = _deadline ?? now.add(const Duration(days: 30));
                      await showCupertinoModalPopup<void>(
                        context: context,
                        builder: (modalCtx) => Container(
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
                                    if (_deadline != null)
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        onPressed: () {
                                          setState(() => _deadline = null);
                                          Navigator.pop(modalCtx);
                                        },
                                        child: Text(S.clearDate,
                                            style: const TextStyle(
                                                color: CupertinoColors.destructiveRed)),
                                      ),
                                    const Spacer(),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      onPressed: () {
                                        setState(() => _deadline = temp);
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
                                  initialDateTime: temp,
                                  minimumDate: now,
                                  maximumDate: now.add(const Duration(days: 365 * 10)),
                                  onDateTimeChanged: (d) => temp = d,
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).padding.bottom),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _deadline != null ? _deadline!.fullDate : S.noDeadline,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: _deadline != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (_deadline != null)
                            GestureDetector(
                              onTap: () => setState(() => _deadline = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                  : Text(S.save,
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
