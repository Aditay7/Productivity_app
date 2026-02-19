import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/goal_provider.dart';
import '../../data/models/goal.dart';
import '../../app/theme.dart';
import 'create_goal_screen.dart';

/// Goals Management Screen
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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Add filter dialog
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return _buildEmptyState(context);
            }

            final activeGoals = goals.where((g) => g.isActive).toList();
            final completedGoals = goals.where((g) => g.isCompleted).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeGoals.isNotEmpty) ...[
                  Text(
                    'Active Goals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...activeGoals.map((goal) => _buildGoalCard(context, ref, goal, false)),
                  const SizedBox(height: 24),
                ],
                if (completedGoals.isNotEmpty) ...[
                  Text(
                    'Completed Goals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedGoals.map((goal) => _buildGoalCard(context, ref, goal, true)),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No Goals Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your first goal to track progress!',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [
                  Colors.grey.shade800.withOpacity(0.3),
                  Colors.grey.shade900.withOpacity(0.3),
                ],
              )
            : AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        color: isCompleted ? Colors.white54 : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (goal.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: TextStyle(
                          color: isCompleted ? Colors.white38 : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip(Icons.calendar_today, goal.type.displayName),
              const SizedBox(width: 8),
              _buildChip(Icons.trending_up, goal.statType.toUpperCase()),
              const SizedBox(width: 8),
              _buildChip(Icons.flag, '${goal.currentValue}/${goal.targetValue} ${goal.unit.displayName}'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(
              isCompleted ? Colors.green : AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.progressPercentage}% Complete',
                style: TextStyle(
                  color: isCompleted ? Colors.white54 : AppTheme.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isCompleted)
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context, ref, goal),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(goalProvider.notifier).deleteGoal(goal.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
