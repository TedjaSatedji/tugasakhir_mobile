import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/quest_model.dart'; // used by _DailyMissionTile
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/level_up_overlay.dart';
import '../wallet/wallet_screen.dart';
import '../wallet/add_transaction_screen.dart';
import '../quest/quest_list_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../games/budget_invaders_screen.dart';
import '../shop/shop_screen.dart';
import '../../providers/notification_provider.dart';
import 'notification_screen.dart';
import '../../core/services/sync_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  final GlobalKey<BudgetInvadersScreenState> _budgetInvadersKey = GlobalKey();

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
      const WalletScreen(),
      const QuestListScreen(),
      const StatsScreen(),
      const ProfileScreen(),
      BudgetInvadersScreen(key: _budgetInvadersKey),
    ];
    _startShakeDetection();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      // Listen for level-ups and show fullscreen overlay
      final charProvider = context.read<CharacterProvider>();
      charProvider.levelUpNotifier.addListener(() {
        final newLevel = charProvider.levelUpNotifier.value;
        if (newLevel != null && mounted) {
          LevelUpOverlay.show(context, newLevel);
          charProvider.levelUpNotifier.value = null;
        }
      });
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
      if (_selectedIndex == 5) return;
      final gameState = _budgetInvadersKey.currentState;
      if (gameState != null && gameState.isGameActive) return;

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
        content: Row(
          children: [
            const Icon(Icons.add_card, color: AppColors.darkBg),
            const SizedBox(width: 10),
            Text(
              'shakeToAddTransaction'.tr(),
              style: const TextStyle(
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
        backgroundColor: context.card,
        selectedItemColor: context.primary,
        unselectedItemColor: context.textDim,
        onTap: (index) async {
          if (_selectedIndex == 5 && index != 5) {
            final state = _budgetInvadersKey.currentState;
            if (state != null && state.isGameActive) {
              final shouldPop = await state.onWillPop();
              if (!shouldPop) return;
              state.resetGame();
            }
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'homeTitle'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.wallet),
            label: 'walletTitle'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.track_changes),
            label: 'target'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_rounded),
            label: 'statsTitle'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'profileTitle'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.videogame_asset_rounded),
            label: 'game'.tr(),
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
        title: Text('homeTitle'.tr()),
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
        backgroundColor: context.card,
        color: context.primary,
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
                color: context.card,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: context.primary.withOpacity(0.3),
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
                              : Icon(
                                  Icons.person,
                                  color: context.primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'hello'.tr(args: [char?.name ?? 'Hero']),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: context.text,
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
                            const SizedBox(height: 6),
                            // Coin chip — tappable → ShopScreen
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ShopScreen()),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.xpColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.xpColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  '🪙 ${char?.coins ?? 0}',
                                  style: const TextStyle(
                                    color: AppColors.xpColor,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
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
            Text(
              'financialOverview'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
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
                      Text(
                        'totalSavings'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.text,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Rp${NumberFormat('#,##0', 'en_US').format(transProvider.balance)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              title: 'income'.tr(),
                              amount: 'Rp${NumberFormat('#,##0', 'en_US').format(transProvider.totalIncome)}',
                              icon: Icons.arrow_downward,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniStatCard(
                              title: 'expense'.tr(),
                              amount: 'Rp${NumberFormat('#,##0', 'en_US').format(transProvider.totalExpense)}',
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
            Text(
              'dailyQuest'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
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
                        'noMissionToday'.tr(),
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
        color: context.bg.withOpacity(0.5),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textDim,
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
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mission.isCompleted 
              ? AppColors.success.withOpacity(0.5) 
              : context.primary.withOpacity(0.3),
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
                    color: mission.isCompleted ? context.textDim : context.text,
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