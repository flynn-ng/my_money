import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppThemeColors {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color cardShadow;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.cardShadow,
  });

  static const light = AppThemeColors(
    background: AppColors.background,
    surface: AppColors.surface,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
    cardShadow: AppColors.cardShadow,
  );

  static const dark = AppThemeColors(
    background: Color(0xFF0F0F0F),
    surface: Color(0xFF1A1A1A),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFF9E9E9E),
    divider: Color(0xFF2A2A2A),
    cardShadow: Color(0x00000000),
  );
}

extension AppThemeExt on BuildContext {
  AppThemeColors get colors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppThemeColors.dark
          : AppThemeColors.light;

  // Context-aware text styles
  TextStyle get tsDisplayLarge =>
      AppTextStyles.displayLarge.copyWith(color: colors.textPrimary);
  TextStyle get tsTitleLarge =>
      AppTextStyles.titleLarge.copyWith(color: colors.textPrimary);
  TextStyle get tsTitleMedium =>
      AppTextStyles.titleMedium.copyWith(color: colors.textPrimary);
  TextStyle get tsBodyLarge =>
      AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary);
  TextStyle get tsBodyMedium =>
      AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary);
  TextStyle get tsLabelSmall =>
      AppTextStyles.labelSmall.copyWith(color: colors.textSecondary);
  TextStyle get tsAmountLarge =>
      AppTextStyles.amountLarge.copyWith(color: colors.textPrimary);
}
