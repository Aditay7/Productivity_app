import '../models/player.dart';
import '../../core/network/api_client.dart';
import '../../core/config/api_config.dart';

/// Repository for player data operations using REST API
class PlayerRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get the player
  Future<Player> getPlayer() async {
    try {
      final response = await _apiClient.get(ApiConfig.playerEndpoint);

      if (response['success'] == true && response['data'] != null) {
        return Player.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to get player');
    } catch (e) {
      throw Exception('Error getting player: $e');
    }
  }

  /// Update player
  Future<void> updatePlayer(Player player) async {
    try {
      await _apiClient.put(ApiConfig.playerEndpoint, body: player.toMap());
    } catch (e) {
      throw Exception('Error updating player: $e');
    }
  }

  /// Add XP to player
  Future<Player> addXP(int xp, String statType) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.playerEndpoint}/add-xp',
        body: {'xp': xp, 'statType': statType},
      );

      if (response['success'] == true && response['data'] != null) {
        return Player.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to add XP');
    } catch (e) {
      throw Exception('Error adding XP: $e');
    }
  }

  /// Toggle shadow mode
  Future<Player> toggleShadowMode(bool enable) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.playerEndpoint}/toggle-shadow-mode',
        body: {'enable': enable},
      );

      if (response['success'] == true && response['data'] != null) {
        return Player.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to toggle shadow mode');
    } catch (e) {
      throw Exception('Error toggling shadow mode: $e');
    }
  }

  /// Reset player (for testing)
  Future<Player> resetPlayer() async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.playerEndpoint}/reset',
      );

      if (response['success'] == true && response['data'] != null) {
        return Player.fromMap(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to reset player');
    } catch (e) {
      throw Exception('Error resetting player: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
