import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../l10n/app_strings.dart';
import '../utils/error_handler.dart';

class ErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorDisplay({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(S.somethingWrong, style: context.tsTitleMedium),
            const SizedBox(height: 4),
            Text(friendlyError(error), style: context.tsBodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: context.colors.textPrimary),
                child: Text(S.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
