import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../core/services/storage_service.dart';
import '../services/local_database.dart';
import '../core/services/sync_service.dart';
import '../core/services/home_widget_service.dart';

class TransactionProvider extends ChangeNotifier {
  final LocalDatabase _db = LocalDatabase.instance;
  final List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  TransactionProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    final items = await _db.getTransactions();
    _transactions
      ..clear()
      ..addAll(items);
    
    // Ensure sorted by newest first
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(
    TransactionType type,
    ExpenseCategory? category,
    double amount,
    String description,
    String? receiptImageUrl, {
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? locationName,
    int xpAwarded = 0,
    int coinsAwarded = 0,
    String? missionCompletedId,
    String? missionCompletedDateKey,
  }) async {
    // Save locally with local image path immediately — no fake delay
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: StorageService.currentUserId,
      type: type,
      category: category,
      amount: amount,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      receiptImageUrl: receiptImageUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      xpAwarded: xpAwarded,
      coinsAwarded: coinsAwarded,
      missionCompletedId: missionCompletedId,
      missionCompletedDateKey: missionCompletedDateKey,
    );

    _transactions.add(transaction);
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _db.upsertTransaction(transaction, isSynced: false);
    await HomeWidgetService.updateFromTransactions(this);
    notifyListeners();

    // Upload image in background if it's a local file path
    if (receiptImageUrl != null && !receiptImageUrl.startsWith('http')) {
      SyncService().uploadImage(receiptImageUrl).then((uploadedUrl) async {
        if (uploadedUrl != null) {
          final updated = transaction.copyWith(receiptImageUrl: uploadedUrl);
          final idx = _transactions.indexWhere((t) => t.id == transaction.id);
          if (idx != -1) _transactions[idx] = updated;
          await _db.upsertTransaction(updated, isSynced: false);
          notifyListeners();
          SyncService().pushTransaction(updated);
        } else {
          SyncService().pushTransaction(transaction);
        }
      });
    } else {
      SyncService().pushTransaction(transaction);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await _db.deleteTransaction(transactionId);
    SyncService().deleteTransaction(transactionId);
    await HomeWidgetService.updateFromTransactions(this);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index == -1) {
      return;
    }

    _transactions[index] = updated;
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    await _db.upsertTransaction(updated, isSynced: false);
    SyncService().pushTransaction(updated);
    await HomeWidgetService.updateFromTransactions(this);
    notifyListeners();
  }

  List<TransactionModel> getTransactionsByCategory(ExpenseCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList();
  }
}