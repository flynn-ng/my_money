import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get titleLarge => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleMedium => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get amountLarge => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
      );
}
