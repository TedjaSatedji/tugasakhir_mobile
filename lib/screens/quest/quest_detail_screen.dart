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
  late int _currentProgress;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.quest.progressPercentage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.questTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.quest.title,
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
                color: _getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
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
              widget.quest.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 30),

            // Rewards
            const Text(
              'Reward',
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
                    icon: Icons.star,
                    label: 'XP',
                    value: '${widget.quest.xpReward}',
                    color: AppColors.xpColor,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _RewardCard(
                    icon: Icons.attach_money,
                    label: 'Rupiah',
                    value: 'Rp${widget.quest.moneyReward.toStringAsFixed(0)}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Deadline
            const Text(
              'Deadline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              TimeConverter.formatDateTime(widget.quest.deadline),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sisa waktu: ${TimeConverter.getTimeUntil(widget.quest.deadline)}',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 30),

            // Progress
            const Text(
              'Progress',
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
                      'Progres: $_currentProgress%',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: AppColors.primaryNeon,
                      onPressed: () {
                        if (_currentProgress < 100) {
                          setState(() {
                            _currentProgress += 10;
                          });
                          context.read<QuestProvider>().updateQuestProgress(
                            widget.quest.id,
                            _currentProgress,
                          );
                        }
                      },
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _currentProgress / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.darkCard,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryNeon,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Action Buttons
            if (widget.quest.status == QuestStatus.active)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<QuestProvider>().completeQuest(widget.quest.id);
                      context.read<CharacterProvider>().addXP(widget.quest.xpReward);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.successCreateQuestMessage),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text(AppStrings.completeQuest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.quest.status) {
      case QuestStatus.active:
        return AppColors.info;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (widget.quest.status) {
      case QuestStatus.active:
        return 'Active';
      case QuestStatus.completed:
        return 'Completed';
      case QuestStatus.failed:
        return 'Failed';
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
          ),
        ],
      ),
    );
  }
}