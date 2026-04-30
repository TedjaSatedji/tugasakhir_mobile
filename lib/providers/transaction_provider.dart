import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class TransactionProvider extends ChangeNotifier {
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

  Future<void> addTransaction(
    TransactionType type,
    ExpenseCategory? category,
    double amount,
    String description,
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
    );

    _transactions.add(transaction);
    _isLoading = false;
    notifyListeners();
  }

  void deleteTransaction(String transactionId) {
    _transactions.removeWhere((t) => t.id == transactionId);
    notifyListeners();
  }

  List<TransactionModel> getTransactionsByCategory(ExpenseCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList();
  }
}