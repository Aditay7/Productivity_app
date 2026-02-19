import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/goal_provider.dart';
import 'create_goal_screen.dart';
import '../habits/habit_calendar_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HabitCalendarScreen(),
                ),
              );
            },
            tooltip: 'Habit Calendar',
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          final activeGoals = goals.where((g) => g.isActive).toList();
          final completedGoals = goals.where((g) => !g.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(goalProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeGoals.isEmpty && completedGoals.isEmpty)
                    _buildEmptyState(),
                  if (activeGoals.isNotEmpty) ...[
                    Text(
                      'Active Goals (${activeGoals.length})',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...activeGoals.map(
                      (goal) => _buildGoalCard(context, ref, goal, true),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (completedGoals.isNotEmpty) ...[
                    Text(
                      'Completed Goals (${completedGoals.length})',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...completedGoals.map(
                      (goal) => _buildGoalCard(context, ref, goal, false),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
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
                onPressed: () => ref.invalidate(goalProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGoalScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first goal',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    WidgetRef ref,
    dynamic goal,
    bool isActive,
  ) {
    final progress = goal.progressPercentage;
    final isCompleted = progress >= 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getGoalTypeColor(goal.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGoalTypeIcon(goal.type),
                    color: _getGoalTypeColor(goal.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getGoalTypeLabel(goal.type),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 28)
                else
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                goal.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.currentValue} / ${goal.targetValue} ${goal.unit.displayName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (goal.statType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatTypeDisplayName(goal.statType),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            if (goal.milestones.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Milestones:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...goal.milestones.take(3).map((milestone) {
                final milestoneProgress =
                    (goal.currentValue / milestone.targetValue * 100).clamp(
                      0,
                      100,
                    );
                final isReached = milestoneProgress >= 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isReached
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isReached ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: isReached
                                ? Colors.grey[600]
                                : Colors.grey[500],
                            decoration: isReached
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '${milestone.targetValue} ${goal.unit.displayName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (goal.achievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.2),
                      Colors.orange.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${goal.achievements.length} Achievement${goal.achievements.length > 1 ? 's' : ''} Unlocked!',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...goal.achievements
                        .take(2)
                        .map(
                          (achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    achievement.title,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteGoal(context, ref, goal),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getGoalTypeIcon(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'monthly':
        return Icons.calendar_today;
      case 'yearly':
        return Icons.calendar_month;
      case 'custom':
        return Icons.flag;
      default:
        return Icons.flag;
    }
  }

  Color _getGoalTypeColor(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'monthly':
        return Colors.blue;
      case 'yearly':
        return Colors.purple;
      case 'custom':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getGoalTypeLabel(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'monthly':
        return 'Monthly Goal';
      case 'yearly':
        return 'Yearly Goal';
      case 'custom':
        return 'Custom Goal';
      default:
        return 'Goal';
    }
  }

  void _deleteGoal(BuildContext context, WidgetRef ref, dynamic goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(goalProvider.notifier).deleteGoal(goal.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getStatTypeDisplayName(String? statType) {
    if (statType == null) return '';
    switch (statType.toLowerCase()) {
      case 'strength':
        return 'Strength';
      case 'intelligence':
        return 'Intelligence';
      case 'discipline':
        return 'Discipline';
      case 'wealth':
        return 'Wealth';
      case 'charisma':
        return 'Charisma';
      default:
        return statType;
    }
  }
}
