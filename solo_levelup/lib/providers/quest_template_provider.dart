import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quest_template.dart';
import '../data/repositories/quest_template_repository.dart';

/// Notifier for quest templates
class QuestTemplateNotifier extends StateNotifier<AsyncValue<List<QuestTemplate>>> {
  final QuestTemplateRepository _repository;

  QuestTemplateNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTemplates();
  }

  /// Load all templates
  Future<void> loadTemplates() async {
    state = const AsyncValue.loading();
    try {
      final templates = await _repository.getAllTemplates();
      state = AsyncValue.data(templates);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create new template
  Future<void> createTemplate(QuestTemplate template) async {
    try {
      final created = await _repository.createTemplate(template);
      final current = state.value ?? [];
      state = AsyncValue.data([created, ...current]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update existing template
  Future<void> updateTemplate(QuestTemplate template) async {
    try {
      await _repository.updateTemplate(template);
      final current = state.value ?? [];
      final updated = current.map((t) => t.id == template.id ? template : t).toList();
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String id) async {
    try {
      await _repository.deleteTemplate(id);
      final current = state.value ?? [];
      final filtered = current.where((t) => t.id != id).toList();
      state = AsyncValue.data(filtered);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle template active status
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _repository.toggleActive(id, isActive);
      final current = state.value ?? [];
      final updated = current.map((t) {
        if (t.id == id) {
          return t.copyWith(isActive: isActive);
        }
        return t;
      }).toList();
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for quest templates
final questTemplateProvider =
    StateNotifierProvider<QuestTemplateNotifier, AsyncValue<List<QuestTemplate>>>((ref) {
  return QuestTemplateNotifier(QuestTemplateRepository());
});

/// Provider for active templates only
final activeTemplatesProvider = Provider<List<QuestTemplate>>((ref) {
  final templatesAsync = ref.watch(questTemplateProvider);
  return templatesAsync.when(
    data: (templates) => templates.where((t) => t.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
