import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile_model.dart';
import '../../household/presentation/household_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(S.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text(S.signOut),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final authAsync = ref.watch(authStateProvider);
    final email = authAsync.value?.session?.user.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Avatar strip ───────────────────────────────────────
            profileAsync.when(
              loading: () => const SizedBox(height: 96),
              error: (_, _) => const SizedBox(height: 96),
              data: (profile) {
                if (profile == null) return const SizedBox(height: 96);
                return Padding(
                  padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 8),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.divider, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(profile.avatarEmoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.displayName,
                                style: AppTextStyles.titleMedium),
                            const SizedBox(height: 2),
                            Text(email,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // ── Tab bar ────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.black,
                indicatorWeight: 2,
                labelStyle: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: const [
                  Tab(text: S.tabProfile),
                  Tab(text: S.tabHousehold),
                  Tab(text: S.tabSettings),
                ],
              ),
            ),
            // ── Tab content ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProfileTab(profileAsync: profileAsync),
                  const HouseholdScreen(),
                  _SettingsTab(onSignOut: _signOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final AsyncValue<ProfileModel?> profileAsync;

  const _ProfileTab({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    return profileAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.black)),
      error: (_, _) => const Center(child: Text(S.somethingWrong)),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return ListView(
          padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 32),
          children: [
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: S.memberSince,
              value: profile.createdAt.fullDate,
            ),
          ],
        );
      },
    );
  }
}

// ── Settings tab ─────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final VoidCallback onSignOut;
  const _SettingsTab({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 32),
      children: [
        _Card(
          children: [
            _Row(
              icon: Icons.category_outlined,
              label: S.manageCategories,
              value: '',
              onTap: () => context.push('/categories'),
            ),
            const _Divider(),
            _Row(
              icon: Icons.info_outline,
              label: S.settingsAbout,
              value: S.appName,
            ),
            const _Divider(),
            _Row(
              icon: Icons.tag_outlined,
              label: S.settingsAppVersion,
              value: S.appVersionValue,
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text(S.signOut),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}

// ── Shared layout widgets ─────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodyMedium),
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _Row(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMedium),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(value, style: AppTextStyles.bodyLarge),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
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
