import 'dart:math';
import '../constants/app_constants.dart';

/// Utility class for XP and level calculations
class XPCalculator {
  /// Calculate XP earned from a quest
  /// Formula: XP = timeSpentMinutes × difficulty × streakMultiplier × shadowMultiplier
  /// where streakMultiplier = 1 + (currentStreak / 10)
  /// and shadowMultiplier = 3.0 in Shadow Monarch Mode
  static int calculateXP({
    required int timeMinutes,
    required double difficultyMultiplier,
    required int currentStreak,
    bool isShadowMode = false,
  }) {
    final streakMultiplier = 1 + (currentStreak / AppConstants.streakDivisor);
    final shadowMultiplier = isShadowMode ? 3.0 : 1.0;
    return (timeMinutes * difficultyMultiplier * streakMultiplier * shadowMultiplier).round();
  }

  /// Calculate player level from total XP
  /// Formula: level = floor(sqrt(totalXP / xpBase))
  /// where xpBase = 200 in Shadow Mode, 100 in Normal Mode
  static int calculateLevel(int totalXP, {bool isShadowMode = false}) {
    final xpBase = isShadowMode ? AppConstants.shadowXpBase : AppConstants.xpBase;
    return sqrt(totalXP / xpBase).floor();
  }

  /// Calculate total XP required for a specific level
  static int xpForLevel(int level, {bool isShadowMode = false}) {
    final xpBase = isShadowMode ? AppConstants.shadowXpBase : AppConstants.xpBase;
    return (level * level * xpBase);
  }

  /// Calculate XP required to reach the next level
  static int xpForNextLevel(int currentLevel, {bool isShadowMode = false}) {
    return xpForLevel(currentLevel + 1, isShadowMode: isShadowMode);
  }

  /// Calculate XP progress percentage to next level
  static double progressToNextLevel(int totalXP, {bool isShadowMode = false}) {
    final currentLevel = calculateLevel(totalXP, isShadowMode: isShadowMode);
    final currentLevelXP = xpForLevel(currentLevel, isShadowMode: isShadowMode);
    final nextLevelXP = xpForLevel(currentLevel + 1, isShadowMode: isShadowMode);
    final xpInCurrentLevel = totalXP - currentLevelXP;
    final xpNeededForNextLevel = nextLevelXP - currentLevelXP;

    return (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }

  /// Calculate remaining XP needed for next level
  static int xpRemainingForNextLevel(int totalXP, {bool isShadowMode = false}) {
    final currentLevel = calculateLevel(totalXP, isShadowMode: isShadowMode);
    final nextLevelXP = xpForLevel(currentLevel + 1, isShadowMode: isShadowMode);
    return nextLevelXP - totalXP;
  }

  /// Calculate streak break penalty (10% of total XP, minimum 100)
  static int calculateStreakPenalty(int totalXP) {
    return (totalXP * 0.1).round().clamp(100, totalXP);
  }
}
