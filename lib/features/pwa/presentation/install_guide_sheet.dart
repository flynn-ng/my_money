import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/sheet_wrapper.dart';

/// Step-by-step "add to home screen" instructions.
///
/// The card matching the visitor's platform is listed first and badged — on the
/// web build `defaultTargetPlatform` follows the browser, so an iPhone opens
/// straight onto the Safari steps.
class InstallGuideSheet extends StatelessWidget {
  const InstallGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAppSheet(
      context: context,
      content: const InstallGuideSheet(),
      initialChildSize: 0.8,
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;

    final ios = _Platform(
      icon: Icons.phone_iphone,
      title: S.installIosTitle,
      steps: S.installIosSteps,
      note: S.installIosNote,
      isCurrent: platform == TargetPlatform.iOS,
    );
    final android = _Platform(
      icon: Icons.android,
      title: S.installAndroidTitle,
      steps: S.installAndroidSteps,
      isCurrent: platform == TargetPlatform.android,
    );
    final desktop = _Platform(
      icon: Icons.desktop_windows_outlined,
      title: S.installDesktopTitle,
      steps: S.installDesktopSteps,
      isCurrent: platform != TargetPlatform.iOS &&
          platform != TargetPlatform.android,
    );

    final all = [ios, android, desktop];
    final platforms = [
      ...all.where((p) => p.isCurrent),
      ...all.where((p) => !p.isCurrent),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad(context), 8, hPad(context), 32),
      children: [
        Text(S.installGuideTitle, style: AppTextStyles.titleLarge),
        const SizedBox(height: 6),
        Text(S.installGuideSubtitle, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),
        for (final p in platforms) ...[
          _PlatformCard(platform: p),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(S.installGuideFooter, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ],
    );
  }
}

class _Platform {
  final IconData icon;
  final String title;
  final List<String> steps;
  final String? note;
  final bool isCurrent;

  const _Platform({
    required this.icon,
    required this.title,
    required this.steps,
    required this.isCurrent,
    this.note,
  });
}

class _PlatformCard extends StatelessWidget {
  final _Platform platform;
  const _PlatformCard({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: platform.isCurrent
            ? Border.all(color: context.colors.textPrimary, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(platform.icon, size: 18, color: context.colors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(platform.title, style: context.tsTitleMedium),
              ),
              if (platform.isCurrent) const _CurrentBadge(),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < platform.steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _Step(number: i + 1, text: platform.steps[i]),
          ],
          if (platform.note != null) ...[
            const SizedBox(height: 12),
            Text(platform.note!,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.divider,
            shape: BoxShape.circle,
          ),
          child: Text('$number',
              style: AppTextStyles.labelSmall
                  .copyWith(color: context.colors.textPrimary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: context.tsBodyLarge),
          ),
        ),
      ],
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(S.installGuideYourDevice, style: AppTextStyles.labelSmall),
    );
  }
}
