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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _pulseController;
  late AnimationController _statsController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _statsBounce;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
        );
    _statsBounce = CurvedAnimation(
      parent: _statsController,
      curve: Curves.elasticOut,
    );

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _statsController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _pulseController.dispose();
    _statsController.dispose();
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
        backgroundColor: AppTheme.cardBackground,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Compact Hero Header ───────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (player) => _HeroHeader(
                  player: player,
                  heroFade: _heroFade,
                  heroSlide: _heroSlide,
                  pulseController: _pulseController,
                ),
                loading: () => Container(
                  height: 130,
                  color: AppTheme.darkPurple.withOpacity(0.3),
                ),
                error: (_, __) => const SizedBox(height: 80),
              ),
            ),

            // ── XP Progress Bar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (player) => _XpProgressSection(player: player),
                loading: () => const SizedBox(height: 80),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Quick Stats Row ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: playerAsync.when(
                  data: (player) => questsAsync.when(
                    data: (quests) => goalsAsync.when(
                      data: (goals) => _QuickStatsRow(
                        player: player,
                        activeQuests: quests
                            .where((q) => !q.isCompleted)
                            .length,
                        activeGoals: goals.where((g) => g.isActive).length,
                        statsBounce: _statsBounce,
                      ),
                      loading: () => const SizedBox(height: 90),
                      error: (_, __) => const SizedBox(),
                    ),
                    loading: () => const SizedBox(height: 90),
                    error: (_, __) => const SizedBox(),
                  ),
                  loading: () => const SizedBox(height: 90),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // ── Attributes Section ───────────────────────────────────
            SliverToBoxAdapter(
              child: playerAsync.when(
                data: (player) => _AttributesSection(player: player),
                loading: () => const SizedBox(height: 180),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Today's Quests ────────────────────────────────────────
            SliverToBoxAdapter(
              child: questsAsync.when(
                data: (quests) {
                  final active = quests
                      .where((q) => !q.isCompleted)
                      .take(5)
                      .toList();
                  return _TodayQuestsSection(quests: active);
                },
                loading: () => const _SectionShimmer(label: "Today's Quests"),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Active Goals ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: goalsAsync.when(
                data: (goals) {
                  final active = goals
                      .where((g) => g.isActive)
                      .take(3)
                      .toList();
                  return _ActiveGoalsSection(goals: active);
                },
                loading: () => const _SectionShimmer(label: 'Active Goals'),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // ── Quick Actions ─────────────────────────────────────────
            SliverToBoxAdapter(child: _QuickActionsSection()),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT HERO HEADER (~130px tall)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final Player player;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final AnimationController pulseController;

  const _HeroHeader({
    required this.player,
    required this.heroFade,
    required this.heroSlide,
    required this.pulseController,
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
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0533), Color(0xFF110628), Color(0xFF0A0E27)],
            ),
          ),
          child: Stack(
            children: [
              // Subtle star particles
              ..._particles(),
              // Glow orb top-right
              Positioned(
                right: -15,
                top: -15,
                child: AnimatedBuilder(
                  animation: pulseController,
                  builder: (_, __) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryPurple.withOpacity(
                            0.22 * pulseController.value,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main content row
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.gold, AppTheme.primaryPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
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
                            const SizedBox(height: 3),
                            Text(
                              player.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 7,
                              runSpacing: 5,
                              children: [
                                _chip(
                                  Icons.local_fire_department,
                                  '${player.currentStreak}d streak',
                                  Colors.orange,
                                ),
                                _chip(
                                  Icons.diamond_outlined,
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
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.gold, Color(0xFFE67E22)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.military_tech,
                              size: 16,
                              color: Colors.black87,
                            ),
                            const SizedBox(height: 3),
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

  List<Widget> _particles() {
    final rand = math.Random(42);
    return List.generate(10, (i) {
      final size = rand.nextDouble() * 2.5 + 1;
      return Positioned(
        left: rand.nextDouble() * 420,
        top: rand.nextDouble() * 130,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (i % 3 == 0 ? AppTheme.gold : AppTheme.primaryPurple)
                .withOpacity(rand.nextDouble() * 0.5 + 0.15),
          ),
        ),
      );
    });
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
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
// XP PROGRESS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _XpProgressSection extends StatefulWidget {
  final Player player;
  const _XpProgressSection({required this.player});
  @override
  State<_XpProgressSection> createState() => _XpProgressSectionState();
}

class _XpProgressSectionState extends State<_XpProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
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
    final player = widget.player;
    final pct = player.xpToNextLevel > 0
        ? (player.xp / player.xpToNextLevel * 100).toStringAsFixed(1)
        : '100.0';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
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
                      color: AppTheme.gold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: AppTheme.gold,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'EXPERIENCE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: '%',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _anim.value,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.gold],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withOpacity(0.45),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${player.xp} XP',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                'Lvl ${player.level + 1}: ${player.xpToNextLevel} XP',
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
class _QuickStatsRow extends StatelessWidget {
  final Player player;
  final int activeQuests;
  final int activeGoals;
  final Animation<double> statsBounce;

  const _QuickStatsRow({
    required this.player,
    required this.activeQuests,
    required this.activeGoals,
    required this.statsBounce,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SI(
        Icons.local_fire_department,
        '${player.currentStreak}',
        'Streak',
        Colors.orange,
      ),
      _SI(Icons.task_alt, '$activeQuests', 'Quests', Colors.blue),
      _SI(Icons.flag, '$activeGoals', 'Goals', Colors.green),
      _SI(
        Icons.workspace_premium,
        '${player.totalStats}',
        'Power',
        AppTheme.primaryPurple,
      ),
    ];

    return AnimatedBuilder(
      animation: statsBounce,
      builder: (_, __) {
        final v = statsBounce.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.7 + 0.3 * v,
          child: Opacity(
            opacity: v,
            child: SizedBox(
              height: 90,
              child: Row(
                children: items
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: e.key == 0 ? 0 : 6,
                            right: e.key == 3 ? 0 : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.cardBackground,
                                e.value.color.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: e.value.color.withOpacity(0.28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: e.value.color.withOpacity(0.1),
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                e.value.icon,
                                color: e.value.color,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.value.value,
                                style: TextStyle(
                                  color: e.value.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                e.value.label,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 9,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SI {
  final IconData icon;
  final String value, label;
  final Color color;
  _SI(this.icon, this.value, this.label, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTRIBUTES SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AttributesSection extends StatelessWidget {
  final Player player;
  const _AttributesSection({required this.player});

  @override
  Widget build(BuildContext context) {
    final stats = StatType.values
        .map((t) => _Attr(t, player.getStatValue(t)))
        .toList();
    final maxVal = stats.map((s) => s.value).reduce(math.max).toDouble();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.auto_graph,
            title: 'ATTRIBUTES',
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: stats
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AnimatedStatBar(
                        attr: a,
                        ratio: maxVal > 0 ? a.value / maxVal : 0.0,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Attr {
  final StatType type;
  final int value;
  _Attr(this.type, this.value);
}

class _AnimatedStatBar extends StatefulWidget {
  final _Attr attr;
  final double ratio;
  const _AnimatedStatBar({required this.attr, required this.ratio});
  @override
  State<_AnimatedStatBar> createState() => _AnimatedStatBarState();
}

class _AnimatedStatBarState extends State<_AnimatedStatBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween(
      begin: 0.0,
      end: widget.ratio,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 450), () {
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
    final color = widget.attr.type.color;
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            widget.attr.type.emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            widget.attr.type.displayName,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: _anim.value,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.5), blurRadius: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${widget.attr.value}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY'S QUESTS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _TodayQuestsSection extends ConsumerWidget {
  final List quests;
  const _TodayQuestsSection({required this.quests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(
                icon: Icons.today,
                title: "TODAY'S QUESTS",
                color: Colors.blue,
              ),
              Text(
                '${quests.length} active',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (quests.isEmpty)
            _EmptyState(
              icon: Icons.task_outlined,
              message: 'No active quests',
              sub: 'Tap + below to create a quest',
              color: Colors.blue,
            )
          else
            ...quests.map((q) => _QuestCard(quest: q)),
        ],
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  final dynamic quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = quest.statType.color as Color;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuestTimerScreen(quest: quest)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.cardBackground, color.withOpacity(0.07)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  quest.statType.emoji,
                  style: const TextStyle(fontSize: 21),
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
                      fontSize: 14,
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
                      const SizedBox(width: 4),
                      Text(
                        '${quest.timeEstimatedMinutes}m',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.bolt, size: 12, color: AppTheme.gold),
                      const SizedBox(width: 3),
                      Text(
                        '+${quest.xpReward} XP',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 12,
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
// ACTIVE GOALS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveGoalsSection extends StatelessWidget {
  final List goals;
  const _ActiveGoalsSection({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.flag_rounded,
            title: 'ACTIVE GOALS',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          if (goals.isEmpty)
            _EmptyState(
              icon: Icons.flag_outlined,
              message: 'No active goals',
              sub: 'Set goals in the Goals tab',
              color: Colors.green,
            )
          else
            ...goals.map((g) => _GoalCard(goal: g)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final dynamic goal;
  const _GoalCard({required this.goal});
  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final double pct = (widget.goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.28)),
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
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
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
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF00E676)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.flash_on,
            title: 'QUICK ACTIONS',
            color: AppTheme.gold,
          ),
          const SizedBox(height: 12),
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
                  color: Colors.deepPurple,
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
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.9),
                widget.color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
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
// SHARED
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({
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
            color: color.withOpacity(0.15),
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
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, sub;
  final Color color;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color.withOpacity(0.5)),
            const SizedBox(height: 7),
            Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
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
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white24)),
      ),
    );
  }
}
