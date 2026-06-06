class ProfileModel {
  final String id;
  final String? householdId;
  final String displayName;
  final String avatarEmoji;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    this.householdId,
    required this.displayName,
    required this.avatarEmoji,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        householdId: json['household_id'] as String?,
        displayName: json['display_name'] as String,
        avatarEmoji: json['avatar_emoji'] as String? ?? '🐝',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  ProfileModel copyWith({
    String? householdId,
    String? displayName,
    String? avatarEmoji,
  }) =>
      ProfileModel(
        id: id,
        householdId: householdId ?? this.householdId,
        displayName: displayName ?? this.displayName,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        createdAt: createdAt,
      );
}
