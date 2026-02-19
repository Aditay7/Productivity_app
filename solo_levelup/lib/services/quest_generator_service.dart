import '../data/models/quest.dart';
import '../data/models/quest_template.dart';
import '../data/repositories/quest_repository.dart';
import '../data/repositories/quest_template_repository.dart';
import '../core/constants/recurrence_type.dart';
import '../core/constants/difficulty.dart';
import '../core/utils/xp_calculator.dart';

/// Service for generating quests from templates
class QuestGeneratorService {
  final QuestTemplateRepository _templateRepo;
  final QuestRepository _questRepo;

  QuestGeneratorService(this._templateRepo, this._questRepo);

  /// Generate today's quests from active templates
  Future<List<Quest>> generateTodayQuests({
    required int currentStreak,
    required bool isShadowMode,
  }) async {
    final templates = await _templateRepo.getActiveTemplates();
    final today = DateTime.now();
    final generatedQuests = <Quest>[];

    for (final template in templates) {
      if (shouldGenerateToday(template, today)) {
        final quest = await createInstanceFromTemplate(
          template,
          currentStreak: currentStreak,
          isShadowMode: isShadowMode,
        );
        generatedQuests.add(quest);
        
        // Update last generated date
        await _templateRepo.updateLastGenerated(template.id!, today);
      }
    }

    return generatedQuests;
  }

  /// Check if template should generate a quest today
  bool shouldGenerateToday(QuestTemplate template, DateTime date) {
    // Check if already generated today
    if (template.lastGeneratedDate != null) {
      final lastGen = template.lastGeneratedDate!;
      if (lastGen.year == date.year &&
          lastGen.month == date.month &&
          lastGen.day == date.day) {
        return false; // Already generated today
      }
    }

    // Check recurrence type
    switch (template.recurrenceType) {
      case RecurrenceType.daily:
        return true;

      case RecurrenceType.weekly:
        if (template.weekdays == null || template.weekdays!.isEmpty) {
          return false;
        }
        return template.weekdays!.contains(date.weekday);

      case RecurrenceType.custom:
        if (template.customDays == null || template.customDays! <= 0) {
          return false;
        }
        final daysSinceCreated = date.difference(template.createdAt).inDays;
        return daysSinceCreated % template.customDays! == 0;
    }
  }

  /// Create a quest instance from template
  Future<Quest> createInstanceFromTemplate(
    QuestTemplate template, {
    required int currentStreak,
    required bool isShadowMode,
  }) async {
    // Force Hard difficulty in Shadow Mode
    final difficulty = isShadowMode ? Difficulty.B : template.difficulty;

    // Calculate XP with Shadow Mode multiplier
    final xpReward = XPCalculator.calculateXP(
      timeMinutes: template.timeMinutes,
      difficultyMultiplier: difficulty.multiplier,
      currentStreak: currentStreak,
      isShadowMode: isShadowMode,
    );

    final quest = Quest(
      title: template.title,
      description: template.description,
      statType: template.statType,
      difficulty: difficulty,
      timeEstimatedMinutes: template.timeMinutes,
      xpReward: xpReward,
      createdAt: DateTime.now(),
      templateId: template.id,
      isTemplateInstance: true,
    );

    // Save to database
    return await _questRepo.createQuest(quest);
  }
}
