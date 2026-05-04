import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sync_service.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  late AnimationController _podiumCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _podiumAnim;

  @override
  void initState() {
    super.initState();
    _podiumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _podiumAnim = CurvedAnimation(parent: _podiumCtrl, curve: Curves.easeOutBack);
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _podiumCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await SyncService().fetchLeaderboard();
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
        _podiumCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat leaderboard. Cek koneksi internet.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: const Text(
          '🏆 Global Leaderboard',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryNeon),
            onPressed: _fetchLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _entries.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryNeon),
          SizedBox(height: 16),
          Text(
            'Memuat leaderboard...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchLeaderboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi',
                style: TextStyle(fontFamily: 'Poppins')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNeon,
              foregroundColor: AppColors.darkBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎮', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text(
            'Belum ada skor!\nJadi yang pertama bermain\nBudget Invaders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final top3 = _entries.take(3).toList();
    final rest = _entries.skip(3).toList();

    return RefreshIndicator(
      color: AppColors.primaryNeon,
      backgroundColor: AppColors.darkCard,
      onRefresh: _fetchLeaderboard,
      child: CustomScrollView(
        slivers: [
          // ── Header gradient banner ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildStarsBanner(),
          ),
          // ── Podium ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _podiumAnim,
              builder: (_, __) => Opacity(
                opacity: _podiumAnim.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 40 * (1 - _podiumAnim.value)),
                  child: _buildPodium(top3),
                ),
              ),
            ),
          ),
          // ── Rest of leaderboard ────────────────────────────────────────
          if (rest.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = rest[i];
                    return _buildListTile(entry, i);
                  },
                  childCount: rest.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Stars animated banner ────────────────────────────────────────────────

  Widget _buildStarsBanner() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryNeon.withOpacity(0.15),
            AppColors.secondaryNeon.withOpacity(0.10),
            AppColors.xpColor.withOpacity(0.15),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('⭐', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text(
            'Budget Invaders — Top Players',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 8),
          Text('⭐', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  // ── Podium widget ────────────────────────────────────────────────────────

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    // Visual order: #2 left, #1 center (tallest), #3 right
    final slot2 = top3.length > 1 ? top3[1] : null;
    final slot1 = top3.isNotEmpty ? top3[0] : null;
    final slot3 = top3.length > 2 ? top3[2] : null;

    const gold   = Color(0xFFFFD700);
    const silver = Color(0xFFC0C0C0);
    const bronze = Color(0xFFCD7F32);

    // Block heights: #1 tallest, #2 medium, #3 shortest
    const h1 = 130.0;
    const h2 = 90.0;
    const h3 = 65.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar / name row (bottom-aligned) ──────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _PodiumTop(entry: slot2, medal: '🥈', color: silver, isFirst: false, glowCtrl: _glowCtrl)),
                Expanded(child: _PodiumTop(entry: slot1, medal: '🥇', color: gold,   isFirst: true,  glowCtrl: _glowCtrl)),
                Expanded(child: _PodiumTop(entry: slot3, medal: '🥉', color: bronze, isFirst: false, glowCtrl: _glowCtrl)),
              ],
            ),
          ),
          // ── Podium blocks row ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _PodiumBlock(height: h2, color: silver, rank: slot2?.rank)),
              Expanded(child: _PodiumBlock(height: h1, color: gold,   rank: slot1?.rank)),
              Expanded(child: _PodiumBlock(height: h3, color: bronze, rank: slot3?.rank)),
            ],
          ),
        ],
      ),
    );
  }

  // ── List tile for rank 4+ ────────────────────────────────────────────────

  Widget _buildListTile(LeaderboardEntry entry, int listIndex) {
    final isMe = entry.isCurrentUser;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primaryNeon.withOpacity(0.08)
            : AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primaryNeon.withOpacity(0.5)
              : AppColors.textSecondary.withOpacity(0.12),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isMe ? AppColors.primaryNeon : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          _SmallAvatar(avatarUrl: entry.avatarUrl, isMe: isMe),
          const SizedBox(width: 12),
          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isMe
                            ? AppColors.primaryNeon
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNeon.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.primaryNeon.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'Kamu',
                          style: TextStyle(
                            color: AppColors.primaryNeon,
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  entry.emailPrefix,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.highScore}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isMe ? AppColors.xpColor : AppColors.textPrimary,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Podium Slot ──────────────────────────────────────────────────────────────

// ── Podium Top (avatar + name + score) ──────────────────────────────────────

class _PodiumTop extends StatelessWidget {
  final LeaderboardEntry? entry;
  final String medal;
  final Color color;
  final bool isFirst;
  final AnimationController glowCtrl;

  const _PodiumTop({
    required this.entry,
    required this.medal,
    required this.color,
    required this.isFirst,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox();
    final avatarSize = isFirst ? 68.0 : 52.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: TextStyle(fontSize: isFirst ? 28 : 20)),
        const SizedBox(height: 4),
        // Glowing avatar ring
        AnimatedBuilder(
          animation: glowCtrl,
          builder: (_, __) {
            final glow = 0.35 + glowCtrl.value * 0.55;
            return Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(glow),
                    blurRadius: isFirst ? 18 : 10,
                    spreadRadius: isFirst ? 3 : 2,
                  ),
                ],
                border: Border.all(color: color, width: isFirst ? 3 : 2.5),
              ),
              child: ClipOval(
                child: _SmallAvatar(
                  avatarUrl: entry!.avatarUrl,
                  isMe: entry!.isCurrentUser,
                  size: avatarSize,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        // Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry!.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 12 : 10,
              color: entry!.isCurrentUser ? AppColors.primaryNeon : color,
            ),
          ),
        ),
        // Score
        Text(
          '${entry!.highScore}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: isFirst ? 13 : 11,
            color: AppColors.xpColor,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Podium Block (the colored step) ─────────────────────────────────────────

class _PodiumBlock extends StatelessWidget {
  final double height;
  final Color color;
  final int? rank;

  const _PodiumBlock({required this.height, required this.color, this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == null) return SizedBox(height: height);
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.7), color.withOpacity(0.3)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        // Uniform border color required for borderRadius to work
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: height > 100 ? 26 : 20,
            color: color.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

// ── Small Avatar ──────────────────────────────────────────────────────────────

class _SmallAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isMe;
  final double size;

  const _SmallAvatar({
    this.avatarUrl,
    required this.isMe,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultIcon(),
          ),
        ),
      );
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMe
            ? AppColors.primaryNeon.withOpacity(0.15)
            : AppColors.darkCard,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.55,
        color: isMe ? AppColors.primaryNeon : AppColors.textSecondary,
      ),
    );
  }
}

// ── Rank frame animated preview for shop ────────────────────────────────────

class RankFramePreview extends StatefulWidget {
  final Color color;
  final double size;
  const RankFramePreview({super.key, required this.color, this.size = 64});

  @override
  State<RankFramePreview> createState() => _RankFramePreviewState();
}

class _RankFramePreviewState extends State<RankFramePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
        final glowOpacity = 0.4 + _ctrl.value * 0.6;
        final scale = 1.0 + _ctrl.value * 0.04;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(glowOpacity),
                  blurRadius: 14,
                  spreadRadius: 3,
                ),
              ],
              color: widget.color.withOpacity(0.1),
            ),
            child: Icon(Icons.person, color: widget.color, size: widget.size * 0.45),
          ),
        );
      },
    );
  }
}
