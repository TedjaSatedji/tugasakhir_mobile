import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import 'package:uuid/uuid.dart';

class QuestProvider extends ChangeNotifier {
  final List<QuestModel> _quests = [];
  bool _isLoading = false;

  List<QuestModel> get quests => _quests;
  bool get isLoading => _isLoading;

  List<QuestModel> get activeQuests =>
      _quests.where((q) => q.status == QuestStatus.active).toList();

  List<QuestModel> get completedQuests =>
      _quests.where((q) => q.status == QuestStatus.completed).toList();

  Future<void> createQuest(
    String title,
    String description,
    int xpReward,
    double moneyReward,
    QuestCategory category,
    DateTime deadline,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final quest = QuestModel(
      id: const Uuid().v4(),
      userId: '1',
      title: title,
      description: description,
      xpReward: xpReward,
      moneyReward: moneyReward,
      category: category,
      status: QuestStatus.active,
      deadline: deadline,
      createdAt: DateTime.now(),
      progressPercentage: 0,
    );

    _quests.add(quest);
    _isLoading = false;
    notifyListeners();
  }

  void completeQuest(String questId) {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _quests[index] = _quests[index].copyWith(status: QuestStatus.completed);
      notifyListeners();
    }
  }

  void updateQuestProgress(String questId, int progress) {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _quests[index] =
          _quests[index].copyWith(progressPercentage: progress);
      notifyListeners();
    }
  }

  void deleteQuest(String questId) {
    _quests.removeWhere((q) => q.id == questId);
    notifyListeners();
  }
}