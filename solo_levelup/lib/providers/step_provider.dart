import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/step_tracker_service.dart';

class StepState {
  final int steps;
  final String status;
  final String? error;
  final int dailyGoal;

  const StepState({
    required this.steps,
    required this.status,
    this.error,
    this.dailyGoal = 8000,
  });

  StepState copyWith({
    int? steps,
    String? status,
    String? error,
    int? dailyGoal,
    bool clearError = false,
  }) {
    return StepState(
      steps: steps ?? this.steps,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

class StepStateNotifier extends StateNotifier<StepState> {
  late final StepTrackerService _service;

  StepStateNotifier() : super(const StepState(steps: 0, status: 'unknown')) {
    _service = StepTrackerService(
      onStepCount: (steps) {
        state = state.copyWith(steps: steps, clearError: true);
      },
      onStatusChanged: (status) {
        state = state.copyWith(status: status);
      },
      onError: (error) {
        state = state.copyWith(error: error);
      },
    );
  }

  Future<void> initialize() async {
    state = state.copyWith(status: 'initializing...');
    await _service.initPlatformState();

    // Load custom goal
    final savedGoal = _service.getSavedDailyGoal();
    state = state.copyWith(dailyGoal: savedGoal);
  }

  Future<void> updateGoal(int newGoal) async {
    await _service.saveDailyGoal(newGoal);
    state = state.copyWith(dailyGoal: newGoal);
  }

  // To prevent memory leaks if used in a specific scoped route
  @override
  void dispose() {
    _service.stopTracking();
    super.dispose();
  }
}

final stepProvider = StateNotifierProvider<StepStateNotifier, StepState>((ref) {
  return StepStateNotifier();
});
