import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F7F7);
  static const cream = Color(0xFFF7F7F7);       // kept as alias for background
  static const surface = Color(0xFFFFFFFF);
  static const black = Color(0xFF0F0F0F);
  static const blackSoft = Color(0xFF1A1A1A);
  // keep amber as alias so existing refs compile — now maps to black
  static const amber = Color(0xFF0F0F0F);
  static const amberLight = Color(0xFFE8E8E8);
  static const amberDark = Color(0xFF1A1A1A);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
  static const blue = Color(0xFF2563EB);
  static const cardShadow = Color(0x0A000000);
  static const textPrimary = Color(0xFF0F0F0F);
  static const textSecondary = Color(0xFF737373);
  static const divider = Color(0xFFE5E5E5);

  static Color fromHex(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } on FormatException {
      return const Color(0xFF78716C);
    }
  }

  static const categoryColors = [
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFF0F0F0F),
    Color(0xFF16A34A),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];
}
