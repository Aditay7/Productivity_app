import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quest_provider.dart';
import '../../providers/player_provider.dart';
import '../../data/repositories/quest_repository.dart';
// Empty
import '../../core/constants/difficulty.dart';
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
// QUEST CARD — Premium RPG Design (Linear / Arc / Superhuman style)
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
    return isActive
        ? _ActiveQuestCard(
            quest: quest,
            isCompleting: isCompleting,
            onComplete: onComplete,
            onTap: onTap,
          )
        : _DoneQuestCard(quest: quest, onTap: onTap);
  }
}

// ── Shared Helpers ────────────────────────────────────────────────────────
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

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

// ── Active Card Implementation ──────────────────────────────────────────────
class _ActiveQuestCard extends StatefulWidget {
  final dynamic quest;
  final bool isCompleting;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const _ActiveQuestCard({
    required this.quest,
    required this.isCompleting,
    this.onComplete,
    this.onTap,
  });

  @override
  State<_ActiveQuestCard> createState() => _ActiveQuestCardState();
}

class _ActiveQuestCardState extends State<_ActiveQuestCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statColor = widget.quest.statType.color as Color;
    final diff = _difficultyFromQuest(widget.quest);

    // Add implicit animation for hover lift
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 16),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF141A2A), // Card Background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.06), // Soft borders
              width: 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Left-side vertical stat color strip (4px)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: statColor),
                ),

                // Subtle radial glow behind the icon
                Positioned(
                  left: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          statColor.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF1A2135,
                          ), // Elevated hover color base
                          border: Border.all(color: statColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: statColor.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.quest.statType.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Content Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quest.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (widget.quest.description != null &&
                                widget.quest.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.quest.description!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Pills Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PremiumPill(
                                  label: widget.quest.statType.name
                                      .toUpperCase(),
                                  color: statColor,
                                ),
                                _PremiumPill(
                                  label: diff.name,
                                  color: diff.color,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Text Info Row
                            Text(
                              'XP: +${widget.quest.xpReward} ⚡  •  ${widget.quest.timeEstimatedMinutes}m',
                              style: TextStyle(
                                color: statColor.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),

                            if (widget.quest.timeActualSeconds != null &&
                                widget.quest.timeActualSeconds > 0) ...[
                              const SizedBox(height: 12),
                              QuestTimerWidget(
                                quest: widget.quest,
                                onTap: widget.onTap,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Action Button
                      _CircularPulseButton(
                        isCompleting: widget.isCompleting,
                        onTap: widget.onComplete,
                        color: statColor,
                      ),
                    ],
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

// ── Done Card Implementation ────────────────────────────────────────────────
class _DoneQuestCard extends StatelessWidget {
  final dynamic quest;
  final VoidCallback? onTap;

  const _DoneQuestCard({required this.quest, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statColor = quest.statType.color as Color;
    final diff = _difficultyFromQuest(quest);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF141A2A).withOpacity(0.85), // Muted Background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Circle (Muted / Checked)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          height: 1.2,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white.withOpacity(0.4),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '+${quest.xpReward} XP Earned ✨',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Completed ${quest.completedAt != null ? _timeAgo(quest.completedAt!) : 'recently'} • Duration ${quest.timeEstimatedMinutes}m',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Stat: ${quest.statType.name}  •  Difficulty: ${diff.name}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      if (quest.productivityScore != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Focus Score: ${quest.productivityScore!.round()}% 🎯',
                          style: TextStyle(
                            color: Colors.blue.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
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

// ── Shared Premium Widgets ────────────────────────────────────────────────
class _PremiumPill extends StatelessWidget {
  final String label;
  final Color color;
  const _PremiumPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CircularPulseButton extends StatefulWidget {
  final bool isCompleting;
  final VoidCallback? onTap;
  final Color color;

  const _CircularPulseButton({
    required this.isCompleting,
    this.onTap,
    required this.color,
  });

  @override
  State<_CircularPulseButton> createState() => _CircularPulseButtonState();
}

class _CircularPulseButtonState extends State<_CircularPulseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isCompleting ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isCompleting || _isHovered
                ? widget.color.withOpacity(0.15)
                : Colors.transparent,
            border: Border.all(
              color: widget.isCompleting
                  ? Colors.transparent
                  : _isHovered
                  ? widget.color
                  : widget.color.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: widget.isCompleting
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: _isHovered
                        ? widget.color
                        : Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                ),
        ),
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
