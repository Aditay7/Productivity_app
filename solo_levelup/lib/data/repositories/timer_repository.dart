import '../models/timer_session.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api_config.dart';

/// Repository for TimerSession / Focus Dungeon operations
class TimerRepository {
  final ApiClient _apiClient = ApiClient();

  /// Start a new focus timer raid
  Future<TimerSession> startTimer({
    required int durationMinutes,
    required String rank,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.timerEndpoint}/start',
        body: {'durationMinutes': durationMinutes, 'rank': rank},
      );

      if (response['success'] == true && response['data'] != null) {
        return TimerSession.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception(response['message'] ?? 'Failed to start timer');
    } catch (e) {
      throw Exception('Error starting timer: $e');
    }
  }

  /// Complete a timer raid and earn XP
  Future<TimerSession> completeTimer(String id) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.timerEndpoint}/$id/complete',
      );

      if (response['success'] == true && response['data'] != null) {
        return TimerSession.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception(response['message'] ?? 'Failed to complete timer');
    } catch (e) {
      throw Exception('Error completing timer: $e');
    }
  }

  /// Fail a timer raid
  Future<TimerSession> failTimer(String id) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.timerEndpoint}/$id/fail',
      );

      if (response['success'] == true && response['data'] != null) {
        return TimerSession.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception(response['message'] ?? 'Failed to abandon timer');
    } catch (e) {
      throw Exception('Error failing timer: $e');
    }
  }

  /// Get past timer history
  Future<List<TimerSession>> getHistory() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.timerEndpoint}/history',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => TimerSession.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error getting timer history: $e');
    }
  }

  /// Get active session
  Future<TimerSession?> getActiveSession() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.timerEndpoint}/active',
      );

      if (response['success'] == true && response['data'] != null) {
        return TimerSession.fromMap(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // It's normal to have no active session
      return null;
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
