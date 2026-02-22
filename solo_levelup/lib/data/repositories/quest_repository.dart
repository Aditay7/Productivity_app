import '../models/quest.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api_config.dart';

/// Repository for quest data operations using REST API
class QuestRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get all quests with optional filters
  Future<List<Quest>> getAllQuests({
    bool? isCompleted,
    String? statType,
    String? templateId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (isCompleted != null) {
        queryParams['isCompleted'] = isCompleted.toString();
      }
      if (statType != null) {
        queryParams['statType'] = statType;
      }
      if (templateId != null) {
        queryParams['templateId'] = templateId;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await _apiClient.get(
        '${ApiConfig.questsEndpoint}$queryString',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Quest.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid id format')) {
        return [];
      } else if (errorString.contains('socketexception') ||
          errorString.contains('clientexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('connection refused') ||
          errorString.contains('timeout')) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }
      throw Exception('Error getting quests: $e');
    }
  }

  /// Get today's quests
  Future<List<Quest>> getTodayQuests() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.questsEndpoint}/today',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Quest.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error getting today\'s quests: $e');
    }
  }

  /// Get quest by ID
  Future<Quest?> getQuestById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.questsEndpoint}/$id');

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting quest: $e');
    }
  }

  /// Create a new quest
  Future<Quest> createQuest(Quest quest) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.questsEndpoint,
        body: quest.toMap(),
      );

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to create quest');
    } catch (e) {
      throw Exception('Error creating quest: $e');
    }
  }

  /// Update quest
  Future<Quest> updateQuest(Quest quest) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.questsEndpoint}/${quest.id}',
        body: quest.toMap(),
      );

      if (response['success'] == true && response['data'] != null) {
        return Quest.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to update quest');
    } catch (e) {
      throw Exception('Error updating quest: $e');
    }
  }

  /// Complete a quest
  Future<Map<String, dynamic>> completeQuest(
    String questId, {
    int? focusRating,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (focusRating != null) {
        body['focusRating'] = focusRating;
      }

      final response = await _apiClient.post(
        '${ApiConfig.questsEndpoint}/$questId/complete',
        body: body.isNotEmpty ? body : null,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // Backend returns the quest directly in 'data', not nested
        final quest = Quest.fromMap(data);

        return {
          'quest': quest,
          'xpEarned': (response['xpEarned'] as num?)?.toInt(),
          'xpModifier': (response['xpModifier'] as num?)?.toDouble(),
          'performanceMessage': response['performanceMessage'] as String?,
          'newAchievements': [], // Achievements are handled separately
        };
      }

      throw Exception('Failed to complete quest');
    } catch (e) {
      throw Exception('Error completing quest: $e');
    }
  }

  /// Delete quest
  Future<void> deleteQuest(String questId) async {
    try {
      await _apiClient.delete('${ApiConfig.questsEndpoint}/$questId');
    } catch (e) {
      throw Exception('Error deleting quest: $e');
    }
  }

  /// Get completed quests count
  Future<int> getCompletedQuestsCount() async {
    try {
      final quests = await getAllQuests(isCompleted: true);
      return quests.length;
    } catch (e) {
      throw Exception('Error getting completed quests count: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
