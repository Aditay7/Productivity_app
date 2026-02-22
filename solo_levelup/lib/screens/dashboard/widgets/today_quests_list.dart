import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/quest_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../../core/utils/responsive.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/level_up_dialog.dart';

/// Today's quests list widget
class TodayQuestsList extends ConsumerWidget {
  const TodayQuestsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayQuests = ref.watch(todayQuestsProvider);
    final incompleteQuests = todayQuests.where((q) => !q.isCompleted).toList();
    final responsive = context.responsive;

    if (incompleteQuests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(responsive.padding),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: responsive.isSmall ? 40 : 48,
              color: AppTheme.gold,
            ),
            SizedBox(height: responsive.spacing),
            Text(
              'No quests for today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: responsive.isSmall ? 14 : 16,
              ),
            ),
            SizedBox(height: responsive.spacing * 0.5),
            Text(
              'Create a new quest to get started!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
                fontSize: responsive.isSmall ? 12 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Quests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...incompleteQuests.map((quest) {
          final currentStreak = ref.watch(playerStreakProvider);
          final xpPreview = XPCalculator.calculateXP(
            timeMinutes: quest.timeEstimatedMinutes,
            difficultyMultiplier: quest.difficulty.multiplier,
            currentStreak: currentStreak,
          );

          return Container(
            margin: EdgeInsets.only(bottom: responsive.spacing * 0.75),
            padding: EdgeInsets.all(responsive.spacing * 0.75),
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
                  padding: EdgeInsets.all(responsive.spacing * 0.4),
                  decoration: BoxDecoration(
                    color: Color(quest.statType.colorValue).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quest.statType.emoji,
                    style: TextStyle(fontSize: responsive.isSmall ? 16 : 20),
                  ),
                ),
                SizedBox(width: responsive.spacing * 0.75),

                // Quest info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quest.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontSize: responsive.isSmall ? 13 : 15),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: responsive.spacing * 0.25),
                      Wrap(
                        spacing: responsive.spacing * 0.75,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                size: responsive.isSmall ? 14 : 16,
                                color: Colors.white54,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${quest.timeEstimatedMinutes}m',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white54,
                                      fontSize: responsive.isSmall ? 11 : 12,
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing * 0.5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+$xpPreview XP',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: responsive.isSmall ? 11 : 12,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Complete button
                IconButton(
                  onPressed: () => _completeQuest(context, ref, quest),
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.gold,
                  iconSize: responsive.isSmall ? 22 : 26,
                  padding: EdgeInsets.all(responsive.spacing * 0.5),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _completeQuest(
    BuildContext context,
    WidgetRef ref,
    quest,
  ) async {
    final playerAsync = ref.read(playerProvider);
    if (!playerAsync.hasValue) return;

    final oldLevel = playerAsync.value!.level;

    // Complete the quest (this will update player XP and stats)
    await ref.read(questProvider.notifier).completeQuest(quest);

    // Check if leveled up
    final newPlayerAsync = ref.read(playerProvider);
    if (newPlayerAsync.hasValue) {
      final newLevel = newPlayerAsync.value!.level;
      if (newLevel > oldLevel && context.mounted) {
        await LevelUpDialog.show(context, newLevel, quest.xpReward);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest completed! +${quest.xpReward} XP'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }
}
