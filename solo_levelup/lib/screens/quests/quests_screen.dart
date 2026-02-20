import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/quest_provider.dart';
import '../../providers/player_provider.dart';
import '../../data/repositories/quest_repository.dart';
import '../../core/constants/difficulty.dart';
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

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshQuests();
    });
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
    if (state == AppLifecycleState.resumed) {
      _refreshQuests();
    }
  }

  void _refreshQuests() {
    ref.invalidate(questProvider);
    ref.invalidate(playerProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveQuests(), _buildCompletedQuests()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddQuestScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Quest'),
      ),
    );
  }

  Widget _buildActiveQuests() {
    final questsAsync = ref.watch(questProvider);

    return questsAsync.when(
      data: (allQuests) {
        final quests = allQuests.where((q) => !q.isCompleted).toList();
        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active quests',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create your first quest',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(questProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return _buildQuestCard(quest, isActive: true);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
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

  Widget _buildCompletedQuests() {
    final questsAsync = ref.watch(questProvider);

    return questsAsync.when(
      data: (allQuests) {
        final quests = allQuests.where((q) => q.isCompleted).toList();
        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No completed quests yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete quests to see them here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(completedQuestsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return _buildQuestCard(quest, isActive: false);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(quest, {required bool isActive}) {
    final difficulty = Difficulty.values.firstWhere(
      (d) => d.toString().split('.').last == quest.difficulty,
      orElse: () => Difficulty.E,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: difficulty.color.withOpacity(0.5), width: 2),
      ),
      child: InkWell(
        onTap: isActive ? () => _showQuestDetails(quest) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: difficulty.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: difficulty.color),
                    ),
                    child: Text(
                      difficulty.name,
                      style: TextStyle(
                        color: difficulty.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _completeQuest(quest),
                    )
                  else
                    Icon(Icons.check_circle, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quest.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              if (quest.description != null &&
                  quest.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quest.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRewardChip(
                    Icons.stars,
                    '${quest.xpReward} XP',
                    Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  ...quest.statRewards.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildRewardChip(
                        Icons.trending_up,
                        '+${entry.value} ${entry.key}',
                        Colors.blue,
                      ),
                    );
                  }),
                ],
              ),
              // Timer widget for active quests
              if (isActive) ...[
                const SizedBox(height: 12),
                QuestTimerWidget(
                  quest: quest,
                  onTap: () => _openTimerScreen(quest),
                ),
              ],
              // Show productivity metrics for completed quests
              if (!isActive && quest.productivityScore != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getProductivityColor(quest.productivityScore!)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getProductivityColor(quest.productivityScore!),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getProductivityIcon(quest.productivityScore!),
                            size: 16,
                            color: _getProductivityColor(quest.productivityScore!),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Performance: ${quest.productivityScore!.round()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _getProductivityColor(quest.productivityScore!),
                            ),
                          ),
                        ],
                      ),
                      if (quest.accuracyScore != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Time Accuracy: ${quest.accuracyScore!.round()}%',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            if (quest.timeActualMinutes != null) ...[
                              Text(
                                ' (${quest.timeActualMinutes} min)',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (quest.focusRating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.center_focus_strong, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Focus: ',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                            ...List.generate(5, (index) {
                              return Icon(
                                index < quest.focusRating! ? Icons.star : Icons.star_border,
                                size: 12,
                                color: index < quest.focusRating! ? Colors.orange : Colors.grey,
                              );
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (!isActive && quest.completedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Completed: ${_formatDate(quest.completedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getProductivityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getProductivityIcon(double score) {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.thumb_up;
    if (score >= 40) return Icons.trending_down;
    return Icons.warning;
  }

  void _showQuestDetails(quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quest.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quest.description != null && quest.description!.isNotEmpty) ...[
              Text(quest.description!),
              const SizedBox(height: 16),
            ],
            const Text(
              'Rewards:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• ${quest.xpReward} XP'),
            ...quest.statRewards.entries.map((entry) {
              return Text('• +${entry.value} ${entry.key}');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeQuest(quest);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _openTimerScreen(quest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestTimerScreen(quest: quest),
      ),
    );
  }

  Future<void> _completeQuest(quest) async {
    final questId = quest.id.toString();

    // Prevent double submission
    if (_completingQuestIds.contains(questId)) return;

    setState(() {
      _completingQuestIds.add(questId);
    });

    try {
      final questRepo = QuestRepository();

      final result = await questRepo.completeQuest(questId);

      // Update player stats and quests - this will trigger UI refresh
      ref.invalidate(playerProvider);
      ref.invalidate(questProvider);

      if (mounted) {
        // Build completion message with performance feedback
        final xpEarned = result['xpEarned'] as int? ?? quest.xpReward;
        final performanceMsg = result['performanceMessage'] as String?;
        final xpModifier = result['xpModifier'] as double?;
        
        String message = 'Quest completed! +$xpEarned XP';
        Color backgroundColor = Colors.green;
        
        if (performanceMsg != null) {
          message = performanceMsg;
          // Color based on performance
          if (xpModifier != null) {
            if (xpModifier >= 1.2) {
              backgroundColor = Colors.green;
            } else if (xpModifier >= 1.0) {
              backgroundColor = Colors.blue;
            } else if (xpModifier >= 0.8) {
              backgroundColor = Colors.orange;
            } else {
              backgroundColor = Colors.red;
            }
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Even if there's an error parsing response, refresh the quests
      // because the backend might have completed it successfully
      ref.invalidate(playerProvider);
      ref.invalidate(questProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingQuestIds.remove(questId);
        });
      }
    }
  }
}
