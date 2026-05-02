import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../core/services/storage_service.dart';
import '../services/local_database.dart';
import '../core/services/sync_service.dart';

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
    );

    _transactions.add(transaction);
    await _db.upsertTransaction(transaction);
    SyncService().pushTransaction(transaction);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await _db.deleteTransaction(transactionId);
    SyncService().deleteTransaction(transactionId);
    notifyListeners();
  }

  List<TransactionModel> getTransactionsByCategory(ExpenseCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList();
  }
}