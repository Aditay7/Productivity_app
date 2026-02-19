import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/player.dart';
import '../data/repositories/player_repository.dart';
import '../core/constants/stat_types.dart';

/// Player state notifier
class PlayerNotifier extends StateNotifier<AsyncValue<Player>> {
  final PlayerRepository _repository;

  PlayerNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlayer();
  }

  /// Load player from database
  Future<void> loadPlayer() async {
    state = const AsyncValue.loading();
    try {
      final player = await _repository.getPlayer();
      state = AsyncValue.data(player);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add XP and update stats
  Future<void> addXP(int xp, StatType statType) async {
    try {
      final updatedPlayer = await _repository.addXP(xp, statType.name);
      state = AsyncValue.data(updatedPlayer);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update player
  Future<void> updatePlayer(Player player) async {
    try {
      await _repository.updatePlayer(player);
      state = AsyncValue.data(player);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle Shadow Monarch Mode
  Future<void> toggleShadowMode(bool enable) async {
    final player = state.value;
    if (player == null) return;

    try {
      final updatedPlayer = player.copyWith(
        isShadowMode: enable,
        shadowModeActivatedAt: enable ? DateTime.now() : null,
      );
      await updatePlayer(updatedPlayer);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Check and apply streak break penalty (Shadow Mode only)
  Future<int> checkStreakPenalty() async {
    final player = state.value;
    if (player == null || !player.isShadowMode) return 0;

    final lastActivity = player.lastActivityDate;
    if (lastActivity == null) return 0;

    final now = DateTime.now();
    final daysSinceActivity = now.difference(lastActivity).inDays;

    // If more than 1 day has passed, streak is broken
    if (daysSinceActivity > 1) {
      final penalty = (player.totalXP * 0.1).round().clamp(100, player.totalXP);
      final newXP = (player.totalXP - penalty).clamp(0, player.totalXP);

      final updatedPlayer = player.copyWith(
        totalXP: newXP,
        currentStreak: 0,
        totalPenaltiesIncurred: player.totalPenaltiesIncurred + penalty,
      );

      await updatePlayer(updatedPlayer);
      return penalty;
    }

    return 0;
  }

  /// Reset player
  Future<void> resetPlayer() async {
    try {
      await _repository.resetPlayer();
      await loadPlayer();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Player repository provider
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});

/// Player state provider
final playerProvider =
    StateNotifierProvider<PlayerNotifier, AsyncValue<Player>>((ref) {
      final repository = ref.watch(playerRepositoryProvider);
      return PlayerNotifier(repository);
    });

/// Current player level provider
final playerLevelProvider = Provider<int>((ref) {
  final playerAsync = ref.watch(playerProvider);
  return playerAsync.when(
    data: (player) => player.level,
    loading: () => 1,
    error: (_, __) => 1,
  );
});

/// Current player streak provider
final playerStreakProvider = Provider<int>((ref) {
  final playerAsync = ref.watch(playerProvider);
  return playerAsync.when(
    data: (player) => player.currentStreak,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Shadow Monarch Mode status provider
final isShadowModeProvider = Provider<bool>((ref) {
  final playerAsync = ref.watch(playerProvider);
  return playerAsync.when(
    data: (player) => player.isShadowMode,
    loading: () => false,
    error: (_, __) => false,
  );
});
