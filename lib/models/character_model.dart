enum CharacterClass { warrior, mage, rogue, paladin }

class CharacterModel {
  final String id;
  final String userId;
  final String name;
  final CharacterClass characterClass;
  final int level;
  final int totalXP;
  final int hp;
  final int mp;
  final String avatarUrl;
  final Map<String, int> stats;

  CharacterModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.characterClass,
    required this.level,
    required this.totalXP,
    required this.hp,
    required this.mp,
    required this.avatarUrl,
    required this.stats,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      characterClass: CharacterClass.values[json['characterClass'] ?? 0],
      level: json['level'] ?? 1,
      totalXP: json['totalXP'] ?? 0,
      hp: json['hp'] ?? 100,
      mp: json['mp'] ?? 50,
      avatarUrl: json['avatarUrl'] ?? '',
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'characterClass': characterClass.index,
      'level': level,
      'totalXP': totalXP,
      'hp': hp,
      'mp': mp,
      'avatarUrl': avatarUrl,
      'stats': stats,
    };
  }

  CharacterModel copyWith({
    int? level,
    int? totalXP,
  }) {
    return CharacterModel(
      id: id,
      userId: userId,
      name: name,
      characterClass: characterClass,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      hp: hp,
      mp: mp,
      avatarUrl: avatarUrl,
      stats: stats,
    );
  }
}