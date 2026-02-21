class ProductivityDashboard {
  final BestCompletionTimes bestCompletionTimes;
  final ProductivityPatterns productivityPatterns;
  final Map<int, QuestDifficultyStats> questsByDifficulty;
  final StatBalance? statBalance;
  final ProgressPeriod weeklyProgress;
  final ProgressPeriod monthlyProgress;

  const ProductivityDashboard({
    required this.bestCompletionTimes,
    required this.productivityPatterns,
    required this.questsByDifficulty,
    this.statBalance,
    required this.weeklyProgress,
    required this.monthlyProgress,
  });

  /// Get total number of completed quests across all difficulties
  int get totalQuests {
    return questsByDifficulty.values.fold(
      0,
      (sum, stats) => sum + stats.completed,
    );
  }

  factory ProductivityDashboard.fromMap(Map<String, dynamic> map) {
    return ProductivityDashboard(
      bestCompletionTimes: BestCompletionTimes.fromMap(
        map['bestCompletionTimes'] as Map<String, dynamic>,
      ),
      productivityPatterns: ProductivityPatterns.fromMap(
        map['productivityPatterns'] as Map<String, dynamic>,
      ),
      questsByDifficulty: (map['questsByDifficulty'] as Map<String, dynamic>)
          .map(
            (key, value) => MapEntry(
              int.parse(key),
              QuestDifficultyStats.fromMap(value as Map<String, dynamic>),
            ),
          ),
      statBalance: map['statBalance'] != null
          ? StatBalance.fromMap(map['statBalance'] as Map<String, dynamic>)
          : null,
      weeklyProgress: ProgressPeriod.fromMap(
        map['weeklyProgress'] as Map<String, dynamic>,
      ),
      monthlyProgress: ProgressPeriod.fromMap(
        map['monthlyProgress'] as Map<String, dynamic>,
      ),
    );
  }
}

class BestCompletionTimes {
  final List<int> hourlyDistribution;
  final List<HourCount> bestHours;
  final String? recommendation;

  const BestCompletionTimes({
    required this.hourlyDistribution,
    required this.bestHours,
    this.recommendation,
  });

  /// Get hour counts (alias for bestHours for backward compatibility)
  List<HourCount> get hourCounts => bestHours;

  factory BestCompletionTimes.fromMap(Map<String, dynamic> map) {
    return BestCompletionTimes(
      hourlyDistribution: List<int>.from(map['hourlyDistribution'] as List),
      bestHours: (map['bestHours'] as List)
          .map((h) => HourCount.fromMap(h as Map<String, dynamic>))
          .toList(),
      recommendation: map['recommendation'] as String?,
    );
  }
}

class HourCount {
  final int hour;
  final int count;

  const HourCount({required this.hour, required this.count});

  factory HourCount.fromMap(Map<String, dynamic> map) {
    return HourCount(
      hour: (map['hour'] as num).toInt(),
      count: (map['count'] as num).toInt(),
    );
  }

  String get timeString {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class ProductivityPatterns {
  final List<DayPattern> weeklyPattern;
  final DayPattern mostProductiveDay;
  final DayPattern leastProductiveDay;

  const ProductivityPatterns({
    required this.weeklyPattern,
    required this.mostProductiveDay,
    required this.leastProductiveDay,
  });

  factory ProductivityPatterns.fromMap(Map<String, dynamic> map) {
    return ProductivityPatterns(
      weeklyPattern: (map['weeklyPattern'] as List)
          .map((d) => DayPattern.fromMap(d as Map<String, dynamic>))
          .toList(),
      mostProductiveDay: DayPattern.fromMap(
        map['mostProductiveDay'] as Map<String, dynamic>,
      ),
      leastProductiveDay: DayPattern.fromMap(
        map['leastProductiveDay'] as Map<String, dynamic>,
      ),
    );
  }
}

class DayPattern {
  final String day;
  final int dayIndex;
  final int count;

  const DayPattern({
    required this.day,
    required this.dayIndex,
    required this.count,
  });

  factory DayPattern.fromMap(Map<String, dynamic> map) {
    return DayPattern(
      day: map['day'] as String,
      dayIndex: (map['dayIndex'] as num).toInt(),
      count: (map['count'] as num).toInt(),
    );
  }
}

class QuestDifficultyStats {
  final int completed;
  final int? totalTime;
  final int? averageTime;

  const QuestDifficultyStats({
    required this.completed,
    required this.totalTime,
    required this.averageTime,
  });

  factory QuestDifficultyStats.fromMap(Map<String, dynamic> map) {
    return QuestDifficultyStats(
      completed: (map['completed'] as num).toInt(),
      totalTime: map['totalTime'] != null
          ? (map['totalTime'] as num).toInt()
          : null,
      averageTime: map['averageTime'] != null
          ? (map['averageTime'] as num).toInt()
          : null,
    );
  }
}

class StatBalance {
  final Map<String, int> stats;
  final int total;
  final int average;
  final String mostDeveloped;
  final String leastDeveloped;
  final String balance;

  const StatBalance({
    required this.stats,
    required this.total,
    required this.average,
    required this.mostDeveloped,
    required this.leastDeveloped,
    required this.balance,
  });

  factory StatBalance.fromMap(Map<String, dynamic> map) {
    return StatBalance(
      stats: (map['stats'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      total: map['total'] as int,
      average: map['average'] as int,
      mostDeveloped: map['mostDeveloped'] as String,
      leastDeveloped: map['leastDeveloped'] as String,
      balance: map['balance'] as String,
    );
  }
}

class ProgressPeriod {
  final int questsCompleted;
  final int xpEarned;
  final DateTime periodStart;

  const ProgressPeriod({
    required this.questsCompleted,
    required this.xpEarned,
    required this.periodStart,
  });

  factory ProgressPeriod.fromMap(Map<String, dynamic> map) {
    return ProgressPeriod(
      questsCompleted: (map['questsCompleted'] as num).toInt(),
      xpEarned: (map['xpEarned'] as num).toInt(),
      periodStart: DateTime.parse(
        (map['weekStart'] ?? map['monthStart']) as String,
      ),
    );
  }
}

class HabitStats {
  final String id;
  final String title;
  final int streak;
  final int completionRate;
  final DateTime? lastCompleted;
  final int totalCompletions;

  const HabitStats({
    required this.id,
    required this.title,
    required this.streak,
    required this.completionRate,
    this.lastCompleted,
    required this.totalCompletions,
  });

  factory HabitStats.fromMap(Map<String, dynamic> map) {
    return HabitStats(
      id: map['id'] as String,
      title: map['title'] as String,
      streak: (map['streak'] as num).toInt(),
      completionRate: (map['completionRate'] as num).toInt(),
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.parse(map['lastCompleted'] as String)
          : null,
      totalCompletions: (map['totalCompletions'] as num).toInt(),
    );
  }
}
