import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class DailyStats {
  final DateTime date;
  final double income;
  final double expense;

  DailyStats({required this.date, required this.income, required this.expense});

  double get net => income - expense;
}

class MonthlyStats {
  final int year;
  final int month;
  final double income;
  final double expense;

  MonthlyStats({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;
  String get label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class CategoryStats {
  final ExpenseCategory category;
  final double total;

  CategoryStats({required this.category, required this.total});
}

class StatsProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];

  void updateTransactions(List<TransactionModel> transactions) {
    // Don't call notifyListeners() here — the Consumer<TransactionProvider>
    // already drives the rebuild. Calling it during build causes
    // "setState() called during build".
    _transactions = transactions;
  }

  // ── Daily Stats (last 7 days) ──────────────────────────────────────────
  List<DailyStats> get last7DaysStats {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day - (6 - i));
      final dayTx = _transactions.where((t) {
        final ts = t.timestamp;
        return ts.year == day.year && ts.month == day.month && ts.day == day.day;
      });
      final income = dayTx
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = dayTx
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      return DailyStats(date: day, income: income, expense: expense);
    });
  }

  // ── Monthly Stats (last 6 months) ─────────────────────────────────────
  List<MonthlyStats> get last6MonthsStats {
    final now = DateTime.now();
    return List.generate(6, (i) {
      int month = now.month - (5 - i);
      int year = now.year;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      final monthTx = _transactions.where((t) {
        return t.timestamp.year == year && t.timestamp.month == month;
      });
      final income = monthTx
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = monthTx
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      return MonthlyStats(year: year, month: month, income: income, expense: expense);
    });
  }

  // ── Category breakdown (all-time expenses) ────────────────────────────
  List<CategoryStats> get categoryBreakdown {
    final Map<ExpenseCategory, double> totals = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense && t.category != null) {
        totals[t.category!] = (totals[t.category!] ?? 0) + t.amount;
      }
    }
    final list = totals.entries
        .map((e) => CategoryStats(category: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  // ── This month summary ────────────────────────────────────────────────
  double get thisMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get thisMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get savingsRate {
    if (thisMonthIncome <= 0) return 0;
    return ((thisMonthIncome - thisMonthExpense) / thisMonthIncome * 100)
        .clamp(0.0, 100.0);
  }
}
