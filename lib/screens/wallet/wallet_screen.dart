import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.walletTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryNeon.withOpacity(0.2),
                        AppColors.secondaryNeon.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.primaryNeon.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Total',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rp${transProvider.balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNeon,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Income & Expense Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: AppStrings.income,
                        amount: transProvider.totalIncome,
                        icon: Icons.arrow_downward,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: AppStrings.expense,
                        amount: transProvider.totalExpense,
                        icon: Icons.arrow_upward,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Transactions List
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 15),
                if (transProvider.transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transProvider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transProvider.transactions[index];
                      return _TransactionTile(transaction: transaction);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rp${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category?.name ?? 'Transfer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign Rp${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}