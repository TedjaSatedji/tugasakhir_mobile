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
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    String? finalImageUrl = receiptImageUrl;
    if (receiptImageUrl != null && !receiptImageUrl.startsWith('http')) {
      final uploadedUrl = await SyncService().uploadImage(receiptImageUrl);
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      }
    }

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: StorageService.currentUserId,
      type: type,
      category: category,
      amount: amount,
      description: description,
      timestamp: timestamp ?? DateTime.now(),
      receiptImageUrl: finalImageUrl,
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
    
    // Save as unsynced first; SyncService will mark it synced on successful push
    await _db.upsertTransaction(transaction, isSynced: false);
    SyncService().pushTransaction(transaction);
    await HomeWidgetService.updateFromTransactions(this);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await _db.deleteTransaction(transactionId);
    SyncService().deleteTransaction(transactionId);
    await HomeWidgetService.updateFromTransactions(this);
    notifyListeners();
  }

  List<TransactionModel> getTransactionsByCategory(ExpenseCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList();
  }
}