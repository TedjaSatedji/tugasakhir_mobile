import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum ShopItemType { gameUpgrade, avatarFrame }

enum UpgradeType { fasterShip, extraLives, fasterBullets }

// ─── Avatar Frame Definitions ────────────────────────────────────────────────

class AvatarFrame {
  final String id;
  final String name;
  final String emoji;
  final int cost; // 0 = free/default
  final bool isAnimated;
  final Color color;

  const AvatarFrame({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.color,
    this.isAnimated = false,
  });

  static const List<AvatarFrame> catalogue = [
    AvatarFrame(
      id: 'frame_neon',
      name: 'Neon',
      emoji: '💚',
      cost: 0,
      color: Color(0xFF00FF41),
    ),
    AvatarFrame(
      id: 'frame_blue',
      name: 'Cyber Blue',
      emoji: '💙',
      cost: 150,
      color: Color(0xFF00D9FF),
    ),
    AvatarFrame(
      id: 'frame_purple',
      name: 'Royal Purple',
      emoji: '💜',
      cost: 200,
      color: Color(0xFF8B5CF6),
    ),
    AvatarFrame(
      id: 'frame_gold',
      name: 'Gold',
      emoji: '⭐',
      cost: 400,
      color: Color(0xFFFFD700),
    ),
    AvatarFrame(
      id: 'frame_holo',
      name: 'Holographic',
      emoji: '🌈',
      cost: 600,
      color: Color(0xFF00FF41), // base color; rendered as animated gradient
      isAnimated: true,
    ),
  ];

  static AvatarFrame byId(String id) =>
      catalogue.firstWhere((f) => f.id == id, orElse: () => catalogue.first);
}

// ─── Game Upgrade Definitions ────────────────────────────────────────────────

class UpgradeDef {
  final UpgradeType type;
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int maxLevel;
  final List<int> costsPerLevel; // length == maxLevel
  final List<String> effectLabels; // description per level (length == maxLevel)

  const UpgradeDef({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.maxLevel,
    required this.costsPerLevel,
    required this.effectLabels,
  });

  static const List<UpgradeDef> catalogue = [
    UpgradeDef(
      type: UpgradeType.fasterShip,
      id: 'upgrade_ship',
      name: 'Faster Ship',
      description: 'Meningkatkan kecepatan gerak kapalmu',
      emoji: '🚀',
      maxLevel: 3,
      costsPerLevel: [60, 120, 200],
      effectLabels: [
        'Speed clamp +25% · Drag ×1.5',
        'Speed clamp +55% · Drag ×1.8',
        'Speed clamp +87% · Drag ×2.2',
      ],
    ),
    UpgradeDef(
      type: UpgradeType.extraLives,
      id: 'upgrade_lives',
      name: 'Extra Lives',
      description: 'Tambah nyawa awal setiap game',
      emoji: '❤️',
      maxLevel: 2,
      costsPerLevel: [150, 300],
      effectLabels: [
        'Mulai dengan 4 ❤️',
        'Mulai dengan 5 ❤️',
      ],
    ),
    UpgradeDef(
      type: UpgradeType.fasterBullets,
      id: 'upgrade_bullets',
      name: 'Faster Bullets',
      description: 'Pelurumu melaju lebih cepat',
      emoji: '⚡',
      maxLevel: 2,
      costsPerLevel: [80, 160],
      effectLabels: [
        'Kecepatan peluru +24%',
        'Kecepatan peluru +52%',
      ],
    ),
  ];

  static UpgradeDef byType(UpgradeType type) =>
      catalogue.firstWhere((d) => d.type == type);
}

// ─── GameUpgrades State ───────────────────────────────────────────────────────

class GameUpgrades {
  final int fasterShipLevel;   // 0–3
  final int extraLivesLevel;   // 0–2
  final int fasterBulletsLevel; // 0–2

  const GameUpgrades({
    this.fasterShipLevel = 0,
    this.extraLivesLevel = 0,
    this.fasterBulletsLevel = 0,
  });

  // ── Computed game values ──────────────────────────────────────────────────

  double get moveSpeedClamp {
    const values = [400.0, 500.0, 620.0, 750.0];
    return values[fasterShipLevel.clamp(0, 3)];
  }

  double get dragSensitivity {
    const values = [1.2, 1.5, 1.8, 2.2];
    return values[fasterShipLevel.clamp(0, 3)];
  }

  int get extraLivesBonus => extraLivesLevel; // +1 or +2 lives

  double get bulletSpeed {
    const values = [420.0, 520.0, 640.0];
    return values[fasterBulletsLevel.clamp(0, 2)];
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  factory GameUpgrades.fromJson(Map<String, dynamic> json) => GameUpgrades(
        fasterShipLevel: json['fasterShipLevel'] ?? 0,
        extraLivesLevel: json['extraLivesLevel'] ?? 0,
        fasterBulletsLevel: json['fasterBulletsLevel'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'fasterShipLevel': fasterShipLevel,
        'extraLivesLevel': extraLivesLevel,
        'fasterBulletsLevel': fasterBulletsLevel,
      };

  GameUpgrades copyWith({
    int? fasterShipLevel,
    int? extraLivesLevel,
    int? fasterBulletsLevel,
  }) =>
      GameUpgrades(
        fasterShipLevel: fasterShipLevel ?? this.fasterShipLevel,
        extraLivesLevel: extraLivesLevel ?? this.extraLivesLevel,
        fasterBulletsLevel: fasterBulletsLevel ?? this.fasterBulletsLevel,
      );

  int currentLevel(UpgradeType type) {
    switch (type) {
      case UpgradeType.fasterShip:
        return fasterShipLevel;
      case UpgradeType.extraLives:
        return extraLivesLevel;
      case UpgradeType.fasterBullets:
        return fasterBulletsLevel;
    }
  }
}
