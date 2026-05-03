import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shop_item_model.dart';
import '../../providers/character_provider.dart';
import '../../providers/shop_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CharacterProvider, ShopProvider>(
      builder: (context, charProvider, shopProvider, _) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Text(
                    '🛒 Shop',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _CoinChip(coins: charProvider.coins),
                  const SizedBox(width: 8),
                ],
              ),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.videogame_asset), text: 'Upgrades'),
                  Tab(icon: Icon(Icons.palette), text: 'Frames'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _UpgradesTab(charProvider: charProvider, shopProvider: shopProvider),
                _FramesTab(charProvider: charProvider, shopProvider: shopProvider),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Coin Chip ─────────────────────────────────────────────────────────────────

class _CoinChip extends StatelessWidget {
  final int coins;
  const _CoinChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.xpColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.xpColor.withOpacity(0.5)),
      ),
      child: Text(
        '🪙 $coins',
        style: const TextStyle(
          color: AppColors.xpColor,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Upgrades Tab ──────────────────────────────────────────────────────────────

class _UpgradesTab extends StatelessWidget {
  final CharacterProvider charProvider;
  final ShopProvider shopProvider;
  const _UpgradesTab({required this.charProvider, required this.shopProvider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Upgrade permanen untuk Budget Invaders.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
        ),
        ...UpgradeDef.catalogue.map((def) => _UpgradeCard(
              def: def,
              currentLevel: shopProvider.upgrades.currentLevel(def.type),
              charProvider: charProvider,
              shopProvider: shopProvider,
            )),
      ],
    );
  }
}

class _UpgradeCard extends StatefulWidget {
  final UpgradeDef def;
  final int currentLevel;
  final CharacterProvider charProvider;
  final ShopProvider shopProvider;

  const _UpgradeCard({
    required this.def,
    required this.currentLevel,
    required this.charProvider,
    required this.shopProvider,
  });

  @override
  State<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<_UpgradeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBuy() async {
    final isMax = widget.currentLevel >= widget.def.maxLevel;
    final cost = isMax ? 0 : widget.def.costsPerLevel[widget.currentLevel];
    final canAfford = widget.charProvider.coins >= cost;

    if (isMax || !canAfford) {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      return;
    }

    final ok = await widget.shopProvider.purchaseUpgrade(
      widget.charProvider,
      widget.def.type,
    );
    if (!ok && mounted) {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMax = widget.currentLevel >= widget.def.maxLevel;
    final cost = isMax ? 0 : widget.def.costsPerLevel[widget.currentLevel];
    final canAfford = widget.charProvider.coins >= cost;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMax
                ? AppColors.xpColor.withOpacity(0.5)
                : AppColors.primaryNeon.withOpacity(0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.def.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.def.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.def.description,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isMax)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.xpColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.xpColor.withOpacity(0.5)),
                    ),
                    child: const Text('MAX',
                        style: TextStyle(
                          color: AppColors.xpColor,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                  )
                else
                  _BuyButton(
                    label: '🪙 $cost',
                    canAfford: canAfford,
                    onTap: _onBuy,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Level progress dots
            Row(
              children: List.generate(widget.def.maxLevel, (i) {
                final filled = i < widget.currentLevel;
                return Container(
                  width: 28,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: filled
                        ? AppColors.primaryNeon
                        : AppColors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              // Next level effect label
            ),
            if (!isMax) ...[
              const SizedBox(height: 8),
              Text(
                'Lv${widget.currentLevel + 1}: ${widget.def.effectLabels[widget.currentLevel]}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryNeon,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Frames Tab ────────────────────────────────────────────────────────────────

class _FramesTab extends StatelessWidget {
  final CharacterProvider charProvider;
  final ShopProvider shopProvider;
  const _FramesTab({required this.charProvider, required this.shopProvider});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: AvatarFrame.catalogue.length,
      itemBuilder: (context, i) {
        final frame = AvatarFrame.catalogue[i];
        return _FrameCard(
          frame: frame,
          isOwned: shopProvider.isFrameOwned(frame.id),
          isEquipped: shopProvider.equippedFrameId == frame.id,
          charProvider: charProvider,
          shopProvider: shopProvider,
        );
      },
    );
  }
}

class _FrameCard extends StatefulWidget {
  final AvatarFrame frame;
  final bool isOwned;
  final bool isEquipped;
  final CharacterProvider charProvider;
  final ShopProvider shopProvider;

  const _FrameCard({
    required this.frame,
    required this.isOwned,
    required this.isEquipped,
    required this.charProvider,
    required this.shopProvider,
  });

  @override
  State<_FrameCard> createState() => _FrameCardState();
}

class _FrameCardState extends State<_FrameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onBuyOrEquip() async {
    if (widget.isEquipped) return;
    if (widget.isOwned) {
      await widget.shopProvider.equipFrame(widget.frame.id);
      HapticFeedback.lightImpact();
      return;
    }
    final ok = await widget.shopProvider.purchaseFrame(
      widget.charProvider,
      widget.frame.id,
    );
    if (!ok && mounted) {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
    } else if (ok) {
      HapticFeedback.lightImpact();
      // Auto-equip on purchase
      await widget.shopProvider.equipFrame(widget.frame.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isEquipped
                ? widget.frame.color
                : AppColors.primaryNeon.withOpacity(0.2),
            width: widget.isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Frame preview
            widget.frame.isAnimated
                ? _HolographicPreview()
                : Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.frame.color, width: 3.5),
                      color: widget.frame.color.withOpacity(0.1),
                    ),
                    child: Icon(Icons.person, color: widget.frame.color, size: 32),
                  ),
            const SizedBox(height: 10),
            Text(
              '${widget.frame.emoji} ${widget.frame.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.5)),
                ),
                child: const Text('✓ Equipped',
                    style: TextStyle(
                      color: AppColors.success,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    )),
              )
            else if (widget.isOwned)
              _BuyButton(label: 'Equip', canAfford: true, onTap: _onBuyOrEquip)
            else
              _BuyButton(
                label: widget.frame.cost == 0 ? 'Free' : '🪙 ${widget.frame.cost}',
                canAfford: widget.charProvider.coins >= widget.frame.cost,
                onTap: _onBuyOrEquip,
              ),
          ],
        ),
      ),
    );
  }
}

// Animated holographic preview for frame_holo
class _HolographicPreview extends StatefulWidget {
  const _HolographicPreview();
  @override
  State<_HolographicPreview> createState() => _HolographicPreviewState();
}

class _HolographicPreviewState extends State<_HolographicPreview>
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
        final t = _ctrl.value;
        final colors = [
          Color.lerp(AppColors.primaryNeon, AppColors.secondaryNeon, t)!,
          Color.lerp(AppColors.secondaryNeon, AppColors.levelUpColor, t)!,
          Color.lerp(AppColors.levelUpColor, AppColors.primaryNeon, t)!,
        ];
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: colors),
          ),
          child: const Padding(
            padding: EdgeInsets.all(3),
            child: CircleAvatar(
              backgroundColor: AppColors.darkCard,
              child: Icon(Icons.person, color: Colors.white54, size: 28),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared Buy Button ─────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  final String label;
  final bool canAfford;
  final VoidCallback onTap;

  const _BuyButton({
    required this.label,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: canAfford
              ? AppColors.primaryNeon.withOpacity(0.15)
              : AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canAfford
                ? AppColors.primaryNeon.withOpacity(0.6)
                : AppColors.error.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: canAfford ? AppColors.primaryNeon : AppColors.error,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
