import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Shows a floating "+N 🪙" animation that floats up and fades out.
/// Usage: CoinRewardOverlay.show(context, 25);
class CoinRewardOverlay {
  static void show(BuildContext context, int amount, {Offset? anchor}) {
    if (amount <= 0) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoinRewardWidget(
        amount: amount,
        anchor: anchor,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _CoinRewardWidget extends StatefulWidget {
  final int amount;
  final Offset? anchor;
  final VoidCallback onDone;

  const _CoinRewardWidget({
    required this.amount,
    required this.onDone,
    this.anchor,
  });

  @override
  State<_CoinRewardWidget> createState() => _CoinRewardWidgetState();
}

class _CoinRewardWidgetState extends State<_CoinRewardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    _slide = Tween<double>(begin: 0.0, end: -70.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final anchorX = widget.anchor?.dx ?? screenW / 2;
    final anchorY = widget.anchor?.dy ?? screenH * 0.55;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left: anchorX - 48,
        top: anchorY + _slide.value,
        child: IgnorePointer(
          child: Opacity(
            opacity: _fade.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.xpColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.xpColor.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '+${widget.amount} 🪙',
                style: const TextStyle(
                  color: AppColors.xpColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
