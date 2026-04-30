import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/quest_model.dart';
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/transaction_provider.dart';
import '../quest/quest_list_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeBody(),
      const QuestListScreen(),
      const WalletScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.homeTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: AppStrings.questTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: AppStrings.walletTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profileTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppStrings.settingsTitle,
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryNeon.withOpacity(0.2),
                    AppColors.secondaryNeon.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang kembali!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<CharacterProvider>(
                    builder: (context, charProvider, _) {
                      final char = charProvider.character;
                      return Text(
                        char?.name ?? 'Hero',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryNeon,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Stats
            const Text(
              'Statistik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 15),
            Consumer2<CharacterProvider, TransactionProvider>(
              builder: (context, charProvider, transProvider, _) {
                final char = charProvider.character;
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: AppStrings.level,
                        value: '${char?.level ?? 1}',
                        color: AppColors.levelUpColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: AppStrings.experience,
                        value: '${char?.totalXP ?? 0}',
                        color: AppColors.xpColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        title: AppStrings.totalSavings,
                        value: 'Rp${transProvider.balance.toStringAsFixed(0)}',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            // Daily Quest
            const Text(
              AppStrings.dailyQuest,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 15),
            Consumer<QuestProvider>(
              builder: (context, questProvider, _) {
                final dailyQuests = questProvider.quests
                    .where((q) => q.status == QuestStatus.active)
                    .take(3)
                    .toList();

                if (dailyQuests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada quest hari ini',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: dailyQuests
                      .map((quest) => _QuestTile(quest: quest))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
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
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

class _QuestTile extends StatelessWidget {
  final QuestModel quest;

  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryNeon.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '+${quest.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.xpColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            color: AppColors.success,
            onPressed: () {
              context.read<QuestProvider>().completeQuest(quest.id);
              context.read<CharacterProvider>().addXP(quest.xpReward);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.questCompleted),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}