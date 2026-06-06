import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile_model.dart';

/// Full-page wrapper used as a bottom-nav destination.
class HouseholdPage extends StatelessWidget {
  const HouseholdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 8),
              child: Text(S.tabHousehold, style: AppTextStyles.titleLarge),
            ),
            const Expanded(child: HouseholdScreen()),
          ],
        ),
      ),
    );
  }
}

/// Embeds as a scrollable body (no Scaffold wrapper).
class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  bool _codeVisible = false;

  Future<void> _showRenameDialog(String householdId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.editHouseholdName),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: S.householdNameHint),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              Navigator.of(ctx).pop();
              if (newName.isEmpty || newName == currentName) return;
              await ref
                  .read(authRepositoryProvider)
                  .updateHouseholdName(householdId, newName);
              ref.invalidate(currentHouseholdProvider);
            },
            child: const Text(S.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final membersAsync = ref.watch(householdMembersProvider);
    final myId = ref.watch(currentProfileProvider).value?.id;

    return householdAsync.when(
      loading: () => const LoadingOverlay(),
      error: (_, _) => const Center(child: Text(S.somethingWrong)),
      data: (household) {
        if (household == null) return const SizedBox.shrink();
        return ListView(
          padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 32),
          children: [
            const SizedBox(height: 4),
                // ── Household card ──────────────────────────────────
                _Card(
                  children: [
                    // Name row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.home_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.householdLabel,
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 2),
                                Text(household.name,
                                    style: AppTextStyles.bodyLarge),
                              ],
                            ),
                          ),
                          _TinyButton(
                            icon: Icons.edit_outlined,
                            onTap: () => _showRenameDialog(
                                household.id, household.name),
                          ),
                        ],
                      ),
                    ),
                    const _Divider(),
                    // Invite code row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.vpn_key_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.inviteCodeLabel,
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 2),
                                Text(
                                  _codeVisible
                                      ? household.inviteCode
                                      : '••••••',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    letterSpacing: _codeVisible ? 2.0 : 4.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _TinyButton(
                            icon: _codeVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            onTap: () =>
                                setState(() => _codeVisible = !_codeVisible),
                          ),
                          const SizedBox(width: 8),
                          _TinyButton(
                            icon: Icons.copy_outlined,
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                  ClipboardData(text: household.inviteCode));
                              messenger.showSnackBar(const SnackBar(
                                content: Text(S.codeCopied),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.black,
                              ));
                            },
                          ),
                          const SizedBox(width: 8),
                          _TinyButton(
                            icon: Icons.share_outlined,
                            onTap: () => Share.share(S.shareInviteText(household.inviteCode)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Members ─────────────────────────────────────────
                membersAsync.when(
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (members) {
                    if (members.isEmpty) return const SizedBox.shrink();
                    if (members.length == 1) {
                      return _InviteBanner(inviteCode: household.inviteCode);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${S.householdMembers} (${members.length})',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _Card(
                          children: [
                            for (int i = 0; i < members.length; i++) ...[
                              if (i > 0) const _Divider(),
                              _MemberTile(
                                profile: members[i],
                                isMe: members[i].id == myId,
                                onRemove: members[i].id == myId
                                    ? null
                                    : () async {
                                        await ref
                                            .read(authRepositoryProvider)
                                            .removeHouseholdMember(
                                                members[i].id);
                                        ref.invalidate(householdMembersProvider);
                                      },
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
          ],
        );
      },
    );
  }
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final ProfileModel profile;
  final bool isMe;
  final VoidCallback? onRemove;
  const _MemberTile({required this.profile, required this.isMe, this.onRemove});

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.removeMemberTitle),
        content: Text(S.removeMemberContent(profile.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(S.removeMember),
          ),
        ],
      ),
    );
    if (confirmed == true) onRemove?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.divider, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(profile.avatarEmoji,
                style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(profile.displayName, style: AppTextStyles.bodyLarge),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(S.youSuffix,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
            )
          else if (onRemove != null)
            _TinyButton(
              icon: Icons.person_remove_outlined,
              onTap: () => _confirmRemove(context),
            ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 46),
      child: Divider(height: 1),
    );
  }
}

// ── Invite banner (shown when household has only 1 member) ────────────────────

class _InviteBanner extends StatelessWidget {
  final String inviteCode;
  const _InviteBanner({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: context.colors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const Text('👋', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(S.inviteBannerTitle, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(S.inviteBannerSubtitle,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Share.share(S.shareInviteText(inviteCode)),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text(S.shareInviteBtn),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TinyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
