import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../core/services/storage_service.dart';
import '../models/character_model.dart';
import '../models/quest_model.dart';
import '../models/transaction_model.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tugasakhir_mobile.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTransactionsTable(db);
        await _createQuestsTable(db);
        await _createCharacterTable(db);
        await _createDailyMissionsTable(db);
        await _createShopPurchasesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createDailyMissionsTable(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE transactions ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE transactions ADD COLUMN longitude REAL');
          await db.execute('ALTER TABLE transactions ADD COLUMN locationName TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE transactions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE character ADD COLUMN coins INTEGER NOT NULL DEFAULT 0');
          await _createShopPurchasesTable(db);
        }
      },
    );
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT,
        type INTEGER,
        category INTEGER,
        amount REAL,
        description TEXT,
        timestamp TEXT,
        receiptImageUrl TEXT,
        detectedCategory TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT,
        is_synced INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _createQuestsTable(Database db) async {
    await db.execute('''
      CREATE TABLE quests (
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        description TEXT,
        xpReward INTEGER,
        targetAmount REAL,
        currentSavedAmount REAL,
        category INTEGER,
        status INTEGER,
        deadline TEXT,
        createdAt TEXT,
        progressPercentage INTEGER
      )
    ''');
  }

  Future<void> _createCharacterTable(Database db) async {
    await db.execute('''
      CREATE TABLE character (
        id TEXT PRIMARY KEY,
        userId TEXT,
        name TEXT,
        characterClass INTEGER,
        level INTEGER,
        totalXP INTEGER,
        hp INTEGER,
        mp INTEGER,
        avatarUrl TEXT,
        stats TEXT,
        coins INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createShopPurchasesTable(Database db) async {
    await db.execute('''
      CREATE TABLE shop_purchases (
        item_id TEXT PRIMARY KEY,
        purchased_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createDailyMissionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE daily_missions (
        id TEXT NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        PRIMARY KEY (id, date)
      )
    ''');
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final userId = StorageService.currentUserId;
    final rows = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return rows.map((row) => TransactionModel.fromJson(row)).toList();
  }

  Future<void> upsertTransaction(TransactionModel transaction, {bool isSynced = true}) async {
    final db = await database;
    final data = transaction.toJson()
      ..['is_synced'] = isSynced ? 1 : 0;
    await db.insert(
      'transactions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markTransactionSynced(String id) async {
    final db = await database;
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await database;
    final userId = StorageService.currentUserId;
    final rows = await db.query(
      'transactions',
      where: 'userId = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    return rows.map((row) => TransactionModel.fromJson(row)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuestModel>> getQuests() async {
    final db = await database;
    final userId = StorageService.currentUserId;
    final rows = await db.query(
      'quests',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map((row) => QuestModel.fromJson(row)).toList();
  }

  Future<void> upsertQuest(QuestModel quest) async {
    final db = await database;
    await db.insert(
      'quests',
      quest.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteQuest(String id) async {
    final db = await database;
    await db.delete('quests', where: 'id = ?', whereArgs: [id]);
  }

  Future<CharacterModel?> getCharacter() async {
    final db = await database;
    final userId = StorageService.currentUserId;
    final rows = await db.query(
      'character',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    final statsRaw = row['stats'] as String?;
    final stats = statsRaw == null || statsRaw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(statsRaw));
    final data = Map<String, dynamic>.from(row)..['stats'] = stats;
    return CharacterModel.fromJson(data);
  }

  Future<void> upsertCharacter(CharacterModel character) async {
    final db = await database;
    final data = character.toJson();
    data['stats'] = jsonEncode(data['stats'] ?? {});
    await db.insert(
      'character',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, bool>> getDailyMissionStates(String dateKey) async {
    final db = await database;
    final rows = await db.query(
      'daily_missions',
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    final result = <String, bool>{};
    for (final row in rows) {
      result[row['id'] as String] = (row['isCompleted'] as int) == 1;
    }
    return result;
  }

  Future<void> upsertDailyMissionState({
    required String dateKey,
    required String missionId,
    required bool isCompleted,
  }) async {
    final db = await database;
    await db.insert(
      'daily_missions',
      {
        'id': missionId,
        'date': dateKey,
        'isCompleted': isCompleted ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getShopPurchases() async {
    final db = await database;
    final rows = await db.query('shop_purchases');
    return rows.map((r) => r['item_id'] as String).toList();
  }

  Future<void> addShopPurchase(String itemId) async {
    final db = await database;
    await db.insert(
      'shop_purchases',
      {
        'item_id': itemId,
        'purchased_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Migrate old records that used hardcoded userId '1' or 'guest'
  /// to the real userId. Call once after login.
  Future<void> migrateOldUserData(String realUserId) async {
    if (realUserId == '1' || realUserId == 'guest') return;

    final db = await database;
    for (final table in ['transactions', 'quests', 'character']) {
      await db.update(
        table,
        {'userId': realUserId},
        where: "userId = ? OR userId = ?",
        whereArgs: ['1', 'guest'],
      );
    }
  }
}
