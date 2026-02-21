import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/timer_session.dart';
import '../data/repositories/timer_repository.dart';

class FocusTimerState {
  final TimerSession? session;
  final int remainingSeconds;
  final bool isLoading;

  const FocusTimerState({
    this.session,
    this.remainingSeconds = 0,
    this.isLoading = false,
  });

  bool get isActive => session != null && session!.status == 'active';

  double get progress {
    if (!isActive || session == null) return 0.0;
    final total = session!.durationMinutes * 60;
    if (total == 0) return 0.0;
    return (total - remainingSeconds) / total;
  }

  FocusTimerState copyWith({
    TimerSession? session,
    int? remainingSeconds,
    bool? isLoading,
  }) {
    // If we explicitly want to nullify session, we can't do it with basic copyWith unless we use a wrapper,
    // but here we usually just replace the state entirely if session is null.
    return FocusTimerState(
      session: session ?? this.session,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final timerRepositoryProvider = Provider((ref) => TimerRepository());

final timerProvider = StateNotifierProvider<TimerNotifier, FocusTimerState>((
  ref,
) {
  return TimerNotifier(ref.watch(timerRepositoryProvider));
});

class TimerNotifier extends StateNotifier<FocusTimerState> {
  final TimerRepository _repository;
  Timer? _ticker;

  TimerNotifier(this._repository)
    : super(const FocusTimerState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final active = await _repository.getActiveSession();
      if (active != null) {
        final elapsed = DateTime.now().difference(active.startedAt).inSeconds;
        final total = active.durationMinutes * 60;
        final remaining = total - elapsed;

        if (remaining > 0) {
          state = FocusTimerState(session: active, remainingSeconds: remaining);
          _startTicker();
        } else {
          // Time passed while offline, auto complete
          await completeTimer(active.id);
        }
      } else {
        state = const FocusTimerState();
      }
    } catch (e) {
      state = const FocusTimerState();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _ticker?.cancel();
        completeTimer(state.session?.id);
      }
    });
  }

  Future<void> startRaid(int durationMinutes, String rank) async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repository.startTimer(
        durationMinutes: durationMinutes,
        rank: rank,
      );
      state = FocusTimerState(
        session: session,
        remainingSeconds: durationMinutes * 60,
      );
      _startTicker();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> completeTimer([String? manualId]) async {
    final id = manualId ?? state.session?.id;
    if (id == null) return;

    _ticker?.cancel();
    state = state.copyWith(isLoading: true);
    try {
      final completed = await _repository.completeTimer(id);
      state = FocusTimerState(session: completed, remainingSeconds: 0);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> failTimer() async {
    final session = state.session;
    if (session == null || session.status != 'active') return;

    _ticker?.cancel();
    state = state.copyWith(isLoading: true);
    try {
      final failed = await _repository.failTimer(session.id!);
      state = FocusTimerState(session: failed, remainingSeconds: 0);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void resetState() {
    _ticker?.cancel();
    state = const FocusTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
