import 'package:dio/dio.dart';
import '../../models/transaction_model.dart';
import '../../models/quest_model.dart';
import '../../models/character_model.dart';
import 'api_client.dart';
import 'storage_service.dart';
import '../../services/local_database.dart';
import '../../providers/quest_provider.dart';

class SyncService {
  final Dio _dio = ApiClient().dio;
  final LocalDatabase _db = LocalDatabase.instance;

  // Pull all data from server and overwrite local DB
  Future<void> pullAll() async {
    try {
      // Fetch all from server
      final transRes = await _dio.get('/sync/transactions');
      final questRes = await _dio.get('/sync/quests');
      final charRes = await _dio.get('/sync/character');
      final missionsRes = await _dio.get('/sync/daily_missions');

      // Transactions
      final remoteTransactions = (transRes.data as List)
          .map((json) => _transactionFromServer(json))
          .toList();
      for (final t in remoteTransactions) {
        await _db.upsertTransaction(t);
      }

      // Quests
      final remoteQuests = (questRes.data as List)
          .map((json) => _questFromServer(json))
          .toList();
      for (final q in remoteQuests) {
        await _db.upsertQuest(q);
      }

      // Character
      if (charRes.data != null) {
        final remoteCharacter = _characterFromServer(charRes.data);
        await _db.upsertCharacter(remoteCharacter);
      }

      // Daily Missions
      final remoteMissions = missionsRes.data as List;
      for (final m in remoteMissions) {
        await _db.upsertDailyMissionState(
          dateKey: m['date'],
          missionId: m['mission_id'],
          isCompleted: m['is_completed'],
        );
      }
    } catch (e) {
      // Ignore 401s or network errors during sync, just stay local
      print("Sync pull failed: $e");
    }
  }

  // --- Transactions ---

  Future<void> pushTransaction(TransactionModel t) async {
    try {
      await _dio.post('/sync/transactions', data: _transactionToServer(t));
    } catch (e) {
      print("Push transaction failed: $e");
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/sync/transactions/$id');
    } catch (e) {
      print("Delete transaction failed: $e");
    }
  }

  // --- Quests ---

  Future<void> pushQuest(QuestModel q) async {
    try {
      await _dio.post('/sync/quests', data: _questToServer(q));
    } catch (e) {
      print("Push quest failed: $e");
    }
  }

  Future<void> deleteQuest(String id) async {
    try {
      await _dio.delete('/sync/quests/$id');
    } catch (e) {
      print("Delete quest failed: $e");
    }
  }

  // --- Character ---

  Future<void> pushCharacter(CharacterModel c) async {
    try {
      await _dio.post('/sync/character', data: _characterToServer(c));
    } catch (e) {
      print("Push character failed: $e");
    }
  }

  // --- Daily Missions ---

  Future<void> pushDailyMissionState(String missionId, String date, bool isCompleted) async {
    try {
      final userId = StorageService.currentUserId;
      final id = "${missionId}_${date}_$userId";
      await _dio.post('/sync/daily_missions', data: {
        'id': id,
        'mission_id': missionId,
        'date': date,
        'is_completed': isCompleted,
      });
    } catch (e) {
      print("Push daily mission failed: $e");
    }
  }

  // --- Mappers ---

  Map<String, dynamic> _transactionToServer(TransactionModel t) {
    return {
      'id': t.id,
      'type': t.type.index,
      'category': t.category?.index,
      'amount': t.amount,
      'description': t.description,
      'timestamp': t.timestamp.toIso8601String(),
      'receipt_image_url': t.receiptImageUrl,
      'detected_category': t.detectedCategory,
      'latitude': t.latitude,
      'longitude': t.longitude,
      'location_name': t.locationName,
    };
  }

  TransactionModel _transactionFromServer(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: StorageService.currentUserId, // from auth
      type: TransactionType.values[json['type'] ?? 0],
      category: json['category'] != null ? ExpenseCategory.values[json['category']] : null,
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      receiptImageUrl: json['receipt_image_url'],
      detectedCategory: json['detected_category'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'],
    );
  }

  Map<String, dynamic> _questToServer(QuestModel q) {
    return {
      'id': q.id,
      'title': q.title,
      'description': q.description,
      'xp_reward': q.xpReward,
      'target_amount': q.targetAmount,
      'current_saved_amount': q.currentSavedAmount,
      'category': q.category.index,
      'status': q.status.index,
      'deadline': q.deadline.toIso8601String(),
      'created_at': q.createdAt.toIso8601String(),
      'progress_percentage': q.progressPercentage,
    };
  }

  QuestModel _questFromServer(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'],
      userId: StorageService.currentUserId,
      title: json['title'],
      description: json['description'] ?? '',
      xpReward: json['xp_reward'] ?? 500,
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      currentSavedAmount: (json['current_saved_amount'] ?? 0).toDouble(),
      category: QuestCategory.values[json['category'] ?? 0],
      status: QuestStatus.values[json['status'] ?? 0],
      deadline: DateTime.parse(json['deadline'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      progressPercentage: json['progress_percentage'] ?? 0,
    );
  }

  Map<String, dynamic> _characterToServer(CharacterModel c) {
    return {
      'id': c.id,
      'name': c.name,
      'character_class': c.characterClass.index,
      'level': c.level,
      'total_xp': c.totalXP,
      'hp': c.hp,
      'mp': c.mp,
      'avatar_url': c.avatarUrl,
      'stats': c.stats,
    };
  }

  CharacterModel _characterFromServer(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'],
      userId: StorageService.currentUserId,
      name: json['name'],
      characterClass: CharacterClass.values[json['character_class'] ?? 0],
      level: json['level'] ?? 1,
      totalXP: json['total_xp'] ?? 0,
      hp: json['hp'] ?? 100,
      mp: json['mp'] ?? 50,
      avatarUrl: json['avatar_url'] ?? '',
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }
}
