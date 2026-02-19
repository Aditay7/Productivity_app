import '../models/quest_template.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api_config.dart';

/// Repository for quest template operations using REST API
class QuestTemplateRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get all templates
  Future<List<QuestTemplate>> getAllTemplates() async {
    try {
      final response = await _apiClient.get(ApiConfig.templatesEndpoint);

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => QuestTemplate.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error getting templates: $e');
    }
  }

  /// Get only active templates
  Future<List<QuestTemplate>> getActiveTemplates() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.templatesEndpoint}?isActive=true',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => QuestTemplate.fromMap(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error getting active templates: $e');
    }
  }

  /// Get single template by ID
  Future<QuestTemplate?> getTemplate(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.templatesEndpoint}/$id',
      );

      if (response['success'] == true && response['data'] != null) {
        return QuestTemplate.fromMap(response['data'] as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Error getting template: $e');
    }
  }

  /// Create a new template
  Future<QuestTemplate> createTemplate(QuestTemplate template) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.templatesEndpoint,
        body: template.toMap(),
      );

      if (response['success'] == true && response['data'] != null) {
        return QuestTemplate.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to create template');
    } catch (e) {
      throw Exception('Error creating template: $e');
    }
  }

  /// Update existing template
  Future<QuestTemplate> updateTemplate(QuestTemplate template) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.templatesEndpoint}/${template.id}',
        body: template.toMap(),
      );

      if (response['success'] == true && response['data'] != null) {
        return QuestTemplate.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to update template');
    } catch (e) {
      throw Exception('Error updating template: $e');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.templatesEndpoint}/$id');
    } catch (e) {
      throw Exception('Error deleting template: $e');
    }
  }

  /// Toggle template active status
  Future<QuestTemplate> toggleActive(String id, bool isActive) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.templatesEndpoint}/$id/toggle',
        body: {'isActive': isActive},
      );

      if (response['success'] == true && response['data'] != null) {
        return QuestTemplate.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to toggle template');
    } catch (e) {
      throw Exception('Error toggling template: $e');
    }
  }

  /// Update the last generated date for a template
  Future<void> updateLastGenerated(String id, DateTime date) async {
    try {
      await _apiClient.put(
        '${ApiConfig.templatesEndpoint}/$id/last-generated',
        body: {'lastGeneratedDate': date.toIso8601String()},
      );
    } catch (e) {
      throw Exception('Error updating last generated date: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
