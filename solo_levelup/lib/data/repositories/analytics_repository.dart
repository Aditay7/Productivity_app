import '../models/analytics.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api_config.dart';

/// Repository for analytics operations
class AnalyticsRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get productivity dashboard data
  Future<ProductivityDashboard> getProductivityDashboard() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.analyticsEndpoint}/dashboard',
      );

      if (response['success'] == true && response['data'] != null) {
        return ProductivityDashboard.fromMap(
          response['data'] as Map<String, dynamic>,
        );
      }

      throw Exception('Failed to get productivity dashboard');
    } catch (e) {
      throw Exception('Error getting productivity dashboard: $e');
    }
  }

  /// Get habit statistics
  Future<List<HabitStats>> getHabitStats() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.analyticsEndpoint}/habits',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => HabitStats.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error getting habit stats: $e');
    }
  }

  /// Mark habit as completed
  Future<void> completeHabit(String templateId) async {
    try {
      await _apiClient.post(
        '${ApiConfig.analyticsEndpoint}/habits/$templateId/complete',
      );
    } catch (e) {
      throw Exception('Error completing habit: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
