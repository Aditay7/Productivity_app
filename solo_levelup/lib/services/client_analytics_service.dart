import '../data/models/quest.dart';

/// Service for calculating client-side analytics metrics
class ClientAnalyticsService {
  /// Calculate average focus rating per day for the last 7 days
  Map<DateTime, double> calculateFocusTrends(List<Quest> quests) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Filter quests: completed in last 7 days and has focus rating
    final recentQuests = quests.where((q) {
      if (!q.isCompleted || q.completedAt == null || q.focusRating == null) {
        return false;
      }
      return q.completedAt!.isAfter(sevenDaysAgo);
    }).toList();

    // Group by day
    final dailyRatings = <DateTime, List<int>>{};
    for (final quest in recentQuests) {
      final date = DateTime(
        quest.completedAt!.year,
        quest.completedAt!.month,
        quest.completedAt!.day,
      );

      dailyRatings.putIfAbsent(date, () => []).add(quest.focusRating!);
    }

    // Calculate average per day
    final trends = <DateTime, double>{};
    // Initialize last 7 days with 0 (or connect gaps)
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final date = DateTime(d.year, d.month, d.day);

      if (dailyRatings.containsKey(date)) {
        final ratings = dailyRatings[date]!;
        final average = ratings.reduce((a, b) => a + b) / ratings.length;
        trends[date] = average;
      } else {
        trends[date] = 0.0;
      }
    }

    return trends;
  }

  /// Calculate estimated vs actual time for recent quests
  List<TimeAccuracyData> calculateTimeAccuracy(
    List<Quest> quests, {
    int limit = 7,
  }) {
    // Filter quests: completed, has estimated time, has actual time
    final eligibleQuests = quests.where((q) {
      return q.isCompleted &&
          q.timeEstimatedMinutes > 0 &&
          (q.timeActualMinutes ?? 0) > 0;
    }).toList();

    // Sort by completion date descending
    eligibleQuests.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    // Take top N
    final recentQuests = eligibleQuests.take(limit).toList();

    // Reverse to show oldest to newest in chart
    return recentQuests.reversed.map((q) {
      // timeActualMinutes is already in minutes
      return TimeAccuracyData(
        questTitle: q.title,
        estimatedMinutes: q.timeEstimatedMinutes,
        actualMinutes: q.timeActualMinutes!,
      );
    }).toList();
  }

  /// Calculate focus rating distribution
  Map<int, int> calculateFocusDistribution(List<Quest> quests) {
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final quest in quests) {
      if (quest.isCompleted && quest.focusRating != null) {
        final rating = quest.focusRating!;
        if (distribution.containsKey(rating)) {
          distribution[rating] = distribution[rating]! + 1;
        }
      }
    }

    return distribution;
  }
}

class TimeAccuracyData {
  final String questTitle;
  final int estimatedMinutes;
  final int actualMinutes;

  TimeAccuracyData({
    required this.questTitle,
    required this.estimatedMinutes,
    required this.actualMinutes,
  });
}
