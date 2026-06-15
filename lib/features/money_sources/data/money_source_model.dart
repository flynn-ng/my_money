import 'package:flutter/material.dart';

enum MoneySourceType { cash, bank, property, investment, other }

class MoneySourceModel {
  final String id;
  final String householdId;
  final String name;
  final String type; // 'cash' | 'bank' | 'property' | 'investment' | 'other'
  final String icon;
  final String color;
  final double initialBalance;
  final String currency;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final double currentBalance; // initialBalance + income − expense

  const MoneySourceModel({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.initialBalance,
    this.currency = 'VND',
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.currentBalance,
  });

  factory MoneySourceModel.fromJson(
    Map<String, dynamic> json, {
    double income = 0,
    double expense = 0,
  }) {
    final initial = (json['initial_balance'] as num).toDouble();
    return MoneySourceModel(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'cash',
      icon: json['icon'] as String? ?? '💳',
      color: json['color'] as String? ?? '#2196F3',
      initialBalance: initial,
      currency: json['currency'] as String? ?? 'VND',
      isArchived: json['is_archived'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentBalance: initial + income - expense,
    );
  }

  Color get colorValue {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  MoneySourceType get sourceType => MoneySourceType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => MoneySourceType.other,
      );
}
