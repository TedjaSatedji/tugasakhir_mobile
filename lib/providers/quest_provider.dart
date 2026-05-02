import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../core/services/storage_service.dart';
import '../services/local_database.dart';
import '../core/services/sync_service.dart';
import 'package:easy_localization/easy_localization.dart';

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

class QuestProgressResult {
  final int progressXp;
  final int completionXp;
  final int missionXp;
  final bool completedNow;

  const QuestProgressResult({
    required this.progressXp,
    required this.completionXp,
    required this.missionXp,
    required this.completedNow,
  });

  int get totalXp => progressXp + completionXp + missionXp;

  static const none = QuestProgressResult(
    progressXp: 0,
    completionXp: 0,
    missionXp: 0,
    completedNow: false,
  );
}

class QuestProvider extends ChangeNotifier {
  final LocalDatabase _db = LocalDatabase.instance;
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
    loadQuests();
  }

  Future<void> loadQuests() async {
    _isLoading = true;
    notifyListeners();

    final items = await _db.getQuests();
    _quests
      ..clear()
      ..addAll(items);

    _isLoading = false;
    await _loadDailyMissions();
    notifyListeners();
  }

  Future<void> _loadDailyMissions() async {
    _dailyMissions.clear();

    final dateKey = _todayKey();
    final savedStates = await _db.getDailyMissionStates(dateKey);

    final missions = <DailyMission>[
      DailyMission(
        id: 'mission_1',
        title: 'mission1Title'.tr(),
        xpReward: 20,
        isCompleted: savedStates['mission_1'] ?? false,
      ),
      DailyMission(
        id: 'mission_2',
        title: 'mission2Title'.tr(),
        xpReward: 50,
        isCompleted: savedStates['mission_2'] ?? false,
      ),
    ];

    _dailyMissions.addAll(missions);

    for (final mission in missions) {
      await _db.upsertDailyMissionState(
        dateKey: dateKey,
        missionId: mission.id,
        isCompleted: mission.isCompleted,
      );
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<int> completeDailyMission(String id) async {
    if (_dailyMissions.isEmpty) {
      await _loadDailyMissions();
    }

    final index = _dailyMissions.indexWhere((m) => m.id == id);
    if (index == -1) {
      return 0;
    }

    final mission = _dailyMissions[index];
    if (!mission.isCompleted) {
      mission.isCompleted = true;
      await _db.upsertDailyMissionState(
        dateKey: _todayKey(),
        missionId: mission.id,
        isCompleted: true,
      );
      SyncService().pushDailyMissionState(mission.id, _todayKey(), true);
      notifyListeners();
      return mission.xpReward;
    }

    return 0;
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
      userId: StorageService.currentUserId,
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
    await _db.upsertQuest(quest);
    SyncService().pushQuest(quest);
    _isLoading = false;
    notifyListeners();
  }

  Future<QuestProgressResult> addFundsToGoal(String questId, double amount) async {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1 || amount <= 0) {
      return QuestProgressResult.none;
    }

    final quest = _quests[index];
    if (quest.status == QuestStatus.completed) {
      return QuestProgressResult.none;
    }

    double newAmount = quest.currentSavedAmount + amount;
    int newProgress = (newAmount / quest.targetAmount * 100).toInt();
    if (newProgress > 100) newProgress = 100;

    QuestStatus newStatus = quest.status;
    bool completedNow = false;
    if (newAmount >= quest.targetAmount) {
      newAmount = quest.targetAmount;
      newStatus = QuestStatus.completed;
      completedNow = true;
    }

    _quests[index] = quest.copyWith(
      currentSavedAmount: newAmount,
      progressPercentage: newProgress,
      status: newStatus,
    );

    await _db.upsertQuest(_quests[index]);
    SyncService().pushQuest(_quests[index]);

    // Also complete the daily mission for saving money
    final missionXp = await completeDailyMission('mission_2');

    notifyListeners();

    return QuestProgressResult(
      progressXp: 0,
      completionXp: completedNow ? quest.xpReward : 0,
      missionXp: missionXp,
      completedNow: completedNow,
    );
  }

  Future<void> completeQuest(String questId) async {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _quests[index] = _quests[index].copyWith(status: QuestStatus.completed);
      await _db.upsertQuest(_quests[index]);
      SyncService().pushQuest(_quests[index]);
      notifyListeners();
    }
  }

  Future<void> updateQuestProgress(String questId, int progress) async {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      _quests[index] =
          _quests[index].copyWith(progressPercentage: progress);
      await _db.upsertQuest(_quests[index]);
      SyncService().pushQuest(_quests[index]);
      notifyListeners();
    }
  }

  Future<void> deleteQuest(String questId) async {
    _quests.removeWhere((q) => q.id == questId);
    await _db.deleteQuest(questId);
    SyncService().deleteQuest(questId);
    notifyListeners();
  }
}