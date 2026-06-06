enum TransactionType { expense, income }

class TransactionModel {
  final String id;
  final String householdId;
  final String paidById;
  final String categoryId;
  final String type; // 'expense' | 'income'
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  // Joined data
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? paidByName;

  const TransactionModel({
    required this.id,
    required this.householdId,
    required this.paidById,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.paidByName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TransactionModel(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      paidById: json['paid_by_id'] as String,
      categoryId: json['category_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      paidByName: profile?['display_name'] as String?,
    );
  }

  TransactionType get txType => TransactionType.values.byName(type);

  Map<String, dynamic> toInsertJson() => {
        'household_id': householdId,
        'paid_by_id': paidById,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'date': date.toIso8601String().substring(0, 10),
        if (notes != null) 'notes': notes,
      };
}
