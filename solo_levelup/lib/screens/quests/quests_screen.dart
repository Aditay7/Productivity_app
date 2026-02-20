import 'dart:async';
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
          colors: [Color(0xFF1A0533), Color(0xFF110628), Color(0xFF0A0E27)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  // Icon + title
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUEST BOARD',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'My Quests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Stats chips
                  _HeaderChip('$active', 'Active', AppTheme.primaryPurple),
                  const SizedBox(width: 8),
                  _HeaderChip('$completed', 'Done', Colors.green),
                ],
              ),
            ),
            // Custom tab bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: tabController,
                padding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(9),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: '⚔️  Active'),
                  Tab(text: '✅  Completed'),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: ' $label',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
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
            colors: [const Color(0xFF1A1F3A), statColor.withOpacity(0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: statColor.withOpacity(isActive ? 0.35 : 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: statColor.withOpacity(isActive ? 0.08 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: stat icon + title + complete btn
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        quest.statType.emoji,
                        style: const TextStyle(fontSize: 22),
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
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: isActive
                                ? null
                                : TextDecoration.lineThrough,
                            decorationColor: Colors.white30,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Difficulty + stat type chips
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
                    _CompleteBtn(isCompleting: isCompleting, onTap: onComplete),
                  ] else ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
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
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Row 2: info chips
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    Icons.timer_outlined,
                    '${quest.timeEstimatedMinutes}m',
                    Colors.white38,
                  ),
                  _InfoChip(Icons.bolt, '+${quest.xpReward} XP', AppTheme.gold),
                  if (quest.deadline != null)
                    _InfoChip(
                      Icons.calendar_today,
                      _formatDate(quest.deadline!),
                      Colors.orange,
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
                _PerformanceBar(score: quest.productivityScore!.toDouble()),
              ],

              // Completed at
              if (!isActive && quest.completedAt != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Completed ${_formatDate(quest.completedAt!)}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: diff.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: diff.color.withOpacity(0.5)),
      ),
      child: Text(
        diff.name,
        style: TextStyle(
          color: diff.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${stat.emoji} ${stat.displayName}',
        style: TextStyle(
          color: stat.color.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isCompleting ? Colors.white10 : Colors.green.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleting
                ? Colors.white24
                : Colors.green.withOpacity(0.5),
          ),
        ),
        child: Center(
          child: isCompleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                )
              : const Icon(Icons.check, color: Colors.green, size: 18),
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
          Text(icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
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
          colors: [AppTheme.primaryPurple, AppTheme.gold],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.5),
            blurRadius: 16,
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'New Quest',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
