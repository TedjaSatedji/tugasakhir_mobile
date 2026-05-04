import 'package:flutter/material.dart';
import '../models/character_model.dart';
import '../models/shop_item_model.dart';
import '../models/leaderboard_model.dart';
import 'package:uuid/uuid.dart';
import '../core/services/storage_service.dart';
import '../services/local_database.dart';
import '../core/services/sync_service.dart';

class CharacterProvider extends ChangeNotifier {
  static const int baseXpPerLevel = 200;
  static const int xpIncrementPerLevel = 50;
  static const int coinsPerLevelUp = 30;
  final LocalDatabase _db = LocalDatabase.instance;
  CharacterModel? _character;
  bool _isLoading = false;

  /// Emits the new level number when a level-up occurs; reset to null after reading.
  final ValueNotifier<int?> levelUpNotifier = ValueNotifier(null);

  CharacterModel? get character => _character;
  bool get isLoading => _isLoading;
  int get coins => _character?.coins ?? 0;

  CharacterProvider() {
    loadCharacter();
  }

  Future<void> loadCharacter() async {
    _isLoading = true;
    notifyListeners();

    _character = await _db.getCharacter();

    if (_character == null) {
      _character = _createDefaultCharacter();
      await _db.upsertCharacter(_character!);
      SyncService().pushCharacter(_character!);
    }

    _isLoading = false;
    notifyListeners();
  }

  CharacterModel _createDefaultCharacter() {
    return CharacterModel(
      id: const Uuid().v4(),
      userId: StorageService.currentUserId,
      name: 'Hero',
      characterClass: CharacterClass.warrior,
      level: 1,
      totalXP: 0,
      hp: 100,
      mp: 50,
      avatarUrl: '',
      stats: {
        'strength': 10,
        'intelligence': 10,
        'agility': 10,
      },
    );
  }

  Future<void> createCharacter(
    String name,
    CharacterClass characterClass,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _character = CharacterModel(
      id: const Uuid().v4(),
      userId: StorageService.currentUserId,
      name: name,
      characterClass: characterClass,
      level: 1,
      totalXP: 0,
      hp: 100,
      mp: 50,
      avatarUrl: '',
      stats: {
        'strength': 10,
        'intelligence': 10,
        'agility': 10,
      },
    );

    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addXP(int xp) async {
    if (_character != null) {
      final oldLevel = _character!.level;
      int newXP = _character!.totalXP + xp;
      int newLevel = levelForXp(newXP);

      // Award coins and fire notifier on level-up
      int bonusCoins = 0;
      if (newLevel > oldLevel) {
        bonusCoins = coinsPerLevelUp * (newLevel - oldLevel);
        levelUpNotifier.value = newLevel;
      }

      _character = _character!.copyWith(
        totalXP: newXP,
        level: newLevel,
        coins: (_character!.coins + bonusCoins),
      );
      await _db.upsertCharacter(_character!);
      SyncService().pushCharacter(_character!);
      notifyListeners();
    }
  }

  Future<void> addXpForAmount(double amount) async {
    final xp = (amount / 1000).floor();
    if (xp <= 0) {
      return;
    }
    await addXP(xp);
  }

  /// Adds coins to the character balance.
  Future<void> addCoins(int amount) async {
    if (_character == null || amount <= 0) return;
    _character = _character!.copyWith(coins: _character!.coins + amount);
    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
  }

  /// Attempts to deduct [amount] coins. Returns false if balance is insufficient.
  bool spendCoins(int amount) {
    if (_character == null || _character!.coins < amount) return false;
    _character = _character!.copyWith(coins: _character!.coins - amount);
    _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
    return true;
  }

  /// Persists a new set of game upgrade levels to the character record.
  Future<void> updateShopUpgrades(GameUpgrades upgrades) async {
    if (_character == null) return;
    _character = _character!.copyWith(shopUpgrades: upgrades);
    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
  }

  /// Persists the updated list of owned frame IDs to the character record.
  Future<void> updateOwnedFrames(List<String> frames) async {
    if (_character == null) return;
    _character = _character!.copyWith(ownedFrames: frames);
    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
  }

  /// Updates a specific key in the character's stats dictionary.
  /// Useful for syncing arbitrary integer progression data like high scores.
  Future<void> updateStat(String key, int value) async {
    if (_character == null) return;
    final newStats = Map<String, int>.from(_character!.stats);
    newStats[key] = value;
    _character = _character!.copyWith(stats: newStats);
    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
  }

  static int levelForXp(int totalXp) {
    int level = 1;
    int requirement = baseXpPerLevel;
    int remaining = totalXp;

    while (remaining >= requirement) {
      remaining -= requirement;
      level += 1;
      requirement += xpIncrementPerLevel;
    }

    return level;
  }

  static int xpIntoLevel(int totalXp) {
    int requirement = baseXpPerLevel;
    int remaining = totalXp;

    while (remaining >= requirement) {
      remaining -= requirement;
      requirement += xpIncrementPerLevel;
    }

    return remaining;
  }

  static int xpRequiredForNextLevel(int level) {
    return baseXpPerLevel + xpIncrementPerLevel * (level - 1);
  }

  Future<void> updateCharacterName(String newName) async {
    _character ??= _createDefaultCharacter();
    _character = _character!.copyWith(name: newName);
    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    _character ??= _createDefaultCharacter();
    String finalUrl = avatarUrl;
    if (!avatarUrl.startsWith('http')) {
      final uploadedUrl = await SyncService().uploadImage(avatarUrl);
      if (uploadedUrl != null) {
        finalUrl = uploadedUrl;
      }
    }
    _character = _character!.copyWith(avatarUrl: finalUrl);
    await _db.upsertCharacter(_character!);
    SyncService().pushCharacter(_character!);
    notifyListeners();
  }

  /// Fetches the leaderboard and grants/revokes rank-exclusive frames.
  /// Called after a new high score is saved.
  Future<void> syncLeaderboardRank({List<LeaderboardEntry>? entries}) async {
    if (_character == null) return;
    try {
      final leaderboardEntries =
          entries ?? await SyncService().fetchLeaderboard();
      if (leaderboardEntries.isEmpty) return;

      // Find current user's rank (match by character name + email prefix from
      // the local character; isCurrentUser is set by SyncService)
          final myEntry =
            leaderboardEntries.where((e) => e.isCurrentUser).isNotEmpty
              ? leaderboardEntries.firstWhere((e) => e.isCurrentUser)
              : null;
      final myRank = myEntry?.rank;

      // Determine which rank frames to grant
      const rankFrames = ['frame_rank1', 'frame_rank2', 'frame_rank3'];
      final ownedFrames = List<String>.from(_character!.ownedFrames);

      for (final frameId in rankFrames) {
        final targetRank = rankFrames.indexOf(frameId) + 1;
        final shouldOwn = myRank != null && myRank == targetRank;
        final currentlyOwned = ownedFrames.contains(frameId);

        if (shouldOwn && !currentlyOwned) {
          ownedFrames.add(frameId);
        } else if (!shouldOwn && currentlyOwned) {
          ownedFrames.remove(frameId);
        }
      }

      if (!_listsEqual(ownedFrames, _character!.ownedFrames)) {
        await updateOwnedFrames(ownedFrames);
      }
    } catch (e) {
      print('syncLeaderboardRank failed: $e');
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}