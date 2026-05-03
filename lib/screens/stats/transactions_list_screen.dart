import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/theme_extensions.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../wallet/transaction_detail_screen.dart';

class TransactionsListScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins')),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transProvider, _) {
          var filtered = transProvider.transactions.where((t) {
            if (filterDay != null) {
              return t.timestamp.year == filterDay!.year &&
                     t.timestamp.month == filterDay!.month &&
                     t.timestamp.day == filterDay!.day;
            }
            if (filterMonth != null && filterYear != null) {
              return t.timestamp.year == filterYear &&
                     t.timestamp.month == filterMonth;
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

          // Group by date
          final Map<String, List<TransactionModel>> grouped = {};
          for (var t in filtered) {
            final dateStr = DateFormat('yyyy-MM-dd').format(t.timestamp);
            if (!grouped.containsKey(dateStr)) {
              grouped[dateStr] = [];
            }
            grouped[dateStr]!.add(t);
          }

          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final transactions = grouped[date]!;
              
              double dailyTotal = 0;
              for (var t in transactions) {
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
                  ...transactions.map((t) => _TransactionTile(transaction: t)),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

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
