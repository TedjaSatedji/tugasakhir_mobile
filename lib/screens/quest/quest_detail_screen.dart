import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/time_converter.dart';
import '../../models/quest_model.dart';
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';

class QuestDetailScreen extends StatefulWidget {
  final QuestModel quest;

  const QuestDetailScreen({
    super.key,
    required this.quest,
  });

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // To make sure we have the latest state of the quest
    return Consumer<QuestProvider>(
      builder: (context, questProvider, _) {
        final currentQuest = questProvider.quests.firstWhere(
          (q) => q.id == widget.quest.id,
          orElse: () => widget.quest,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Target'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () async {
                  await questProvider.deleteQuest(currentQuest.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Target dihapus')),
                  );
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  currentQuest.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentQuest.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(currentQuest.status),
                    style: TextStyle(
                      color: _getStatusColor(currentQuest.status),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currentQuest.description.isEmpty ? 'Tidak ada deskripsi' : currentQuest.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),

                // Rewards & Target
                const Text(
                  'Detail Finansial',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _RewardCard(
                        icon: Icons.track_changes,
                        label: 'Target (Rp)',
                        value: currentQuest.targetAmount.toStringAsFixed(0),
                        color: AppColors.primaryNeon,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _RewardCard(
                        icon: Icons.star,
                        label: 'Reward XP',
                        value: '${currentQuest.xpReward}',
                        color: AppColors.xpColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Deadline
                const Text(
                  'Tenggat Waktu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  TimeConverter.formatDateTime(currentQuest.deadline),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sisa waktu: ${TimeConverter.getTimeUntil(currentQuest.deadline)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),

                // Progress
                const Text(
                  'Progres Tabungan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp${currentQuest.currentSavedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp${currentQuest.targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentQuest.targetAmount > 0 ? (currentQuest.currentSavedAmount / currentQuest.targetAmount).clamp(0.0, 1.0) : 0,
                        minHeight: 12,
                        backgroundColor: AppColors.darkCard,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Action Buttons
                if (currentQuest.status == QuestStatus.active)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _showAddFundsDialog(context, currentQuest);
                        },
                        icon: const Icon(Icons.add_card),
                        label: const Text('Tambah Dana'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNeon,
                          foregroundColor: AppColors.darkBg,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddFundsDialog(BuildContext context, QuestModel quest) {
    final TextEditingController amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: const Text(
            'Tambah Dana',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Masukkan jumlah (Rp)',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryNeon),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryNeon),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primaryNeon,
                            onPrimary: AppColors.darkBg,
                            surface: AppColors.darkCard,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryNeon, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primaryNeon, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  final result = await context
                      .read<QuestProvider>()
                      .addFundsToGoal(quest.id, amount);
                  await context.read<CharacterProvider>().addXpForAmount(amount);
                  if (result.totalXp > 0) {
                    await context.read<CharacterProvider>().addXP(result.totalXp);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dana berhasil ditambahkan!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNeon,
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(color: AppColors.darkBg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return AppColors.info;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return 'Aktif';
      case QuestStatus.completed:
        return 'Tercapai';
      case QuestStatus.failed:
        return 'Gagal';
    }
  }
}

class _RewardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RewardCard({
    required this.icon,
    required this.label,
    required this.value,
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}