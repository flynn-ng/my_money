class HouseholdModel {
  final String id;
  final String name;
  final String inviteCode;
  final DateTime createdAt;

  const HouseholdModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) => HouseholdModel(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['invite_code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
