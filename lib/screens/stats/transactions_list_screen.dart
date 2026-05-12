import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/theme_extensions.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../wallet/transaction_detail_screen.dart';

enum _SortField { date, amountHigh, amountLow, type, category }

class TransactionsListScreen extends StatefulWidget {
  final String title;
  final DateTime? filterDay;
  final int? filterMonth;
  final int? filterYear;

  const TransactionsListScreen({
    super.key,
    required this.title,
    this.filterDay,
    this.filterMonth,
    this.filterYear,
  });

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  _SortField _sortField = _SortField.date;

  static const _sortLabels = {
    _SortField.date: 'Date',
    _SortField.amountHigh: 'Amount ↓',
    _SortField.amountLow: 'Amount ↑',
    _SortField.type: 'Type',
    _SortField.category: 'Category',
  };

  List<TransactionModel> _sort(List<TransactionModel> list) {
    final sorted = List<TransactionModel>.from(list);
    switch (_sortField) {
      case _SortField.date:
        sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case _SortField.amountHigh:
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _SortField.amountLow:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case _SortField.type:
        // income first, then expense, then transfer
        sorted.sort((a, b) => a.type.index.compareTo(b.type.index));
        break;
      case _SortField.category:
        sorted.sort((a, b) {
          final ca = a.category?.name ?? 'zzz';
          final cb = b.category?.name ?? 'zzz';
          return ca.compareTo(cb);
        });
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontFamily: 'Poppins')),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transProvider, _) {
          var filtered = transProvider.transactions.where((t) {
            if (widget.filterDay != null) {
              return t.timestamp.year == widget.filterDay!.year &&
                     t.timestamp.month == widget.filterDay!.month &&
                     t.timestamp.day == widget.filterDay!.day;
            }
            if (widget.filterMonth != null && widget.filterYear != null) {
              return t.timestamp.year == widget.filterYear &&
                     t.timestamp.month == widget.filterMonth;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'noTransactionYet'.tr(),
                style: TextStyle(
                  color: context.textDim,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }

          final sorted = _sort(filtered);

          // When sorted by date, group by day; otherwise show flat list
          if (_sortField == _SortField.date) {
            return _GroupedList(transactions: sorted);
          }

          return Column(
            children: [
              _SortBar(
                current: _sortField,
                onSelect: (f) => setState(() => _sortField = f),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) => _TransactionTile(transaction: sorted[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sort Chip Bar ─────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final _SortField current;
  final ValueChanged<_SortField> onSelect;

  const _SortBar({required this.current, required this.onSelect});

  static const _labels = {
    _SortField.date: 'Date',
    _SortField.amountHigh: 'Amount ↓',
    _SortField.amountLow: 'Amount ↑',
    _SortField.type: 'Type',
    _SortField.category: 'Category',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.card.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.sort, size: 16, color: context.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _SortField.values.map((f) {
                  final isSelected = f == current;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSelect(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primary
                              : context.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? context.primary
                                : context.textDim.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _labels[f]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: isSelected ? Colors.white : context.textDim,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grouped by date (default Date sort) ──────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _GroupedList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Build sort bar wrapper
    return Column(
      children: [
        _SortBar(
          current: _SortField.date,
          onSelect: (f) {
            // find ancestor state and update
            final state = context
                .findAncestorStateOfType<_TransactionsListScreenState>();
            state?.setState(() => state._sortField = f);
          },
        ),
        Expanded(
          child: _GroupedListBody(transactions: transactions),
        ),
      ],
    );
  }
}

class _GroupedListBody extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _GroupedListBody({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.timestamp);
      grouped.putIfAbsent(dateStr, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final txList = grouped[date]!;

        double dailyTotal = 0;
        for (var t in txList) {
          if (t.type == TransactionType.expense) dailyTotal -= t.amount;
          else if (t.type == TransactionType.income) dailyTotal += t.amount;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: context.card.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    '${dailyTotal < 0 ? '-' : ''}Rp ${NumberFormat('#,##0', 'en_US').format(dailyTotal.abs())}',
                    style: TextStyle(
                      color: context.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            ...txList.map((t) => _TransactionTile(transaction: t)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final sign = isIncome ? '+' : '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: context.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.category?.name ?? 'transfer'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textDim,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign Rp${NumberFormat('#,##0', 'en_US').format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  color: context.textDim,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
