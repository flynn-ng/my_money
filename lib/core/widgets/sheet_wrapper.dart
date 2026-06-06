import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

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
