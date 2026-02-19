import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/goal.dart';
import '../data/repositories/goal_repository.dart';

/// Provider for goals
final goalProvider = StateNotifierProvider<GoalNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalNotifier(GoalRepository());
});

/// Provider for active goals only
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  final goalsAsync = ref.watch(goalProvider);
  return goalsAsync.when(
    data: (goals) => goals.where((g) => g.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Notifier for goals
class GoalNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final GoalRepository _repository;

  GoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  /// Load all goals
  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getAllGoals();
      state = AsyncValue.data(goals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load active goals only
  Future<void> loadActiveGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getActiveGoals();
      state = AsyncValue.data(goals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create new goal
  Future<void> createGoal(Goal goal) async {
    try {
      final created = await _repository.createGoal(goal);
      final current = state.value ?? [];
      state = AsyncValue.data([created, ...current]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update existing goal
  Future<void> updateGoal(Goal goal) async {
    try {
      final updated = await _repository.updateGoal(goal);
      final current = state.value ?? [];
      final newGoals = current.map((g) => g.id == updated.id ? updated : g).toList();
      state = AsyncValue.data(newGoals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update goal progress
  Future<void> updateProgress(String id, int value) async {
    try {
      final updated = await _repository.updateGoalProgress(id, value);
      final current = state.value ?? [];
      final newGoals = current.map((g) => g.id == updated.id ? updated : g).toList();
      state = AsyncValue.data(newGoals);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete goal
  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      final current = state.value ?? [];
      final filtered = current.where((g) => g.id != id).toList();
      state = AsyncValue.data(filtered);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
