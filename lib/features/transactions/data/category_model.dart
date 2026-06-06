import 'package:flutter/material.dart';

/// All supported Material icon keys (stored as "mat:NAME" in the DB).
/// Using a const map ensures the tree-shaker can enumerate every IconData.
const Map<String, IconData> kMatIcons = {
  'mat:restaurant': Icons.restaurant,
  'mat:local_cafe': Icons.local_cafe,
  'mat:shopping_cart': Icons.shopping_cart,
  'mat:local_hospital': Icons.local_hospital,
  'mat:fitness_center': Icons.fitness_center,
  'mat:home': Icons.home,
  'mat:school': Icons.school,
  'mat:directions_car': Icons.directions_car,
  'mat:local_taxi': Icons.local_taxi,
  'mat:flight': Icons.flight,
  'mat:movie': Icons.movie,
  'mat:sports_esports': Icons.sports_esports,
  'mat:phone': Icons.phone,
  'mat:sports_soccer': Icons.sports_soccer,
  'mat:credit_card': Icons.credit_card,
  'mat:work': Icons.work,
  'mat:attach_money': Icons.attach_money,
  'mat:favorite': Icons.favorite,
  'mat:pets': Icons.pets,
  'mat:local_pharmacy': Icons.local_pharmacy,
  'mat:directions_bus': Icons.directions_bus,
  'mat:child_care': Icons.child_care,
  'mat:star': Icons.star,
  'mat:card_giftcard': Icons.card_giftcard,
};

class CategoryModel {
  final String id;
  final String householdId;
  final String name;
  final String icon;
  final String color;
  final String type; // 'expense' | 'income' | 'both'
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.householdId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        type: json['type'] as String,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  CategoryModel copyWith({
    String? name,
    String? icon,
    String? color,
    String? type,
    int? sortOrder,
  }) =>
      CategoryModel(
        id: id,
        householdId: householdId,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        type: type ?? this.type,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Color get colorValue {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF78716C);
    }
  }

  /// True when icon is an emoji string, false when it's a Material icon codepoint
  /// (stored as hex string prefixed with "mat:", e.g. "mat:e532").
  bool get isEmoji => !icon.startsWith('mat:');

  /// Returns the icon as a Widget (Text for emoji, Icon for Material icons).
  Widget iconWidget({double size = 20}) {
    if (isEmoji) {
      return Text(icon, style: TextStyle(fontSize: size));
    }
    final iconData = kMatIcons[icon];
    if (iconData == null) return Text('📦', style: TextStyle(fontSize: size));
    return Icon(iconData, size: size, color: colorValue);
  }
}
