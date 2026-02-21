import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quest.dart';
import '../data/repositories/quest_repository.dart';
import 'player_provider.dart';
import 'goal_provider.dart';

/// Quest state notifier
class QuestNotifier extends StateNotifier<AsyncValue<List<Quest>>> {
  final QuestRepository _repository;
  final Ref _ref;

  QuestNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    loadQuests();
  }

  /// Load all quests
  Future<void> loadQuests() async {
    state = const AsyncValue.loading();
    try {
      final quests = await _repository.getAllQuests();
      state = AsyncValue.data(quests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create a new quest
  Future<void> createQuest(Quest quest) async {
    try {
      await _repository.createQuest(quest);
      await loadQuests();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update an existing quest
  Future<void> updateQuest(Quest quest) async {
    try {
      await _repository.updateQuest(quest);
      await loadQuests();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Complete a quest
  Future<void> completeQuest(Quest quest, {int? focusRating}) async {
    try {
      if (quest.id == null) {
        throw Exception('Quest ID is required');
      }

      // Complete quest via API (returns quest + new achievements)
      await _repository.completeQuest(
        quest.id.toString(),
        focusRating: focusRating,
      );

      // Refresh player (XP already updated by backend)
      await _ref.read(playerProvider.notifier).loadPlayer();

      // Reload quests
      await loadQuests();

      // ── Refresh goals so progress updates immediately ─────────────
      _ref.invalidate(goalProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a quest
  Future<void> deleteQuest(String id) async {
    try {
      await _repository.deleteQuest(id);
      await loadQuests();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Quest repository provider
final questRepositoryProvider = Provider<QuestRepository>((ref) {
  return QuestRepository();
});

/// Quest state provider
final questProvider =
    StateNotifierProvider<QuestNotifier, AsyncValue<List<Quest>>>((ref) {
      final repository = ref.watch(questRepositoryProvider);
      return QuestNotifier(repository, ref);
    });

/// Today's quests provider
final todayQuestsProvider = Provider<List<Quest>>((ref) {
  final questsAsync = ref.watch(questProvider);
  return questsAsync.when(
    data: (quests) {
      final now = DateTime.now();
      return quests.where((quest) {
        final questDate = quest.createdAt;
        return questDate.year == now.year &&
            questDate.month == now.month &&
            questDate.day == now.day;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Incomplete quests provider
final incompleteQuestsProvider = Provider<List<Quest>>((ref) {
  final questsAsync = ref.watch(questProvider);
  return questsAsync.when(
    data: (quests) => quests.where((q) => !q.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Completed quests provider
final completedQuestsProvider = Provider<List<Quest>>((ref) {
  final questsAsync = ref.watch(questProvider);
  return questsAsync.when(
    data: (quests) => quests.where((q) => q.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
