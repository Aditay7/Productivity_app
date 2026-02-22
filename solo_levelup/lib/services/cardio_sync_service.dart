import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';

class CardioSyncService {
  static const String _kSyncQueue = 'cardio_sync_queue';

  /// Add today's updated progress to the sync queue.
  /// If today already exists in the queue, it overrides the entry with the latest numbers.
  Future<void> queueDailyLog({
    required String dateStr,
    required int steps,
    required Map<String, int> hourlyDistribution,
    double distanceKm = 0.0,
    double caloriesBurned = 0.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Read existing queue
    List<dynamic> queueRaw = [];
    final queueStr = prefs.getString(_kSyncQueue);
    if (queueStr != null) {
      try {
        queueRaw = jsonDecode(queueStr);
      } catch (_) {}
    }

    // Convert hourly map to backend schema array: [{hour: '00', steps: 10}, ...]
    final List<Map<String, dynamic>> hourlyArray = hourlyDistribution.entries
        .map((e) {
          return {'hour': e.key, 'steps': e.value};
        })
        .toList();

    // Find if date already in queue
    final payload = {
      'date': dateStr,
      'steps': steps,
      'distanceKm': distanceKm,
      'caloriesBurned': caloriesBurned,
      'activeMinutes': (steps * 0.01).round(), // Rough estimate for now
      'hourlyDistribution': hourlyArray,
    };

    final existingIndex = queueRaw.indexWhere(
      (element) => element['date'] == dateStr,
    );

    if (existingIndex >= 0) {
      queueRaw[existingIndex] = payload;
    } else {
      queueRaw.add(payload);
    }

    await prefs.setString(_kSyncQueue, jsonEncode(queueRaw));
  }

  /// Attempts to push the entire local queue to the backend.
  /// If successful, it clears the queue.
  Future<bool> pushSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString(_kSyncQueue);

    if (queueStr == null) return true; // Nothing to sync

    List<dynamic> queueRaw;
    try {
      queueRaw = jsonDecode(queueStr);
    } catch (_) {
      return true;
    }

    if (queueRaw.isEmpty) return true;

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.cardioEndpoint}/daily-logs/sync',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'logs': queueRaw}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // Success! Clear the queue.
        await prefs.remove(_kSyncQueue);
        return true;
      } else {
        return false;
      }
    } catch (_) {
      // Network failed, queue remains for next time
      return false;
    }
  }

  /// Directly pushes a completed explicit workout session to the Backend.
  Future<bool> saveWorkoutSession({
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required int steps,
    required double distanceKm,
    required double caloriesBurned,
    required double averagePaceKmH,
    List<List<double>> routeCoords = const [],
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.cardioEndpoint}/workouts',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': type,
              'startTime': startTime.toIso8601String(),
              'endTime': endTime.toIso8601String(),
              'durationSeconds': durationSeconds,
              'steps': steps,
              'distanceKm': distanceKm,
              'caloriesBurned': caloriesBurned,
              'averagePaceKmH': averagePaceKmH,
              'routeCoords': routeCoords,
            }),
          )
          .timeout(ApiConfig.timeout);

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

// Global instance for easy access
final cardioSyncService = CardioSyncService();
