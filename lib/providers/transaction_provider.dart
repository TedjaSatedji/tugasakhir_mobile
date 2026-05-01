import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../services/local_database.dart';

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
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
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
    String? receiptImageUrl,
  ) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: '1',
      type: type,
      category: category,
      amount: amount,
      description: description,
      timestamp: DateTime.now(),
      receiptImageUrl: receiptImageUrl,
    );

    _transactions.add(transaction);
    await _db.upsertTransaction(transaction);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await _db.deleteTransaction(transactionId);
    notifyListeners();
  }

  List<TransactionModel> getTransactionsByCategory(ExpenseCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList();
  }
}