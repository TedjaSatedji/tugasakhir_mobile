import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/quest_model.dart';
import '../../providers/quest_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/character_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/coin_reward_overlay.dart';
import 'create_quest_screen.dart';
import 'quest_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_snackbar.dart';

const int _maxAmountDigits = 15;

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  final TextEditingController _searchController = TextEditingController();
  QuestStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fabBottomInset = MediaQuery.of(context).padding.bottom + 8;
    return Scaffold(
      appBar: AppBar(
        title: Text('targetSavings'.tr()),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomInset),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateQuestScreen(),
              ),
            );
          },
          backgroundColor: context.primary,
          child: Icon(Icons.add, color: context.bg),
        ),
      ),
      body: Consumer<QuestProvider>(
        builder: (context, questProvider, _) {
          if (questProvider.quests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.savings_outlined,
                      size: 80,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(height: 30),
                    Text(
                      'noTarget'.tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.text,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'noTargetDesc'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textDim,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateQuestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                      'createFirstTarget'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: context.bg,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final query = _searchController.text.toLowerCase();
          final filteredQuests = questProvider.quests.where((q) {
            final matchesQuery = q.title.toLowerCase().contains(query);
            final matchesStatus = _selectedStatusFilter == null || q.status == _selectedStatusFilter;
            return matchesQuery && matchesStatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'searchTarget'.tr(),
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
                            selected: _selectedStatusFilter == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = null;
                              });
                            },
                            selectedColor: context.primary.withOpacity(0.3),
                            checkmarkColor: context.primary,
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == null ? context.primary : context.textDim,
                              fontFamily: 'Poppins',
                            ),
                            backgroundColor: context.card,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('active'.tr()),
                            selected: _selectedStatusFilter == QuestStatus.active,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = QuestStatus.active;
                              });
                            },
                            selectedColor: context.primary.withOpacity(0.3),
                            checkmarkColor: context.primary,
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == QuestStatus.active ? context.primary : context.textDim,
                              fontFamily: 'Poppins',
                            ),
                            backgroundColor: context.card,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('completed'.tr()),
                            selected: _selectedStatusFilter == QuestStatus.completed,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = QuestStatus.completed;
                              });
                            },
                            selectedColor: AppColors.success.withOpacity(0.3),
                            checkmarkColor: AppColors.success,
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == QuestStatus.completed ? AppColors.success : context.textDim,
                              fontFamily: 'Poppins',
                            ),
                            backgroundColor: context.card,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredQuests.isEmpty
                    ? Center(
                        child: Text(
                          'noMatchingTarget'.tr(),
                          style: TextStyle(
                            color: context.textDim,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredQuests.length,
                        itemBuilder: (context, index) {
                          final quest = filteredQuests[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuestDetailScreen(quest: quest),
                                ),
                              );
                            },
                            child: _GoalCard(quest: quest),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  _CurrencyInputFormatter({required this.maxDigits, this.maxValue});

  final int maxDigits;
  final int? maxValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final trimmed = digitsOnly.length > maxDigits
        ? digitsOnly.substring(0, maxDigits)
        : digitsOnly;
    final parsed = int.parse(trimmed);
    final capped = maxValue != null ? parsed.clamp(0, maxValue!) : parsed;
    final formatted =
      NumberFormat.decimalPattern('en_US').format(capped);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final QuestModel quest;

  const _GoalCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final double progress = quest.targetAmount > 0 
        ? (quest.currentSavedAmount / quest.targetAmount).clamp(0.0, 1.0) 
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(context).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(context).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getStatusColor(context),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          color: context.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(context).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText().tr(),
                          style: TextStyle(
                            color: _getStatusColor(context),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'collected'.tr(),
                          style: TextStyle(
                            color: context.textDim,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${NumberFormat('#,##0', 'en_US').format(quest.currentSavedAmount)}',
                          style: TextStyle(
                            color: _getStatusColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'target'.tr(),
                          style: TextStyle(
                            color: context.textDim,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${NumberFormat('#,##0', 'en_US').format(quest.targetAmount)}',
                          style: TextStyle(
                            color: context.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(context)),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Footer Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: context.bg.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.xpColor,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '+${quest.xpReward} XP',
                      style: const TextStyle(
                        color: AppColors.xpColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                if (quest.status == QuestStatus.active)
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddFundsDialog(context);
                    },
                    icon: Icon(Icons.add, size: 18, color: context.bg,),
                    label: Text(
                      'addFunds'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: context.bg,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final remainingAmount = (quest.targetAmount - quest.currentSavedAmount)
        .clamp(0.0, quest.targetAmount)
        .floor();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: context.primary),
            const SizedBox(width: 10),
            Text(
              'addFunds'.tr(),
              style: TextStyle(
                color: context.text,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'target'.tr()}: ${quest.title}',
              style: TextStyle(
                color: context.textDim,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                _CurrencyInputFormatter(
                  maxDigits: _maxAmountDigits,
                  maxValue: remainingAmount,
                ),
              ],
              style: TextStyle(
                color: context.primary, 
                fontSize: 24, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: context.textDim.withOpacity(0.5)),
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  color: context.primary, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.textDim.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'cancel'.tr(),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final rawAmount = amountController.text.replaceAll(',', '');
                    final amount = double.tryParse(rawAmount) ?? 0;
                    if (amount > 0) {
                      final questProvider = context.read<QuestProvider>();
                      final dateKey = questProvider.todayKey();

                      final result = await context
                        .read<QuestProvider>()
                          .addFundsToGoal(quest.id, amount);

                      final amountXp = (amount / 1000).floor();
                      final xpAwarded = amountXp + result.totalXp;
                      final coinsAwarded = result.coinReward;
                          
                      // Log as an expense in the wallet
                      await context.read<TransactionProvider>().addTransaction(
                            TransactionType.expense,
                            ExpenseCategory.other,
                            amount,
                            'Tabungan Target: ${quest.title}',
                            null,
                            timestamp: DateTime.now(),
                        xpAwarded: xpAwarded,
                        coinsAwarded: coinsAwarded,
                        missionCompletedId:
                          result.missionXp > 0 ? 'mission_2' : null,
                        missionCompletedDateKey:
                          result.missionXp > 0 ? dateKey : null,
                          );

                      if (xpAwarded > 0) {
                        await context
                            .read<CharacterProvider>()
                            .addXP(xpAwarded);
                      }
                      if (coinsAwarded > 0) {
                        await context
                            .read<CharacterProvider>()
                            .addCoins(coinsAwarded);
                        if (context.mounted) {
                          CoinRewardOverlay.show(context, coinsAwarded);
                        }
                      }
                      
                      context.read<NotificationProvider>().addNotification(
                        NotificationModel(
                          title: 'fundsAddedTitle'.tr(),
                          message: 'fundsAddedDesc'.tr(args: [NumberFormat('#,##0', 'en_US').format(amount), quest.title]),
                          type: NotificationType.system,
                        ),
                      );

                      Navigator.pop(ctx);
                      AppSnackbar.show(context, message: 'fundsAddedSuccess'.tr(), isError: false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'save'.tr(),
                    style: TextStyle(
                      color: context.bg,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (quest.category) {
      case QuestCategory.gadget:
        return Icons.devices;
      case QuestCategory.travel:
        return Icons.flight_takeoff;
      case QuestCategory.emergency:
        return Icons.health_and_safety;
      case QuestCategory.investment:
        return Icons.trending_up;
      case QuestCategory.other:
        return Icons.category;
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (quest.status) {
      case QuestStatus.active:
        return context.primary;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (quest.status) {
      case QuestStatus.active:
        return 'onGoing'; 
      case QuestStatus.completed:
        return 'completedQuest';
      case QuestStatus.failed:
        return 'failedQuest';
    }
  }
}