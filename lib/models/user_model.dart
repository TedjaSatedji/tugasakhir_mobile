class UserModel {
  final String id;
  final String email;
  final String characterName;
  final int level;
  final int totalXP;
  final double totalSavings;
  final String profileImageUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.characterName,
    required this.level,
    required this.totalXP,
    required this.totalSavings,
    required this.profileImageUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      characterName: (json['characterName'] ?? 'Hero').toString(),
      level: json['level'] ?? 1,
      totalXP: json['totalXP'] ?? 0,
      totalSavings: (json['totalSavings'] ?? 0).toDouble(),
      profileImageUrl: json['profileImageUrl'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'characterName': characterName,
      'level': level,
      'totalXP': totalXP,
      'totalSavings': totalSavings,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? characterName,
    int? level,
    int? totalXP,
    double? totalSavings,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      characterName: characterName ?? this.characterName,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      totalSavings: totalSavings ?? this.totalSavings,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}