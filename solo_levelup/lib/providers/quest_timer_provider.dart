import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../data/models/quest.dart';
import '../services/quest_timer_service.dart';
import 'quest_provider.dart';

/// Provider for quest timer service
final questTimerServiceProvider = Provider((ref) => QuestTimerService());

/// Provider for active timer quest
final activeTimerQuestProvider = StateProvider<Quest?>((ref) => null);

/// Provider for elapsed time in seconds
final elapsedTimeProvider = StateProvider<int>((ref) => 0);

/// Provider for timer running state
final isTimerRunningProvider = StateProvider<bool>((ref) => false);

/// Quest timer notifier
class QuestTimerNotifier extends StateNotifier<AsyncValue<Quest?>> {
  QuestTimerNotifier(this.ref, this._timerService)
    : super(const AsyncValue.data(null));

  final Ref ref;
  final QuestTimerService _timerService;
  Timer? _timer;

  /// Start timer for a quest
  Future<void> startTimer(Quest quest) async {
    // Optimistic UI Update
    final optimisticQuest = quest.copyWith(
      timerState: TimerState.running,
      timeStarted: DateTime.now(),
    );
    state = AsyncValue.data(optimisticQuest);
    ref.read(activeTimerQuestProvider.notifier).state = optimisticQuest;
    ref.read(isTimerRunningProvider.notifier).state = true;
    startElapsedTimeCounter(optimisticQuest);

    try {
      final updatedQuest = await _timerService.startTimer(quest.id!);
      state = AsyncValue.data(updatedQuest);
      ref.read(activeTimerQuestProvider.notifier).state = updatedQuest;

      // Refresh quest list
      ref.invalidate(questProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Revert optimistic update
      ref.read(activeTimerQuestProvider.notifier).state = null;
      ref.read(isTimerRunningProvider.notifier).state = false;
      _stopElapsedTimeCounter();
    }
  }

  /// Pause timer
  Future<void> pauseTimer(String questId) async {
    // Optimistic UI Update
    final currentActive = ref.read(activeTimerQuestProvider);
    if (currentActive?.id == questId) {
      final optimisticQuest = currentActive!.copyWith(
        timerState: TimerState.paused,
      );
      state = AsyncValue.data(optimisticQuest);
      ref.read(activeTimerQuestProvider.notifier).state = optimisticQuest;
      ref.read(isTimerRunningProvider.notifier).state = false;
      _stopElapsedTimeCounter();
    }

    try {
      final updatedQuest = await _timerService.pauseTimer(questId);
      state = AsyncValue.data(updatedQuest);
      ref.read(activeTimerQuestProvider.notifier).state = updatedQuest;
      ref.read(isTimerRunningProvider.notifier).state = false;

      // Refresh quest list
      ref.invalidate(questProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Resume timer
  Future<void> resumeTimer(String questId) async {
    // Optimistic UI Update
    final currentActive = ref.read(activeTimerQuestProvider);
    if (currentActive?.id == questId) {
      final optimisticQuest = currentActive!.copyWith(
        timerState: TimerState.running,
      );
      state = AsyncValue.data(optimisticQuest);
      ref.read(activeTimerQuestProvider.notifier).state = optimisticQuest;
      ref.read(isTimerRunningProvider.notifier).state = true;
      startElapsedTimeCounter(optimisticQuest);
    }

    try {
      final updatedQuest = await _timerService.resumeTimer(questId);
      state = AsyncValue.data(updatedQuest);
      ref.read(activeTimerQuestProvider.notifier).state = updatedQuest;
      ref.read(isTimerRunningProvider.notifier).state = true;
      startElapsedTimeCounter(updatedQuest);

      // Refresh quest list
      ref.invalidate(questProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Stop timer
  Future<void> stopTimer(String questId, {int? focusRating}) async {
    // Optimistic UI Update
    final currentActive = ref.read(activeTimerQuestProvider);
    if (currentActive?.id == questId) {
      ref.read(activeTimerQuestProvider.notifier).state = null;
      ref.read(isTimerRunningProvider.notifier).state = false;
      _stopElapsedTimeCounter();
    }

    try {
      final updatedQuest = await _timerService.stopTimer(
        questId,
        focusRating: focusRating,
      );
      state = AsyncValue.data(updatedQuest);
      ref.read(activeTimerQuestProvider.notifier).state = null;
      ref.read(isTimerRunningProvider.notifier).state = false;
      ref.read(elapsedTimeProvider.notifier).state = 0;

      // Refresh quest list
      ref.invalidate(questProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Complete quest with timer
  Future<Map<String, dynamic>?> completeQuestWithTimer(
    String questId, {
    int? focusRating,
  }) async {
    // Optimistic UI Update
    final currentActive = ref.read(activeTimerQuestProvider);
    if (currentActive?.id == questId) {
      ref.read(activeTimerQuestProvider.notifier).state = null;
      ref.read(isTimerRunningProvider.notifier).state = false;
      _stopElapsedTimeCounter();
    }

    try {
      final result = await _timerService.completeQuestWithTimer(
        questId,
        focusRating: focusRating,
      );
      state = AsyncValue.data(result['quest']);
      ref.read(activeTimerQuestProvider.notifier).state = null;
      ref.read(isTimerRunningProvider.notifier).state = false;
      ref.read(elapsedTimeProvider.notifier).state = 0;

      // Refresh quest list
      ref.invalidate(questProvider);

      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Start elapsed time counter
  void startElapsedTimeCounter(Quest quest) {
    _stopElapsedTimeCounter();

    if (quest.timeStarted != null) {
      // Calculate initial elapsed time
      final now = DateTime.now();
      final elapsed = now.difference(quest.timeStarted!);
      final pausedSeconds = (quest.pausedDuration ?? 0) ~/ 1000;
      final elapsedSeconds = elapsed.inSeconds - pausedSeconds;

      ref.read(elapsedTimeProvider.notifier).state = elapsedSeconds;

      // Start timer to update every second
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        ref.read(elapsedTimeProvider.notifier).state++;
      });
    }
  }

  /// Stop elapsed time counter
  void _stopElapsedTimeCounter() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopElapsedTimeCounter();
    super.dispose();
  }
}

/// Provider for quest timer notifier
final questTimerProvider =
    StateNotifierProvider<QuestTimerNotifier, AsyncValue<Quest?>>((ref) {
      final timerService = ref.watch(questTimerServiceProvider);
      return QuestTimerNotifier(ref, timerService);
    });
