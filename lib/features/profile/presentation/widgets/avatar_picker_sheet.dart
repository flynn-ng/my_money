import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/sheet_wrapper.dart';

const _avatarOptions = [
  // Faces
  '😀', '😊', '🥰', '😎', '🤩', '🤑', '😇', '🥳',
  // Animals
  '🐝', '🐱', '🐶', '🦊', '🐰', '🐼', '🦁', '🐨', '🦋', '🐸', '🐯', '🐮',
  // Nature & objects
  '🌟', '⭐', '🔥', '💎', '💰', '🏠', '🌈', '🎯', '👑', '💪', '🎉', '🌸',
];

class AvatarPickerSheet extends StatelessWidget {
  final String currentEmoji;
  final ValueChanged<String> onSelect;

  const AvatarPickerSheet({
    super.key,
    required this.currentEmoji,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentEmoji,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, _) => SheetWrapper(
          child: AvatarPickerSheet(
            currentEmoji: currentEmoji,
            onSelect: onSelect,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(S.avatarPickerTitle,
              style: AppTextStyles.titleMedium),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _avatarOptions.length,
            itemBuilder: (context, i) {
              final emoji = _avatarOptions[i];
              final isSelected = emoji == currentEmoji;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.textPrimary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? context.colors.textPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
