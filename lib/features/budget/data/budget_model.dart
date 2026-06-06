class BudgetModel {
  final String id;
  final String householdId;
  final String categoryId;
  final DateTime month;
  final double amount;

  // Joined / computed
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  double spent;

  BudgetModel({
    required this.id,
    required this.householdId,
    required this.categoryId,
    required this.month,
    required this.amount,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.spent = 0,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    return BudgetModel(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      categoryId: json['category_id'] as String,
      month: DateTime.parse(json['month'] as String),
      amount: (json['amount'] as num).toDouble(),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }

  double get progress => amount > 0 ? (spent / amount).clamp(0, 1) : 0;
  double get remaining => amount - spent;
}
