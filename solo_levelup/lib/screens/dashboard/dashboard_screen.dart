import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/goal_provider.dart';
import '../../core/constants/stat_types.dart';
import '../../app/theme.dart';
import '../../data/models/player.dart';
import '../../widgets/dashboard/activity_heatmap_section.dart';
import '../../providers/profile_provider.dart';
import '../profile/profile_screen.dart';
import 'dart:io';

// Solid card color used consistently across the dashboard
const _kCard = Color(0xFF1A1630);
const _kSurface = Color(0xFF120F25);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _statsCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));

    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _pulseCtrl.dispose();
    _statsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);
    final questsAsync = ref.watch(questProvider);
    final goalsAsync = ref.watch(goalProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(playerProvider);
          ref.invalidate(questProvider);
          ref.invalidate(goalProvider);
        },
        color: AppTheme.gold,
        backgroundColor: _kCard,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (p) => _HeroHeader(
                  player: p,
                  heroFade: _heroFade,
                  heroSlide: _heroSlide,
                  pulseCtrl: _pulseCtrl,
                ),
                loading: () => const _LoadingBlock(height: 120),
                error: (_, __) => const SizedBox(height: 80),
              ),
            ),

            // ── RPG Status Ring (XP ring + quick bento stats) ────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (p) => questsAsync.when(
                  data: (q) => goalsAsync.when(
                    data: (g) => _XpRingSection(
                      player: p,
                      activeQuests: q.where((x) => !x.isCompleted).length,
                      activeGoals: g.where((x) => x.isActive).length,
                    ),
                    loading: () => const _LoadingBlock(height: 160),
                    error: (_, __) => const SizedBox(),
                  ),
                  loading: () => const _LoadingBlock(height: 160),
                  error: (_, __) => const SizedBox(),
                ),
                loading: () => const _LoadingBlock(height: 160),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Attributes Radar Chart ────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (p) => _AttributesRadarSection(player: p),
                loading: () => const _LoadingBlock(height: 300),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Activity Heatmap ─────────────────────────────────────────
            const SliverToBoxAdapter(child: ActivityHeatmapSection()),

            // ── Active Goals ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: goalsAsync.when(
                data: (g) => _ActiveGoalsSection(
                  goals: g.where((x) => x.isActive).take(3).toList(),
                ),
                loading: () => const _SectionShimmer(label: 'Active Goals'),
                error: (_, __) => const SizedBox(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER  — solid dark surface, no gradient
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends ConsumerWidget {
  final Player player;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final AnimationController pulseCtrl;

  const _HeroHeader({
    required this.player,
    required this.heroFade,
    required this.heroSlide,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'GOOD MORNING,'
        : hour < 17
        ? 'GOOD AFTERNOON,'
        : 'GOOD EVENING,';

    return FadeTransition(
      opacity: heroFade,
      child: SlideTransition(
        position: heroSlide,
        child: Container(
          color: _kSurface,
          child: Stack(
            children: [
              // Subtle star dots
              ..._dots(),
              // Pulse glow behind level badge
              Positioned(
                right: 12,
                top: 12,
                child: AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, __) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.gold.withOpacity(0.06 * pulseCtrl.value),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar circle
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.gold.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child:
                              ref.watch(profileProvider).profilePicPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.file(
                                    File(
                                      ref
                                          .watch(profileProvider)
                                          .profilePicPath!,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    player
                                        .getName(
                                          ref.watch(profileProvider).name ??
                                              ref
                                                  .watch(authProvider)
                                                  .user
                                                  ?.username,
                                        )[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Name + chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              player.getName(
                                ref.watch(profileProvider).name ??
                                    ref.watch(authProvider).user?.username,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _chip(
                                  Icons.local_fire_department,
                                  '${player.currentStreak}d',
                                  Colors.orange,
                                ),
                                _chip(
                                  Icons.diamond,
                                  '${player.totalXP} XP',
                                  AppTheme.gold,
                                ),
                                if (player.isShadowMode)
                                  _chip(
                                    Icons.dark_mode,
                                    'Shadow',
                                    Colors.purple,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Level badge & Logout Dropdown
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.gold,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.military_tech,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'LVL',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '${player.level}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _dots() {
    final r = math.Random(99);
    return List.generate(8, (i) {
      final sz = r.nextDouble() * 2 + 1;
      return Positioned(
        left: r.nextDouble() * 400,
        top: r.nextDouble() * 110,
        child: Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (i % 2 == 0 ? AppTheme.gold : AppTheme.primaryPurple)
                .withOpacity(r.nextDouble() * 0.35 + 0.1),
          ),
        ),
      );
    });
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RPG STATUS RING  —  Circular XP ring + 2×2 bento quick stats
// ─────────────────────────────────────────────────────────────────────────────
class _XpRingSection extends StatefulWidget {
  final Player player;
  final int activeQuests, activeGoals;
  const _XpRingSection({
    required this.player,
    required this.activeQuests,
    required this.activeGoals,
  });
  @override
  State<_XpRingSection> createState() => _XpRingSectionState();
}

class _XpRingSectionState extends State<_XpRingSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    final progress = widget.player.xpToNextLevel > 0
        ? (widget.player.xp / widget.player.xpToNextLevel).clamp(0.0, 1.0)
        : 1.0;
    _anim = Tween(
      begin: 0.0,
      end: progress,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final pct = p.xpToNextLevel > 0
        ? (p.xp / p.xpToNextLevel * 100).toStringAsFixed(1)
        : '100.0';

    final bentoItems = [
      (
        Icons.local_fire_department,
        '${p.currentStreak}',
        'Streak',
        Colors.orange,
      ),
      (
        Icons.task_alt,
        '${widget.activeQuests}',
        'Quests',
        AppTheme.primaryPurple,
      ),
      (Icons.flag_rounded, '${widget.activeGoals}', 'Goals', Colors.green),
      (Icons.workspace_premium, '${p.totalStats}', 'Power', Colors.blue),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Circular XP ring ───────────────────────────────────────
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _anim.value,
                  ringColor: AppTheme.primaryPurple,
                  trackColor: Colors.white.withOpacity(0.06),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LVL',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${p.level}',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── 2 × 2 bento stat tiles ────────────────────────────────
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bentoItems.map((item) {
                return SizedBox(
                  width:
                      (MediaQuery.of(context).size.width - 32 - 140 - 14 - 8) /
                      2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: item.$4.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.$1, color: item.$4, size: 18),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: TextStyle(
                            color: item.$4,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor, trackColor;
  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeW = 10.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke,
    );

    // Glow shadow
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ringColor.withOpacity(0.3)
          ..strokeWidth = strokeW + 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = ringColor
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Gold tip dot
    if (progress > 0.01) {
      final tipAngle = -math.pi / 2 + 2 * math.pi * progress;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()
          ..color = AppTheme.gold
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTRIBUTES  —  Pentagon radar/spider chart
// ─────────────────────────────────────────────────────────────────────────────
class _AttributesRadarSection extends StatefulWidget {
  final Player player;
  const _AttributesRadarSection({required this.player});
  @override
  State<_AttributesRadarSection> createState() =>
      _AttributesRadarSectionState();
}

class _AttributesRadarSectionState extends State<_AttributesRadarSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
      const Duration(milliseconds: 400),
      () => mounted ? _ctrl.forward() : null,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attrs = StatType.values
        .map((t) => (t, widget.player.getStatValue(t)))
        .toList();
    final maxVal = attrs
        .map((a) => a.$2)
        .reduce(math.max)
        .toDouble()
        .clamp(1.0, 9999.0);

    final values = attrs.map((a) => a.$2 / maxVal).toList();
    final colors = attrs.map((a) => a.$1.color).toList();
    final icons = attrs.map((a) => a.$1.icon).toList();
    final names = attrs.map((a) => a.$1.displayName).toList();
    final rawValues = attrs.map((a) => a.$2).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.auto_graph,
            title: 'ATTRIBUTES',
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT: Radar chart ──────────────────────────────
                Expanded(
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => SizedBox(
                      height: 200,
                      child: CustomPaint(
                        painter: _RadarPainter(
                          values: values,
                          colors: colors,
                          animValue: _anim.value,
                          fillColor: AppTheme.primaryPurple.withOpacity(0.18),
                          strokeColor: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ),
                // ── DIVIDER ────────────────────────────────────────
                Container(
                  width: 1,
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white.withOpacity(0.06),
                ),
                // ── RIGHT: Mini arc rings ──────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(attrs.length, (i) {
                      return _StatArcRing(
                        icon: icons[i],
                        name: names[i],
                        color: colors[i],
                        value: rawValues[i],
                        ratio: values[i],
                        animValue: _anim.value,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini arc ring row widget ───────────────────────────────────────────────────
/// Each stat appears as a small circular arc with label on the right.
class _StatArcRing extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  final int value;
  final double ratio; // 0–1 relative to max stat
  final double animValue; // 0–1 animation progress

  const _StatArcRing({
    required this.icon,
    required this.name,
    required this.color,
    required this.value,
    required this.ratio,
    required this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // ── Mini arc ring ────────
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: _ArcRingPainter(
                progress: (ratio * animValue).clamp(0.0, 1.0),
                color: color,
                strokeWidth: 4.5,
              ),
              child: Center(child: Icon(icon, size: 13, color: color)),
            ),
          ),
          const SizedBox(width: 10),
          // ── Name + Value ────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$value pts',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // ── Pct badge ────────
          Text(
            '${(ratio * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color.withOpacity(0.5),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arc ring painter ────────────────────────────────────────────────────────────
class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _ArcRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2; // top
    final sweep = 2 * math.pi * progress;

    // Track ring
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = color.withOpacity(0.1)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress < 0.01) return;

    // Glow
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withOpacity(0.25)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Arc
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tip dot
    final tipAngle = start + sweep;
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      ),
      strokeWidth / 2 + 0.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.progress != progress;
}

// ── Radar CustomPainter ───────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double animValue;
  final Color fillColor, strokeColor;

  const _RadarPainter({
    required this.values,
    required this.colors,
    required this.animValue,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // ── Grid rings ──────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + 2 * math.pi * i / n;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Spokes ────────────────────────────────────────────────────
    final spokePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        spokePaint,
      );
    }

    // ── Filled polygon (animated) ─────────────────────────────────
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * values[i] * animValue;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
    }
    dataPath.close();

    // Glow fill
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Vertex dots ───────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final r = radius * values[i] * animValue;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      // Glow aura
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = colors[i].withOpacity(0.25)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Dot
      canvas.drawCircle(
        Offset(x, y),
        4.5,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.fill,
      );

      // White center of dot
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Outer ring mark on spoke (100% position)
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(outerX, outerY),
        2.5,
        Paint()
          ..color = colors[i].withOpacity(0.4)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.animValue != animValue || old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// XP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _XpBar extends StatefulWidget {
  final Player player;
  const _XpBar({required this.player});
  @override
  State<_XpBar> createState() => _XpBarState();
}

class _XpBarState extends State<_XpBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final progress = widget.player.xpToNextLevel > 0
        ? (widget.player.xp / widget.player.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;
    _anim = Tween(
      begin: 0.0,
      end: progress,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final pct = p.xpToNextLevel > 0
        ? (p.xp / p.xpToNextLevel * 100).toStringAsFixed(1)
        : '100.0';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: AppTheme.gold,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EXPERIENCE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: pct,
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: '%',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _anim.value,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${p.xp} XP',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                'Next level: ${p.xpToNextLevel} XP',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatGridCard extends StatefulWidget {
  final StatType type;
  final int value;
  final double ratio;
  final bool isFullWidth;
  const _StatGridCard({
    required this.type,
    required this.value,
    required this.ratio,
    required this.isFullWidth,
  });
  @override
  State<_StatGridCard> createState() => _StatGridCardState();
}

class _StatGridCardState extends State<_StatGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = Tween(
      begin: 0.0,
      end: widget.ratio,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.type.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.type.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.type.displayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.value}',
                style: TextStyle(
                  color: widget.type.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'PTS',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Animated mini bar
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _anim.value,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.type.color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.type.color.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE GOALS
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveGoalsSection extends StatelessWidget {
  final List goals;
  const _ActiveGoalsSection({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.flag_rounded,
            title: 'ACTIVE GOALS',
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          if (goals.isEmpty)
            _Empty(
              icon: '🎯',
              message: 'No active goals',
              sub: 'Set goals in the Goals tab',
            )
          else
            ...goals.map((g) => _DashGoalTile(goal: g)),
        ],
      ),
    );
  }
}

class _DashGoalTile extends StatefulWidget {
  final dynamic goal;
  const _DashGoalTile({required this.goal});
  @override
  State<_DashGoalTile> createState() => _DashGoalTileState();
}

class _DashGoalTileState extends State<_DashGoalTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final double pct = (widget.goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(
      begin: 0.0,
      end: pct,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: _anim.value,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${goal.currentValue} / ${goal.targetValue} ${goal.unit.displayName}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String icon, message, sub;
  const _Empty({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final double height;
  const _LoadingBlock({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _SectionShimmer extends StatelessWidget {
  final String label;
  const _SectionShimmer({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white24)),
      ),
    );
  }
}
