import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _loading = false;
  bool _showPassword = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: values['email'] as String,
            password: values['password'] as String,
          );
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
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(32),
              const Text('🐝', style: TextStyle(fontSize: 56), textAlign: TextAlign.center)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const Gap(12),
              Text(S.appName,
                      style: AppTextStyles.displayLarge
                          .copyWith(color: context.colors.textPrimary),
                      textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 150.ms),
              const Gap(4),
              Text(S.tagline,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.textSecondary),
                      textAlign: TextAlign.center)
                  .animate().fadeIn(delay: 250.ms),
              const Gap(40),
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: 'email',
                      decoration: InputDecoration(
                          labelText: S.email, prefixIcon: const Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                    const Gap(12),
                    FormBuilderTextField(
                      name: 'password',
                      decoration: InputDecoration(
                        labelText: S.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      obscureText: !_showPassword,
                      validator: FormBuilderValidators.required(),
                    ),
                  ],
                ),
              ),
              const Gap(20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                    backgroundColor: context.colors.textPrimary,
                    foregroundColor: context.colors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _loading
                    ? SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: context.colors.background))
                    : Text(S.signIn,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ).animate().fadeIn(delay: 400.ms),
              const Gap(8),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(S.noAccount,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: context.colors.textPrimary)),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
