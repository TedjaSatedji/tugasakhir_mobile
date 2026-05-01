import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class DailyMission {
  final String id;
  final String title;
  final int xpReward;
  bool isCompleted;

  DailyMission({
    required this.id,
    required this.title,
    required this.xpReward,
    this.isCompleted = false,
  });
}

class QuestProvider extends ChangeNotifier {
  final List<QuestModel> _quests = [];
  final List<DailyMission> _dailyMissions = [];
  bool _isLoading = false;

  List<QuestModel> get quests => _quests;
  List<DailyMission> get dailyMissions => _dailyMissions;
  bool get isLoading => _isLoading;

  List<QuestModel> get activeQuests =>
      _quests.where((q) => q.status == QuestStatus.active).toList();

  List<QuestModel> get completedQuests =>
      _quests.where((q) => q.status == QuestStatus.completed).toList();

  QuestProvider() {
    _generateDailyMissions();
  }

  void _generateDailyMissions() {
    _dailyMissions.clear();
    // Basic mission
    _dailyMissions.add(DailyMission(
      id: 'mission_1',
      title: 'Catat 1 Transaksi Keuangan',
      xpReward: 20,
    ));

    // Dynamic mission based on active goals
    // Wait, since this is called on init, _quests might be empty. 
    // We can add a generic one for now.
    _dailyMissions.add(DailyMission(
      id: 'mission_2',
      title: 'Sisihkan uang untuk Target Tabungan',
      xpReward: 50,
    ));
    notifyListeners();
  }

  void completeDailyMission(String id) {
    final mission = _dailyMissions.firstWhere((m) => m.id == id, orElse: () => _dailyMissions.first);
    if (!mission.isCompleted) {
      mission.isCompleted = true;
      notifyListeners();
    }
  }

  Future<void> createQuest(
    String title,
    String description,
    double targetAmount,
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
      xpReward: 500, // Fixed XP reward for reaching a goal
      targetAmount: targetAmount,
      currentSavedAmount: 0,
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

  void addFundsToGoal(String questId, double amount) {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      final quest = _quests[index];
      double newAmount = quest.currentSavedAmount + amount;
      
      int newProgress = (newAmount / quest.targetAmount * 100).toInt();
      if (newProgress > 100) newProgress = 100;

      QuestStatus newStatus = quest.status;
      if (newAmount >= quest.targetAmount) {
        newAmount = quest.targetAmount;
        newStatus = QuestStatus.completed;
      }

      _quests[index] = quest.copyWith(
        currentSavedAmount: newAmount,
        progressPercentage: newProgress,
        status: newStatus,
      );
      
      // Also complete the daily mission for saving money
      completeDailyMission('mission_2');
      
      notifyListeners();
    }
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