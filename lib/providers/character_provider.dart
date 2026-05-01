import 'package:flutter/material.dart';
import '../models/character_model.dart';
import 'package:uuid/uuid.dart';
import '../services/local_database.dart';

class CharacterProvider extends ChangeNotifier {
  static const int baseXpPerLevel = 200;
  static const int xpIncrementPerLevel = 50;
  final LocalDatabase _db = LocalDatabase.instance;
  CharacterModel? _character;
  bool _isLoading = false;

  CharacterModel? get character => _character;
  bool get isLoading => _isLoading;

  CharacterProvider() {
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    _isLoading = true;
    notifyListeners();

    _character = await _db.getCharacter();

    if (_character == null) {
      _character = _createDefaultCharacter();
      await _db.upsertCharacter(_character!);
    }

    _isLoading = false;
    notifyListeners();
  }

  CharacterModel _createDefaultCharacter() {
    return CharacterModel(
      id: const Uuid().v4(),
      userId: '1',
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
      userId: '1',
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

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addXP(int xp) async {
    if (_character != null) {
      int newXP = _character!.totalXP + xp;
      int newLevel = levelForXp(newXP);
      
      _character = _character!.copyWith(
        totalXP: newXP,
        level: newLevel,
      );
      await _db.upsertCharacter(_character!);
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
    notifyListeners();
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    _character ??= _createDefaultCharacter();
    _character = _character!.copyWith(avatarUrl: avatarUrl);
    await _db.upsertCharacter(_character!);
    notifyListeners();
  }
}