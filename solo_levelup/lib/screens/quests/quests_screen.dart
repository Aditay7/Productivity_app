import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quest_provider.dart';
import '../../providers/player_provider.dart';
import '../../data/repositories/quest_repository.dart';
import '../../core/constants/difficulty.dart';
import '../../core/constants/stat_types.dart';
import '../../app/theme.dart';
import '../../widgets/quest/quest_timer_widget.dart';
import 'add_quest_screen.dart';
import 'quest_timer_screen.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final Set<String> _completingQuestIds = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    ref.invalidate(questProvider);
    ref.invalidate(playerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        children: [
          // ── Custom Header ────────────────────────────────────────────
          _QuestsHeader(
            tabController: _tabController,
            questsAsync: questsAsync,
          ),

          // ── Tab Content ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActiveTab(
                  completingIds: _completingQuestIds,
                  onComplete: _completeQuest,
                ),
                _CompletedTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _AddQuestFAB(),
    );
  }

  Future<void> _completeQuest(quest) async {
    final questId = quest.id.toString();
    if (_completingQuestIds.contains(questId)) return;
    setState(() => _completingQuestIds.add(questId));

    try {
      final result = await QuestRepository().completeQuest(questId);
      ref.invalidate(playerProvider);
      ref.invalidate(questProvider);

      if (mounted) {
        final xpEarned = result['xpEarned'] as int? ?? quest.xpReward;
        final performanceMsg = result['performanceMessage'] as String?;
        final xpMod = result['xpModifier'] as double?;

        Color bg = Colors.green;
        if (xpMod != null) {
          bg = xpMod >= 1.2
              ? Colors.green
              : xpMod >= 1.0
              ? Colors.blue
              : xpMod >= 0.8
              ? Colors.orange
              : Colors.red;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(performanceMsg ?? 'Quest completed! +$xpEarned XP'),
            backgroundColor: bg,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ref.invalidate(playerProvider);
      ref.invalidate(questProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _completingQuestIds.remove(questId));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM HEADER WITH TABS
// ─────────────────────────────────────────────────────────────────────────────
class _QuestsHeader extends StatelessWidget {
  final TabController tabController;
  final AsyncValue questsAsync;

  const _QuestsHeader({required this.tabController, required this.questsAsync});

  @override
  Widget build(BuildContext context) {
    final active = questsAsync.maybeWhen(
      data: (q) => (q as List).where((x) => !x.isCompleted).length,
      orElse: () => 0,
    );
    final completed = questsAsync.maybeWhen(
      data: (q) => (q as List).where((x) => x.isCompleted).length,
      orElse: () => 0,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B3A), Color(0xFF120F25)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  // Icon + title
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.gold.withOpacity(0.3),
                          AppTheme.gold.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      color: AppTheme.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUEST BOARD',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'My Quests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Stats chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _HeaderChip('$active', 'Active', AppTheme.primaryPurple),
                      const SizedBox(height: 6),
                      _HeaderChip('$completed', 'Done', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            // Custom tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TabBar(
                  controller: tabController,
                  padding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.primaryPurple.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  tabs: const [
                    Tab(text: '⚔️ Active'),
                    Tab(text: '✅ Done'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String count, label;
  final Color color;
  const _HeaderChip(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE QUESTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveTab extends ConsumerWidget {
  final Set<String> completingIds;
  final Future<void> Function(dynamic) onComplete;

  const _ActiveTab({required this.completingIds, required this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questProvider);

    return questsAsync.when(
      data: (allQuests) {
        final quests = allQuests.where((q) => !q.isCompleted).toList();
        if (quests.isEmpty) {
          return _EmptyQuestState(
            icon: '⚔️',
            title: 'No Active Quests',
            subtitle:
                'Your quest board is empty.\nTap the button below to add one!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(questProvider),
          color: AppTheme.gold,
          backgroundColor: AppTheme.cardBackground,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: quests.length,
            itemBuilder: (context, i) => _QuestCard(
              quest: quests[i],
              isActive: true,
              isCompleting: completingIds.contains(quests[i].id.toString()),
              onComplete: () => onComplete(quests[i]),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestTimerScreen(quest: quests[i]),
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('$e', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(questProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED QUESTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _CompletedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questProvider);

    return questsAsync.when(
      data: (allQuests) {
        final quests = allQuests.where((q) => q.isCompleted).toList();
        if (quests.isEmpty) {
          return _EmptyQuestState(
            icon: '🏆',
            title: 'No Completed Quests',
            subtitle: 'Complete your first quest to\nsee it here!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(questProvider),
          color: AppTheme.gold,
          backgroundColor: AppTheme.cardBackground,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: quests.length,
            itemBuilder: (context, i) =>
                _QuestCard(quest: quests[i], isActive: false),
          ),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (e, _) => const SizedBox(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEST CARD — Rich design
// ─────────────────────────────────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final dynamic quest;
  final bool isActive;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const _QuestCard({
    required this.quest,
    required this.isActive,
    this.isCompleting = false,
    this.onComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statColor = quest.statType.color as Color;
    final diff = _difficultyFromQuest(quest);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [
                    statColor.withOpacity(0.12),
                    const Color(0xFF16152B),
                    const Color(0xFF131222),
                  ]
                : [const Color(0xFF16152B), const Color(0xFF131222)],
            stops: isActive ? const [0.0, 0.5, 1.0] : const [0.0, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? statColor.withOpacity(0.25)
                : Colors.white.withOpacity(0.05),
            width: 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: statColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtle ambient glow for active quests
              if (isActive)
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statColor.withOpacity(0.1),
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: const SizedBox(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: Icon + Title/Chips + Check/Done
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stat Icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statColor.withOpacity(isActive ? 0.25 : 0.1),
                                statColor.withOpacity(isActive ? 0.05 : 0.0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statColor.withOpacity(
                                isActive ? 0.3 : 0.1,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              quest.statType.emoji,
                              style: TextStyle(fontSize: isActive ? 20 : 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Chips
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quest.title,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white.withOpacity(0.95)
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                  decoration: isActive
                                      ? null
                                      : TextDecoration.lineThrough,
                                  decorationColor: Colors.white30,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _DiffChip(diff),
                                  const SizedBox(width: 6),
                                  _StatChip(quest.statType),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          _CompleteBtn(
                            isCompleting: isCompleting,
                            onTap: onComplete,
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.withOpacity(0.8),
                              size: 24,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (quest.description != null &&
                        quest.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        quest.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Divider over Info Chips
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Info Chips row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoChip(
                          Icons.timer_outlined,
                          '${quest.timeEstimatedMinutes}m',
                          Colors.white.withOpacity(0.6),
                        ),
                        _InfoChip(
                          Icons.bolt_rounded,
                          '+${quest.xpReward} XP',
                          AppTheme.gold,
                        ),
                        if (quest.deadline != null)
                          _InfoChip(
                            Icons.calendar_today_rounded,
                            _formatDate(quest.deadline!),
                            Colors.orange.withOpacity(0.9),
                          ),
                      ],
                    ),

                    // Timer widget (active only)
                    if (isActive) ...[
                      const SizedBox(height: 10),
                      QuestTimerWidget(quest: quest, onTap: onTap),
                    ],

                    // Performance metrics (completed only)
                    if (!isActive && quest.productivityScore != null) ...[
                      const SizedBox(height: 10),
                      _PerformanceBar(
                        score: quest.productivityScore!.toDouble(),
                      ),
                    ],

                    // Completed at
                    if (!isActive && quest.completedAt != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.green.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed ${_formatDate(quest.completedAt!)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Difficulty _difficultyFromQuest(dynamic quest) {
    try {
      return Difficulty.values.firstWhere(
        (d) => d.toString().split('.').last == quest.difficulty,
        orElse: () => Difficulty.E,
      );
    } catch (_) {
      return Difficulty.E;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

// ── Small inner widgets ───────────────────────────────────────────────────────
class _DiffChip extends StatelessWidget {
  final Difficulty diff;
  const _DiffChip(this.diff);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: diff.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: diff.color.withOpacity(0.2)),
      ),
      child: Text(
        diff.name,
        style: TextStyle(
          color: diff.color.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final StatType stat;
  const _StatChip(this.stat);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: stat.color.withOpacity(0.15)),
      ),
      child: Text(
        '${stat.emoji} ${stat.displayName}',
        style: TextStyle(
          color: stat.color.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CompleteBtn extends StatelessWidget {
  final bool isCompleting;
  final VoidCallback? onTap;
  const _CompleteBtn({required this.isCompleting, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCompleting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleting
                ? [Colors.white10, Colors.white10]
                : [
                    Colors.green.withOpacity(0.8),
                    Colors.green.withOpacity(0.4),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: isCompleting
              ? null
              : [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: isCompleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final double score;
  const _PerformanceBar({required this.score});
  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? Colors.green
        : score >= 60
        ? Colors.blue
        : score >= 40
        ? Colors.orange
        : Colors.red;
    final label = score >= 80
        ? '🏆 Excellent'
        : score >= 60
        ? '👍 Good'
        : score >= 40
        ? '📉 Average'
        : '⚠️ Below target';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${score.round()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyQuestState extends StatelessWidget {
  final String icon, title, subtitle;
  const _EmptyQuestState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(icon, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD QUEST FAB
// ─────────────────────────────────────────────────────────────────────────────
class _AddQuestFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryPurple, Color(0xFF9D65FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddQuestScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'New Quest',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
