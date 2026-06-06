class SavingsGoalModel {
  final String id;
  final String householdId;
  final String name;
  final String icon;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;

  const SavingsGoalModel({
    required this.id,
    required this.householdId,
    required this.name,
    required this.icon,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.isCompleted,
    required this.createdAt,
  });

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      SavingsGoalModel(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '🏦',
        targetAmount: (json['target_amount'] as num).toDouble(),
        currentAmount: (json['current_amount'] as num).toDouble(),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        isCompleted: json['is_completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0, 1) : 0;

  int? get daysLeft =>
      deadline?.difference(DateTime.now()).inDays;
}

class SavingsContributionModel {
  final String id;
  final String goalId;
  final String addedById;
  final double amount;
  final DateTime date;
  final String? notes;

  const SavingsContributionModel({
    required this.id,
    required this.goalId,
    required this.addedById,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory SavingsContributionModel.fromJson(Map<String, dynamic> json) =>
      SavingsContributionModel(
        id: json['id'] as String,
        goalId: json['goal_id'] as String,
        addedById: json['added_by'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
      );
}
