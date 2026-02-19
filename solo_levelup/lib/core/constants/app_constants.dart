// Core constants for the RPG app
class AppConstants {
  // XP Calculation
  static const int xpBase = 100; // Base XP for level calculation
  static const int shadowXpBase = 200; // Shadow Mode: 2x XP requirements
  static const double streakDivisor = 10.0; // Streak multiplier divisor

  // Difficulty multipliers
  static const double easyMultiplier = 1.0;
  static const double mediumMultiplier = 2.0;
  static const double hardMultiplier = 3.0;

  // Achievement keys
  static const String firstQuestKey = 'first_quest';
  static const String streak7Key = 'streak_7';
  static const String streak30Key = 'streak_30';
  static const String streak100Key = 'streak_100';
  static const String xp1kKey = 'xp_1k';
  static const String xp10kKey = 'xp_10k';
  static const String xp100kKey = 'xp_100k';
  static const String strength100Key = 'strength_100';
  static const String intelligence100Key = 'intelligence_100';
  static const String discipline100Key = 'discipline_100';
  static const String wealth100Key = 'wealth_100';
  static const String charisma100Key = 'charisma_100';
  static const String quests50Key = 'quests_50';
  static const String balancedBuildKey = 'balanced_build';

  // Shared preferences keys
  static const String firstLaunchKey = 'first_launch';

  // Database
  static const String databaseName = 'solo_levelup.db';
  static const int databaseVersion = 3; // Incremented for Recurring Quests
}
