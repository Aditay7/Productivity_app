import 'package:flutter_test/flutter_test.dart';
import 'package:solo_levelup/data/models/quest.dart';
import 'package:solo_levelup/services/client_analytics_service.dart';
import 'package:solo_levelup/core/constants/stat_types.dart';
import 'package:solo_levelup/core/constants/difficulty.dart';

void main() {
  late ClientAnalyticsService service;
  late DateTime now;
  late DateTime yesterday;

  setUp(() {
    service = ClientAnalyticsService();
    now = DateTime.now();
    yesterday = now.subtract(const Duration(days: 1));
  });

  Quest createMockQuest({
    required String title,
    bool isCompleted = true,
    int? timeEstimatedMinutes,
    int? timeActualMinutes,
    int? focusRating,
    DateTime? completedAt,
  }) {
    return Quest(
      title: title,
      statType: StatType.strength,
      difficulty: Difficulty.E,
      timeEstimatedMinutes: timeEstimatedMinutes ?? 30,
      timeActualMinutes: timeActualMinutes,
      xpReward: 10,
      createdAt: now.subtract(const Duration(days: 5)),
      isCompleted: isCompleted,
      completedAt: completedAt ?? now,
      focusRating: focusRating,
    );
  }

  group('calculateTimeAccuracy', () {
    test('returns correct data for completed quests with estimates', () {
      final List<Quest> quests = [
        createMockQuest(
          title: 'Quest 1',
          timeEstimatedMinutes: 30,
          timeActualMinutes: 45,
          completedAt: now,
        ),
        createMockQuest(
          title: 'Quest 2',
          timeEstimatedMinutes: 60,
          timeActualMinutes: 50,
          completedAt: yesterday,
        ),
      ];

      final result = service.calculateTimeAccuracy(quests);

      expect(result.length, 2);
      expect(
        result[1].questTitle,
        'Quest 1',
      ); // Newer is last in chart (reversed in service)
      expect(result[1].estimatedMinutes, 30);
      expect(result[1].actualMinutes, 45);

      expect(result[0].questTitle, 'Quest 2');
      expect(result[0].estimatedMinutes, 60);
      expect(result[0].actualMinutes, 50);
    });

    test('ignores quests incomplete or missing actual time', () {
      final quests = [
        createMockQuest(title: 'Incomplete', isCompleted: false),
        createMockQuest(title: 'No actual', timeActualMinutes: null),
      ];

      final result = service.calculateTimeAccuracy(quests);
      expect(result, isEmpty);
    });

    test('respects limit', () {
      final quests = List.generate(
        10,
        (i) => createMockQuest(
          title: 'Quest $i',
          completedAt: now.subtract(Duration(hours: i)),
          timeActualMinutes: 30,
        ),
      );

      final result = service.calculateTimeAccuracy(quests, limit: 5);
      expect(result.length, 5);
    });
  });

  group('calculateFocusTrends', () {
    test('calculates daily averages correctly', () {
      final List<Quest> quests = [
        createMockQuest(title: 'Q1', focusRating: 5, completedAt: now),
        createMockQuest(
          title: 'Q2',
          focusRating: 3,
          completedAt: now,
        ), // Avg: 4
        createMockQuest(
          title: 'Q3',
          focusRating: 2,
          completedAt: yesterday,
        ), // Avg: 2
      ];

      final trends = service.calculateFocusTrends(quests);

      // Normalized dates
      final today = DateTime(now.year, now.month, now.day);
      final yest = DateTime(yesterday.year, yesterday.month, yesterday.day);

      expect(trends[today], 4.0);
      expect(trends[yest], 2.0);
    });

    test('returns 0 for days with no quests', () {
      final quests = <Quest>[];
      final trends = service.calculateFocusTrends(quests);

      expect(trends.length, 7);
      expect(trends.values.every((v) => v == 0.0), isTrue);
    });
  });
}
