import 'dart:convert';
import 'shop_item_model.dart';

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
  final int coins;
  final GameUpgrades shopUpgrades;
  final List<String> ownedFrames;

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
    this.coins = 0,
    this.shopUpgrades = const GameUpgrades(),
    this.ownedFrames = const ['frame_neon'],
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
      coins: json['coins'] ?? 0,
      shopUpgrades: json['shopUpgrades'] != null
          ? GameUpgrades.fromJson(
              json['shopUpgrades'] is String
                  ? jsonDecode(json['shopUpgrades'])
                  : Map<String, dynamic>.from(json['shopUpgrades']))
          : const GameUpgrades(),
      ownedFrames: json['ownedFrames'] != null
          ? List<String>.from(
              json['ownedFrames'] is String
                  ? jsonDecode(json['ownedFrames'])
                  : json['ownedFrames'])
          : const ['frame_neon'],
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
      'coins': coins,
      'shopUpgrades': shopUpgrades.toJson(),
      'ownedFrames': ownedFrames,
    };
  }

  CharacterModel copyWith({
    String? name,
    int? level,
    int? totalXP,
    String? avatarUrl,
    Map<String, int>? stats,
    int? coins,
    GameUpgrades? shopUpgrades,
    List<String>? ownedFrames,
  }) {
    return CharacterModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      characterClass: characterClass,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      hp: hp,
      mp: mp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stats: stats ?? this.stats,
      coins: coins ?? this.coins,
      shopUpgrades: shopUpgrades ?? this.shopUpgrades,
      ownedFrames: ownedFrames ?? this.ownedFrames,
    );
  }
}