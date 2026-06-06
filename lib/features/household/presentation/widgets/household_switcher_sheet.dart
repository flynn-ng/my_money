import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/sheet_wrapper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/household_model.dart';

class HouseholdSwitcherSheet extends ConsumerStatefulWidget {
  const HouseholdSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, _) => const SheetWrapper(child: HouseholdSwitcherSheet()),
      ),
    );
  }

  @override
  ConsumerState<HouseholdSwitcherSheet> createState() =>
      _HouseholdSwitcherSheetState();
}

class _HouseholdSwitcherSheetState
    extends ConsumerState<HouseholdSwitcherSheet> {
  bool _joiningMode = false;
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _switchTo(HouseholdModel household, String userId) async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).switchHousehold(userId, household.id);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(myHouseholdsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leave(HouseholdModel household, String activeId, String userId,
      List<HouseholdModel> all) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.leaveHouseholdTitle),
        content: Text(S.leaveHouseholdContent(household.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(S.leaveHousehold),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      // If leaving the active household and others exist, switch first
      if (household.id == activeId) {
        final next = all.firstWhere((h) => h.id != household.id,
            orElse: () => household);
        if (next.id != household.id) {
          await ref
              .read(authRepositoryProvider)
              .switchHousehold(userId, next.id);
        }
      }
      await ref
          .read(authRepositoryProvider)
          .leaveHousehold(userId, household.id);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(myHouseholdsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).joinHousehold(code, userId);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(myHouseholdsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createNew() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).createHousehold(userId);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(myHouseholdsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdsAsync = ref.watch(myHouseholdsProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final activeId = profileAsync.value?.householdId ?? '';
    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(S.switchHouseholdTitle, style: AppTextStyles.titleMedium),
        ),
        Expanded(
          child: householdsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.black)),
            error: (_, _) => Center(child: Text(S.somethingWrong)),
            data: (households) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                ...households.map((h) {
                  final isActive = h.id == activeId;
                  return _HouseholdTile(
                    household: h,
                    isActive: isActive,
                    loading: _loading,
                    onTap: isActive
                        ? null
                        : () => _switchTo(h, userId),
                    onLeave: () =>
                        _leave(h, activeId, userId, households),
                  );
                }),
                const SizedBox(height: 16),
                if (_joiningMode) ...[
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: S.inviteCodeHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: _loading ? null : _join,
                        icon: const Icon(Icons.check),
                      ),
                    ),
                    onSubmitted: (_) => _join(),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setState(() => _joiningMode = false),
                    child: Text(S.cancel),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed:
                        _loading ? null : () => setState(() => _joiningMode = true),
                    icon: const Icon(Icons.group_add_outlined, size: 18),
                    label: Text(S.joinAnotherHousehold),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _createNew,
                    icon: const Icon(Icons.add_home_outlined, size: 18),
                    label: Text(S.createNewHousehold),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  final HouseholdModel household;
  final bool isActive;
  final bool loading;
  final VoidCallback? onTap;
  final VoidCallback onLeave;

  const _HouseholdTile({
    required this.household,
    required this.isActive,
    required this.loading,
    required this.onTap,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? context.colors.textPrimary
                : context.colors.divider,
            width: isActive ? 2 : 1,
          ),
        ),
        child: const Icon(Icons.home_outlined, size: 20),
      ),
      title: Text(household.name, style: AppTextStyles.bodyMedium),
      subtitle: isActive
          ? Text(S.activeHousehold,
              style: AppTextStyles.labelSmall
                  .copyWith(color: context.colors.textPrimary))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Icon(Icons.check_circle_rounded,
                size: 20, color: context.colors.textPrimary)
          else
            TextButton(
              onPressed: loading ? null : onTap,
              child: Text(S.switchHouseholdTitle
                  .split(' ')
                  .first), // "Chuyển" / "Switch"
            ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: loading ? null : onLeave,
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(S.leaveHousehold),
          ),
        ],
      ),
      onTap: loading ? null : onTap,
    );
  }
}
