import 'dart:math';
import '../../core/constants/stat_types.dart';

/// Player model representing the user's character
class Player {
  final int id;
  final int level;
  final int totalXP;
  final int strength;
  final int intelligence;
  final int discipline;
  final int wealth;
  final int charisma;
  final int currentStreak;
  final DateTime? lastActivityDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Shadow Monarch Mode fields
  final bool isShadowMode;
  final DateTime? shadowModeActivatedAt;
  final int totalPenaltiesIncurred;

  Player({
    required this.id,
    required this.level,
    required this.totalXP,
    required this.strength,
    required this.intelligence,
    required this.discipline,
    required this.wealth,
    required this.charisma,
    required this.currentStreak,
    this.lastActivityDate,
    required this.createdAt,
    required this.updatedAt,
    this.isShadowMode = false,
    this.shadowModeActivatedAt,
    this.totalPenaltiesIncurred = 0,
  });

  /// Get player name (default: "Shadow Monarch" or "Hunter")
  String getName([String? username]) {
    final prefix = isShadowMode ? 'Shadow Monarch' : 'Hunter';
    if (username != null && username.isNotEmpty) {
      return '$prefix $username';
    }
    return prefix;
  }

  /// Get current XP progress in current level
  int get xp {
    final xpForCurrentLevel = _xpForLevel(level - 1);
    return totalXP - xpForCurrentLevel;
  }

  /// Get XP required to reach next level
  int get xpToNextLevel {
    final xpForNextLevel = _xpForLevel(level);
    final xpForCurrentLevel = _xpForLevel(level - 1);
    return xpForNextLevel - xpForCurrentLevel;
  }

  /// Calculate total XP required to reach a given level
  int _xpForLevel(int level) {
    if (level <= 0) return 0;
    // Formula: 100 * level^1.5 (exponential growth)
    return (100 * sqrt(level * level * level)).round();
  }

  /// Get stat value by type
  int getStatValue(StatType statType) {
    switch (statType) {
      case StatType.strength:
        return strength;
      case StatType.intelligence:
        return intelligence;
      case StatType.discipline:
        return discipline;
      case StatType.wealth:
        return wealth;
      case StatType.charisma:
        return charisma;
    }
  }

  /// Get all stats as a map (for UI compatibility)
  Map<String, int> get stats => {
    'Strength': strength,
    'Intelligence': intelligence,
    'Discipline': discipline,
    'Wealth': wealth,
    'Charisma': charisma,
  };

  /// Get total of all stats
  int get totalStats =>
      strength + intelligence + discipline + wealth + charisma;

  /// Create from database map
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: (map['_id'] ?? map['id']) is String
          ? 1 // MongoDB uses string IDs, we'll use 1 for the single player
          : (map['_id'] ?? map['id'] ?? 1) as int,
      level: map['level'] as int,
      totalXP: (map['totalXp'] ?? map['total_xp']) as int,
      strength: map['strength'] as int,
      intelligence: map['intelligence'] as int,
      discipline: map['discipline'] as int,
      wealth: map['wealth'] as int,
      charisma: map['charisma'] as int,
      currentStreak: (map['currentStreak'] ?? map['current_streak']) as int,
      lastActivityDate:
          (map['lastActivityDate'] ?? map['last_activity_date']) != null
          ? DateTime.parse(
              (map['lastActivityDate'] ?? map['last_activity_date']) as String,
            )
          : null,
      createdAt: DateTime.parse(
        (map['createdAt'] ?? map['created_at']) as String,
      ),
      updatedAt: DateTime.parse(
        (map['updatedAt'] ?? map['updated_at']) as String,
      ),
      isShadowMode:
          (map['isShadowMode'] ?? map['is_shadow_mode']) as bool? ?? false,
      shadowModeActivatedAt:
          (map['shadowModeActivatedAt'] ?? map['shadow_mode_activated_at']) !=
              null
          ? DateTime.parse(
              (map['shadowModeActivatedAt'] ?? map['shadow_mode_activated_at'])
                  as String,
            )
          : null,
      totalPenaltiesIncurred:
          (map['totalPenaltiesIncurred'] ?? map['total_penalties_incurred'])
              as int? ??
          0,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'totalXp': totalXP,
      'strength': strength,
      'intelligence': intelligence,
      'discipline': discipline,
      'wealth': wealth,
      'charisma': charisma,
      'currentStreak': currentStreak,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isShadowMode': isShadowMode,
      'shadowModeActivatedAt': shadowModeActivatedAt?.toIso8601String(),
      'totalPenaltiesIncurred': totalPenaltiesIncurred,
    };
  }

  /// Create a copy with updated fields
  Player copyWith({
    int? id,
    int? level,
    int? totalXP,
    int? strength,
    int? intelligence,
    int? discipline,
    int? wealth,
    int? charisma,
    int? currentStreak,
    DateTime? lastActivityDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isShadowMode,
    DateTime? shadowModeActivatedAt,
    int? totalPenaltiesIncurred,
  }) {
    return Player(
      id: id ?? this.id,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      strength: strength ?? this.strength,
      intelligence: intelligence ?? this.intelligence,
      discipline: discipline ?? this.discipline,
      wealth: wealth ?? this.wealth,
      charisma: charisma ?? this.charisma,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isShadowMode: isShadowMode ?? this.isShadowMode,
      shadowModeActivatedAt:
          shadowModeActivatedAt ?? this.shadowModeActivatedAt,
      totalPenaltiesIncurred:
          totalPenaltiesIncurred ?? this.totalPenaltiesIncurred,
    );
  }

  /// Create initial player
  factory Player.initial() {
    final now = DateTime.now();
    return Player(
      id: 1,
      level: 1,
      totalXP: 0,
      strength: 0,
      intelligence: 0,
      discipline: 0,
      wealth: 0,
      charisma: 0,
      currentStreak: 0,
      lastActivityDate: null,
      createdAt: now,
      updatedAt: now,
      isShadowMode: false,
      shadowModeActivatedAt: null,
      totalPenaltiesIncurred: 0,
    );
  }
}
