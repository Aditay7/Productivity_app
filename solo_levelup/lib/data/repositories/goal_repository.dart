import '../models/goal.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api_config.dart';

/// Repository for goal operations
class GoalRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get all goals
  Future<List<Goal>> getAllGoals({
    GoalType? type,
    String? statType,
    bool? isCompleted,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type.value;
      if (statType != null) queryParams['statType'] = statType;
      if (isCompleted != null) {
        queryParams['isCompleted'] = isCompleted.toString();
      }

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';

      final response = await _apiClient.get(
        '${ApiConfig.goalsEndpoint}$queryString',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Goal.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid id format')) {
        // Backend returns this when looking up by a yet-to-be-properly-initialized user ObjectId
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
      throw Exception('Error getting goals: $e');
    }
  }

  /// Get active goals only
  Future<List<Goal>> getActiveGoals() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.goalsEndpoint}/active',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Goal.fromMap(json as Map<String, dynamic>))
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
      throw Exception('Error getting active goals: $e');
    }
  }

  /// Get goal by ID
  Future<Goal?> getGoal(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.goalsEndpoint}/$id');

      if (response['success'] == true && response['data'] != null) {
        return Goal.fromMap(response['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting goal: $e');
    }
  }

  /// Create a new goal
  Future<Goal> createGoal(Goal goal) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.goalsEndpoint,
        body: goal.toMap(),
      );

      if (response['success'] == true && response['data'] != null) {
        return Goal.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to create goal');
    } catch (e) {
      throw Exception('Error creating goal: $e');
    }
  }

  /// Update existing goal
  Future<Goal> updateGoal(Goal goal) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.goalsEndpoint}/${goal.id}',
        body: goal.toMap(),
      );

      if (response['success'] == true && response['data'] != null) {
        return Goal.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to update goal');
    } catch (e) {
      throw Exception('Error updating goal: $e');
    }
  }

  /// Update goal progress
  Future<Goal> updateGoalProgress(String id, int value) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.goalsEndpoint}/$id/progress',
        body: {'value': value},
      );

      if (response['success'] == true && response['data'] != null) {
        return Goal.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to update goal progress');
    } catch (e) {
      throw Exception('Error updating goal progress: $e');
    }
  }

  /// Delete goal
  Future<void> deleteGoal(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.goalsEndpoint}/$id');
    } catch (e) {
      throw Exception('Error deleting goal: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
