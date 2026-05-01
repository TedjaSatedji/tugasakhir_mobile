import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/quest_model.dart';
import '../../providers/quest_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'create_quest_screen.dart';
import 'quest_detail_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateQuestScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryNeon,
        child: const Icon(Icons.add, color: AppColors.darkBg),
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
                      color: AppColors.primaryNeon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      size: 80,
                      color: AppColors.primaryNeon,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Belum ada Target',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Tentukan tujuan keuanganmu dan pantau progresnya setiap hari!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
                    label: const Text(
                      'Buat Target Pertama',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: AppColors.darkBg,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
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
                        hintText: 'Cari target...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryNeon),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryNeon.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primaryNeon.withOpacity(0.3)),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Semua'),
                            selected: _selectedStatusFilter == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = null;
                              });
                            },
                            selectedColor: AppColors.primaryNeon.withOpacity(0.3),
                            checkmarkColor: AppColors.primaryNeon,
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == null ? AppColors.primaryNeon : AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            backgroundColor: AppColors.darkCard,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Aktif'),
                            selected: _selectedStatusFilter == QuestStatus.active,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = QuestStatus.active;
                              });
                            },
                            selectedColor: AppColors.primaryNeon.withOpacity(0.3),
                            checkmarkColor: AppColors.primaryNeon,
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == QuestStatus.active ? AppColors.primaryNeon : AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            backgroundColor: AppColors.darkCard,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Selesai'),
                            selected: _selectedStatusFilter == QuestStatus.completed,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = QuestStatus.completed;
                              });
                            },
                            selectedColor: AppColors.success.withOpacity(0.3),
                            checkmarkColor: AppColors.success,
                            labelStyle: TextStyle(
                              color: _selectedStatusFilter == QuestStatus.completed ? AppColors.success : AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            backgroundColor: AppColors.darkCard,
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
                          'Tidak ada target yang sesuai',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
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
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getStatusColor(),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(),
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
                        const Text(
                          'Terkumpul',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${quest.currentSavedAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: _getStatusColor(),
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
                        const Text(
                          'Target',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${quest.targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
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
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
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
              color: AppColors.darkBg.withOpacity(0.5),
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
                    icon: const Icon(Icons.add, size: 18, color: AppColors.darkBg,),
                    label: const Text(
                      'Tambah Dana',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: AppColors.darkBg,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.primaryNeon),
            SizedBox(width: 10),
            Text(
              'Tambah Dana',
              style: TextStyle(
                color: AppColors.textPrimary,
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
              'Target: ${quest.title}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.primaryNeon, 
                fontSize: 24, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  color: AppColors.primaryNeon, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryNeon, width: 2),
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
                  child: const Text(
                    'Batal',
                    style: TextStyle(
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
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      context.read<QuestProvider>().addFundsToGoal(quest.id, amount);
                      
                      context.read<NotificationProvider>().addNotification(
                        NotificationModel(
                          title: 'Dana Ditambahkan',
                          message: 'Rp${amount.toStringAsFixed(0)} ditambahkan ke target "${quest.title}"',
                          type: NotificationType.system,
                        ),
                      );

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dana berhasil ditambahkan!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: AppColors.darkBg,
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

  Color _getStatusColor() {
    switch (quest.status) {
      case QuestStatus.active:
        return AppColors.primaryNeon;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (quest.status) {
      case QuestStatus.active:
        return 'SEDANG BERJALAN';
      case QuestStatus.completed:
        return 'TERCAPAI';
      case QuestStatus.failed:
        return 'GAGAL';
    }
  }
}