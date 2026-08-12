import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_text_styles.dart';
import '../constants/app_theme.dart';
import '../l10n/app_strings.dart';
import '../offline/connectivity_provider.dart';

/// Thin strip shown above the app shell while the network is unreachable, so
/// cached numbers are never mistaken for live ones.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isOnlineProvider)) return const SizedBox.shrink();

    return Material(
      color: context.colors.divider,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 15, color: context.colors.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${S.offlineTitle} — ${S.offlineHint}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: context.colors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
