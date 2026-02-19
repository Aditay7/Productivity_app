import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../data/models/quest.dart';

/// Service for managing quest timers
class QuestTimerService {
  /// Start quest timer
  Future<Quest> startTimer(String questId) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/$questId/timer/start',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Quest.fromMap(data['data']);
    } else {
      throw Exception('Failed to start timer: ${response.body}');
    }
  }

  /// Pause quest timer
  Future<Quest> pauseTimer(String questId) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/$questId/timer/pause',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Quest.fromMap(data['data']);
    } else {
      throw Exception('Failed to pause timer: ${response.body}');
    }
  }

  /// Resume quest timer
  Future<Quest> resumeTimer(String questId) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/$questId/timer/resume',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Quest.fromMap(data['data']);
    } else {
      throw Exception('Failed to resume timer: ${response.body}');
    }
  }

  /// Stop quest timer
  Future<Quest> stopTimer(String questId, {int? focusRating}) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/$questId/timer/stop',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({if (focusRating != null) 'focusRating': focusRating}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Quest.fromMap(data['data']);
    } else {
      throw Exception('Failed to stop timer: ${response.body}');
    }
  }

  /// Complete quest with timer
  Future<Map<String, dynamic>> completeQuestWithTimer(
    String questId, {
    int? focusRating,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/$questId/complete-with-timer',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({if (focusRating != null) 'focusRating': focusRating}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'quest': Quest.fromMap(data['data']),
        'skillResult': data['skillResult'],
      };
    } else {
      throw Exception('Failed to complete quest: ${response.body}');
    }
  }

  /// Get overdue quests
  Future<List<Quest>> getOverdueQuests() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/overdue'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> questsJson = data['data'];
      return questsJson.map((json) => Quest.fromMap(json)).toList();
    } else {
      throw Exception('Failed to get overdue quests: ${response.body}');
    }
  }

  /// Get quests due soon (within 24 hours)
  Future<List<Quest>> getDueSoonQuests() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.questsEndpoint}/due-soon'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> questsJson = data['data'];
      return questsJson.map((json) => Quest.fromMap(json)).toList();
    } else {
      throw Exception('Failed to get due soon quests: ${response.body}');
    }
  }
}
