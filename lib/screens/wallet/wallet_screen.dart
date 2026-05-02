import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'spending_map_screen.dart';
import 'transaction_detail_screen.dart';
import '../tools/currency_converter_screen.dart';
import '../tools/time_converter_screen.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _selectedTypeFilter;
  ExpenseCategory? _selectedCategoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('walletTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.primaryNeon),
            tooltip: 'spendingMap'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpendingMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange, color: AppColors.primaryNeon),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurrencyConverterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.public, color: AppColors.secondaryNeon),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimeConverterScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryNeon,
        child: const Icon(Icons.add, color: AppColors.darkBg),
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
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'totalBalance'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textDim,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rp${NumberFormat('#,##0', 'en_US').format(transProvider.balance)}',
                        textAlign: TextAlign.center,
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
                        title: 'income'.tr(),
                        amount: transProvider.totalIncome,
                        icon: Icons.arrow_downward,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: 'expense'.tr(),
                        amount: transProvider.totalExpense,
                        icon: Icons.arrow_upward,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Search and Filter Section
                Text(
                  'transactionHistory'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: context.text,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'searchTransaction'.tr(),
                    hintStyle: TextStyle(color: context.textDim),
                    prefixIcon: Icon(Icons.search, color: context.primary),
                    filled: true,
                    fillColor: context.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary.withOpacity(0.3)),
                    ),
                  ),
                  style: TextStyle(color: context.text, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('all'.tr()),
                        selected: _selectedTypeFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTypeFilter = null;
                          });
                        },
                        selectedColor: context.primary.withOpacity(0.3),
                        checkmarkColor: context.primary,
                        labelStyle: TextStyle(
                          color: _selectedTypeFilter == null ? context.primary : context.textDim,
                          fontFamily: 'Poppins',
                        ),
                        backgroundColor: context.card,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('income'.tr()),
                        selected: _selectedTypeFilter == TransactionType.income,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTypeFilter = TransactionType.income;
                          });
                        },
                        selectedColor: AppColors.success.withOpacity(0.3),
                        checkmarkColor: AppColors.success,
                        labelStyle: TextStyle(
                          color: _selectedTypeFilter == TransactionType.income ? AppColors.success : context.textDim,
                          fontFamily: 'Poppins',
                        ),
                        backgroundColor: context.card,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('expense'.tr()),
                        selected: _selectedTypeFilter == TransactionType.expense,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTypeFilter = TransactionType.expense;
                          });
                        },
                        selectedColor: AppColors.error.withOpacity(0.3),
                        checkmarkColor: AppColors.error,
                        labelStyle: TextStyle(
                          color: _selectedTypeFilter == TransactionType.expense ? AppColors.error : context.textDim,
                          fontFamily: 'Poppins',
                        ),
                        backgroundColor: context.card,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Builder(
                  builder: (context) {
                    final query = _searchController.text.toLowerCase();
                    var filteredTransactions = transProvider.transactions.where((t) {
                      final matchesQuery = t.description.toLowerCase().contains(query);
                      final matchesType = _selectedTypeFilter == null || t.type == _selectedTypeFilter;
                      final matchesCategory = _selectedCategoryFilter == null || t.category == _selectedCategoryFilter;
                      return matchesQuery && matchesType && matchesCategory;
                    }).toList();

                    if (filteredTransactions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'noTransactionYet'.tr(),
                            style: TextStyle(
                              color: context.textDim,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return _TransactionTile(transaction: transaction);
                      },
                    );
                  }
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
        color: context.card,
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
                style: TextStyle(
                  fontSize: 12,
                  color: context.textDim,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rp${NumberFormat('#,##0', 'en_US').format(amount)}',
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