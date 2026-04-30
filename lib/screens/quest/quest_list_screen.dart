import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/quest_model.dart';
import '../../providers/quest_provider.dart';
import 'create_quest_screen.dart';
import 'quest_detail_screen.dart';

class QuestListScreen extends StatelessWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.questTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateQuestScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuestProvider>(
        builder: (context, questProvider, _) {
          if (questProvider.quests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum ada quest',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 30),
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
                    label: const Text(AppStrings.createQuest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: questProvider.quests.length,
            itemBuilder: (context, index) {
              final quest = questProvider.quests[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestDetailScreen(quest: quest),
                    ),
                  );
                },
                child: _QuestCard(quest: quest),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final QuestModel quest;

  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quest.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.xpColor,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '+${quest.xpReward} XP',
                    style: const TextStyle(
                      color: AppColors.xpColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              Text(
                'Rp${quest.moneyReward.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (quest.status) {
      case QuestStatus.active:
        return AppColors.info;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.failed:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    switch (quest.status) {
      case QuestStatus.active:
        return 'Active';
      case QuestStatus.completed:
        return 'Completed';
      case QuestStatus.failed:
        return 'Failed';
    }
  }
}