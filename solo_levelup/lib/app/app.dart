import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import '../screens/main_screen.dart';
import '../services/quest_generator_service.dart';
import '../data/repositories/quest_template_repository.dart';
import '../data/repositories/quest_repository.dart';
import '../providers/player_provider.dart';
import '../providers/quest_provider.dart';

/// Main app widget with bottom navigation
class SoloLevelUpApp extends ConsumerStatefulWidget {
  const SoloLevelUpApp({super.key});

  @override
  ConsumerState<SoloLevelUpApp> createState() => _SoloLevelUpAppState();
}

class _SoloLevelUpAppState extends ConsumerState<SoloLevelUpApp> {
  @override
  void initState() {
    super.initState();
    // Generate today's quests from templates on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateTodayQuests();
    });
  }

  Future<void> _generateTodayQuests() async {
    try {
      final playerAsync = ref.read(playerProvider);
      if (!playerAsync.hasValue) return;

      final player = playerAsync.value!;
      final generator = QuestGeneratorService(
        QuestTemplateRepository(),
        QuestRepository(),
      );

      await generator.generateTodayQuests(
        currentStreak: player.currentStreak,
        isShadowMode: player.isShadowMode,
      );

      // Refresh quest list
      ref.invalidate(questProvider);
    } catch (e) {
      // Silently fail - don't disrupt app startup
      debugPrint('Quest generation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo Level Up',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
