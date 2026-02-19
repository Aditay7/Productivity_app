import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quest_provider.dart';
import '../../providers/player_provider.dart';
import '../../data/models/quest.dart';
import '../../app/theme.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../widgets/common/level_up_dialog.dart';
import 'add_quest_screen.dart';
import 'package:solo_levelup/screens/quests/quest_timer_screen.dart';
import '../../widgets/quest/focus_rating_dialog.dart';

/// Quest List Screen - view and manage all quests
class QuestListScreen extends ConsumerStatefulWidget {
  const QuestListScreen({super.key});

  @override
  ConsumerState<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends ConsumerState<QuestListScreen> {
  String _filter = 'all'; // all, today, week, completed

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(questProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quests')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Today', 'today'),
                  const SizedBox(width: 8),
                  _buildFilterChip('This Week', 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', 'completed'),
                ],
              ),
            ),

            // Quest list
            Expanded(
              child: questsAsync.when(
                data: (quests) {
                  final filteredQuests = _filterQuests(quests);

                  if (filteredQuests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quests found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredQuests.length,
                    itemBuilder: (context, index) {
                      final quest = filteredQuests[index];
                      return _buildQuestTile(quest);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: AppTheme.primaryPurple.withOpacity(0.3),
      backgroundColor: AppTheme.cardBackground,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryPurple : Colors.white24,
      ),
    );
  }

  List<Quest> _filterQuests(List<Quest> quests) {
    switch (_filter) {
      case 'today':
        final now = DateTime.now();
        return quests.where((q) {
          final date = q.createdAt;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
      case 'week':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return quests.where((q) => q.createdAt.isAfter(weekAgo)).toList();
      case 'completed':
        return quests.where((q) => q.isCompleted).toList();
      default:
        return quests;
    }
  }

  Widget _buildQuestTile(Quest quest) {
    return Dismissible(
      key: Key('quest_${quest.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(questProvider.notifier).deleteQuest(quest.id!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quest deleted')));
      },
      child: GestureDetector(
        onTap: () {
          if (!quest.isCompleted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuestTimerScreen(quest: quest)),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(quest.statType.colorValue).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Stat icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(quest.statType.colorValue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quest.statType.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),

              // Quest info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: quest.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (quest.description != null &&
                        quest.description!.isNotEmpty)
                      Text(
                        quest.description!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (quest.timerState == TimerState.running)
                          _buildInfoChip(
                            Icons.play_arrow,
                            'Running',
                            color: Colors.green,
                          )
                        else if (quest.timerState == TimerState.paused)
                          _buildInfoChip(
                            Icons.pause,
                            'Paused',
                            color: Colors.orange,
                          )
                        else
                          _buildInfoChip(
                            Icons.timer,
                            '${quest.timeEstimatedMinutes} min',
                          ),
                        if (quest.isOverdue == true)
                          _buildInfoChip(
                            Icons.warning,
                            'Overdue',
                            color: Colors.red,
                          )
                        else if (quest.deadline != null)
                          _buildInfoChip(
                            Icons.access_time,
                            'Due ${_formatTime(quest.deadline!)}',
                            color: Colors.orange,
                          ),
                        _buildInfoChip(
                          Icons.star,
                          quest.difficulty.displayName,
                        ),
                        _buildInfoChip(
                          Icons.emoji_events,
                          '+${quest.xpReward} XP',
                          color: AppTheme.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date_utils.DateUtils.relativeDate(quest.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              ),

              // Edit and Complete buttons
              if (!quest.isCompleted) ...[
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddQuestScreen(quest: quest),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.primaryPurple,
                  iconSize: 28,
                ),
                IconButton(
                  onPressed: () => _completeQuest(quest),
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.gold,
                  iconSize: 32,
                ),
              ] else
                const Icon(Icons.check_circle, color: AppTheme.gold, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color ?? Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _completeQuest(Quest quest) async {
    // Show focus rating dialog
    final rating = await showDialog<int?>(
      context: context,
      builder: (context) => const FocusRatingDialog(),
    );

    // If result is null, dialog was cancelled
    if (rating == null) return;

    // If result is -1, it means "Complete without rating"
    final focusRating = rating == -1 ? null : rating;

    final playerAsync = ref.read(playerProvider);
    if (!playerAsync.hasValue) return;

    final oldLevel = playerAsync.value!.level;

    await ref
        .read(questProvider.notifier)
        .completeQuest(quest, focusRating: focusRating);

    final newPlayerAsync = ref.read(playerProvider);
    if (newPlayerAsync.hasValue) {
      final newLevel = newPlayerAsync.value!.level;
      if (newLevel > oldLevel && mounted) {
        await LevelUpDialog.show(context, newLevel, quest.xpReward);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest completed! +${quest.xpReward} XP'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }
}
