import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../data/auth_repository.dart';

class HouseholdLinkScreen extends ConsumerStatefulWidget {
  const HouseholdLinkScreen({super.key});

  @override
  ConsumerState<HouseholdLinkScreen> createState() => _HouseholdLinkScreenState();
}

class _HouseholdLinkScreenState extends ConsumerState<HouseholdLinkScreen> {
  bool _loading = false;
  bool _showJoinField = false;
  final _codeController = TextEditingController();
  String? _createdCode;

  Future<void> _createHousehold() async {
    setState(() => _loading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser!;
      final household = await ref.read(authRepositoryProvider).createHousehold(user.id);
      if (mounted) {
        setState(() => _createdCode = household.inviteCode);
        ref.invalidate(currentProfileProvider);
      }
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

  Future<void> _joinHousehold() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser!;
      await ref.read(authRepositoryProvider).joinHousehold(code, user.id);
      ref.invalidate(currentProfileProvider);
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(40),
              const Text('🏠', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
              const Gap(16),
              Text(S.householdSetup, style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
              const Gap(6),
              Text(S.householdSubtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const Gap(40),
              if (_createdCode != null)
                _InviteCodeCard(code: _createdCode!)
              else if (!_showJoinField) ...[
                FilledButton.icon(
                  onPressed: _loading ? null : _createHousehold,
                  icon: const Icon(Icons.add_home_outlined),
                  label: Text(S.createHousehold),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
                const Gap(12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showJoinField = true),
                  icon: const Icon(Icons.group_add_outlined),
                  label: Text(S.joinWithCode),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.amberDark,
                      side: const BorderSide(color: AppColors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: S.inviteCodeHint,
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _showJoinField = false),
                    ),
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
                const Gap(12),
                FilledButton(
                  onPressed: _loading ? null : _joinHousehold,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(S.joinBtn,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String code;
  const _InviteCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: context.colors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.green, size: 48),
          const Gap(12),
          Text(S.householdCreated, style: AppTextStyles.titleLarge),
          const Gap(6),
          Text(S.shareCodeHint, style: AppTextStyles.bodyMedium),
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(code,
                style: AppTextStyles.titleLarge.copyWith(
                    letterSpacing: 4, color: AppColors.amberDark)),
          ),
          const Gap(12),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.codeCopied)),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(S.copyCode),
          ),
          const Gap(4),
          Text(S.allSet, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
