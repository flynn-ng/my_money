import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';

/// Unified header for modal bottom sheets: title on the left, an optional
/// [trailing] widget, and a close button on the right. Keeps the add/edit
/// sheets (transaction / budget / goal) visually consistent.
class SheetHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SheetHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 8, 2),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.tsTitleMedium)),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          IconButton(
            icon: const Icon(Icons.close),
            color: context.colors.textSecondary,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

/// Consistent wrapper for all modal bottom sheet content.
/// Provides cream background, rounded top corners, and a drag handle pill.
class SheetWrapper extends StatelessWidget {
  final Widget child;
  const SheetWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Shows [content] as a unified modal bottom sheet with [initialChildSize].
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget content,
  double initialChildSize = 0.72,
  double minChildSize = 0.4,
  double maxChildSize = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (_, _) => SheetWrapper(child: content),
    ),
  );
}
