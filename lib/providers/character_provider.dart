import 'package:flutter/material.dart';
import '../models/character_model.dart';
import 'package:uuid/uuid.dart';

class CharacterProvider extends ChangeNotifier {
  CharacterModel? _character;
  bool _isLoading = false;

  CharacterModel? get character => _character;
  bool get isLoading => _isLoading;

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

    _isLoading = false;
    notifyListeners();
  }

  void addXP(int xp) {
    if (_character != null) {
      int newXP = _character!.totalXP + xp;
      int newLevel = _character!.level + (newXP ~/ 1000);
      
      _character = _character!.copyWith(
        totalXP: newXP,
        level: newLevel,
      );
      notifyListeners();
    }
  }

  void updateCharacterName(String newName) {
    if (_character != null) {
      _character = CharacterModel(
        id: _character!.id,
        userId: _character!.userId,
        name: newName,
        characterClass: _character!.characterClass,
        level: _character!.level,
        totalXP: _character!.totalXP,
        hp: _character!.hp,
        mp: _character!.mp,
        avatarUrl: _character!.avatarUrl,
        stats: _character!.stats,
      );
      notifyListeners();
    }
  }
}