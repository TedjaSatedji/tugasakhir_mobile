import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/quest_model.dart';
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/transaction_provider.dart';
import '../wallet/wallet_screen.dart';
import '../wallet/add_transaction_screen.dart';
import '../quest/quest_list_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/notification_provider.dart';
import 'notification_screen.dart';
import '../../core/services/sync_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  // ── Shake detection ──────────────────────────────────────────────────
  static const double _shakeThreshold = 15.0; // m/s²
  static const Duration _shakeCooldown = Duration(seconds: 2);
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShake = DateTime(0);
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeBody(onRefresh: _refreshData),
      const QuestListScreen(),
      const WalletScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
    _startShakeDetection();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await SyncService().pullAll();
    if (!mounted) return;
    context.read<TransactionProvider>().loadTransactions();
    context.read<QuestProvider>().loadQuests();
    context.read<CharacterProvider>().loadCharacter();
  }

  void _startShakeDetection() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((AccelerometerEvent event) {
      final double magnitude = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      // Subtract gravity (~9.8 m/s²) to get net acceleration
      final double netAccel = (magnitude - 9.8).abs();

      if (netAccel > _shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShake) > _shakeCooldown) {
          _lastShake = now;
          _openAddTransaction();
        }
      }
    });
  }

  void _openAddTransaction() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.add_card, color: AppColors.darkBg),
            SizedBox(width: 10),
            Text(
              '📳 Shake detected — Tambah Transaksi!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: AppColors.darkBg,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryNeon,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkBg,
        selectedItemColor: AppColors.primaryNeon,
        unselectedItemColor: AppColors.textSecondary,
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
            icon: Icon(Icons.track_changes),
            label: 'Target',
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
  final Future<void> Function() onRefresh;
  const _HomeBody({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notifProvider.unreadCount > 9 ? '9+' : '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        backgroundColor: AppColors.darkCard,
        color: AppColors.primaryNeon,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Gamification Banner
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.primaryNeon.withOpacity(0.3),
                ),
              ),
              child: Consumer<CharacterProvider>(
                builder: (context, charProvider, _) {
                  final char = charProvider.character;
                  return Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNeon.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: (char?.avatarUrl.isNotEmpty ?? false)
                              ? (char!.avatarUrl.startsWith('http')
                                  ? CachedNetworkImage(imageUrl: char.avatarUrl, fit: BoxFit.cover)
                                  : Image.file(File(char.avatarUrl), fit: BoxFit.cover))
                              : const Icon(
                                  Icons.person,
                                  color: AppColors.primaryNeon,
                                ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${char?.name ?? 'Hero'}!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  'Level ${char?.level ?? 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.levelUpColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _xpProgress(char?.totalXP ?? 0),
                                      backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                                      color: AppColors.xpColor,
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${char?.totalXP ?? 0} XP',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.xpColor,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Financial Overview
            const Text(
              'Ringkasan Keuangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 15),
            Consumer<TransactionProvider>(
              builder: (context, transProvider, _) {
                return Container(
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
                        AppStrings.totalSavings,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Rp${transProvider.balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNeon,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              title: AppStrings.income,
                              amount: 'Rp${transProvider.totalIncome.toStringAsFixed(0)}',
                              icon: Icons.arrow_downward,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniStatCard(
                              title: AppStrings.expense,
                              amount: 'Rp${transProvider.totalExpense.toStringAsFixed(0)}',
                              icon: Icons.arrow_upward,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Daily Missions
            const Text(
              'Misi Harian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 15),
            Consumer<QuestProvider>(
              builder: (context, questProvider, _) {
                final dailyMissions = questProvider.dailyMissions;

                if (dailyMissions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada misi hari ini',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: dailyMissions
                      .map((mission) => _DailyMissionTile(mission: mission))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMissionTile extends StatelessWidget {
  final DailyMission mission;

  const _DailyMissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mission.isCompleted 
              ? AppColors.success.withOpacity(0.5) 
              : AppColors.primaryNeon.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    decoration: mission.isCompleted ? TextDecoration.lineThrough : null,
                    color: mission.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '+${mission.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.xpColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (mission.isCompleted)
            const Icon(Icons.check_circle, color: AppColors.success)
          else
            const Icon(Icons.circle_outlined, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

double _xpProgress(int totalXp) {
  final level = CharacterProvider.levelForXp(totalXp);
  final intoLevel = CharacterProvider.xpIntoLevel(totalXp);
  final required = CharacterProvider.xpRequiredForNextLevel(level);
  if (required <= 0) {
    return 0;
  }
  return (intoLevel / required).clamp(0.0, 1.0);
}