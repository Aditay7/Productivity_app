import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/analytics.dart';
import '../data/models/quest.dart';
import '../data/repositories/analytics_repository.dart';
import '../services/client_analytics_service.dart';
import 'quest_provider.dart';

/// Provider for productivity dashboard
final productivityDashboardProvider = FutureProvider<ProductivityDashboard>((
  ref,
) async {
  final repository = AnalyticsRepository();
  try {
    return await repository.getProductivityDashboard();
  } finally {
    repository.dispose();
  }
});

/// Provider for habit stats
final habitStatsProvider = FutureProvider<List<HabitStats>>((ref) async {
  final repository = AnalyticsRepository();
  try {
    return await repository.getHabitStats();
  } finally {
    repository.dispose();
  }
});

/// Provider for client analytics service
final clientAnalyticsServiceProvider = Provider(
  (ref) => ClientAnalyticsService(),
);

/// Provider for recent completed quests (for client-side analytics)
final recentQuestsProvider = FutureProvider<List<Quest>>((ref) async {
  final repository = ref.watch(questRepositoryProvider);
  // Fetch quests from last 30 days
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  return await repository.getAllQuests(
    isCompleted: true,
    startDate: thirtyDaysAgo,
    endDate: now,
  );
});

/// Provider for client-side analytics data
final clientAnalyticsProvider = FutureProvider<ClientAnalyticsData>((
  ref,
) async {
  final quests = await ref.watch(recentQuestsProvider.future);
  final service = ref.watch(clientAnalyticsServiceProvider);

  return ClientAnalyticsData(
    focusTrends: service.calculateFocusTrends(quests),
    timeAccuracy: service.calculateTimeAccuracy(quests),
    focusDistribution: service.calculateFocusDistribution(quests),
  );
});

class ClientAnalyticsData {
  final Map<DateTime, double> focusTrends;
  final List<TimeAccuracyData> timeAccuracy;
  final Map<int, int> focusDistribution;

  ClientAnalyticsData({
    required this.focusTrends,
    required this.timeAccuracy,
    required this.focusDistribution,
  });
}
