import '../core/network/api_client.dart';
import '../core/config/api_config.dart';
import '../data/models/quest.dart';

/// Service for managing quest timers
class QuestTimerService {
  final ApiClient _apiClient = ApiClient();

  /// Start quest timer
  Future<Quest> startTimer(String questId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.questsEndpoint}/$questId/timer/start',
      );

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception(response['message'] ?? 'Failed to start timer');
    } catch (e) {
      throw Exception('Failed to start timer: $e');
    }
  }

  /// Pause quest timer
  Future<Quest> pauseTimer(String questId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.questsEndpoint}/$questId/timer/pause',
      );

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception(response['message'] ?? 'Failed to pause timer');
    } catch (e) {
      throw Exception('Failed to pause timer: $e');
    }
  }

  /// Resume quest timer
  Future<Quest> resumeTimer(String questId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.questsEndpoint}/$questId/timer/resume',
      );

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception(response['message'] ?? 'Failed to resume timer');
    } catch (e) {
      throw Exception('Failed to resume timer: $e');
    }
  }

  /// Stop quest timer
  Future<Quest> stopTimer(String questId, {int? focusRating}) async {
    try {
      final body = <String, dynamic>{};
      if (focusRating != null) {
        body['focusRating'] = focusRating;
      }

      final response = await _apiClient.post(
        '${ApiConfig.questsEndpoint}/$questId/timer/stop',
        body: body.isNotEmpty ? body : null,
      );

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception(response['message'] ?? 'Failed to stop timer');
    } catch (e) {
      throw Exception('Failed to stop timer: $e');
    }
  }

  /// Complete quest with timer
  Future<Map<String, dynamic>> completeQuestWithTimer(
    String questId, {
    int? focusRating,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (focusRating != null) {
        body['focusRating'] = focusRating;
      }

      final response = await _apiClient.post(
        '${ApiConfig.questsEndpoint}/$questId/complete-with-timer',
        body: body.isNotEmpty ? body : null,
      );

      if (response['success'] == true && response['data'] != null) {
        return {
          'quest': Quest.fromMap(response['data'] as Map<String, dynamic>),
          'skillResult': response['skillResult'],
        };
      }
      throw Exception(response['message'] ?? 'Failed to complete quest');
    } catch (e) {
      throw Exception('Failed to complete quest: $e');
    }
  }

  /// Get overdue quests
  Future<List<Quest>> getOverdueQuests() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.questsEndpoint}/overdue',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Quest.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get overdue quests: $e');
    }
  }

  /// Get quests due soon (within 24 hours)
  Future<List<Quest>> getDueSoonQuests() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.questsEndpoint}/due-soon',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Quest.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get due soon quests: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
