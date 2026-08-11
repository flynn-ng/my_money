import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../data/locale_provider.dart';
import '../data/theme_provider.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile_model.dart';
import '../../household/presentation/widgets/household_switcher_sheet.dart';
import '../../notifications/push_subscription_service.dart';
import '../../pwa/presentation/install_guide_sheet.dart';
import '../../pwa/pwa_install_service.dart';
import 'widgets/avatar_picker_sheet.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => AlertDialog(
        title: Text(S.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(S.signOut),
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
      backgroundColor: context.colors.background,
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
                      GestureDetector(
                        onTap: () => AvatarPickerSheet.show(
                          context,
                          currentEmoji: profile.avatarEmoji,
                          onSelect: (emoji) async {
                            await ref
                                .read(authRepositoryProvider)
                                .updateAvatarEmoji(profile.id, emoji);
                            ref.invalidate(currentProfileProvider);
                          },
                        ),
                        child: Stack(
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
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.surface, width: 1.5),
                                ),
                                child: const Icon(Icons.edit,
                                    size: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
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
                labelColor: context.colors.textPrimary,
                unselectedLabelColor: context.colors.textSecondary,
                indicatorColor: context.colors.textPrimary,
                indicatorWeight: 2,
                labelStyle: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: [
                  Tab(text: S.tabProfile),
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
      error: (_, _) => Center(child: Text(S.somethingWrong)),
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

class _SettingsTab extends ConsumerWidget {
  final VoidCallback onSignOut;
  const _SettingsTab({required this.onSignOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final householdsAsync = ref.watch(myHouseholdsProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 32),
      children: [
        _Card(
          children: [
            _Row(
              icon: Icons.home_outlined,
              label: S.householdSwitchRow,
              value: householdsAsync.when(
                loading: () => '',
                error: (_, _) => '',
                data: (hs) => hs.length > 1 ? '${hs.length}' : '',
              ),
              onTap: () => HouseholdSwitcherSheet.show(context),
            ),
            const _Divider(),
            _Row(
              icon: Icons.category_outlined,
              label: S.manageCategories,
              value: '',
              onTap: () => context.push('/categories'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          children: [
            _SegmentRow(
              icon: Icons.brightness_6_outlined,
              label: S.settingsAppearance,
              segments: [
                (ThemeMode.system, Icons.brightness_auto_outlined, S.themeSystem),
                (ThemeMode.light, Icons.light_mode_outlined, S.themeLight),
                (ThemeMode.dark, Icons.dark_mode_outlined, S.themeDark),
              ],
              selected: themeMode,
              onChanged: (v) =>
                  ref.read(themeModeProvider.notifier).set(v as ThemeMode),
            ),
            const _Divider(),
            _SegmentRow(
              icon: Icons.language_outlined,
              label: S.settingsLanguage,
              segments: [
                (const Locale('vi'), null, S.languageVietnamese),
                (const Locale('en'), null, S.languageEnglish),
              ],
              selected: locale,
              onChanged: (v) =>
                  ref.read(localeProvider.notifier).set(v as Locale),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (kIsWeb) ...[
          // Nothing to install when the app is already running standalone.
          if (!ref.read(pwaInstallServiceProvider).isInstalled) ...[
            _Card(
              children: [
                _Row(
                  icon: Icons.add_to_home_screen,
                  label: S.installGuideRow,
                  value: '',
                  onTap: () => InstallGuideSheet.show(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _Card(children: [const _NotificationToggleRow()]),
          const SizedBox(height: 16),
        ],
        _Card(
          children: [
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
          label: Text(S.signOut),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: context.colors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<(Object, IconData?, String)> segments;
  final Object selected;
  final ValueChanged<Object> onChanged;

  const _SegmentRow({
    required this.icon,
    required this.label,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.colors.textSecondary),
              const SizedBox(width: 12),
              Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Object>(
              style: SegmentedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: AppTextStyles.labelSmall,
                selectedBackgroundColor: context.colors.textPrimary,
                selectedForegroundColor: context.colors.background,
                foregroundColor: context.colors.textSecondary,
                side: BorderSide(color: context.colors.divider),
              ),
              segments: segments
                  .map((s) => ButtonSegment<Object>(
                        value: s.$1,
                        icon: s.$2 != null ? Icon(s.$2, size: 14) : null,
                        label: Text(s.$3),
                      ))
                  .toList(),
              selected: {selected},
              onSelectionChanged: (set) => onChanged(set.first),
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
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

class _NotificationToggleRow extends ConsumerStatefulWidget {
  const _NotificationToggleRow();

  @override
  ConsumerState<_NotificationToggleRow> createState() =>
      _NotificationToggleRowState();
}

class _NotificationToggleRowState
    extends ConsumerState<_NotificationToggleRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.read(pushSubscriptionServiceProvider);
    if (!service.isSupported) return const SizedBox.shrink();

    final subscribedAsync = ref.watch(pushSubscribedProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(S.pushNotifications, style: AppTextStyles.bodyMedium),
          ),
          subscribedAsync.when(
            loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => const SizedBox.shrink(),
            data: (isSubscribed) => _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: isSubscribed,
                    activeThumbColor: AppColors.black,
                    onChanged: profileAsync.value?.householdId == null
                        ? null
                        : (val) => _toggle(val, profileAsync.value!),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool enable, ProfileModel profile) async {
    if (_loading) return;
    setState(() => _loading = true);

    final service = ref.read(pushSubscriptionServiceProvider);
    if (enable) {
      final ok = await service.subscribe(
        profileId: profile.id,
        householdId: profile.householdId!,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.pushPermissionDenied)),
        );
      }
    } else {
      await service.unsubscribe(profileId: profile.id);
    }

    if (mounted) {
      setState(() => _loading = false);
      ref.invalidate(pushSubscribedProvider);
    }
  }
}
