import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/goal_provider.dart';
import '../../core/constants/stat_types.dart';
import '../../app/theme.dart';
import '../../data/models/player.dart';
import '../templates/manage_templates_screen.dart';
import '../quests/add_quest_screen.dart';
import '../quests/quest_timer_screen.dart';

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
  late Animation<double> _statsBounce;

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
    _statsBounce = CurvedAnimation(
      parent: _statsCtrl,
      curve: Curves.elasticOut,
    );

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

            // ── XP Bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (p) => _XpBar(player: p),
                loading: () => const _LoadingBlock(height: 76),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Quick Stats ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: playerAsync.when(
                  data: (p) => questsAsync.when(
                    data: (q) => goalsAsync.when(
                      data: (g) => _QuickStats(
                        player: p,
                        activeQuests: q.where((x) => !x.isCompleted).length,
                        activeGoals: g.where((x) => x.isActive).length,
                        bounce: _statsBounce,
                      ),
                      loading: () => const _LoadingBlock(height: 90),
                      error: (_, __) => const SizedBox(),
                    ),
                    loading: () => const _LoadingBlock(height: 90),
                    error: (_, __) => const SizedBox(),
                  ),
                  loading: () => const _LoadingBlock(height: 90),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // ── Attributes ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (p) => _AttributesSection(player: p),
                loading: () => const _LoadingBlock(height: 200),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Today's Quests ────────────────────────────────────────
            SliverToBoxAdapter(
              child: questsAsync.when(
                data: (q) => _TodayQuestsSection(
                  quests: q.where((x) => !x.isCompleted).take(5).toList(),
                ),
                loading: () => const _SectionShimmer(label: "Today's Quests"),
                error: (_, __) => const SizedBox(),
              ),
            ),

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

            // ── Quick Actions ─────────────────────────────────────────
            const SliverToBoxAdapter(child: _QuickActionsSection()),

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
class _HeroHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                      Container(
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
                        child: Center(
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
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
                              player.name,
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
                      // Level badge — solid, no gradient
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.gold, width: 1.5),
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

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final Player player;
  final int activeQuests, activeGoals;
  final Animation<double> bounce;

  const _QuickStats({
    required this.player,
    required this.activeQuests,
    required this.activeGoals,
    required this.bounce,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.local_fire_department,
        '${player.currentStreak}',
        'Streak',
        Colors.orange,
      ),
      (Icons.task_alt, '$activeQuests', 'Quests', AppTheme.primaryPurple),
      (Icons.flag_rounded, '$activeGoals', 'Goals', Colors.green),
      (Icons.workspace_premium, '${player.totalStats}', 'Power', Colors.blue),
    ];

    return AnimatedBuilder(
      animation: bounce,
      builder: (_, __) {
        final v = bounce.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.75 + 0.25 * v,
          child: Opacity(
            opacity: v,
            child: SizedBox(
              height: 88,
              child: Row(
                children: items.asMap().entries.map((e) {
                  final idx = e.key;
                  final (icon, value, label, color) = e.value;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: idx == 0 ? 0 : 5,
                        right: idx == 3 ? 0 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTRIBUTES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AttributesSection extends StatelessWidget {
  final Player player;
  const _AttributesSection({required this.player});

  @override
  Widget build(BuildContext context) {
    final attrs = StatType.values
        .map((t) => (t, player.getStatValue(t)))
        .toList();
    final maxVal = attrs.map((a) => a.$2).reduce(math.max).toDouble();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.auto_graph,
            title: 'ATTRIBUTES',
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: attrs.map((a) {
                  final ratio = maxVal > 0 ? a.$2 / maxVal : 0.0;
                  final isLastSingle = attrs.length % 2 != 0 && a == attrs.last;
                  return SizedBox(
                    width: isLastSingle ? constraints.maxWidth : w,
                    child: _StatGridCard(
                      type: a.$1,
                      value: a.$2,
                      ratio: ratio,
                      isFullWidth: isLastSingle,
                    ),
                  );
                }).toList(),
              );
            },
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
// TODAY'S QUESTS
// ─────────────────────────────────────────────────────────────────────────────
class _TodayQuestsSection extends ConsumerWidget {
  final List quests;
  const _TodayQuestsSection({required this.quests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(
                icon: Icons.today,
                title: "TODAY'S QUESTS",
                color: AppTheme.primaryPurple,
              ),
              Text(
                '${quests.length} active',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (quests.isEmpty)
            _Empty(
              icon: '⚔️',
              message: 'No active quests',
              sub: 'Tap + below to create one',
            )
          else
            ...quests.map((q) => _DashQuestTile(quest: q)),
        ],
      ),
    );
  }
}

class _DashQuestTile extends ConsumerWidget {
  final dynamic quest;
  const _DashQuestTile({required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = quest.statType.color as Color;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuestTimerScreen(quest: quest)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  quest.statType.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${quest.timeEstimatedMinutes}m',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.bolt, size: 12, color: AppTheme.gold),
                      const SizedBox(width: 3),
                      Text(
                        '+${quest.xpReward} XP',
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
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
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
// QUICK ACTIONS
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.flash_on,
            title: 'QUICK ACTIONS',
            color: AppTheme.gold,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.add_task,
                  label: 'New Quest',
                  color: AppTheme.primaryPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddQuestScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.library_books,
                  label: 'Templates',
                  color: const Color(0xFF5A3D8A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageTemplatesScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 19),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
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
