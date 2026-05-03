import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/shop_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../shop/shop_screen.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profileTitle'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character Info Card
            Consumer2<CharacterProvider, ShopProvider>(
              builder: (context, charProvider, shopProvider, _) {
                final character = charProvider.character;
                final frameColor = shopProvider.equippedFrame.isAnimated
                    ? AppColors.primaryNeon
                    : shopProvider.equippedFrame.color;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  character?.name ?? 'Hero',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    color: context.text,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _titleForLevel(character?.level ?? 1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryNeon,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Avatar with equipped frame
                          shopProvider.equippedFrame.isAnimated
                              ? _AnimatedFrameAvatar(character: character)
                              : Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: frameColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: (character?.avatarUrl.isNotEmpty ?? false)
                                        ? (character!.avatarUrl.startsWith('http')
                                            ? CachedNetworkImage(imageUrl: character.avatarUrl, fit: BoxFit.cover)
                                            : Image.file(File(character.avatarUrl), fit: BoxFit.cover))
                                        : Icon(
                                            Icons.person,
                                            size: 40,
                                            color: context.primary,
                                          ),
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              label: 'level'.tr(),
                              value: '${character?.level ?? 1}',
                              color: AppColors.levelUpColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoTile(
                              label: 'experience'.tr(),
                              value: '${character?.totalXP ?? 0}',
                              color: AppColors.xpColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoTile(
                              label: 'Coins',
                              value: '🪙 ${character?.coins ?? 0}',
                              color: AppColors.xpColor,
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





            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  );
                },
                icon: const Text('🛒', style: TextStyle(fontSize: 16)),
                label: const Text('Shop', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.xpColor.withOpacity(0.15),
                  foregroundColor: AppColors.xpColor,
                  side: const BorderSide(color: AppColors.xpColor, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: Text('editProfile'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: context.bg,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: Text('settingsTitle'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.card,
                  foregroundColor: context.text,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                },
                icon: const Icon(Icons.logout),
                label: Text('logout'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textDim,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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

String _titleForLevel(int level) {
  if (level >= 20) return 'LEGEND';
  if (level >= 15) return 'ELITE';
  if (level >= 10) return 'VETERAN';
  if (level >= 5) return 'ADVENTURER';
  return 'NOVICE';
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                color: AppColors.primaryNeon,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFrameAvatar extends StatefulWidget {
  final dynamic character;
  const _AnimatedFrameAvatar({this.character});

  @override
  State<_AnimatedFrameAvatar> createState() => _AnimatedFrameAvatarState();
}

class _AnimatedFrameAvatarState extends State<_AnimatedFrameAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final hue = _ctrl.value * 360.0;
        final colors = [
          HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor(),
          HSVColor.fromAHSV(1, (hue + 90) % 360, 1, 1).toColor(),
          HSVColor.fromAHSV(1, (hue + 180) % 360, 1, 1).toColor(),
          HSVColor.fromAHSV(1, (hue + 270) % 360, 1, 1).toColor(),
          HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor(), // close the loop
        ];
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: colors,
              transform: GradientRotation(_ctrl.value * 2 * math.pi),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: Container(
                color: AppColors.darkCard,
                child: (widget.character?.avatarUrl?.isNotEmpty ?? false)
                    ? (widget.character!.avatarUrl.startsWith('http')
                        ? Image.network(widget.character!.avatarUrl, fit: BoxFit.cover)
                        : Image.file(File(widget.character!.avatarUrl), fit: BoxFit.cover))
                    : const Icon(Icons.person, size: 36, color: Colors.white54),
              ),
            ),
          ),
        );
      },
    );
  }
}